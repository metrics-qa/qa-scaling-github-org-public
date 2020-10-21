#!/usr/bin/env python3
 

import requests
import argparse
import os, shutil
import json
import random
from datetime import datetime
from datetime import date
import time

possibleResults = ['passed', 'failed', 'incomplete']

parser = argparse.ArgumentParser(description='Variable test run script')
parser.add_argument('--duration', '-d', help='Run time in ms', default='random')
parser.add_argument('-bank', '-i', help='set to true if you want to test pinging iron-bank', action='store_true', default=False)
parser.add_argument('-waves', '-w', help='set to true if you want to test moving vcd files', action='store_true', default=False)
parser.add_argument('-coverage', '-c', help='set to true if you want to test moving coverage files', action='store_true', default=False)
parser.add_argument('--result', '-r', help='preset the result of the test run', default='random', choices=['passed', 'failed', 'incomplete', 'random'])
args = parser.parse_args()

cluster = str(os.environ['HOSTNAME']).split('-')[0]

def createIronBankSession():
    print("session")
    url = "https://iron-bank." + cluster + ".metrics.ca/usage/v1/"
    sbody = {
        "externalId": "00000",
        "version": "1.0",
        "type": "scaling_generator_session",
        "user": 'Variable Scaling Generator'
    }
    headers = { "Content-Type": "application/json" }
    cert = (os.path.abspath('/.tls/tls_cert.pem'), os.path.abspath('/.tls/tls_key.pem'))
    sres = requests.post(url + "sessions", data=json.dumps(sbody), headers=headers, cert=cert, verify=False)
    print(sres.json())
    sessionId = sres.json().get('id')
    
    feature_name = 'scaling_generator_feature_1'
    fbody = {
        "sessionId": sessionId,
        "name": feature_name
    }
    fres = requests.post(url + 'features', data=json.dumps(fbody), headers=headers, cert=cert, verify=False)
    print(fres.json())
    featureName = fres.json().get('name')
    return sessionId, featureName

def pingIronBank(sessionId, feature):
    print('ping')
    url = "https://iron-bank." + cluster + ".metrics.ca/ping/v1/minutes"

    body = { "sessionId": sessionId, "features": [feature] }
    headers = { "Content-Type": "application/json" }
    cert = (os.path.abspath('/.tls/tls_cert.pem'), os.path.abspath('/.tls/tls_key.pem'))
    pres = requests.post(url, data=json.dumps(body), headers=headers, cert=cert, verify=False)
    print(pres.json())
    return pres.json()

duration = random.randint(300000, 1200000)
startTime = datetime.now()
elapsedTime = 0

if args.duration is not 'random': 
    duration = int(args.duration)
print('duration (s): ' + str(duration/1000))
logPath = 'results/sim.log'
if not os.path.exists(os.path.dirname(logPath)):
    os.makedirs(os.path.dirname(logPath))
logFile = open(logPath, 'w+')
if args.result == "random":
    r = random.choice(possibleResults)
    print('RESULT[' + r + ']')
    logFile.write('RESULT[' + r + ']')
else: 
    print('RESULT[' + args.result + ']')
    logFile.write('RESULT[' + args.result + ']')


if args.bank:
    if cluster is not 'nightly' or cluster is not 'staging':
        logFile.write("This " + cluster + " cluster is not setup to run this project on")
    try:
        sid, fname = createIronBankSession()
        print(sid + " : " + fname + '\n')
        logFile.write(sid + " : " + fname + '\n')
    except Exception as err:
        print(err)
        logFile.write(str(err) + '\n')

    minuteTracker = 0
    minuteStartTime = startTime

while elapsedTime < duration:
    total_delta = datetime.now()-startTime
    elapsedTime = total_delta.total_seconds() * 1000
    print('update elapsedTime: ' + str(elapsedTime))
    if args.bank:
        minute_delta = datetime.now() - minuteStartTime
        minuteTracker = minute_delta.total_seconds() * 1000
        if minuteTracker > 60000:
            try:
                response = pingIronBank(sid, fname)
                print(response)
                logFile.write(str(response) + '\n')
            except Exception as err:
                print(err)
                logFile.write(str(err) + '\n')
            minuteTracker=0
            print('reset minuteStartTime: ' + str(minuteStartTime))
            minuteStartTime = datetime.now()
    time.sleep(5)

print('=T:Simulation terminated by $finish at time ' + str(elapsedTime) + '\n')
print('=F:LIU KANG WINS .... Fatality')
print('Simulation time precision is 1s\n')

if args.waves:
    shutil.copyfile('resources/waves/waves.vcd', 'results/sim.vcd')
    logFile.write('Moved sim.vcd to results folder\n')
    print('Moved sim.vcd to results folder\n')

if args.coverage:
    metricsFiles = ["metrics_1.db", "metrics_2.db", "metrics_3.db", "metrics_4.db", "metrics_5.db"]
    useFile = random.choice(metricsFiles)
    shutil.copyfile('resources/coverage/' + useFile, 'results/metrics.db')
    logFile.write('Moved metrics.db to results folder\n')
    print('Moved metrics.db to results folder\n')

logFile.close()
exit(0)

