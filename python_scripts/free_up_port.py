#!/bin/python
import subprocess
import os
from argparse import ArgumentParser

parser = ArgumentParser(description='Kill the running process on a given port')
parser.add_argument('port_number', type=int, help='Enter port number you want to free up')

port = parser.parse_args().port_number
try:
    output = subprocess.check_output(['lsof', '-n', "-iTCP:%s" % port])
except subprocess.CalledProcessError:
    print("Error: No process is listening on  %s" % port)
else:
    listening = None
   
    for line in output.splitlines():
        if "LISTEN" in line:
            listening = line
            break
    if listening:
        #PID is the second column of output
        pid = int(listening.split()[1])
        os.kill(pid,9)
        print("Killed %s on port %s" %(pid,port))
    ##this else block won't be executed as we have same condition in except
    else:
        print("No process is running on %s" % port)
