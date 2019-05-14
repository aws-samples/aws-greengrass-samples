import logging
import time
import datetime
import json
import os
import dns.ipv4
import dns.resolver
import dns.inet
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, InvalidName
import __future__

def write_to_mongo(topic_message):
    try:
        mongodb_conn = "localhost"
        mongoClient = MongoClient(mongodb_conn)
        db = mongoClient.plc_poc_db
        collection = db.plc_poc
        receiveTime = datetime.datetime.now()
        message = {"time": receiveTime, "value": topic_message}
        collection.insert_one(message)
    except Exception as e:
        logging.error(e)

def function_handler(event, context):
    try:
        write_to_mongo(event)
    except Exception as e:
        logging.error(e)
    return
