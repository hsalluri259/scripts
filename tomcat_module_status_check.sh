#!/bin/bash
#set -x
ENV=$1
SOURCE=$2
TO=$3
DEPLOY_STATUS=$4
username=xyz
password=abc
port=8443
server_list=/opt/app/workload/jenkins/scripts/deploy/tomcatlist
result=/opt/app/workload/jenkins/scripts/tools/api_test/logs
PWD=`pwd`
while IFS=":" read host_name environment
do
        status_new=0
        if [[ $ENV == $environment ]];
        then
                echo "Checking module status for ${host_name} of $ENV"
                curl -u $username:$password https://${host_name}:$port/manager/text/list -k >> $result/${ENV}_${host_name}
        echo "${DEPLOY_STATUS} </br>" >> $result/final_${ENV}_module_status
        echo "Status of modules on ${host_name} of ${ENV} environment </br>" >> $result/final_${ENV}_module_status
        while IFS=":" read context status session module
        do
                if [[ `echo $module | grep -c -w "pwdmgmt"` -eq "1" ]] || [[ `echo $module | grep -c -w "iamportalnewui"` -eq "1" ]]|| [[ `echo $module | grep -c -w "iampwdmgmt"` -eq "1" ]]; then
                        continue
                else
                        if [[ `echo $status | grep -c -w "stopped"` -eq "1" ]]; then
                                sed -i "s/.*${host_name}.*/Status of modules on ${host_name} of ${ENV} environment <\/br> - <font color=red> Below module(s) failed <\/font><\/br><\/br>/" $result/final_${ENV}_module_status
                                echo "<font color=red> $module : $status </font></br> </br>" >> $result/final_${ENV}_module_status
                                status_new="stopped"
                        elif [[ `echo $status | grep -c -w "running"` -eq "1" ]] && [[ `echo ${status_new} | grep -c -w "stopped"` -eq "0" ]] ; then
                                sed -i "s/.*${host_name}.*/Status of modules on ${host_name} of ${ENV} environment <\/br> - <font color=green> OK <\/font><\/br><\/br>/" $result/final_${ENV}_module_status
                        else
                                continue
                        fi
                fi
        done < $result/${ENV}_${host_name}
        fi
if [ -f "$result/${ENV}_${host_name}" ]
then
rm $result/${ENV}_${host_name}
fi
done < ${server_list}
email_setup()
{
/usr/sbin/sendmail -t << MAIL_END
Subject : ALERT:MODULE Status ${ENV}
To: $TO
from: do_not_reply@HALO_FN_ALERT
Mime-Version: 1.0
Content-Type: text/html
<html>
<b>Below are the details of tomcat module test</b></br></br>
<b>$DETAIL </br>
</html>
MAIL_END
}
#Send email
DETAIL=`cat $result/final_${ENV}_module_status`
if [[ `echo $DETAIL | grep -c -w "stopped"` -eq "1" ]] && [[ `echo $SOURCE | grep -c -w "cron"` -eq "1" ]] ; then
email_setup
elif [[ `echo $SOURCE | grep -c -w "jenkins"` -eq "1" ]] ; then
echo "Email triggered to $TO"
email_setup
else
        echo "No email triggered"
fi

rm $result/final_${ENV}_module_status
exit 0
