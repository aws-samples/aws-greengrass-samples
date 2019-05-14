import logging
import messagebird
import requests
import urllib3
import chardet
import sys
import os
import certifi
import dns.ipv4
import dns.resolver
import dns.inet
import idna
import __future__

def send_sms(sms_content):
    access_key = 'AccessKey'
    client = messagebird.Client(access_key)
    sms_originator = 'phonenumber'
    sms_recipients = 'phonenumber'
    try:
        client.message_create(sms_originator,sms_recipients,sms_content)
    except Exception as e:
        logging.error(e)

def function_handler(event, context):
    try:
        send_sms(event)
    except Exception as e:
        logging.error(e)
    return
