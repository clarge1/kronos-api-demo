# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }

}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda_kronos" {
  type = "zip"

  source_dir  = "${path.root}/kronos"
  output_path = "${path.root}/kronos.zip"
}

resource "aws_s3_object" "lambda_kronos" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "kronos.zip"
  source = data.archive_file.lambda_kronos.output_path

  etag = filemd5(data.archive_file.lambda_kronos.output_path)
}



resource "aws_lambda_function" "kronos" {
  function_name = "Kronos"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_kronos.key

  runtime = "python3.9"
  handler = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda_kronos.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  layers = [
    aws_lambda_layer_version.required_packages.arn,
  ]

}

resource "null_resource" "pip_install" {
  triggers = {
    shell_hash = "${sha256(file("${path.root}/requirements.txt"))}"
  }

  provisioner "local-exec" {
    command = "python3 -m pip install -r requirements.txt -t ${path.root}/layer/python/lib/python3.9/site-packages --no-user"
  }
}


data "archive_file" "required_packages_zip" {
  type        = "zip"
  source_dir  = "${path.root}/layer"
  output_path = "${path.root}/layer.zip"
  depends_on  = [null_resource.pip_install]
}


resource "aws_lambda_layer_version" "required_packages" {
  layer_name          = "required_packages"
  filename            = data.archive_file.required_packages_zip.output_path
  source_code_hash    = data.archive_file.required_packages_zip.output_base64sha256
  compatible_runtimes = ["python3.9"]
}



resource "aws_cloudwatch_log_group" "kronos" {
  name = "/aws/lambda/${aws_lambda_function.kronos.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "kronos" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.kronos.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "kronos" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /unlock-time"
  target    = "integrations/${aws_apigatewayv2_integration.kronos.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kronos.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
