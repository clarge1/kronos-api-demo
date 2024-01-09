# Learn Terraform - Lambda functions and API Gateway

AWS Lambda functions and API gateway are often used to create serverless
applications.

This repo is a companion repo to the [AWS Lambda functions and API gateway](https://developer.hashicorp.com/terraform/tutorials/aws/lambda-api-gateway) tutorial.



run: 

aws lambda invoke --region=us-east-2 --function-name=$(terraform output -raw function_name) response.json

curl "$(terraform output -raw base_url)/unlock-time"