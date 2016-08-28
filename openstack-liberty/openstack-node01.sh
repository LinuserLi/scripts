#!/usr/bin/env bash

mv /etc/chrony.conf{,.bak}
cat << eof > /etc/chrony.conf
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
allow 10.10.10.1/24
bindcmdaddress 10.10.10.11
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
eof

systemctl start chronyd.service && systemctl enable chronyd.service

chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* node01                        3   7   377    39    +49us[  +64us] +/-   30ms


==============================================================================================================================================================================================
#Install Mariadb

#配置mariadb-10.1 官方的源
[root@node01 ~ 14:48:37&&1]#cat <<  eof >> /etc/yum.repos.d/mariadb.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
eof

#安装mariadb
[root@node01 ~ 14:48:37&&1]#yum install -y mariadb mariadb-server MySQL-python

#修改mariadb 数据存路径
[root@node01 ~ 14:48:37&&1]#sed -i 's#^basedir=#basedir=/usr#' /etc/init.d/mysql
[root@node01 ~ 14:48:37&&1]#sed -i 's#^datadir=#datadir=/data/mysql/data#' /etc/init.d/mysql

#创建数据库目录，并将所属主和组都修改为mysql
[root@node01 ~ 14:48:37&&1]#mkdir -p /data/mysql/data && chown -R mysql:mysql /data/mysql

#备份默认的配置文件
[root@node01 ~ 14:48:37&&1]#mv /etc/my.cnf{,.bak}

#重新配置的主配置文件
[root@node01 ~ 14:48:37&&1]#cat << eof > /etc/my.cnf
[mysqld]
datadir=/data/mysql/data
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
skip-name-resolve
[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d
eof

#openstack 配置文件
[root@node01 ~ 14:48:37&&1]#cat << eof > /etc/my.cnf.d/mariadb_openstack.cnf
[mysqld]
bind-address = 10.10.10.11
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
eof

#初始化配置
[root@node01 ~ 14:48:37&&1]#mysql_install_db --user=mysql --datadir=/data/mysql/data --basedir=/usr/

#启动
[root@node01 ~ 14:48:37&&1]#systemctl start mariadb.service && systemctl enable mariadb.service

[root@node01 ~ 14:48:37&&1]#mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user.  If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] y
New password:                    NpV6Shs4EsaAoApqauQ+4Yx7CK4=
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
 ... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n
 ... skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

===============================================================================================================================================================================================
# Install Mongodb

[root@node01 ~ 14:48:37&&1]#yum install -y mongodb mongodb-server

[root@node01 ~ 14:48:37&&1]#mv /etc/mongod.conf{,.bak}

[root@node01 ~ 14:48:37&&1]#mkdir -p /data/mongodb/data && chown -R mongodb:mongodb /data/mongodb

[root@node01 ~ 14:48:37&&1]#cat << eof > /etc/mongod.conf
bind_ip = 10.10.10.11
fork = true
pidfilepath = /var/run/mongodb/mongod.pid
logpath = /var/log/mongodb/mongod.log
unixSocketPrefix = /var/run/mongodb
dbpath = /data/mongodb/data
smallfiles = true
eof

[root@node01 ~ 14:48:37&&1]#systemctl start mongod &&systemctl enable mongod
==============================================================================================================================================================================================
#Install memcached

[root@node01 ~ 14:48:37&&1]#yum install -y memcached python-memcached

[root@node01 ~ 14:48:37&&1]#mv /etc/sysconfig/memcached{,.bak}

[root@node01 ~ 14:48:37&&1]#cat << eof > /etc/sysconfig/memcached
PORT="11211"
USER="memcached"
MAXCONN="10000"
CACHESIZE="64"
OPTIONS="-l 10.10.10.11"
eof

[root@node01 ~ 14:48:37&&1]#systemctl start memcached && systemctl enable memcached
=============================================================================================================================================================================================
#install rabbitmq-server

[root@node01 ~ 14:48:37&&1]#yum install -y rabbitmq-server

[root@node01 ~ 14:48:37&&1]#systemctl start rabbitmq-server.service && systemctl enable rabbitmq-server.service

[root@node01 ~ 14:48:37&&1]#rabbitmqctl add_user openstack I1EeXw3H2O7CQrkrz6BF3M8LJns=

[root@node01 ~ 14:48:37&&1]#rabbitmqctl set_permissions openstack ".*" ".*" ".*"




















