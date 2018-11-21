#!/bin/bash
LOGFILE=sshrequest.txt
LOGFILESHORT=sshrequestshort.txt
for i in `cat serverlist | grep -v '#'`
do
    echo "hostname and vtier" >> ${LOGFILE} 2>&1
    hostname=`echo ${i}|cut -d '@' -f2`
    vtier=`echo ${i}|cut -d '@' -f1`
    echo "raising ssh request for ${hostname} ------ ${vtier}" >> ${LOGFILE} 2>&1
    /usr/local/bin/sshrequest -b "Pushing files and running commands on remote servers" -d ${vtier} -s ${hostname} -J application_account -j host_name -a Y,Y,Y,Y -e 20991231 >> ${LOGFILE} 2>&1
        if [ $? -eq 0 ]
                then
                        echo "ssh request raised for ${hostname} ----- ${vtier}" >> ${LOGFILE} 2>&1
                        echo "${hostname} - ${vtier} - Passed" >> LOGFILESHORT
                        echo "${hostname} - ${vtier} - Passed"
                        echo "==========================================================================================" >> ${LOGFILE} 2>&1
                else
                        echo "ssh request failed to raise for ${hostname} ----- ${vtier}" >> ${LOGFILE} 2>&1
                        echo "${hostname} - ${vtier} - Failed" >> LOGFILESHORT
                        echo "${hostname} - ${vtier} - Failed"
                        echo "==========================================================================================" >> ${LOGFILE} 2>&1
        fi
done
