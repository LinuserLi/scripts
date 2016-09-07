#!/usr/bin/env bash
#User   :Install tomcat
#Write  :kings
#Data   :2015-08-31

function TIME(){
    sleep 5
}

INSTALL_LOG=/var/log/install.log
SOFTDIR='/usr/local/src'

#Check User
if [ `whoami` != "root" ];then
    echo 'Please use ROOT user do it'
fi

#Check network
#Define packets
PACKETS=`ping -c 4 www.baidu.com |egrep packet |awk '{print $6}'|sed 's/%//'`
if [ $PACKETS -gt 0 ];then
    echo 'Please check your network'
fi

#Install epelCHEKIRCHEKIR
#Define system version
VERSION=`awk '{print $3}' /etc/redhat-release |awk -F '.' '{print $1}'`
if [ $VERSION -eq 6 ];then
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >>$INSTALL_LOG
    else
        rpm -Ivh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm >>$INSTALL_LOG
fi

#Disabled selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#Install vim losf sysstat wget  curl unzip lrzsz telnet
yum install -y vim losf sysstat wget  curl unzip lrzsz telnet >>$INSTALL_LOG

#Update system packets
#yum update -y >>$INSTALL_LOG

#Check system java
if [ -f '/usr/sbin/java' ];then
        mv /usr/sbin/java{,.bak}
fi

cd $SOFTDIR

#Begin tar and install JDK 1.8.0_60
tar zxf jdk-8u60-linux-x64.tar.gz -C /usr/local

#Config java path
cat << EOF >> /etc/profile
JAVA_HOME=/usr/local/jdk1.8.0_60
JAVA_BIN=/usr/local/jdk1.8.0_60/bin
JRE_HOME=/usr/local/jdk1.8.0_60/jre
CLASSPATH=/usr/local/jdk1.8.0_60/lib:/usr/local/jdk1.8.0_60/jre/lib:/usr/local/jdk1.8.0_60/jre/lib/charsets.jar
PATH=\$PATH:/usr/local/jdk1.8.0_60/bin:/usr/local/jdk1.8.0_60/jre/bin
export JAVA_HOME  JAVA_BIN JRE_HOME  CLASSPATH PATH
EOF

source /etc/profile

#Begin tar and install tomcat 8.0.26
tar -zxf apache-tomcat-8.0.26.tar.gz -C /usr/local/src

mv apache-tomcat-8.0.26 /usr/local/tomcat

ln -s /usr/local/tomcat/bin/catalina.sh /etc/init.d/tomcat

sed -i "2i # chkconfig: 112 63 37\n# description: tomcat server init script\n# Source Function Library\n. /etc/init.d/functions\nJAVA_HOME=/usr/local/jdk1.8.0_60\nCATALINA_HOME=/usr/local/tomcat" /etc/init.d/tomcat

chmod 755 /etc/init.d/tomcat

service tomcat start

TIME
#Define tomcat port 8080
TOMCAT_PORT=`netstat -lnp|grep 8080 |awk -F ':::' '{print $2}'`
if [ $TOMCAT_PORT -ne 0 ];then
    echo "Tomcat install success"
fi

#Add tomcat service to system
chkconfig --add tomcat && chkconfig tomcat on

#Add iptables to port 8080 and save iptables service
iptables -I INPUT -p tcp --dport 8080 -j ACCEPT && service iptables save

reboot

