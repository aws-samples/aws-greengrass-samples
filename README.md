AWS Greengrass Samples

## License Summary

These samples are made available under a modified MIT license. See the LICENSE file.

## greengrass-dependency-checker

This folder contains tools that help you check for system-level dependencies that Greengrass requires to be run.
Refer to the requirements outlined in the Greengrass Documentation, as well as the Greengrass Getting Started Guide, Module 1:
http://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html

## greengrass-modbus-adapter-python

This folder contains a sample Python Lambda function that will that will connect to a preconfigured modbus server and monitor coils for change. If the monitored values change, the Lambda function sends a message to a specific MQTT topic.
Refer to the pymodbus documentation: https://pymodbus.readthedocs.io/en/latest/.
Refer to the OPC/UA example: http://docs.aws.amazon.com/greengrass/latest/developerguide/opcua.html

## hello-world-python

This folder contains a sample Lambda function that uses the Greengrass SDK to publish a HelloWorld message to AWS IoT.
Refer to the Greengrass Getting Started Guide, Module 3 (Part I): http://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html

## hello-world-counter-python

This folder contains a sample Lambda function that uses the Greengrass SDK to publish HelloWorld messages to AWS IoT, maintaining state.
Refer to the Greengrass Getting Started Guide, Module 3 (Part II): http://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html

## traffic-light-example-python

This folder contains a set of functions that demonstrate a traffic light example using two Greengrass devices, a light controller and a traffic light.
It also contains a Lambda function that collects data from the traffic light system and sends it to an AWS DynamoDB table.
Refer to the Greengrass Getting Started Guide, Modules 5 and 6: http://docs.aws.amazon.com/greengrass/latest/developerguide/gg-gs.html

## greengrass-opcua-adapter-nodejs

This folder contains a sample NodeJS Lambda function that will that will connect to a preconfigured list of OPC-UA servers, and monitored configured NodeIds for change. If a monitor node's value changes, this lambda get notified, and republishes that value change onto a specific topic.
Refer to this documentation page for more details: http://docs.aws.amazon.com/greengrass/latest/developerguide/opcua.html
