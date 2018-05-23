'use strict';

require('requirish')._(module);
const Subscriber = require('subscriber');
const opcua = require('node-opcua');
const IotData = require('aws-greengrass-core-sdk').IotData;
const MessageSecurityMode = require("node-opcua-service-secure-channel").MessageSecurityMode;
const SecurityPolicy = require("node-opcua-secure-channel").SecurityPolicy;

const device = new IotData();

Subscriber.setOPCUA(opcua);
Subscriber.setIoTDevice(device);
const OPCUASubscriber = Subscriber.OPCUASubscriber;

const configSet = {   
    server: {
        name: 'server',
        url: 'opc.tcp://localhost:26543',
    },  
    subscriptions: [
        {   
        name: 'MyPumpSpeed',
        nodeId: 'ns=1;s=PumpSpeed',
        },  
    ],  
};


const clientOptions = { 
    keepSessionAlive: true,
    connectionStrategy: {
        maxRetry: 100000, 
        initialDelay: 2000,
        maxDelay: 10 * 1000,
    },  
};

console.log("Setting up OPCUA client");
const client = new opcua.OPCUAClient(clientOptions);
const subscriber = new OPCUASubscriber(client, configSet.server, configSet.subscriptions);
subscriber.connect();

exports.handler = (event, context) => {
    console.log('Not configured to be called');
};
