#!/usr/bin/env python3

import os

def getTestStatus():
    try:
        testlog = reversed(open(os.path.join('/mux-flow/results/', 'simulation.log'), encoding='iso8859_2').readlines())
        for line in testlog:
            if 'RESULT[passed]' in line: 
                return 'passed'
            if 'RESULT[failed]' in line:
                return 'failed'
        return 'failed'
    except: 
        return 'incomplete'

# Call a function to get the test pass/fail status
result = open('testRunResult', 'w+')
resultStr = str(getTestStatus())
result.write(resultStr)
result.close()
