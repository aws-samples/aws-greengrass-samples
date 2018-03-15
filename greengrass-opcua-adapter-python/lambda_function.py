"""
Sample AWS Lambda Function that can be deployed to AWS Greengrass
as a long-running Lambda function to expose a modbus client that will
attach to a server and then forward the messages to the MQTT client.

See README.md to learn how to test.
"""

from __future__ import print_function

import json
import logging
import os
import time

from opcua import Client, ua

import greengrasssdk

# pylint: disable=C0103
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

SERVER_URL = os.environ.get('SERVER_URL', 'opc.tcp://localhost:26543/example/server')
SUBSCRIPTION_NODEID = os.environ.get('SUBSCRIPTION_NODEID', 'ns=1;s=PumpSpeed')

IOT_MQTT_TOPIC = 'hello/opcua'

# pylint: disable=C0103
greengrass_client = greengrasssdk.client('iot-data')


class SubscriptionHandler(object):
    """
    Handles messages in the subscription.
    """

    def datachange_notification(self, node, val, data):
        """
        Handles notifications when data has changed.
        """
        logger.info("New data change event; new value is: %s", val)
        logger.debug("From node: %s; data is: %s", node, data)

        # Forward the data to an MQTT topic 
        message = {
            'data': val
        }

        greengrass_client.publish(
            topic=IOT_MQTT_TOPIC,
            payload=json.dumps(message)
        )

    def event_notification(self, event):
        """
        Handles event notifications.
        """
        logger.debug("Received event: %s", event)


#pylint: disable=unused-argument
def lambda_handler(event, context):
    """
    Handler for the AWS Lambda function.
    :param event: AWS Lambda uses this parameter to pass in event data to the handler. This
    parameter is usually of the Python dict type. It can also be list, str, int, float, or
    NoneType type.
    :param context: The AWS Lambda event context. To learn more about what is included in
    the context,
    see https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html.
    """

    logger.debug('Handling event: %s', json.dumps(event))

    client = Client(SERVER_URL)

    try:
        client.connect()
        root = client.get_root_node()

        logger.debug("Root node is: %s", root)
        objects = client.get_objects_node()
        logger.debug("Objects node is: %s", objects)

        # Node objects have methods to read and write node attributes as well as browse or populate address space
        logger.debug("Children of root are: %s", root.get_children())

        logger.debug('Creating subscription...')
        subscription_handler = SubscriptionHandler()
        subscription = client.create_subscription(500, subscription_handler)
        logger.info('Finished creating subscription to %s', SERVER_URL)

        logger.debug('Subscribing to data changes...')
        variable = root.get_child(["0:Objects", "2:MyObject", "2:MyVariable"])
        handle = subscription.subscribe_data_change(variable)
        logger.info('Subscribed to %s', handle)

        while True:
            time.sleep(1)

    finally: 
        client.disconnect()    



if __name__ == '__main__':
    FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    logging.basicConfig(format=FORMAT)
    logging.getLogger("opcua.client").setLevel(logging.WARNING)
    logging.getLogger("opcua.common").setLevel(logging.WARNING)
    logging.getLogger("opcua.uaprotocol").setLevel(logging.WARNING)
    logger.debug('Starting main...')

# Mock up event data and a context object
function_event = {}
function_context = {}

# In long-running Lambda functions installed on AWS Greengrass, the lambda_handler
# function doesn't get called. Rather, the script just runs. So the handler needs
# to be called here.
lambda_handler(function_event, function_context)
