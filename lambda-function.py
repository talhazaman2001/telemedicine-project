import json
import boto3
import datetime

# Initialise DynamoDb resource and table
dynamodb = boto3.resource('dynamodb')
table = dynamodb.table('GlucoseData')

def lambda_handler(event, context):
    """
    AWS Lambda function to process blood glucose levels data from IoT devices.

    This function takes patient data from IoT devices, validates it, and stores it in DynamoDB.
    It also sends alerts via SNS if abnormal blood glucose levels are detected.
    """

    # Parse the incoming event (JSON)
    try: 
        glucose_data = json.loads(event['body'])
        device_id = glucose_data['device_id']
        timestamp = glucose_data.get('timestamp', datetime.now().isoformat())
        glucose_levels = glucose_data['glucose_levels']

        # Store Glucose levels data in DynamoDB
        response = table.put_item(
            Item = {
                'device_id': device_id, # unique to each patient
                'timestamp': timestamp,
                'glucose_levels': glucose_levels
            }
        )

        # If Glucose levels in mg/DL above a threshold, send an alert
        if glucose_levels > 180:
            send_alert (device_id, glucose_levels)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Glucose levels processed successfully',
                'device_id': device_id,
                'timestamp': timestamp,
                'glucose_levels': glucose_levels
            })
        }
    except Exception as e:
        # Any exception during processing: missing value/failure to communicate with DynamoDB
        return {
            'statusCode': 500,
            'body': json.dumps({'error' : str(e)})
        }


def send_alert(device_id, glucose_levels):
    """
    Sends an alert via SNS when abnormal Glucose levels  detected.
    
    Args:
        device_id (str): The ID of the device with abnormal Glucose levels.
        glucose_levels (float): The Glucose levels that triggered an alert.
    """

    sns = boto3.client('sns')
    topic_arn = 'arn:aws:sns:eu-west-2:463470963000:GlucoseAlerts'
    message = (f'ALERT: Device {device_id} has abnormal glucose levels.\n'
               f'Glucose Levels: {glucose_levels} mg/DL')

    # Publish the message to SNS
    sns.publish(
        TopicArn = topic_arn,
        Message = message,
        Subject = 'Abnormal Glucose Levels Alert'
    )          

    