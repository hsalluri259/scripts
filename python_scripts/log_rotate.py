#!/opt/app/python3/bin/python3
import subprocess, os, datetime, time, sys, shutil
##Prerequisite: Python3

## This log rotate script works with a list of directories and exception handling in case directory doesn't exist
class LogRotation:
    log_dir = ['/home/nginx/nginx-1.8.0/logs', '/opt/app/nginx/logs', '/opt/app/tomcat/logs']
    nginx_logs = ['access.log', 'error.log']
    now = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M")
    #defining a method with an instance self to access class attributes and methods
    def log_rotation(self):
        for f in self.log_dir:
            try:
                #making it class attribute to access in another method log_removal()
                self.ch_dir = os.chdir(f)
                if f == '/opt/app/tomcat/logs':
                    self.archive_dir = '/opt/app/tomcat/logs'
                    ##stdout lrmid logic
                    #b'LRMIID-21973\n' strip() will remove \n and decode() will remove b''
                    #lrmid = (subprocess.check_output("/opt/app/aft/scldlrm/bin/lrmcli -running | head -5 | tail -1 | cut -d ' ' -f1", shell=True)).decode('utf-8').strip()
                    os.system("/opt/app/aft/scldlrm/bin/lrmcli -running | head -5 | tail -1 | cut -d ' ' -f1 > output.txt")
                    lrmid = open("output.txt").read().strip()
                    print(lrmid)
                    print('current dir is %s' % os.getcwd())
                    filesize = os.system("ls -ltr %s/stdout.%s.log | cut -d ' ' -f5 > output.txt" % (f, lrmid))
                    #Opening output.txt-->read-->strip new line-->convert to float -->Divide by 1048576 to convert into MBs
                    filesize_mb = float(open("output.txt").read().strip()) / 1048576

                    if filesize_mb >= 50:
                        print("filesize is %fM" % filesize_mb)
                        source_file = 'stdout.' + lrmid + '.log'
                        destination_file = 'stdout.' + lrmid + '.log_' + self.now
                        print("source file is %s and destination is %s" % (source_file, destination_file))
                        shutil.copy(source_file, destination_file)
                        ## making stdout file null
                        os.system("cat /dev/null > %s" % source_file)
                        print('check whether log become null or not')
                    else:
                        print("file size is %fM which is lessthan 50M, doing nothing" % filesize_mb)
                elif f == '/home/nginx/nginx-1.8.0/logs':
                    self.archive_dir = '/opt/app/workload/logs'
                    if os.path.isdir(self.archive_dir):
                        print("workload/logs is there")
                    else:
                        os.mkdir(self.archive_dir)
                    for log in self.nginx_logs:
                        logfile = os.system("ls -ltr %s/%s | cut -d ' ' -f5 > output.txt" % (f, log))
                        log_mb = float(open("output.txt").read().strip()) / 1048576

                        if log_mb >= 50:
                            print("filesize is %fM" % log_mb)
                            dest_file = log + '_' + self.now
                            dest_dir = os.path.join('/opt/app/workload/logs', dest_file)
                            shutil.copy(log, dest_dir)
                            os.system("cat /dev/null > %s" % log)
                        else:
                            print("File size is %fM which is lessthan 50M, doing nothing" % log_mb)
                elif f == '/opt/app/nginx/logs':
                    self.archive_dir = '/opt/app/nginx/logs'
                    for log in self.nginx_logs:
                        logfile = os.system("ls -ltr %s/%s | cut -d ' ' -f5 > output.txt" % (f, log))
                        log_mb = float(open("output.txt").read().strip()) / 1048576
                        if log_mb >= 50:
                            print("filesize is %fM" % log_mb)
                            dest_file = log + '_' + self.now
                            dest_dir = os.path.join('/opt/app/nginx/logs', dest_file)
                            shutil.copy(log, dest_dir)
                            os.system("cat /dev/null > %s" % log)
                        else:
                            print("File size is %fM which is lessthan 50M, doing nothing" % log_mb)
                os.remove("output.txt")
                self.log_removal()
            except FileNotFoundError:
                print("%s directory doesn't exist. Please ignore this message, you're good" % f)
    def log_removal(self):
        for g in os.listdir(os.chdir(self.archive_dir)):
            #checking for 45days old files to delete since last modification
            #The below time.time() module will give time in seconds since epoch. For Unix, the epoch is 1970
            #st_mtime will give time of last modification < (time in seconds since epoch) - 45days
            #if any file is older than 45days there, if statement will satisfy
            #for ex: there's a file test.txt last modified on August 20. 50days older from Current date October 10. st_mtime will be 1533877260seconds
            #time.time() will be 1539196793 -3888000=1535308793seconds
            #st_time is 1533877260 < time.time() 1535308793.
            #Since test.txt file is older than 45days, it will be deleted.
            if os.stat(g).st_mtime < time.time() - 45 * 86400:
                if os.path.isfile(g):
                    if g == 'nginx.pid':
                        print("%s found, not removing" % g)
                    else:
                        #printing time of last modification and file for my convenience
                        #print("%s file is %f seconds" % (g, os.stat(g).st_mtime))
                        #file removal logic
                        os.remove(g)
            else:
                #print("%s is not older than 45days, not removing it" % g)
                continue
#defining an object for class LogRotation
log_rotation_object = LogRotation()
log_rotation_object.log_rotation()
