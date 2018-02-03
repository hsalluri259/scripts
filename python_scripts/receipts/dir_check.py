#!/bin/python
import os
if os.path.isdir('./nrw'):
    os.rmdir('./nrw')
else:
    print("no dir")
