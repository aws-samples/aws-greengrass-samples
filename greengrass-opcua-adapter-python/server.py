#!/usr/bin/env python
"""
Example server inspired heavily from the Pymodbus server payload example

Starts a simple exmaple server that can be used to send and receive m
messages to verify client functionality.
"""
import logging
import time

from opcua import ua, Server

logging.basicConfig()
# pylint: disable=C0103
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def run_opcua_server():
    """
    Creates the OPC/UA server and starts it.
    """

    # setup our server
    server = Server()
    server.set_endpoint("opc.tcp://localhost:26543/example/server")

    # setup our own namespace, not really necessary but should as spec
    uri = "https://github.com/nathanagood/aws-greengrass-samples"
    idx = server.register_namespace(uri)

    # get Objects node, this is where we should put our nodes
    objects = server.get_objects_node()

    # populating our address space
    myobj = objects.add_object(idx, "MyObject")
    myvar = myobj.add_variable(idx, "MyVariable", 6.7)
    myvar.set_writable()    # Set MyVariable to be writable by clients

    # starting!
    server.start()
    
    try:
        count = 0
        while True:
            time.sleep(5)
            count += 1
            logger.debug('Setting value: %s', count)
            myvar.set_value(count)
    finally:
        #close connection, remove subcsriptions, etc
        server.stop()


if __name__ == "__main__":
    FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    logging.basicConfig(format=FORMAT)
    logger.info("Starting OPC/UA server...")
    logging.getLogger("opcua.server").setLevel(logging.WARNING)
    run_opcua_server()
