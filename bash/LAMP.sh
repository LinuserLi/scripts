#!/bin/bash

#该脚本的作用	：在线一键部署LNMP
#Write			: King
#Date			: 2015-03-19

#mysql 	数据存放目录为/data/mysql
#php 	主配置文件在 /usr/local/php/etc 
#nginx	web 程序目录/usr/local/nginx/html/index,主配置目录 /usr/local/nignx/conf/nginx.conf

#安装系统扩展源：
rpm -ivh "http://www.lishiming.net/data/attachment/forum/month_1211/epel-release-6-7.noarch.rpm" 

#安装系统运维包：
yum install -y lrzsz gcc gcc-c++  make man vim tree unzip wget lua-devel lua-static patch libxml2-devel libxslt libxslt-devel gd gd-devel ntp ntpdate screen sysstat tree rsync lsof autoconf gettext  gettext-devel automake libtool git
 
#升级系统：
yum update -y
 
#替换selinux 配置：
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
 
#源码下载目录
SoftDir="/usr/local/src"

#下载安装Mysql:
cd $SoftDir && wget http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.23-linux-glibc2.5-x86_64.tar.gz

#解压：
cd $SoftDir && tar  zxf mysql-5.6.23-linux-glibc2.5-x86_64.tar.gz 

#移动解压目录病重命名Mysql:
cd $SoftDir && mv mysql-5.6.23-linux-glibc2.5-x86_64 /usr/local/mysql

#添加mysql 系统用户：
if [ -z `grep mysql /etc/passwd` ] ;then	
	useradd -s /sbin/nologin mysql
fi

#创建mysql 初始化数据目录：
if [ ! -d "/data" ] ;then 
	mkdir -p /data/mysql
fi

#将mysql 初始化目录所属主和组修改为mysql:
chown -R mysql.mysql /data/mysql/

#定义Mysql 源码目录：
MysqlS="/usr/local/mysql"

#初始化
cd $MysqlS && ./scripts/mysql_install_db --datadir=/data/mysql --user=mysql 

#备份系统默认的my.cnf 文件：
mv /etc/my.cnf{,.bak}

#复制mysql 的 主配置文件到etc 目录下病重命名为my.cnf
cd $MysqlS && cp support-files/my-default.cnf /etc/my.cnf

#复制mysql 的启动脚本到/etc/init.d 目录下：
cd $MysqlS &&  cp support-files/mysql.server /etc/init.d/mysqld

#赋予启动755 权限:
chmod 755 /etc/init.d/mysqld 

#修改my.cnf 文件配置如下：
cat << EOF > /etc/my.cnf
[mysqld]
pid-file=/data/mysql/mysql.pid
log-error=/var/log/mysql.log
datadir = /data/mysql
basedir = /usr/local/mysql
character-set-server=utf8   
port = 3306
socket = /tmp/mysql.sock
key_buffer_size = 256M
max_allowed_packet = 1M
table_open_cache = 256
sort_buffer_size = 1M
read_buffer_size = 1M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 16M
thread_concurrency = 8
binlog_format=mixed
server-id = 1
slow-query-log = 1
slow-query-log-file = /data/mysql/mysql-slow.log
log-bin = mysql-bin
log-bin-index = mysql-bin.index
symbolic-links = 0
skip-name-resolve

[client]
port = 3306
socket = /tmp/mysql.sock
default-character-set=utf8  

[mysqldump]
quick
max_allowed_packet = 16M

#[mysqld_safe]

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 128M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF

#启动mysql:
service mysqld start

if [ `echo $?` -eq 0 ] ;then
	echo "Mysql started"
else
	exit
fi

#===================================== 		安装LTP	  =======================================
#下载LTP:
cd $SoftDir &&  wget http://sourceforge.net/projects/ltp/files/LTP%20Source/ltp-20150119/ltp-full-20150119.tar.bz2/download

#解压
cd $SoftDir &&  tar jxf download 

#配置编译参数：
cd $SoftDir/ltp-full-20150119 && ./configure 

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/ltp-full-20150119 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/ltp-full-20150119 && make install
else
	exit
fi

#===================================== 		安装openssl1.0.2 	  =======================================
#下载openssl:
cd $SoftDir &&  wget http://www.openssl.org/source/openssl-1.0.2.tar.gz

#解压：
cd $SoftDir && tar zxf openssl-1.0.2.tar.gz 

#进入解压目录，配置编译参数：
cd $SoftDir/openssl-1.0.2 && ./config

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/openssl-1.0.2 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/lopenssl-1.0.2 && make install
else
	exit
fi

#===================================== 		安装curl-7.41.0 	  =======================================
#下载:
cd $SoftDir &&  wget http://curl.haxx.se/download/curl-7.41.0.tar.gz

