#
# Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#

# ***********************         IMPORTANT          ***********************
# This lambda function is part of the traffic light example and requires 
# both lightController.py and trafficLight.py to work properly.
# It also requires setup steps including permissions. Please refer to 
# Module 6 in Greengrass getting started guide for directions.
#
# Because this Lambda creates a small table in DynamoDB, you may be charged
# for creating a table. Please refer to DynamoDB Pricing here: 
# https://aws.amazon.com/dynamodb/pricing/
#
# **************************************************************************

# This example demonstrates how a shadow state can be tracked in a long-lived
# lambda and how to interface with DynamoDB. This lambda function listens 
# to shadow MQTT message on light status, and when the light is green, 
# it generates a random number to represent the number of cars that have passed. 
# This function stores statistics on these numbers and uploads them to DynamoDB 
# on every fourth green light. Since this function is long-lived it 
# will run forever when deployed to a Greengrass core.

import logging
import boto3
from datetime import datetime
from random import *
from botocore.exceptions import ClientError

# Initialized DynamoDB client
# Note this creates a dynamodb table in region us-east-1 (N. Virginia)
# Change the region name to something different if you like
# Note endpoint and aws credentials are not specified. By default this 
# uses the credentials configured for the session. See Boto 3 docs
# for more details.

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tableName = "CarStats"

# Create the dynamo db table if needed
try:
    table = dynamodb.create_table(
        TableName=tableName,
        KeySchema=[
            {
                'AttributeName': 'Time', 
                'KeyType': 'HASH'  #Partition key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'Time',
                'AttributeType': 'S'
            }
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 5,
            'WriteCapacityUnits': 5
        }
    )

    # Wait until the table exists.
    table.meta.client.get_waiter('table_exists').wait(TableName=tableName)
except ClientError as e:
    if e.response['Error']['Code'] == 'ResourceInUseException':
        print("Table already created")
    else:
        raise e

# initialize the logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# This is a long lived lambda so we can keep state as below
totalTraffic = 0
totalGreenlights = 0
minCars = -1
maxCars = -1

# This handler is called when an event is sent via MQTT
# Event targets are set in subscriptions settings
# This should be set up to listen to shadow document updates
# This function gets traffic light updates from the shadow MQTT event
# On every Green light it does the following:
#    passing cars are simulated by a random number 1 <= n <= 20
#    the minimum and maximum cars passing during a green light are tracked
#    the total number of cars passing during all green lights are tracked
# On every 3rd Green light these stats are sent to CarStats dynamodb table
# using a timestamp as the hash key
def function_handler(event, context):
    global totalTraffic
    global totalGreenlights
    global minCars
    global maxCars
    
    # grab the light status from the event
    # Shadow JSON schema:
    # { "state": { "desired": { "property":<R,G,Y> } } }
    logger.info(event)
    lightValue = event["current"]["state"]["reported"]["property"]
    logger.info("reported light state: " + lightValue)
    if lightValue == 'G':
        logger.info("Green light")

        # generate a random number of cars passing during this green light
        cars = randint(1, 20)

        # update stats
        totalTraffic += cars
        totalGreenlights+=1
        if cars < minCars or minCars == -1:
            minCars = cars
        if cars > maxCars:
            maxCars = cars

        logger.info("Cars passed during green light: " + str(cars))
        logger.info("Total Traffic: " + str(totalTraffic))
        logger.info("Total Greenlights: " + str(totalGreenlights))
        logger.info("Minimum Cars passing: " + str(minCars))
        logger.info("Maximum Cars passing: " + str(maxCars))

        # update car stats to dynamodb every 3 green lights
        if totalGreenlights % 3 == 0:
            global tableName
            table = dynamodb.Table(tableName)
            table.put_item(
                Item={
                    'Time':str(datetime.utcnow()),
                    'TotalTraffic':totalTraffic,
                    'TotalGreenlights':totalGreenlights,
                    'MinCarsPassing':minCars,
                    'MaxCarsPassing':maxCars,
                }
            )
    return