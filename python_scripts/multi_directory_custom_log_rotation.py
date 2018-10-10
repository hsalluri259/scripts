#!/opt/app/python3/bin/python3
import subprocess, os, datetime, time, sys, shutil
## This log rotate script works with a list of directories and exception handling in case directory doesn't exist
class LogRotation:
    log_dir = ['/opt/app/nginx/logs','/opt/app/tomcat/logs', 'b']
    ##stdout lrmid logic
    #b'LRMIID-21973\n' strip() will remove \n and decode() will remove b''
    lrmid = (subprocess.check_output("/opt/app/aft/scldlrm/bin/lrmcli -running | head -5 | tail -1 | cut -d ' ' -f1", shell=True)).decode('utf-8').strip()
    print(lrmid)
    ###stdout lrmid logic end
    now = datetime.datetime.now().strftime("%Y-%m-%d-%H-%M")
    #defining a method with an instance self to access class attributes and methods
    def log_rotation(self):
        for f in self.log_dir:
            try:
                self.ch_dir = os.chdir(f)
                print('current dir is %s' % os.getcwd())
                self.filesize_bytes = int(subprocess.check_output("ls -ltr %s/stdout.%s.log | cut -d ' ' -f5" % (f, self.lrmid),  shell=True))
                print("filesize is %dBytes" % self.filesize_bytes)
                if self.filesize_bytes >= 52428800:
                    filesize_mb = self.filesize_bytes / 1048576
                    print("filesize is %fM" % filesize_mb)
                    source_file = 'stdout.' + self.lrmid + '.log'
                    destination_file = 'stdout.' + self.lrmid + '.log_' + self.now
                    print("source file is %s and destination is %s" % (source_file, destination_file))
                    shutil.copy(source_file, destination_file)
                    ## making stdout file null
                    subprocess.check_output("cat /dev/null > %s" % source_file, shell=True)
                    print('check whether log become null or not')
                else:
                    filesize_mb = self.filesize_bytes / 1048576
                    print("file size is %fM which is lessthan 50M, doing nothing" % filesize_mb)
                self.log_removal()
            except FileNotFoundError:
                print("%s directory doesn't exist" % f)
    def log_removal(self):
        for g in os.listdir(self.ch_dir):
            #checking for 45days old files to delete since last modification
            #The below time.time() module will give time in seconds since epoch. For Unix, the epoch is 1970
            #st_mtime will give time of last modification < (time in seconds since epoch) - 45days
            #if any file is older than 45days there, if statement will satisfy
            #for ex: there's a file test.txt last modified on August 20. 50days older from Current date October 10. st_mtime will be 1533877260seconds
            #time.time() will be 1539196793 -3888000=1535308793seconds
            #st_time is 1533877260 < time.time() 1535308793.
            #Since test.txt file is older than 45days, it will be deleted.
            if os.stat(g).st_mtime < time.time() - 45 * 86400:
                #printing time of last modification and file for my convenience
                print( "%f file is %s" % (os.stat(g).st_mtime, g))
                if os.path.isfile(g):
                    print(g)
                    #file removal logic
                    os.remove(g)
#defining an object for class LogRotation
log_rotation_object = LogRotation()
log_rotation_object.log_rotation()