#解压：
cd $SoftDir && tar zxf curl-7.41.0.tar.gz 

#进入解压目录，配置编译参数：
cd $SoftDir/curl-7.41.0 && ./configure

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/curl-7.41.0 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/curl-7.41.0 && make install
else
	exit
fi

#===================================== 		安装libmcrypt-2.5.8	  	==================================
#下载:
cd $SoftDir &&  wget http://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download

#解压：
cd $SoftDir && tar zxf download.1

#进入解压目录，配置编译参数：
cd $SoftDir/libmcrypt-2.5.8 && ./configure

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/libmcrypt-2.5.8 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/libmcrypt-2.5.8 && make install
else
	exit
fi

#=======================================	安装PHP 5.5.22  	====================================
#下载PHP 5.5.22
cd $SoftDir &&  wget http://ar2.php.net/distributions/php-5.5.22.tar.gz

#解压PHP：
cd $SoftDir && tar zxf php-5.5.22.tar.gz 

#添加php-fpm 用户，不允许登陆系统
useradd -s /sbin/nologin php-fpm

#进入PHP解压目录，配置编译参数：
cd $SoftDir/php-5.5.22 && ./configure --prefix=/usr/local/php   --with-config-file-path=/usr/local/php/etc  --enable-fpm   --with-fpm-user=php-fpm  --with-fpm-group=php-fpm   --with-mysql=/usr/local/mysql  --with-mysql-sock=/tmp/mysql.sock  --with-libxml-dir  --with-gd   --with-jpeg-dir   --with-png-dir   --with-freetype-dir  --with-iconv-dir   --with-zlib-dir   --with-mcrypt   --enable-soap   --enable-gd-native-ttf   --enable-ftp  --enable-mbstring  --enable-exif  --enable-zend-multibyte   --disable-ipv6   --with-pear   --with-curl --with-openssl --with-mysqli --enable-mysqlnd --with-gettext

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/php-5.5.22 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/php-5.5.22 && make install
else
	exit
fi

#复制Php 主配置：
cd $SoftDir/php-5.5.22 && cp php.ini-production /usr/local/php/etc/php.ini

#创建php-fpm 主配置文件：
cat <<EOF > /usr/local/php/etc/php-fpm.conf
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
[www]
listen = /tmp/php-fcgi.sock
user = php-fpm
group = php-fpm
pm = dynamic
pm.max_children = 50
pm.start_servers = 20
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
rlimit_files = 1024
EOF

#测试php-fpm 配置：
/usr/local/php/sbin/php-fpm -t
if [ `echo $?` -eq 0 ];then
	echo "php-fpm installed successfully"
else
	exit
fi

#拷贝php-fpm 启动脚本：
cd $SoftDir/php-5.5.22 && cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

#赋予脚本可执行权限：
chmod 755 /etc/init.d/php-fpm

#将php-fpm 写入随机启动：
chkconfig --add php-fpm && chkconfig php-fpm on

#启动php-fpm
service php-fpm start

#=======================================	安装pcre2-10.00		====================================
#下载
cd $SoftDir && wget http://softlayer-sng.dl.sourceforge.net/project/pcre/pcre/8.36/pcre-8.36.tar.gz

#解压：
cd $SoftDir && tar zxf pcre-8.36.tar.gz  

#接入pcre,配置编译参数：
cd $SoftDir/pcre-8.36 && ./configure 

#编译
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/pcre-8.36 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ];then
	cd $SoftDir/pcre-8.36 && make install
else
	exit
fi

#=======================================	添加libmaxminddb	====================================
#下载：
cd $SoftDir && wget https://github.com/maxmind/libmaxminddb/releases/download/0.5.5/libmaxminddb-0.5.5.tar.gz

#解压：
cd $SoftDir && tar zxf libmaxminddb-0.5.5.tar.gz
cd $SoftDir/libmaxminddb-0.5.5 && ./configure

#配置编译参数：
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/libmaxminddb-0.5.5 && make
else
	exit
fi

#编译：
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/libmaxminddb-0.5.5 &&  make install
else
	exit
fi


#=======================================	添加geoip2模块		====================================
#下载
cd $SoftDir && wget https://codeload.github.com/leev/ngx_http_geoip2_module/zip/maste

#解压：
cd $SoftDir && unzip master 

#=======================================	添加gperftools		====================================
#下载：
cd $SoftDir && wget http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz

#解压：
cd $SoftDir &&  tar zxf libunwind-1.1.tar.gz

#进入解压目录，配置编译参数：：
cd $SoftDir/libunwind-1.1 && ./configure

