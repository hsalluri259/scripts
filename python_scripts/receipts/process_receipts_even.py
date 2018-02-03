#!/bin/python
import glob
import os
import shutil
import json
import math
import re
if os.path.exists('./processed'):
    shutil.rmtree('./processed')
    os.mkdir("./processed")
else:
    print("Processed directory doesn't exists")
    os.mkdir('./processed')
#Get a list of receipts
receipts = [f for f in glob.iglob('./new/receipts-[0-9]*.json')
        if re.match('./new/receipts-[0-9]*[02468].json', f)]
subtotal = 0.0
#Iterate over receipts
for path in receipts:
    with open(path) as f:
    #Read content and tally a subtotal
         content = json.load(f)
         subtotal += float(content['value'])
    destination = path.replace('new', 'processed')
    ##Mv the file to processed directory
    shutil.move(path, destination)
    #Print that we processed the file
    print("moved '%s' to '%s'" % (path, destination))
#Print the subtotal of all processed receipts
print("Receipt subtotal: $%s" % round(subtotal, 2))
