#!/bin/bash
##writing script to find out average throughput with input access.log
ip_address=$1
count=0
sum=0
while read line
do
        if [[ `echo $line | grep -c $1` -eq "1" ]];
        then
        echo "Printing line for the given IP: $line"
        result=`echo $line | cut -d 't' -f3`
        sum=`expr $sum + $result`

                count=$[ $count + 1 ]
        fi
done < access.log
echo "Sum is $sum"
echo "count is $count"
average=`expr $sum / $count`
echo "Average throughput is $average"
exit