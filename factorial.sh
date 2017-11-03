#!/bin/bash
#Add commas to number in factorial answer
#########################################
while [ $# -lt 1 ]
do
        echo "Check Usage"
        echo "Available actions: ./factorial.sh 20"
        exit
done
factorial=1
counter=1
number=$1
while [ $counter -le $number ]
do
        factorial=$[ $factorial * $counter ]
        counter=$[ $counter + 1 ]
done
####
result=$(echo $factorial | sed '{
:start
s/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/
t start
}')
##
echo " The result is $result"
