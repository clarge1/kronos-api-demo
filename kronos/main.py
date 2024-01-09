import os
import sys
import json
import logging
import time_helper
import discord_helper

# Hack to use dependencies from lib directory
BASE_PATH = os.path.dirname(__file__)
sys.path.append(BASE_PATH + "/lib")

LOGGER = logging.getLogger(__name__)
logging.getLogger().setLevel(logging.INFO)




def response(status=200, headers=None, body=''):

    if not body:
        return {'statusCode': status}

    if headers is None:
        headers = {'Content-Type': 'application/json'}

    return {
        'statusCode': status,
        'headers': headers,
        'body': json.dumps(body)
    }

def lambda_handler(event, context):
    '''
    This function is called on HTTP request.
    It logs the request and an execution context. Then it returns body of the request.
    '''
    
    LOGGER.info(f'Context: {context}, Request: {event}')

    unlock_time_message = time_helper.get_next_unlock_time()
    discord_helper.send_message(f'<@444271672799789067>\n{unlock_time_message}')

    return response(status=200, body=unlock_time_message)


if __name__ == '__main__':
    # Do nothing if executed as a script
    lambda_handler({'lambda':'land'},{'hello':'world'})