import json
from enum import Enum
import math
import os
import boto3
import random
from datetime import datetime

sqs_client = boto3.client("sqs")
SQS_URL = os.getenv("SQS_URL")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
sns_client = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
tableName = os.getenv("DYNAMODB_TABLE")
table = dynamodb.Table(tableName)

class StatusType(Enum):
    STATUS = "status"
    ERROR = "error"

class Status(Enum):
    VALUE_OUT_OF_RANGE = ("VALUE_OUT_OF_RANGE", StatusType.ERROR)
    TEMPERATURE_TOO_LOW = ("TEMPERATURE_TOO_LOW", StatusType.STATUS)
    TEMPERATURE_TOO_HIGH = ("TEMPERATURE_TOO_HIGH", StatusType.STATUS)
    TEMPERATURE_CRITICAL = ("TEMPERATURE_CRITICAL", StatusType.STATUS)
    TEMPERATURE_OK = ("OK", StatusType.STATUS)
    UNKNOWN = ("UNKNOWN", StatusType.ERROR)

    def __init__(self, label, status_type):
        self.label = label
        self.type = status_type

def check_for_sensor_in_db(sensor_id):
    response = table.get_item(Key={'sensor_id': sensor_id})
    return True if 'Item' in response else False

def save_sensor_in_db(sensor_id):
    table.put_item(Item={'sensor_id': sensor_id, 'broken': False})

def change_sensor_status(sensor_id, broken):
    table.update_item(
        Key={'sensor_id': sensor_id},
        UpdateExpression='SET broken = :val1',
        ExpressionAttributeValues={':val1': broken}
    )

def calc_temp(R):
    a = 1.4 * 10**-3
    b = 2.37 * 10**-4
    c = 9.90 * 10**-8

    den = (a + b * math.log(R) + c * math.log(R)**3)
    den = den if den != 0 else 1

    return (1/den) - 273.15

def check_range(R):
   return (R >= 1 and R <= 20*10**3)

def get_status_for_temp(t):
    if t < 20:
        return Status.TEMPERATURE_TOO_LOW
    elif t < 100:
        return Status.TEMPERATURE_OK
    elif t < 250:
        return Status.TEMPERATURE_TOO_HIGH
    else:
        return Status.TEMPERATURE_CRITICAL

def send_email(sensor_id, temp):
    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=f"Temperature critical for sensor with id: {sensor_id}",
        Subject="Critical temperature!"
    )

def save_error_to_db(sensor_id, temp):
    change_sensor_status(sensor_id, True)

def save_to_sqs(sensor_id, temp):
    print(f"Sensor {sensor_id} is OK")
    sqs_client.send_message(
            QueueUrl=SQS_URL,
            MessageBody=json.dumps({"sensor_id": sensor_id, "value": temp, "location_id": random.randint(1, 5), "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")})
        )

status_handlers = {
    Status.TEMPERATURE_CRITICAL: send_email,
    Status.VALUE_OUT_OF_RANGE: save_error_to_db,
    Status.TEMPERATURE_OK: save_to_sqs
}

def lambda_handler(event, context):
    r = event["value"]
    sensor_id = event["sensor_id"]
    print(r)
    try:
        if not check_range(r):
            raise ValueError("VALUE_OUT_OF_RANGE")
    
        temp = calc_temp(r)
        print("TEMP: " + str(temp))
        status = get_status_for_temp(temp)
    except ValueError as e:
        status = Status.VALUE_OUT_OF_RANGE
    except Exception as e:
        print(f"Error: {e}")
        status = Status.UNKNOWN

    if not check_for_sensor_in_db(sensor_id):
        save_sensor_in_db(sensor_id)

    handler = status_handlers.get(status, lambda sensor_id, temp: None)
    try:
        handler(sensor_id, temp)
    except Exception as e:
        print(f"Error in handler: {e}")

    return (json.dumps({status.type.value: status.label}))
