#!/bin/bash
while [ $# -ne 1 ]
do
        echo "Check usage"
        echo "available actions: ./reverse.sh data2.txt"
        exit
done
#Shell wrapper for sed editor script.
#               to reverse text file lines.
###########################################
##G Appends hold space to pattern space
##h Copies pattern space to hold space
##passing data2.txt as $1 in the command line
sed -n '{1!G ; h ; $p }' $1
