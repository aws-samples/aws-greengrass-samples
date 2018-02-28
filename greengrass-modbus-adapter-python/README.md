# Modbus Adapter Example for AWS Greengrass (Python)

This folder contains a sample AWS Lambda function implemented in Python that demonstrates how to create a listener for communications using the [Modbus](https://en.wikipedia.org/wiki/Modbus) protocol.

This example and documentation assumes you already have an AWS Greengrass device configured and are familiar with the process of deploying a Lambda function to AWS Greengrass. It's highly recommended that you follow the steps in
"[Module 1: Environment Setup for Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/module1.html)", "[Module 2: Installing the Greengrass Core](https://docs.aws.amazon.com/greengrass/latest/developerguide/module2.html)", and "[Module 3 \(Parts 1 & 2\): AWS Lambda on AWS Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/module3-I.html)" under "[Getting Started with Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html)"

## Files

### `lambda_function.py`

This file contains the AWS Lambda code. This code uses a modbus client to attach to a the local modbus server (see "`server.py`") and forwards messages to an MQTT topic `modbus/demo`.

### `server.py`

To provide a simple local server for use when testing the AWS Lambda function, the `server.py` contents were directly based on the documentation for **PyModbus**. See [the example here](https://pymodbus.readthedocs.io/en/latest/source/example/modbus_payload_server.html).

## Testing

To see the code in action running as an AWS Lambda function on your AWS Greengrass device, using the AWS console follow these steps:

1. If you're using Linux or Mac OS, run `package.sh` on the command line in the *greengrass-modus-adapter-python* directory to create the `modbus_client.zip` file.
1. Log into the AWS console.
1. Create an AWS Lambda function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/create-lambda.html).
1. Deploy a version of the function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/package.html).
1. Create an alias for the function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/package.html).
1. Add the Lambda function to AWS Greengrass using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/configs-core.html).
1. Add the subscription using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/configs-core.htm).
1. Under AWS IoT *Test*, subscribe to the `modbus/demo` topic using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/lambda-check.html).

You will need the contents of the `greengrass-modbus-adapter-python` folder on your AWS Greengrass device if you want to run the local modbus server.

To test the function, first start the server by logging onto the AWS Greengrass device `python server.py`. This will create the server and bind it to `localhost:5020`.

If you followed the steps above to deploy the function, it should be running on the Greengrass device.

Use the `python` command to start the python console, and type the following commands:

    $ python
    Python 2.7.12 (default, Dec  4 2017, 14:50:18)
    [GCC 5.4.0 20160609] on linux2
    Type "help", "copyright", "credits" or "license" for more information.
    >>> from pymodbus.client.sync import ModbusTcpClient
    >>> client = ModbusTcpClient('127.0.0.1', 5020)
    >>> client.write_coils(0, [0, 1, 0, 1, 0, 1, 1, 1])

When you call the `client.write_coils` function, you should see a message in the AWS IoT console that looks like this:

    {
        "0": false,
        "1": true,
        "2": false,
        "3": true,
        "4": false,
        "5": true,
        "6": true,
        "7": true
    }
