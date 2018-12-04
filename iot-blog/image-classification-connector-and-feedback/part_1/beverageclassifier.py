#
# Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# beverageclassifier.py
# This lambda function demonstrates the use of the AWS IoT Greengrass Image Classification
# Connector. It will capture an image using a Raspberry Pi PiCamera, make an
# inference using the IoT Greengrass Image Classification Connector (via the IoT Greengrass
# machine learning SDK), and report the result back to a topic.
#
# To be used alongside part 1 of the accompanying blog post.
#

import json
import os
import time

import boto3
import logging
import numpy as np
from picamera import PiCamera

import greengrasssdk
import greengrass_machine_learning_sdk as ml

# This directory will be used to store our
# unlabeled training data. It should be
# configured as a local resource in GG.
LOCAL_RESOURCE_DIR = "/raw_field_data"

# Categories listed in the order defined in the
# .lst used to train the model (alphabetical).
CATEGORIES = ['beer-mug', 'clutter', 'coffee-mug', 'soda-can', 'wine-bottle']

gg_client = greengrasssdk.client('iot-data')
ml_client = ml.client('inference')

# Configure the PiCamera to take square images. Other
# resolutions will be scaled to a square when fed into
# the image-classification model which can result
# in image distortion.
camera = PiCamera(resolution=(400,400))

def capture_and_save_image_as(filename):
    camera.capture(filename, format='jpeg')

def get_inference(image_filename):
    logging.info('Invoking Greengrass ML Inference Service')
    
    with open(image_filename, 'rb') as image_file:
        image = image_file.read()

    try:
        response = ml_client.invoke_inference_service(
            AlgoType='image-classification',
            ServiceName="beverage-classifier",
            ContentType='image/jpeg',
            Body=image
        )
    except ml.GreengrassInferenceException as e:
        logging.info('Inference exception {}("{}")'.format(e.__class__.__name__, e))
        raise
    except ml.GreengrassDependencyException as e:
        logging.info('Dependency exception {}("{}")'.format(e.__class__.__name__, e))
        raise

    inference = response['Body'].read()
    inference = inference[1:-1]
    predictions = np.fromstring(inference, dtype=np.float, sep=',')

    logging.info("Received the following predictions from beverage-classifier model:" + str(predictions))

    # Get the prediction that has the highest confidence
    prediction_confidence = predictions.max()

    # The indicies of the inference result will match our CATEGORIES
    # array. Find the index of the highest prediction confidence,
    # and index into the CATEGORIES array to find the category name.
    predicted_category = CATEGORIES[predictions.argmax()]

    return predicted_category, prediction_confidence

def create_image_filename():
    current_time_millis = int(time.time() * 1000)
    filename = LOCAL_RESOURCE_DIR + "/" + str(current_time_millis) + ".jpg"
    return filename

def function_handler(event, context):
    image_filename = create_image_filename()
    capture_and_save_image_as(image_filename)

    predicted_category, prediction_confidence = get_inference(image_filename)

    gg_client.publish(
        topic='/response/prediction/beverage_container',
        payload=json.dumps({'message':'Classified image as {} with a confidence of {}'.format(predicted_category, str(prediction_confidence))})
    )
    
    os.remove(image_filename)
    return
