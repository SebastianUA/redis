#!/usr/bin/env bash -x

# CREATED:
# vitaliy.natarov@yahoo.com
#
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov
#
# Set some colors for status OK, FAIL and titles
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

SETCOLOR_TITLE="echo -en \\033[1;36m" #Fuscia
SETCOLOR_TITLE_GREEN="echo -en \\033[0;32m" #green
SETCOLOR_TITLE_PURPLE="echo -en \\033[0;35m" #purple 
SETCOLOR_NUMBERS="echo -en \\033[0;34m" #BLUE

# whoami
if [ "`whoami`" = "root" ]; then
     # LOGs
     FlushCacheReport="/var/log/FlushCacheReport.log"
     if [ ! -f "$FlushCacheReport" ]; then
          $SETCOLOR_TITLE
          echo "The flushall-caches.log file NOT FOUND in the folder /var/log";
          $SETCOLOR_NORMAL
          touch $FlushCacheReport
          $SETCOLOR_TITLE
          echo "The $FlushCacheReport file was CREATED";
          $SETCOLOR_NORMAL
     else
          $SETCOLOR_TITLE
          echo "The '$FlushCacheReport' file allready exists"
          rm -f $FlushCacheReport
          touch $FlushCacheReport
          $SETCOLOR_NORMAL
     fi
     RootFolder="/var/log/RootFolder.log"
     if [ ! -f "$RootFolder" ]; then
          $SETCOLOR_TITLE
          echo "The RootFolder.log file NOT FOUND in the folder /var/log";
          $SETCOLOR_NORMAL
          touch $RootFolder
          $SETCOLOR_TITLE
          echo "The $RootFolder file was CREATED";
          $SETCOLOR_NORMAL
      else
          $SETCOLOR_TITLE
          echo "The '$RootFolder' file allready exists"
          rm -f $RootFolder
          touch $RootFolder
          $SETCOLOR_NORMAL
      fi  
else 
     echo" `whoami 2> /dev/null` doesn't have permissions. Please use ROOT user for it!";
     exit; 
fi

      # Receiver email for reports
      List_of_emails="vnatarov@gorillagroup.com"
      exec > >(tee -a ${FlushCacheReport} )
      exec 2> >(tee -a ${FlushCacheReport} >&2)
      echo "**************************************************************" >> $FlushCacheReport
      echo "HOSTNAME: `hostname`" >> $FlushCacheReport
      echo "**************************************************************" >> $FlushCacheReport

###############################################################
########################## FUNCTIONS ##########################
###############################################################
#
function Install_Software () {
      #
      if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/fedora_version ] ; then
            if ! type -path "expect" > /dev/null 2>&1; then
                  yum install expect -y &> /dev/null
                  $SETCOLOR_TITLE
                  echo "expect has been INSTALLED on this server: `hostname`";
                  $SETCOLOR_NORMAL
            else
                  $SETCOLOR_TITLE
                  echo "expect INSTALLED on this server: `hostname`";
                  $SETCOLOR_NORMAL
            fi

            if [ -z "`rpm -qa | grep mailx`" ]; then
                  yum install mailx -y &> /dev/null
                  $SETCOLOR_TITLE
                  echo "service of mail has been installed on `hostname`";
                  $SETCOLOR_NORMAL
            else
                  $SETCOLOR_TITLE
                  echo "mailx INSTALLED on this server: `hostname`";
                  $SETCOLOR_NORMAL    
            fi
            elif [ -f /etc/debian_version ]; then
                  echo "Debian/Ubuntu/Kali Linux";
                  #
                  if ! type -path "expect" > /dev/null 2>&1; then
                        aptitude install expect-dev expect -y &> /dev/null
                        $SETCOLOR_TITLE
                        echo "expect has been INSTALLED on this server: `hostname`";
                        $SETCOLOR_NORMAL
                  else
                        $SETCOLOR_TITLE
                        echo "expect INSTALLED on this server: `hostname`";
                        $SETCOLOR_NORMAL
                  fi

                  if [ -z "`which mailx`" ]; then
                        apt-get install mailutils -y &> /dev/null
                        $SETCOLOR_TITLE
                        echo "service of mail has been installed on `hostname`";
                        $SETCOLOR_NORMAL
                  else
                        $SETCOLOR_TITLE
                        echo "mailx INSTALLED on this server: `hostname`";
                        $SETCOLOR_NORMAL    
            fi
            else
                  OS=$(uname -s)
                  VER=$(uname -r)
                  echo 'OS=' $OS 'VER=' $VER
      fi
} 
# start this funcion
Install_Software

