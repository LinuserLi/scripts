#!/bin/bash

#Auther        :www.linuser.com
#Date        :2015-06-18
#User        :Set basic environment

function FAILED() {
        if [ `echo $?` -ne 0 ];then
                exit
        fi
}

#检查用户是否为root
USER=`whoami`
if [ $USER  != 'root' ];then
        echo "Please user root"
        exit
fi

#检查网络是否通畅
NET=`ping -c 4 www.google.com |grep received |awk '{print $6}'|sed -e 's/%//'`
if [ $NET -ge 2 ];then
        echo "Please check your network" 
        exit
fi

#配置PS 环境：
if [ -z `egrep -i ps1 /etc/profile |awk '{print $1}'` ];then
	echo "PS1='\[\e[35;1m\][\u@\h \w \t&&\#]\\$\[\e[m\]'" >> /etc/profile && source /etc/profile
fi

#查看系统编码是否为en_US.UTF-8
lang=`grep -i lang /etc/sysconfig/i18n |awk -F '"' '{print $2}'`
if [ $lang != 'en_US.UTF-8' ];then 
        sed -i "s/$lang/en_US.UTF-8/" i18n 
fi

#做本机的hosts 解析：
ETH=`egrep -i device /etc/sysconfig/network-scripts/ifcfg-eth0 |awk -F '=' '{print $2}'`
if  [  -z `egrep -i $(echo $HOSTNAME) /etc/hosts |awk '{print $2}'` ];then
	echo $(ip ad |grep "global $ETH" |awk -F "/" '{print $1}' |awk '{print $2}'  && echo $HOSTNAME) >> /etc/hosts
fi

#关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

#禁止root用户登陆：
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

#禁止使用DNS反向解析：
sed -i 's/#UseDNS yes/UseDNS no/'  /etc/ssh/sshd_config

#加快登陆速度：
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g'  /etc/ssh/sshd_config

#重新加载openssh
service sshd restart

#添加普通用户linuser并设置密码为：20140301
if [ -z `egrep -i linuser /etc/passwd` ] ;then
	useradd linuser
	echo "20140301" |passwd --stdin linuser
	echo "linuser ALL=(ALL)       ALL" >> /etc/sudoers
fi

#添加mysql 用户并设置密码为：20141001
if [ -z `egrep -i mysql /etc/passwd` ] ;then
	useradd mysql
	echo "20141001" |passwd --stdin mysql
	echo "mysql ALL=(ALL)       ALL" >> /etc/sudoers
fi

#添加Postgres 用户并设置密码为：20150130
if [ -z `egrep -i postgres /etc/passwd` ] ;then
	useradd postgres
	echo "20150130" |passwd --stdin postgres
	echo "postgres ALL=(ALL)       ALL" >> /etc/sudoers
fi

#设置时区
if [ ! -f /etc/localtime.bak ];then
        cp /etc/localtime{,.bak}
        yes|cp /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
fi

#安装扩展源：
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
FAILED

#安装必要的维护工具
yum install -y gcc gcc-c++ wget  curl unzip lrzsz sysstat ntp man vim bash-completion ntp screen expect
FAILED

#升级系统
yum update -y
FAILED

#每半个小时从网络上更新一次系统时间
if [ `egrep -i ntpdate /etc/crontab |awk -F '/' '{print $4}' |awk '{print $1}'` == "" ];then
	echo "#每半个小时从网络上更新一次系统时间" >> /etc/crontab
	echo "30 * * * *      root    /usr/sbin/ntpdate       time-a.nist.gov" >> /etc/crontab
fi
#或者写成：
#if [ ! -z `egrep -i ntpdate /etc/crontab |awk -F '/' '{print $4}' |awk '{print $1}'` ];then 
#	echo "#每半个小时从网络上更新一次系统时间" >> /etc/crontab
#	echo "30 * * * *      root    /usr/sbin/ntpdate       time-a.nist.gov" >> /etc/crontab
#fi


#重启系统
sync && reboot
