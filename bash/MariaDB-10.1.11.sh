#!/usr/bin/env bash

set -e

#定义MySQL 数据存储目录、源码解压目录及时间标记：
DATA='/data/mysql/data'
BASE='/usr/local/mysql'
DATE="$(date +%Y%m%d%H%M%S)"

#设置mysql root 密码：
PASSWD="$(openssl rand -hex 10)"

#设置系统环境变量
if [ -z "$(egrep PS1 /etc/profile)" ];then
    echo 'PS1='\[\e[35;1m\][\u@\h \w \t]\\$\[\e[m\]'' >> /etc/profile
fi

#安装扩展源：
rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#安装一些必要的维护包
yum install -y vim lrzsz lsof tcpdump firewalld firewall-config telnet unzip jemalloc jemalloc-devel

#判断服务器是否有安装过mysql:
if [ ! -z "$(egrep mysql /etc/passwd)" ] && [ -d "${BASE}" ] ;then
    echo "MySQL or MariaDB was installed"
    exit
fi

#创建mariadb 解压目录并将mraidb 二进制文件解压到创建的目录中
if [ ! -d "${BASE}" ] ;then
    mkdir -p $BASE
    tar zxf /usr/local/src/mariadb-10.1.11-linux-glibc_214-x86_64.tar.gz -C /usr/local/mysql --strip-components=1
fi

#添加mysql 系统用户，并禁止其登录系统
useradd -s /sbin/nologin mysql

#创建mysql 数据存储目录并将其所属主和组修改mysql：
if [ ! -d "${DATA}" ]; then
    mkdir -p $DATA && chown -R mysql:mysql /data/mysql
fi

#备份系统自带的my.cnf 文件，重新生成配置
mv /etc/my.cnf{,_"$DATE".bak}
cat << eof > /etc/my.cnf
[client]
port                            = 3306
socket                          = /tmp/mysql.sock
default-character-set           = utf8
#user                            = root
#password                        = \$PASSWD

[mysqld]
port                            = 3306
socket                          = /tmp/mysql.sock
character-set-server            = utf8
skip-external-locking
key_buffer_size                 = 256M
max_allowed_packet              = 1M
table_open_cache                = 256
sort_buffer_size                = 1M
read_buffer_size                = 1M
read_rnd_buffer_size            = 4M
myisam_sort_buffer_size         = 64M
thread_cache_size               = 8
query_cache_size                = 16M
thread_concurrency              = 8
datadir                         = /data/mysql/data
log-bin                         = mysql-bin
binlog_format                   = mixed
server-id	                    = 1
skip-name-resolve

[mysqldump]
quick
max_allowed_packet              = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size                = 128M
sort_buffer_size               = 128M
read_buffer                    = 2M
write_buffer                   = 2M

[mysqlhotcopy]
interactive-timeout
eof

#将密码写入配置文件中：
echo "#password = $PASSWD" >> /etc/my.cnf

#初始化MySQL
cd $BASE && ./scripts/mysql_install_db --user=mysql --basedir="$BASE" --datadir="$DATA"

#创建启动脚本
cat << eof > /usr/lib/systemd/system/mysql.service
[Unit]
Description=MySQL Community Server
After=network.target
After=syslog.target

[Service]
PIDFile=/data/mysql/data/mariadb.pid
ExecStart=/usr/local/mysql/bin/mysqld_safe
EeecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=600
Restart=always
PrivateTmp=false

[Install]
WantedBy=multi-user.target
eof

#将mysql 设置为随机启动：
systemctl start mysql && systemctl enable mysql

#删除不要的数据库test
$BASE/bin/mysql -uroot -e 'drop database test'

#删除空用户：
$BASE/bin/mysql -uroot -e "delete from mysql.user where user=''"

#设置mysql root 账号密码：
/usr/local/mysql/bin/mysqladmin -uroot password ${PASSWD}

#设置环境变量
echo "PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile

