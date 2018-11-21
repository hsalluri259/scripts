#!/bin/bash
#set -x
#Get Tomcat hostname, DB hostname, DB Sid, DB Password and bounce paramaters from command line
Hosts=$1
DBHost=$2
DBSid=$3
DBPASS=$4
#Variable declaration
jenkins_dir=/opt/app/workload/jenkins/scripts/tools/tomcat_build/tomcat_8_5
tomcat_dir=/opt/app/tomcat
tomcat_home=/home/tomcat
certificate_dir=/opt/app/workload/jenkins/scripts/tools/tomcat_build/certificates
now=`date +%m%d%Y%H%M`
IFS="," read -r -a ARR <<< "$Hosts"
for THost in ${ARR[@]}
do
                SHORT_THost=`echo $THost | cut -d'.' -f1`
                build_log=/opt/app/workload/jenkins/scripts/tools/tomcat_build/logs/tomcat_build_log_${SHORT_THost}.${now}
        #Take backup of exisiting tomcat
                echo "Taking backup of existing tomcat directory in /opt/app/workload"
                sshcmd -u tomcat -s $THost "tar -cvf /opt/app/workload/tomcat.tar /opt/app/tomcat/*" 2>&1 >> ${build_log}
                voltage_creds=`sshcmd -u tomcat -s $THost "cat ${tomcat_dir}/conf/catalina.properties | grep "voltage.mechid.password""`
        #Copy cacerts from JDK 1.7 to 1.8
                echo "Copying  cacerts from JDK 1.7 to 1.8"
                sshcmd -u tomcat -s $THost "cp /opt/app/java/jdk/jdk170/jre/lib/security/cacerts /opt/app/java/jdk/jdk180/jre/lib/security/" 2>&1 >> ${build_log}
        #Copy java.security,US_export_policy.jar, and local_policy.jar in tar file
                echo "Copying java.security,US_export_policy.jar, and local_policy.jar in tar file"
                sshput -u tomcat -s $THost ${jenkins_dir}/jdk_security_jars.tar /opt/app/java/jdk/jdk180/jre/lib/security/ 2>&1 >> ${build_log}
        #Stopping tomcat and deinstalling older version
                echo "Stopping tomcat and deinstalling older version"
                tomcatName=`sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f1`
                echo "Tomcat name is $tomcatName"
                tomcatVersion=`sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f5`
                echo "tomcat version is $tomcatVersion"
                sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -kill -name ${tomcatName} -version ${tomcatVersion}" 2>&1 >> ${build_log}
                sleep 60
                tomcatVersionFull=`/opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" component pkginv -n $THost -dh -df | grep tomcat | cut -d" " -f13`
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" component pkgdeinstall -c ${tomcatName}:${tomcatVersionFull} -w -n $THost 2>&1 >> ${build_log}
        #Set correct version of JDK to be used by SWM/LRM
                echo "Setting correct version of JDK to be used by SWM/LRM"
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" node varset -v "SCLD_JAVA_HOME=/opt/app/java/jdk/jdk180" -n $THost 2>&1 >> ${build_log}
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" node varset -v "JAVA_HOME=/opt/app/java/jdk/jdk180" -n $THost 2>&1 >> ${build_log}
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=syx -DAFTSWM_PASSWORD="password" node varset -v "CLDLRM_JAVA_VERSION=1.8" -n $THost 2>&1 >> ${build_log}
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=sux -DAFTSWM_PASSWORD="password" node varlist -n $THost 2>&1 >> ${build_log}
        #Install new version of tomcat
                echo "Installing new version of tomcat - 8.5.28-01"
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" component pkginstall -c org.apache:tomcat:8.5.28-01 -w -n $THost 2>&1 >> ${build_log}
                /opt/app/aft/aftswmcli/bin/swmcli -DAFTSWM_USERNAME=xys -DAFTSWM_PASSWORD="password" component pkginv -n $THost 2>&1 >> ${build_log}
        #Put files in respective folders
                echo "Copying tomcat files"
                sshput -u tomcat -s $THost ${jenkins_dir}/conf.tar ${tomcat_dir}/conf/ 2>&1 >> ${build_log}
                sshput -u tomcat -s $THost ${jenkins_dir}/jars.tar ${tomcat_dir}/lib/ 2>&1 >> ${build_log}
                sshput -u tomcat -s $THost ${jenkins_dir}/etc.tar ${tomcat_dir}/etc/ 2>&1 >> ${build_log}
                sshput -u tomcat -s $THost ${jenkins_dir}/home.tar ${tomcat_home}/ 2>&1 >> ${build_log}
                sshput -u tomcat -s $THost ${jenkins_dir}/manager/context.xml ${tomcat_dir}/webapps/host-manager/META-INF/  2>&1 >> ${build_log}
                sshput -u tomcat -s $THost ${jenkins_dir}/manager/context.xml ${tomcat_dir}/webapps/manager/META-INF/  2>&1 >> ${build_log}
        #Untar files
                echo "Extracting tomcat files to respective directories"
                sshcmd -u tomcat -s $THost "tar -xvf ${tomcat_dir}/conf/conf.tar -C ${tomcat_dir}/conf/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "tar -xvf ${tomcat_dir}/lib/jars.tar -C ${tomcat_dir}/lib/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "tar -xvf ${tomcat_dir}/etc/etc.tar -C ${tomcat_dir}/etc/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "tar -xvf ${tomcat_home}/home.tar -C ${tomcat_home}/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "tar -xvf ${tomcat_home}/voltage.tar -C ${tomcat_home}/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "tar -xvf /opt/app/java/jdk/jdk180/jre/lib/security/jdk_security_jars.tar -C /opt/app/java/jdk/jdk180/jre/lib/security/" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "chmod -R 755 ${tomcat_dir}"
        #Restore voltage credentials
                echo "Restoring Voltage credentials"
                sshcmd -u tomcat -s $THost "sed -i "s/.*voltage.mechid.password.*/$voltage_creds/" ${tomcat_dir}/conf/catalina.properties" 2>&1 >> ${build_log}
        #Modify lrm.xml
                sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -modify -file /opt/app/tomcat/etc/lrm.xml"
        #Make changes to server.xml as per the environment details
                sshcmd -u tomcat -s $THost "sed -i -e 's/DBHOSTNAME/${DBHost}/g' ${tomcat_dir}/conf/server.xml" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "sed -i -e 's/SID/${DBSid}/g' ${tomcat_dir}/conf/server.xml" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "sed -i -e 's/PASSWORD/${DBPASS}/g' ${tomcat_dir}/conf/server.xml" 2>&1 >> ${build_log}
                sshcmd -u tomcat -s $THost "sed -i -e 's/CERTALIAS/${SHORT_THost}/g' ${tomcat_dir}/conf/server.xml" 2>&1 >> ${build_log}
        #Import certificate if not already there
                keys_jks=`sshcmd -u tomcat -s $THost 'ls /home/tomcat/keystore/ | grep ^keys.jks$' | tail -1`
                if [[ `echo $keys_jks | grep -c -w "keys.jks"` -eq "1" ]];
                then
                        echo "Keystore keys.jks is already there, Skipping keystore import"
                else
                        sshcmd -u tomcat -s $THost "mkdir ${tomcat_home}/keystore" 2>&1 >> ${build_log}
                        sshput -u tomcat -s $THost ${certificate_dir}/${THost}.pfx ${tomcat_home}/keystore/ 2>&1 >> ${build_log}
                        sshcmd -u tomcat -s $THost "cd ${tomcat_home}/keystore/;/opt/app/java/jdk/jdk180/bin/keytool -importkeystore -srckeystore ${THost}.pfx -srcstoretype pkcs12 -srcalias ${SHORT_THost} -srcstorepass ncc-1701E! -destkeystore keys.jks -deststoretype jks -deststorepass ncc-1701E! -destalias ${SHORT_THost}" 2>&1 >> ${build_log}
                fi
        #Start tomcat
                echo "Restarting tomcat"
                echo "Stopping tomcat"
                tomcatName=`sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f1`
                echo "Tomcat name is $tomcatName"
                tomcatVersion=`sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -configured -dh -df" | tail -1 | cut -d' ' -f5`
                echo "tomcat version is $tomcatVersion"
                sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -kill -name ${tomcatName} -version ${tomcatVersion}" 2>&1 >> ${build_log}
                sleep 60
                sshcmd -u tomcat -s $THost "/opt/app/aft/scldlrm/bin/lrmcli -start -name ${tomcatName} -version ${tomcatVersion}" 2>&1 >> ${build_log}
done
