# OPC/UA Adapter Example for AWS Greengrass (Python)

This folder contains a sample AWS Lambda function implemented in Python that demonstrates how to create a listener for communications using the [OPC/UA](https://en.wikipedia.org/wiki/OPC_Unified_Architecture) protocol.

This example and documentation assumes you already have an AWS Greengrass device configured and are familiar with the process of deploying a Lambda function to AWS Greengrass. It's highly recommended that you follow the steps in
"[Module 1: Environment Setup for Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/module1.html)", "[Module 2: Installing the Greengrass Core](https://docs.aws.amazon.com/greengrass/latest/developerguide/module2.html)", and "[Module 3 \(Parts 1 & 2\): AWS Lambda on AWS Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/module3-I.html)" under "[Getting Started with Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html)"

The MQTT topic to which this example writes is `hello/opcua`. You will need to configure a subscription to that topic for Greengrass. See step 3 under "[Configure the Lambda Function for AWS Greengrass](https://docs.aws.amazon.com/greengrass/latest/developerguide/config-lambda.html)" to learn how to set up a subscription.

## Files

### `lambda_function.py`

This file contains the AWS Lambda code. This code uses a modbus client to attach to a the local modbus server (see "`server.py`") and forwards messages to an MQTT topic `modbus/demo`.

### `server.py`

To provide a simple local server for use when testing the AWS Lambda function, the `server.py` contents were directly based on the documentation for **PyModbus**. See [the example here](https://pymodbus.readthedocs.io/en/latest/source/example/modbus_payload_server.html).

## Packaging the code

Before you can package the example code to deploy as a AWS Lambda function, you will need to download
the AWS Greengrass Core SDK software. Follow the steps under to
 "[Create and Package a Lambda Function](https://docs.aws.amazon.com/greengrass/latest/developerguide/create-lambda.html)" to download the 
AWS Greengrass Core SDK. You will need the following folders in the base directory for your project: 

* `greengrass_common`
* `greengrass_ipc_python_sdk`
* `greengrasssdk`

The `package.sh` script will exit if you do not have these folder present. It includes them in the 
package (ZIP file) for your Lambda function.

To package up your Lambda function, execute the following command:

    $ ./package.sh

It will create a file called `python_opcua_adapter.zip` in your folder. you can upload this ZIP file,
as-is, when creating your Lambda function.

### Recommended: using virtualenv

When modifying the function code, consider using [virtualenv](https://virtualenv.pypa.io/en/stable/) to create an environment *for each Lambda function that you create*. As an example, in this repository the **greengrass-opcua-adapter-python** and **greengrass-modbus-adapter-python** folders each should have their own `venv` folders inside them.

Using virtualenv in this fashion allows you to scope the required libraries, found in `requirements.txt`, to each Lambda function so the packages do not become bloated by containing libraries that aren't required.

The `package.sh` script will use the `requirements.txt` file to download dependencies into a temporary folder location so the dependencies are included in the ZIP file.

## Testing

To see the code in action running as an AWS Lambda function on your AWS Greengrass device, using the AWS console follow these steps:

1. If you're using Linux or Mac OS, run `package.sh` on the command line in the *greengrass-modus-adapter-python* directory to create the `modbus_client.zip` file.
1. Log into the AWS console.
1. Create an AWS Lambda function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/create-lambda.html).
1. Deploy a version of the function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/package.html).
1. Create an alias for the function using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/package.html).
1. Add the Lambda function to AWS Greengrass using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/configs-core.html).
1. Add the subscription using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/configs-core.htm). This example publishes messages to the `hello/opcua` topic.
1. Under AWS IoT *Test*, subscribe to the `hello/opcua` topic using the steps [here](https://docs.aws.amazon.com/greengrass/latest/developerguide/lambda-check.html).

You will need the contents of the **greengrass-opcua-adapter-python** folder on your AWS Greengrass device if you want to run the local modbus server.

To test the function, first start the server by logging onto the AWS Greengrass device `python server.py`. This will create the server and bind it to `localhost:26543`.

If you followed the steps above to deploy the function, it should be running on the Greengrass device. The server code will periodically write a message to the OPC/UA server. The Lambda function will in turn publish this message to the `hello/opcua` topic. If you are testing in the console, every five seconds you should see a message that looks like the following:

    {
        'data': 5
    }