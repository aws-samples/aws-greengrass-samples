"""
Sample AWS Lambda Function that can be deployed to AWS Greengrass
as a long-running Lambda function to expose a modbus client that will
attach to a server and then forward the messages to the MQTT client.

See README.md to learn how to test.
"""

from __future__ import print_function
import logging
import json
import threading
import time
import os

from pymodbus.client.sync import ModbusTcpClient

import greengrasssdk

# pylint: disable=C0103
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

MODBUS_IP = os.environ.get('MODBUS_SERVER_IP', '127.0.0.1')
MODBUS_PORT = int(os.environ.get('MODBUS_SERVER_PORT', '5020'))

# pylint: disable=C0103
greengrass_client = greengrasssdk.client('iot-data')

def client_factory():
    """
    Creates an instance of the Modbus client.
    """
    logger.debug("Creating client for: %s", threading.current_thread())
    client = ModbusTcpClient(MODBUS_IP, port=MODBUS_PORT)
    client.connect()
    return client


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

    client = client_factory()

    try:
        coil_values = [[False]*8]
        while True:
            result = client.read_coils(1, 8)
            logger.debug("Received value: %s", result)
            coil_values.append(result.bits)
            logger.debug(coil_values)

            if coil_values[0] != coil_values[1]:
                mqtt_payload = {i: coil_values[1][i] for i in range(0, len(coil_values[1]))}
                logger.debug("Values have changed, notifying with payload: %s",
                             json.dumps(mqtt_payload)
                            )
                greengrass_client.publish(topic='modbus/demo', payload=json.dumps(mqtt_payload))
            else:
                logger.debug("Values are the same. Going back to sleep.")

            # Sleep for 5 seconds
            del coil_values[0]
            time.sleep(5)

    finally:
        client.close()


if __name__ == '__main__':
    FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    logging.basicConfig(format=FORMAT)
    logging.getLogger("pymodbus.factory").setLevel(logging.WARNING)
    logging.getLogger("pymodbus.transaction").setLevel(logging.WARNING)
    logger.debug('Starting main...')

# Mock up event data and a context object
function_event = {}
function_context = {}

lambda_handler(function_event, function_context)
