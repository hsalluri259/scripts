#!/bin/python
import os
import random
import json
import shutil

count = os.getenv("FILE_COUNT") or 100
words = [word.strip() for word in open('/usr/share/dict/words').readlines()]

if os.path.isdir('./new'):
    print("new directory exists, removing it to recreate")
    shutil.rmtree('./new')
    os.mkdir('./new')
else:
    os.mkdir('./new')
for identifier in range(1, count + 1):
    amount = random.uniform(1.0, 1000.0)
    content = {
        'topic': random.choice('words'),
	'value': "%.2f" % amount
    }
    with open('./new/receipts-%s.json' % identifier, 'w') as f:
        json.dump(content, f)
