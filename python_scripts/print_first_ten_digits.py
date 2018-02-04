#!/bin/python

#    Prints the first ten digits of Pi to the screen.
#    Accepts an optional environment variable called DIGITS. If present, the script will print that many digits of Pi instead of 10.

from os import getenv
from math import pi

digits = getenv("DIGITS") or 10
print("%.*f" % (int(digits),pi))
