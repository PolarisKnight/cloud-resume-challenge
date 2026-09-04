# If the comments on some lines seem redundant, that is because they are. This script is for learning.

import boto3
import json

dynamodb = boto3.resource('dynamodb') # use the AWS Python SDK to define "dynamodb" in this script
table = dynamodb.Table('VisitorCounter') # the name of the table to focus on is VisitorCounter

def handler(event, context): # Lambda always passes these 2 parameters, even if they are not used in the function.
    response = table.update_item(
        Key={'counter': 1}, # matches the hash_key = "counter"
        UpdateExpression='ADD visits :incr', # ADD performs the increment atomically on DynamoDB's side, so this prevents race conditions
        ExpressionAttributeValues={':incr': 1}, # :incr is valued at 1
        ReturnValues='UPDATED_NEW' # hand back new values of attributes changed
    )

# DynamoDB returns numbers as Decimal, but json.dumps does not support that. Since this is a basic counter, we can declare as int.
    new_count = int(response['Attributes']['visits']) # Attributes and visits are keys that are returned with UPDATED_NEW


# returns must be actual strings if using AWS_PROXY integration. This can be done with json.dumps
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
},
        # 'body': str(new_count) will not work with AWS_PROXY
        'body': json.dumps({'visits': new_count})
    }