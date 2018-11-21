#!/bin/bash
host_name=`hostname`.vci.att.com
###Getting tomcat name and version to shut down/start tomcat
tomcatName=`/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df | tail -1 | cut -d' ' -f1`
echo "Tomcat name is $tomcatName"
tomcatVersion=`/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df | tail -1 | cut -d' ' -f5`
echo "tomcat version is $tomcatVersion"
instance_txt=/opt/app/tomcat/logs/lrm_instance_status
#email setup starts here
email_setup()
{
TO=email1@xyz.com,email2@xyz.com
/usr/sbin/sendmail -t << MAIL_END
Subject : Test ALERT: Ignore Status ${host_name}
To: $TO
from: do_not_reply@HALO_FN_ALERT
Mime-Version: 1.0
Content-Type: text/html
<html>
<b>Server Name: ${host_name} </b></br></br>
<b>Status: <font color=$color>$STATUS</font></br>
</html>
MAIL_END
}
##Tomcat shutdown section starts here
/opt/app/aft/scldlrm/bin/lrmcli -shutdown -name ${tomcatName} -version ${tomcatVersion} > ${instance_txt}
if [[ `cat $instance_txt | head -5 | tail -1 | cut -d'[' -f1 | grep -c -w "INFO,Resource is not running"` -eq 1 ]];
then
        echo "Resource is not running"
        STATUS="It's already down, starting server"
        color=red
        email_setup color
        sleep 10
elif [[ `cat $instance_txt | head -5 | tail -1 | cut -d'[' -f1 | grep -c -w "SUCCESS,Shutdown successful"` -eq 1 ]];
then
        echo "SUCCESS,Shutdown successful"
        STATUS="Shutting down"
        color=red
        email_setup color
        sleep 70
else
        echo "FAIL,Failure shutting down resource within the configured timeout"
        echo "Resource is not down, killing it now"
        STATUS="Shutting down"
        color=red
        email_setup color
        /opt/app/aft/scldlrm/bin/lrmcli -kill -name ${tomcatName} -version ${tomcatVersion}
        sleep 70
fi
##Checking if there are any connections on port 8443
CONNECTIONS=$(netstat -na | grep 8443 | grep -v grep | wc -l)
echo $CONNECTIONS
while [ $CONNECTIONS -gt 0 ];
do
        sleep 60;
        CONNECTIONS=$(netstat -na | grep 8443 | grep -v grep | wc -l)
done
##starting tomcat
/opt/app/aft/scldlrm/bin/lrmcli -start -name ${tomcatName} -version ${tomcatVersion}
##Tomcat status check starts here
i=True
while [ $i == 'True' ]
do
        tomcat_status=/opt/app/tomcat/logs/${host_name}_tomcat_status
        wget https://${host_name}:8443 --no-check-certificate -o $tomcat_status
        echo "Checking for Server status"
        if [[ `cat $tomcat_status | grep -c -w "awaiting response... 200"` -eq 1 ]];
        then
                STATUS="Started Successfully"
                color=green
                email_setup color
                i=False
        else
                echo "connection refused"
                echo "Server is not up yet. Sleeping for 60seconds"
                STATUS="Not"
                sleep 60
        fi
done
##Tomcat status check ends here
rm /home/tomcat/index.html*
