#!/bin/bash
#ENV_NAME=$1
user=nginx
source_location=/opt/app/workload/jenkins/scripts/nginx_build
#destination_location=
serverlist=/opt/app/workload/jenkins/scripts/nginx_build/serverlist
nginx_dir=/opt/app/nginx
nginx_conf=/opt/app/nginx/conf
nginx_home=/home/nginx
workload_location=/opt/app/workload
source_cert_location=/opt/app/workload/jenkins/scripts/nginx_build/certificates
destination_cert_location=/opt/app/workload/ssl
while IFS=":" read host_name environment
do
        if [[ $ENV_NAME == $environment ]];
        then
                full_host=${host_name}.vci.att.com
                echo "Full hostname is $full_host"
                echo $environment
                #echo "Checking for nginx directory"
                #sshcmd -u $user -s $host_name "if [[ ! -d $nginx_dir ]];then; echo 'Install nginx_1.10.3 before proceeding with configuration changes' && exit; fi;"
                #echo "AFter exit"
                echo "Copying .profile at ${nginx_home}"
                sshput -u $user -s $full_host ${source_location}/.profile ${nginx_home}/
                echo "Copying nginx.conf at ${nginx_conf}"
                sshput -u $user -s $full_host ${source_location}/nginx.conf ${nginx_conf}/
                sshcmd -u $user -s $full_host "sed -i -e 's/zlt22919/${host_name}/g' ${nginx_conf}/nginx.conf"
                sshcmd -u $user -s $full_host "cp /etc/nginx/{scgi_params,mime.types,koi-win,koi-utf,fastcgi_params,fastcgi.conf,win-utf,uwsgi_params} ${nginx_conf}/"
                sshcmd -u $user -s $full_host "if [[ ! -d $destination_cert_location ]]; then mkdir $destination_cert_location; fi;"
                echo "Copying SSL certs at ${destination_cert_location}"
                sshput -u $user -s $full_host ${source_cert_location}/${full_host}.pfx ${destination_cert_location}
                sshcmd -u $user -s $full_host "cd $destination_cert_location; openssl pkcs12 -in ${full_host}.pfx -password pass:ncc-1701E! -clcerts -nokeys -out ${host_name}.cer;"
                sshcmd -u $user -s $full_host "cd $destination_cert_location; openssl pkcs12 -in ${full_host}.pfx -password pass:ncc-1701E! -clcerts -nodes -out ${host_name}.key;"
                sshcmd -u $user -s $full_host "chmod -R 755 $destination_cert_location;"
                sshput -u $user -s $full_host ${source_location}/dhparams.pem ${nginx_dir}
                echo "Creating html directory to keep index.html and 50x.html"
                sshcmd -u $user -s $full_host "mkdir ${nginx_dir}/html"
                sshput -u $user -s $full_host ${source_location}/index.html ${nginx_dir}/html/index.html
                sshput -u $user -s $full_host ${source_location}/50x.html ${nginx_dir}/html/50x.html
                echo "Creating Sym links for startup scripts"
                sshcmd -u $user -s $full_host "ln -s /opt/app/nginx/bin/nginx_stop.sh /opt/app/workload/stopnginx.sh"
                sshcmd -u $user -s $full_host "ln -s /opt/app/nginx/bin/nginx_start.sh /opt/app/workload/startnginx.sh"
                sshput -u $user -s $full_host ${source_location}/nginx_restart.sh ${workload_location}
                echo "Restarting nginx server on $full_host"
                sshcmd -u $user -s $full_host "/bin/sh ${workload_location}/nginx_restart.sh"

        fi
done < ${serverlist}