function Operation_status () {
     if [ $? -eq 0 ]; then
         $SETCOLOR_SUCCESS;
         echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
         $SETCOLOR_NORMAL;
             echo;
     else
        $SETCOLOR_FAILURE;
        echo -n "$(tput hpa $(tput cols))$(tput cub 6)[fail]"
        $SETCOLOR_NORMAL;
        echo;
     fi
}

function Add_Root_Folder_to_File () {
    for Roots in `echo $RootF|xargs -I{} -n1 echo {}` ; do
        if [ ! -z "$Roots" ]; then
              echo "$Roots" >> $RootFolder
              sed -e 's/\s\+/\n/g' $RootFolder > $RootFolder-2
              awk '!x[$0]++' $RootFolder-2 > $RootFolder
        fi
    done   
}

function Check_Web_Servers () {
  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/fedora_version ] ; then
    if  type -path "nginx" > /dev/null 2>&1; then
         for Iconfig in `ls -al /etc/nginx/conf.d/*.conf | grep "^-"| grep -vE "(default|geo|example)"|awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
              RootF=$(cat $Iconfig 2> /dev/null| grep root|cut -d ";" -f1 | awk '{print $2}'|grep -vE "(SCRIPT_FILENAME|fastcgi_param|fastcgi_script_name|log|-f)"|uniq| grep -vE "(blog|wp)")
              SITE=$(cat $Iconfig 2> /dev/null| grep "server_name"|awk '{print $2}'|cut -d ";" -f1) 
              echo $SITE
              # run Add_Root_Folder_to_File function
                Add_Root_Folder_to_File
          done        
    elif type -path "httpd" > /dev/null 2>&1; then 
          #for Iconfig in `ls -al /etc/httpd/conf.d/vhosts/*.conf | grep "^-"| grep -vE "(default|geo|example)"|awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
           for Iconfig in `ls -alR /etc/httpd/conf.d/*.conf | grep "^-"| grep -vE "(default|geo|example)"|awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
                RootF=$(cat $Iconfig 2> /dev/null| grep DocumentRoot| cut -d '"' -f2|uniq| grep -v "blog")
                SITE=$(cat $Iconfig 2> /dev/null| grep -E "ServerName"|awk '{print $2}')
                # run Add_Root_Folder_to_File function
                  Add_Root_Folder_to_File 
            done    
    else
         echo "Please check which web-server installed on `hostname`";         
    fi
  #fi  
  elif [[ -f /etc/debian_version ]]; then
      #statements  
      #echo "UBUNTU! Need to parse";
      if  type -path "nginx" > /dev/null 2>&1; then
         for Iconfig in `ls -al /etc/nginx/conf.d/*.conf | grep "^-"| grep -vE "(default|geo|example)"|awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
              RootF=$(cat $Iconfig 2> /dev/null| grep root|cut -d ";" -f1 | awk '{print $2}'|grep -vE "(SCRIPT_FILENAME|fastcgi_param|fastcgi_script_name|log|-f)"|uniq| grep -vE "(blog|wp)")
              SITE=$(cat $Iconfig 2> /dev/null| grep "server_name"|awk '{print $2}'|cut -d ";" -f1) 
              echo $SITE
              # run Add_Root_Folder_to_File function
                Add_Root_Folder_to_File
          done        
    elif type -path "apache2" > /dev/null 2>&1; then 
          echo "apache2";
          #for Iconfig in `ls -al /etc/httpd/conf.d/vhosts/*.conf | grep "^-"| grep -vE "(default|geo|example)"|awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
           for Iconfig in `ls -alR /etc/apache2/sites-enabled/*.conf| awk '{print $9}'|xargs -I{} -n1 echo {}` ; do
                RootF=$(cat $Iconfig 2> /dev/null| grep DocumentRoot| cut -d '"' -f2|uniq| grep -v "blog")
                SITE=$(cat $Iconfig 2> /dev/null| grep -E "ServerName"|awk '{print $2}')
                # run Add_Root_Folder_to_File function
                  Add_Root_Folder_to_File 
            done    
    else
         echo "Please check which web-server2 installed on `hostname`";         
    fi
  fi    
}

function Flush_Redis_Cache () {
  $SETCOLOR_TITLE_GREEN
  echo "**********************************************";
  echo "********************REDIS*********************";
  echo "**********************************************";
  $SETCOLOR_NORMAL  
  #
  # check redis IP
  CacheRedisIP=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13| grep "<server>"|uniq|cut -d ">" -f2 | cut -d "<" -f1)
  if [ -z "$CacheRedisIP" ]; then
             CacheRedisIP=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13| grep "<server>"| uniq|cut -d "[" -f3| cut -d "]" -f1) 
  fi
  #
  #SOCK                      
  CacheRedisSock=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13| grep "<server>"|uniq| cut -d ">" -f2|cut -d "<" -f1| cut -d "." -f2)
  if [ -z "$CacheRedisSock" ]; then
             CacheRedisSock=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13| grep "<server>"| uniq| cut -d ">" -f2|cut -d "<" -f1| cut -d "." -f2) 
  fi
  #
  #PORTS
  CacheRedisPorts=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13| cut -d '>' -f2| grep port | cut -d '<' -f1|uniq)
  if [ -z "$CacheRedisPorts" ]; then
           CacheRedisPorts=$(cat `echo $LocalXML 2> /dev/null` |grep Cache_Backend_Redis -A13 | grep port | cut -d "[" -f3| cut -d "]" -f1| grep -Ev "gzip"|uniq)
  fi   
  # If need ignore some port(s)
  IgnoreCacheRedisPorts="666"
  #
  # redis-cli -h 127.0.0.1 -p 6378 flushall   (sessions)
  # redis-cli -h 127.0.0.1 -p 6379 flushall   (cache)
  # redis-cli -h 127.0.0.1 -p 6380 flushall    (full_page_cache)
  #Check_DB
  CacheRedisDB=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13 | grep database | cut -d ">" -f2 |cut -d "<" -f1|uniq)
  #
  # -n : string is not null.
  # -z : string is null, that is, has zero length
  if [ ! -z "$CacheRedisIP" ]; then
      echo "CacheRedisIPs: `echo $CacheRedisIP 2> /dev/null`";
      #
      #flush redis sock
      if [ "$CacheRedisSock" == "sock" ]; then
          echo "redis-cli -s `echo $CacheRedisIP` flushall";
          echo 'flushall' | redis-cli -s `echo $CacheRedisIP`;
      else    

       for ICacheRedisIP in `echo $CacheRedisIP|xargs -I{} -n1 echo {}` ; do
            for ICacheRedisPorts in `echo $CacheRedisPorts|xargs -I{} -n1 echo {}` ; do
                echo "Cache-redis-ports: `echo $CacheRedisPorts 2> /dev/null`";  
                if [ "$ICacheRedisPorts" -ne "$IgnoreCacheRedisPorts" ]; then
                      #echo "CacheRedisDB = `echo $CacheRedisDB 2> /dev/null`"
                      if [ -z "$CacheRedisDB" ]; then
                            if [ -n "`whereis redis-cli| awk '{print $2}'`" ]; then 
                                  R_flush=$(redis-cli -h `echo $ICacheRedisIP` -p `echo $ICacheRedisPorts` flushall)
                                  $SETCOLOR_TITLE
                                  echo "redis-cli -h `echo $ICacheRedisIP` -p `echo $ICacheRedisPorts` flushall";
                                  $SETCOLOR_NORMAL
                            else
                                  Flush_CacheRediss="flushall";
                                  Close_Expect_with_CacheRediss="quit";
                                  $SETCOLOR_TITLE
                                  echo $ICacheRedisIP '+' $ICacheRedisPorts
                                  $SETCOLOR_NORMAL
                                  expect <<EOF 
                                        spawn telnet $ICacheRedisIP $ICacheRedisPorts
                                        expect "Escape character is '^]'."
                                        send "$Flush_CacheRediss\n"
                                        expect "+OK"
                                        sleep 3
                                        send "$Close_Expect_with_CacheRediss\n"
EOF
                            fi           
                      else
                            echo "CacheRedisDB = `echo $CacheRedisDB 2> /dev/null`" 
                            #flush_db
                            $SETCOLOR_TITLE
                            Server_port="SERVER::::> `echo $ICacheRedisIP` PORT::::> `echo $ICacheRedisPorts`";
                            $SETCOLOR_NORMAL
                            echo "`echo $Server_port`";
                            for ICacheRedisDB in `echo $CacheRedisDB|xargs -I{} -n1 echo {}` ; do
                                #echo "Need to flush DB `echo $ICacheRedisDB`";
                                $SETCOLOR_TITLE
                                echo "`echo $Server_port` DataBase::::> `echo $ICacheRedisDB`";
                                $SETCOLOR_NORMAL
                                CacheRedisDBAuth=$(cat `echo $LocalXML` 2> /dev/null| grep Cache_Backend_Redis -A13 | grep password | cut -d ">" -f2 |cut -d "<" -f1|uniq)
                                if [ -z "$CacheRedisDBAuth" ]; then
                                      Flush_CacheRedisDB="flushdb";
                                      Close_Expect_with_CacheRedis="quit";
                                      Close_connection="Connection will be CLOSED now!";
                                      #`which expect| grep -E expect`<< EOF
                                      expect <<EOF 
                                          spawn telnet $ICacheRedisIP $ICacheRedisPorts
                                          expect "Escape character is '^]'."
                                          send "SELECT $ICacheRedisDB\n"
                                          expect "+OK"
                                          send "$Flush_CacheRedisDB\n"
                                          expect "+OK"
                                          sleep 3
                                          send "$Close_connection\n"
                                          send "$Close_Expect_with_CacheRedis\n"                                             
EOF
                                else
                                      $SETCOLOR_TITLE
                                      echo "AUTH Authentication required.";
                                      $SETCOLOR_NORMAL
                                      for ICacheRedisDBAuth in `echo $CacheRedisDBAuth|xargs -I{} -n1 echo {}` ; do
                                            Flush_CacheRedisDB="flushdb";
                                            Close_Expect_with_CacheRedis="quit";
                                            Close_connection="Connection will be CLOSED now!";
                                            expect <<EOF 
                                                spawn telnet $ICacheRedisIP $ICacheRedisPorts
                                                expect "Escape character is '^]'."
                                                send "AUTH $ICacheRedisDBAuth\n"
                                                expect "+OK"
                                                send "SELECT $ICacheRedisDB\n"
                                                expect "+OK"
                                                send "$Flush_CacheRedisDB\n"
                                                expect "+OK"
                                                sleep 3
                                                send "$Close_connection\n"
                                                send "$Close_Expect_with_CacheRedis\n"                                             
EOF
                                        done;
                                fi    
                              done;     
                        fi         
                else
                     echo "Oops IgnoreCacheRedisPorts is '$IgnoreCacheRedisPorts' EXIT!";
                     break;
                fi
                $SETCOLOR_TITLE_PURPLE
                echo "Flushed redis cache on $ICacheRedisPorts port";
                $SETCOLOR_NORMAL
            done;
      #      
     done;
    #
    fi
else
     #rm -rf
     $SETCOLOR_TITLE
     echo "Local Cache on server `hostname`";
     $SETCOLOR_NORMAL
     if [ ! -z "$Cache_Dir" ] ; then
          #     
          `rm -rf echo $Cache_Dir`
          $SETCOLOR_TITLE
          echo "Using LOCAL CACHE with command <rm -rf '$Cache_Dir' has been FLUSHED";
          $SETCOLOR_NORMAL 
      fi    
fi     
} 

function Flush_Memcached () {
       #MEMCACHED
        $SETCOLOR_TITLE_GREEN
        echo "**********************************************";
        echo "******************MEMCACHED*******************";
        echo "**********************************************";
        $SETCOLOR_NORMAL
        MemcachedServer=$(cat `echo $LocalXML` 2> /dev/null | grep -Ev ^$| grep '<memcached>' -A7| grep -E 'host|CDATA|port' | grep -v "ersistent"| grep host| cut -d "[" -f3| cut -d "]" -f1|uniq)
        MemcachedPort=$(cat `echo $LocalXML` 2> /dev/null | grep -Ev ^$| grep '<memcached>' -A7| grep -E 'host|CDATA|port' | grep -v "ersistent"| grep port| cut -d "[" -f3| cut -d "]" -f1|uniq)
        
        Close_Expect_with_Memcached="quit"
        Flush_Memcached="flush_all"  
        if [ ! -z "$MemcachedServer" ] || [ ! -z "$MemcachedPort" ] ; then
              $SETCOLOR_TITLE
              echo "Memcached Server => `echo $MemcachedServer`";
              echo "Memcached Port => `echo $MemcachedPort`";
              $SETCOLOR_NORMAL  
              `which expect | grep -E expect` <<EOF
                    spawn telnet $MemcachedServer $MemcachedPort
                    expect "Escape character is '^]'."
                    send "$Flush_Memcached\n"
                    expect "+OK"
                    sleep 1
                    send "$Close_Expect_with_Memcached\n"
EOF
              $SETCOLOR_TITLE
              echo "memcached has been flushed on server `hostname`";
              $SETCOLOR_NORMAL
        else
              $SETCOLOR_TITLE
              echo "Din't find memcached on server `hostname`";
              $SETCOLOR_NORMAL
        fi
}
#
# Start Check_Web_Servers function
 Check_Web_Servers
#
#
for IRootFolder in `cat $RootFolder|xargs -I{} -n1 echo {}` ; do
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
        echo " ~~~~~~ `echo $SITE` ~~~~~~ ";
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
        if [[ "$IRootFolder" == */ ]]; then 
               $SETCOLOR_TITLE
               echo "Root-folder: $IRootFolder";
               $SETCOLOR_NORMAL
               XML="app/etc/local.xml";
               LocalXML="$IRootFolder$XML"
               $SETCOLOR_TITLE
               echo "Root-XML with '/' : `echo $LocalXML| grep -vE "DocumentRoot"`";
               $SETCOLOR_NORMAL
               Var_Cache="var/cache/*";
               Cache_Dir="$IRootFolder$Var_Cache"
        else
                LocalXML="$IRootFolder/app/etc/local.xml"
                $SETCOLOR_TITLE
                echo "Root-folder: $IRootFolder";
                $SETCOLOR_NORMAL
                $SETCOLOR_TITLE
                echo "Root-XML: `echo $LocalXML`";
                $SETCOLOR_NORMAL
                Cache_Dir="$IRootFolder/var/cache/*"
        fi
        #Run Flush_Redis_Cache function
        Flush_Redis_Cache;
        #Run Flush_Memcached function
        Flush_Memcached;
done; 
# Send report to email list
mail -s " HOSTNAME is `hostname`" $List_of_emails < $FlushCacheReport
if [ $? -eq 0 ]; then
      $SETCOLOR_TITLE
      echo "LOG_FILE= $FlushCacheReport has been sent to `echo $List_of_emails`";
      $SETCOLOR_NORMAL
else
      $SETCOLOR_TITLE
      echo "The email hasn't been sent to `echo $List_of_emails`";    
      $SETCOLOR_NORMAL
fi
# 
rm -f $FlushCacheReport
rm -f $RootFolder
#
echo "|---------------------------------------------------|";
echo "|--------------------FINISHED-----------------------|";
echo "|---------------------------------------------------|";