#!/usr/bin/env python
"""
Example server inspired heavily from the Pymodbus server payload example

Starts a simple exmaple server that can be used to send and receive m
messages to verify client functionality.
"""
import logging

from pymodbus.server.sync import StartTcpServer
from pymodbus.device import ModbusDeviceIdentification
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext, ModbusServerContext

logging.basicConfig()
# pylint: disable=C0103
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def run_payload_server():
    """
    Creates the Modbus server and starts it.
    """

    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, [17]*100),
        co=ModbusSequentialDataBlock(0, [17]*100),
        hr=ModbusSequentialDataBlock(0, [17]*100),
        ir=ModbusSequentialDataBlock(0, [17]*100)
    )
    context = ModbusServerContext(slaves=store, single=True)

    identity = ModbusDeviceIdentification()
    identity.VendorName = 'AWS Greengrass Samples'
    identity.ProductCode = 'AWS'
    identity.VendorUrl = 'https//github.com/aws-samples/aws-greengrass-samples'
    identity.ProductName = 'Sample Local Server'
    identity.ModelName = 'LocalServer'
    identity.MajorMinorRevision = '1.0'

    StartTcpServer(context, identity=identity, address=("127.0.0.1", 5020))


if __name__ == "__main__":
    logger.info("Starting Modbus server...")
    run_payload_server()
