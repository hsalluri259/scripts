#!/bin/python
import glob
import os
import shutil
import json

try:
    os.mkdir("./processed")
except OSError:
    print("Processed directory already exists")

#Get a list of receipts
receipts = glob.glob('./new/receipts-[0-9]*.json')
subtotal = 0.0
#Iterate over receipts
for path in receipts:
    with open(path) as f:
    #Read content and tally a subtotal
         content = json.load(f)
         subtotal += float(content['value'])
    name = path.split('/')[-1]
    print(name)
    destination = "./processed/%s" % name
    ##Mv the file to processed directory
    shutil.move(path, destination)
    #Print that we processed the file
    print("moved '%s' to '%s'" % (path, destination))
#Print the subtotal of all processed receipts
print("REceipt subtotal: $%.2f" % subtotal)
