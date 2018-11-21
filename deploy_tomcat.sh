#!/bin/bash
user_name=tomcat
depot=/opt/app/workload/jenkins/depot/${ENV_NAME}
server_list=/opt/app/workload/jenkins/scripts/deploy/tomcatlist
source_dir=/opt/app/workload/jenkins/depot/ILM_SOURCE/
staging_dir=/opt/app/tomcat/staging
PWD=`pwd`
deployment_dir=/opt/app/tomcat/webapps
restart_script=/home/tomcat
status_file=/opt/app/workload/jenkins/scripts/deploy/logs/${ENV_NAME}_log
##The below file will append hosts to check status
status_hosts=/opt/app/workload/jenkins/scripts/deploy/logs/${ENV_NAME}_statuslist
if [[ $DEPLOYMENT_TYPE == 'default' ]];
then
        echo "You Selected Regular deployment"
        if [[ ! -d ${depot} ]];
        then
                mkdir ${depot}
        fi
        cd ${depot}
        rm wars/* wars.tar
        if [[ ! -d wars ]];
        then
                mkdir wars
        fi
        echo $PWD
        /usr/bin/scp username@host_name:${location_path}/*.war ${depot}/wars
         ls -ltr ${depot}/wars/
        tar -cf wars.tar wars/*
fi
j=1
while IFS=":" read host_name environment
do
        if [[ $ENV_NAME == $environment ]];
        then
                echo "Appending hostname to status_hosts file"
                echo $host_name >> $status_hosts
                echo "Checking for $staging_dir directory"
                sshcmd -u $user_name -s $host_name "if [[ ! -d $staging_dir ]]; then mkdir $staging_dir; fi;"
                echo "Checking for $deployment_dir directory"
                sshcmd -u $user_name -s $host_name "if [[ ! -d $deployment_dir ]]; then mkdir $deployment_dir; fi;"
                if [[ $DEPLOYMENT_TYPE == 'default' ]];
                then
                        echo "Environment name is $environment"
                        sshcmd -u $user_name -s $host_name "cd $staging_dir; rm -r wars wars_v3.tar; mv wars_v2.tar wars_v3.tar; mv wars_v1.tar wars_v2.tar; mv wars.tar wars_v1.tar;"
                        sshput -u $user_name -s $host_name ${depot}/wars.tar ${staging_dir}/
                        echo "Extrracting tar file in $host_name"
                        sshcmd -u $user_name -s $host_name "tar -xf ${staging_dir}/wars.tar -C $staging_dir/; rm $deployment_dir/*.war; cp $staging_dir/wars/* $deployment_dir/"
                else
                        echo "Rolling back deployment to wars_${DEPLOYMENT_TYPE}"
                        sshcmd -u $user_name -s $host_name "cd $staging_dir; rm -r wars; tar -xf $staging_dir/wars_${DEPLOYMENT_TYPE}.tar -C $staging_dir/; cp -p $staging_dir/wars/* $deployment_dir/"
                fi
                restart()
                {
                        tomcatName=`sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f1`
                        echo "Tomcat name is $tomcatName"
                        tomcatVersion=`sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f5`
                        echo "tomcat version is $tomcatVersion"
                        instance_txt=/opt/app/workload/jenkins/scripts/deploy/logs/${ENV_NAME}_lrm_instance_status
                        sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -shutdown -name ${tomcatName} -version ${tomcatVersion}" > ${instance_txt}

                        if [[ `cat $instance_txt | head -6 | tail -1 | cut -d'[' -f1 | grep -c -w "INFO,Resource is not running"` -eq 1 ]];
                        then
                                echo "Resource is not running"
                                sleep 10
                                sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -start -name ${tomcatName} -version ${tomcatVersion}"
                        elif [[ `cat $instance_txt | head -6 | tail -1 | cut -d'[' -f1 | grep -c -w "SUCCESS,Shutdown successful"` -eq 1 ]];
                        then
                                echo "SUCCESS,Shutdown successful"
                                sleep 60
                                sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -start -name ${tomcatName} -version ${tomcatVersion}"
                        else
                                echo "FAIL,Failure shutting down resource within the configured timeout"
                                echo "Resource is not down, killing it now"
                                sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -kill -name ${tomcatName} -version ${tomcatVersion}"
                                sleep 60
                                sshcmd -u $user_name -s $host_name "/opt/app/aft/scldlrm/bin/lrmcli -start -name ${tomcatName} -version ${tomcatVersion}"
                        fi
                }
                restart
                echo "J is $j and host_name is $host_name"
                if [[ $j -eq 2 || $j -eq 4 || $environment == 'HALO_FN_CT' || $environment == 'HALO_FN_CT2' || $environment == 'HALO_E_UAT' ]];
                then
                        ##Below while loop reads hostname from status_host file to check for instance status
                        while read -r line
                        do
                                new_hostname="$line"
                                echo "hostname is $new_hostname, checking for instance status"
                                i=True
                                while [ $i == 'True' ]
                                do
                                        wget https://${host_name}:8443 --no-check-certificate -o $status_file
                                        echo "Checking for Server status"
                                        if [[ `cat $status_file | grep -c -w "awaiting response... 200"` -eq 1 ]];
                                        then
                                                echo "Server is up! Proceeding with next server deployment!"
                                                STATUS="$environment is UP and RUNNING after deployment"
                                                env=$environment
                                                i=False
                                        else
                                                echo "connection refused"
                                                echo "Server is not up yet. Sleeping for 60seconds"
                                                STATUS="Not"
                                                sleep 60
                                        fi
                                done
                                echo "End of instance status check while loop"
                        done < ${status_hosts}
                        echo "end of status_host while loop, Done with $j hosts, removing status file"
                        rm $status_hosts
                fi
                j=$((j+1))
        fi
done < ${server_list}
email_setup()
{
        echo $env $STATUS
        /opt/app/workload/jenkins/scripts/tools/api_test/module_status_check.sh $env jenkins $TO $STATUS
}
if [[ `echo $STATUS | grep -c -w "UP"` -eq "1" ]]; then
        echo $env $STATUS
        email_setup
fi