#编译
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/libunwind-1.1 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/libunwind-1.1 && make install
else
	exit
fi

#=======================================	添加gperftools		====================================
#下载：
cd $SoftDir && wget https://googledrive.com/host/0B6NtGsLhIcf7MWxMMF9JdTN3UVk/gperftools-2.4.tar.gz

#解压：
cd $SoftDir &&  tar zxf gperftools-2.4.tar.gz 

#进入解压目录，配置编译参数：：
cd $SoftDir/gperftools-2.4 && ./configure

#编译
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/gperftools-2.4 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/gperftools-2.4 && make install
else
	exit
fi

#=======================================	安装nginx-1.6.2  	====================================
#下载
cd $SoftDir && wget http://nginx.org/download/nginx-1.6.2.tar.gz

#解压：
cd $SoftDir && tar zxf nginx-1.6.2.tar.gz

#进入解压目录，配置编译参数：
cd $SoftDir/nginx-1.6.2 && ./configure --prefix=/usr/local/nginx --with-http_realip_module  --with-http_sub_module --with-http_dav_module --with-http_gzip_static_module --with-http_stub_status_module  --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_stub_status_module --with-http_ssl_module --http-log-path=/var/log/nginx_access.log --with-google_perftools_module --with-pcre=/usr/local/src/pcre-8.36 --with-openssl=/usr/local/src/openssl-1.0.2 --add-module=/usr/local/src/ngx_http_geoip2_module-master

#编译
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/nginx-1.6.2 && make
else
	exit
fi

#安装：
if [ `echo $?` -eq 0 ] ;then
	cd $SoftDir/nginx-1.6.2 && make install
else
	exit
fi

#设置软链接
ln -s /usr/local/lib/libmaxminddb.so.0 /usr/lib64
ln -s /usr/local/lib/libprofiler.so.0 /usr/lib64
ln -s /usr/local/lib/libunwind.so.8 /usr/lib64

#检测初始化完成的nginx 配置是否有问题
/usr/local/nginx/sbin/nginx  -t
if [ `echo $?` -eq 0 ];then
	echo "Nginx installed successfully!"
else
	exit
fi

#创建nginx 启动脚本
cat <<EOF > /etc/init.d/nginx
#!/bin/bash
# chkconfig: - 30 21
# description: http service.
# Source Function Library
. /etc/init.d/functions
# Nginx Settings

NGINX_SBIN="/usr/local/nginx/sbin/nginx"
NGINX_CONF="/usr/local/nginx/conf/nginx.conf"
NGINX_PID="/usr/local/nginx/logs/nginx.pid"
RETVAL=0
prog="Nginx"

start() {
        echo -n \$"Starting \$prog: "
        mkdir -p /dev/shm/nginx_temp
        daemon \$NGINX_SBIN -c \$NGINX_CONF
        RETVAL=\$?
        echo
        return \$RETVAL
}

stop() {
        echo -n \$"Stopping \$prog: "
        killproc -p \$NGINX_PID \$NGINX_SBIN -TERM
        rm -rf /dev/shm/nginx_temp
        RETVAL=\$?
        echo
        return \$RETVAL
}

reload(){
        echo -n \$"Reloading \$prog: "
        killproc -p \$NGINX_PID \$NGINX_SBIN -HUP
        RETVAL=\$?
        echo
        return \$RETVAL
}

restart(){
        stop
        start
}

configtest(){
    \$NGINX_SBIN -c \$NGINX_CONF -t
    return 0
}

case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  reload)
        reload
        ;;
  restart)
        restart
        ;;
  configtest)
        configtest
        ;;
  *)
        echo $"Usage: \$0 {start|stop|reload|restart|configtest}"
        RETVAL=1
esac

exit \$RETVAL
EOF

#赋予脚本可执行权限
chmod 755 /etc/init.d/nginx

#备份nginx主配置文件
cp /usr/local/nginx/conf/nginx.conf{,.bak}

#重新nginx 配置：
cat << EOF > /usr/local/nginx/conf/nginx.conf
error_log /var/log/nginx_error.log crit;
pid /usr/local/nginx/logs/nginx.pid;
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm index.php;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location ~ \.php\$ {
            root           html;
            fastcgi_pass   unix:/tmp/php-fcgi.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
}
EOF

#创建PHP测试文件：
echo "<?php   echo phpinfo();  ?>" >/usr/local/nginx/html/index.php

#备份index.html:
mv /usr/local/nginx/html/index.html{,.bak}

#启动nginx:
service nginx start

#将nginx 写入随机启动：
chkconfig --add nginx && chkconfig nginx on

#开启防火墙的80端口
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

#保存防火墙配置
service iptables save

#重启防火墙：
service iptables restart