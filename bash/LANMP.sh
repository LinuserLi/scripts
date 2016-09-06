LANMP一键安装脚本


#!/bin/bash

#Author:Kings
#date	:20150525

#LANMP一键安装脚本 (Centos 6.6 + Apache 2.4.12 + Nginx 1.9 + Mysql 5.6 + PHP 5.6)

FAILED () {
if [ `echo $?` -ne 0 ];then
		echo "Faild,please install again!"
		exit
fi
}


#检测当前用户是否为root，否则提示使用root 用户执行该脚本
if [ `whoami` != "root" ];then 
	echo "Please use the root user. " 
	exit
fi

#判断网络是否通畅
if [ `ping -c 4 linux.linuser.com |grep packets |awk '{print $6}'|sed -e 's/%//'` -gt 1 ];then 
		echo "Your System Network not Accept,Please Set network."
	else 
		echo "Your Network is OK"
fi

#定义脚本安装日志
INSLOG="/var/log/install.log"

#安装系统扩展源：http://dl.fedoraproject.org/pub/epel
if [ `awk '{print $3}' /etc/redhat-release |awk -F '.' '{print $1}'` -eq 6 ];then
		rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm &>>$INSLOG
	elif [ `awk '{print $3}' /etc/redhat-release |awk -F '.' '{print $1}'` -eq 7 ];then
		rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm &>>$INSLOG
fi

echo 

#安装系统运维包：
echo "1、Install Packs:lrzsz gcc gcc-c++  make man vim ......."

 yum install -y lrzsz gcc gcc-c++  make man vim tree unzip wget perl perl-devel libxml2 libxml2-devel openssl openssl-devel curl curl-devel gd libvpx libvpx-devel libjpeg-turbo-devel libjpeg-turbo libpng libpng-devel libXpm libXpm-devel freetype freetype-devel t1lib t1lib-devel ntpdate patch  &>>$INSLOG

FAILED

echo 
sleep 5

#升级系统：
echo "2、Update system"

 yum update -y &>>$INSLOG

FAILED

echo 
sleep 10 

#替换selinux 配置：
echo "3、Disable selinux"

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

echo
sleep 3 

#开启防火墙80端口：
echo "4、Open 80 port"

IPTABLE=`iptables -nvL |egrep -i 80 |awk -F ':' '{print $2}' |sort  |uniq -c |sort -rn |awk '{print $2}'`

if [ -z "$IPTABLE" ] ;then
		iptables -I INPUT -p tcp --dport 80 -j ACCEPT && service iptables save &>>$INSLOG
	else
		echo "The port 80 was opened"
fi

echo

#定义软件下载目录：
SOFTDIR="/usr/local/src"

######################################	下载安装pcre-8.37	######################################
echo "5、Install Pcre-8.37"

#下载源码包：
 wget -O $SOFTDIR/pcre-8.37.tar.gz http://ncu.dl.sourceforge.net/project/pcre/pcre/8.37/pcre-8.37.tar.gz  &>>$INSLOG

#解压：
tar -zxf $SOFTDIR/pcre-8.37.tar.gz -C $SOFTDIR

#配置编译参数：
cd $SOFTDIR/pcre-8.37 && ./configure  &>>$INSLOG

FAILED

#编译及安装：
make &>>$INSLOG 

FAILED

make install  &>>$INSLOG

FAILED

echo "Install complete"
echo  && sleep 5
######################################	下载安装apr-1.5.2	######################################
echo "6、Will Install Apr"

#下载源码包：
wget -O $SOFTDIR/apr-1.5.2.tar.gz http://apache.communilink.net//apr/apr-1.5.2.tar.gz &>>$INSLOG

#解压：
tar -zxf $SOFTDIR/apr-1.5.2.tar.gz -C $SOFTDIR

#配置编译参数：
cd $SOFTDIR/apr-1.5.2 && ./configure &>>$INSLOG

FAILED

#编译及安装：
make &>>$INSLOG

FAILED

make install &>>$INSLOG

FAILED

echo "Install APR complete"

echo  && sleep 5

######################################	下载安装apr-util-1.5.2	######################################
echo  "7、Will Install Apr-util"

#下载:
cd ../ && wget http://apache.communilink.net//apr/apr-util-1.5.4.tar.gz &>>$INSLOG

#解压：
tar -zxf apr-util-1.5.4.tar.gz

#编译：
cd apr-util-1.5.4 && ./configure --with-apr=/usr/local/src/apr-1.5.2 &>>$INSLOG

FAILED

make  &>>$INSLOG

FAILED

make install  &>>$INSLOG

FAILED

echo "Install APR-util complete"

echo  && sleep 5

######################################	下载安装httpd-2.4.12	######################################
echo "8、Will Install Httpd"

#下载HTTP 
cd ../ &&  wget http://apache.communilink.net/httpd/httpd-2.4.12.tar.gz  &>>$INSLOG 

#解压：
tar zxf httpd-2.4.12.tar.gz 

#配置编译参数
cd httpd-2.4.12 && ./configure --prefix=/usr/local/httpd --enable-mods-shared=all  --with-pcre --with-include-apr  &>>$INSLOG

FAILED

#编译
make &>>$INSLOG

FAILED

#编译安装
make install &>>$INSLOG

FAILED

#设置主机名
sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/g' /usr/local/httpd/conf/httpd.conf

FAILED

#测试apache 的配置是否有问题。
echo "Test Apache config"

/usr/local/httpd/bin/apachectl -t &>>$INSLOG

if [ `echo $?` -eq 0 ];then
		echo "Syntax OK"
	else
		exit
fi

#启动apache
/usr/local/httpd/bin/apachectl start

FAILED

#创建httpd 启动脚本：
cat << EOF > /etc/init.d/httpd
#!/bin/bash
# chkconfig: - 30 21
# description: http service.
# Source Function Library
. /etc/init.d/functions
# Httpd Settings

APACHECTL="/usr/local/httpd/bin/apachectl"

case \$1 in
        start)
                echo httpd start.................OK
                \$APACHECTL -k start
                ;;
        stop)
                echo httpd stop.................OK
                \$APACHECTL -k stop
                ;;
        restart)
                echo httpd restart..............OK
                \$APACHECTL -k restart
                ;;
        configtest)
               \$APACHECTL -t &>> /var/log/install.log
                if [ `echo \$?` -eq 0 ];then
                        echo "httpd config Secussesfully!"
                else
                        echo "httpd config Failed,Plase check."
                fi
                ;;
esac
EOF

#赋予脚本可执行权限：
chmod 755 /etc/init.d/httpd

#将apache 加入随机启动项
#echo "/usr/local/httpd/bin/apachectl start" >> /etc/rc.local
chkconfig --add httpd && chkconfig httpd on

echo "Install Httpd complete"

echo  && sleep 5
######################################	下载安装mysql-5.6.24	######################################
echo "9、Install Mysql-5.6.24"

#开始下载mysql
cd ../ && wget http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.24-linux-glibc2.5-x86_64.tar.gz &>>$INSLOG 

#解压
tar zxf mysql-5.6.24-linux-glibc2.5-x86_64.tar.gz 

#将解压目录移动到/usr/local 目录下并重命名为Msyql
mv mysql-5.6.24-linux-glibc2.5-x86_64 /usr/local/mysql

#添加系统用户mysql,创建mariadb 数据存放目录，以及修改目录所属主和组都为mysql:
useradd -s /sbin/nologin mysql && mkdir -p /data/mysql && chown -R mysql:mysql /data/mysql  /usr/local/mysql

#进入源码目录：
cd /usr/local/mysql

#初始化Mysql
./scripts/mysql_install_db --user=mysql --datadir=/data/mysql/ --basedir=/usr/local/mysql/  &>>$INSLOG

FAILED

#将mysql启动脚本复制到/etc/init.d 目录下并重命名为mysqld,同时赋予可执行权限
cp support-files/mysql.server /etc/init.d/mysqld && chmod 755 /etc/init.d/mysqld

#备份系统自带的my.cnf 文件：
mv /etc/my.cnf{,.bak}

#创建mysql 配置文件，做如下配置：
cat << EOF >/etc/my.cnf
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
interactive-out
EOF

#启动mysql
service mysqld start

FAILED

#加入随机启动
chkconfig --add mysqld && chkconfig mysqld on

echo "Install Mysql complete"

echo  && sleep 5

######################################	下载安装libmcrypt-2.5.7	######################################
echo "10、Install  libmcrypt "

cd $SOFTDIR 

wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz &>>$INSLOG

tar zxf libmcrypt-2.5.7.tar.gz

cd libmcrypt-2.5.7 &&  ./configure &>>$INSLOG

FAILED

make   &>>$INSLOG

FAILED

make install  &>>$INSLOG

FAILED

echo "Install libmcrypt complete"

echo  && sleep 5
######################################	下载安装PHP-5.6.9	######################################
echo "11、Install PHP-5.6.9"

#下载：
cd $SOFTDIR && wget http://ar2.php.net/distributions/php-5.6.9.tar.gz  &>>$INSLOG

#解压：
tar zxf php-5.6.9.tar.gz

#进入解压目录，配置编译参数：

cd php-5.6.9 &&  ./configure --prefix=/usr/local/php --with-apxs2=/usr/local/httpd/bin/apxs --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-mysql-sock=/tmp/mysql.sock --with-pdo-mysql=/usr/local/mysql --with-gd --with-png-dir --with-jpeg-dir --with-freetype-dir --with-xpm-dir --with-vpx-dir --with-zlib-dir --with-t1lib --with-iconv --enable-libxml --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --enable-opcache --enable-mbregex --enable-fpm --enable-mbstring --enable-ftp --enable-gd-native-ttf --with-openssl --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-gettext --enable-session --with-mcrypt --with-curl --enable-ctype --enable-mysqlnd &>>$INSLOG

#编译
make  &>>$INSLOG

FAILED

#安装 
make install  &>>$INSLOG

FAILED

#复制php 的主配置文件
cp php.ini-production /usr/local/php/etc/php.ini

#复制php-fpm 启动脚本文件
#cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

#创建php-fpm 的主配置文件
cat <<EOF > /usr/local/php/etc/php-fpm.conf
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
[www]
listen = 127.0.0.1:9000
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

#测试php-fpm 是否OK
/usr/local/php/sbin/php-fpm -t 

FAILED

#将php-fpm 启动脚本拷贝至/etc/init.d 目录下并重命名为php-fpm
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

#添加php-fpm 用户
useradd -s /sbin/nologin php-fpm

#设置php-fpm 脚本文件可执行权限
chmod 755 /etc/init.d/php-fpm 

echo "Install php complete"

echo  && sleep 5
######################################	下载解压ngx_http_geoip2_module	######################################
echo "12、Unzip ngx_http_geoip2_module"

cd $SOFTDIR

#下载
wget https://codeload.github.com/leev/ngx_http_geoip2_module/zip/master &>>$INSLOG

#解压：
unzip master  &>>$INSLOG

echo "Unzip geoip2 complete"

echo  && sleep 5
######################################	下载安装libmaxminddb-0.5.5	######################################
echo "13、Install libmaxminddb"

cd $SOFTDIR

#下载
wget https://github.com/maxmind/libmaxminddb/releases/download/0.5.5/libmaxminddb-0.5.5.tar.gz &>>$INSLOG 

#解压：
tar zxf libmaxminddb-0.5.5.tar.gz

#配置编译参数：
cd libmaxminddb-0.5.5 && ./configure &>>$INSLOG

FAILED

#编译
make &>>$INSLOG 

FAILED 

#编译安装
make install &>>$INSLOG

FAILED

echo "Install libmaxminddb complete"

echo  && sleep 5
######################################	下载安装libunwind-1.1	######################################
echo "14、Install libunwind"

cd ../

#下载libunwind
wget http://download.savannah.gnu.org/releases/libunwind/libunwind-1.1.tar.gz &>>$INSLOG

#解压：
tar zxf libunwind-1.1.tar.gz 

#配置编译参数：
cd libunwind-1.1 && ./configure &>>$INSLOG

FAILED

#编译：
make &>>$INSLOG 

FAILED

#编译安装
make install &>>$INSLOG

FAILED

echo "Install libunwind complete"

echo  && sleep 5
######################################	下载安装gperftools-2.4	######################################
echo "15、Install gperftools"

cd ../

#下载gperftools:
wget https://googledrive.com/host/0B6NtGsLhIcf7MWxMMF9JdTN3UVk/gperftools-2.4.tar.gz &>>$INSLOG

#解压：
tar zxf gperftools-2.4.tar.gz 

#配置编译参数：
cd gperftools-2.4 && ./configure &>>$INSLOG

FAILED

#编译：
make &>>$INSLOG

FAILED

#编译安装：
make install &>>$INSLOG

echo "Install gperftools complete"

echo  && sleep 5
######################################	下载安装nginx-1.9.0	######################################
echo "16、Install nginx"

#下载nginx:
cd ../  && wget http://nginx.org/download/nginx-1.9.0.tar.gz &>>$INSLOG

#解压：
tar zxf nginx-1.9.0.tar.gz 

#编译：
cd nginx-1.9.0 && ./configure --prefix=/usr/local/nginx --with-http_realip_module  --with-http_sub_module --with-http_dav_module --with-http_gzip_static_module --with-http_stub_status_module  --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_secure_link_module --with-http_stub_status_module --with-http_ssl_module --http-log-path=/var/log/nginx_access.log --with-google_perftools_module --with-pcre=/usr/local/src/pcre-8.37 --add-module=/usr/local/src/ngx_http_geoip2_module-master &>>$INSLOG

FAILED

#编译：
make &>>$INSLOG

FAILED

#编译安装
make install &>>$INSLOG

FAILED

#做几个库文件的软连接：
ln -s /usr/local/lib/libmaxminddb.so.0 /usr/lib64/
ln -s /usr/local/lib/libprofiler.so.0 /usr/lib64/
ln -s /usr/local/lib/libunwind.so.8 /usr/lib64/

#检测nginx 配置是否有问题：
/usr/local/nginx/sbin/nginx  -t  &>>$INSLOG

FAILED

#创建nginx 启动脚本：
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

#赋予脚本可执行权限：
chmod 755 /etc/init.d/nginx


#设置随机启动nginx
chkconfig --add nginx && chkconfig nginx on

######################################	整合apache 和nginx	######################################
echo "17、整合apache 和nginx"

#备份nginx 主配置文件：
cp /usr/local/nginx/conf/nginx.conf{,.bak}

#重新配置nginx：
cat << EOF > /usr/local/nginx/conf/nginx.conf
user nobody nobody;
worker_processes 2;
error_log /var/log/nginx_error.log crit;
pid /usr/local/nginx/logs/nginx.pid;
#worker_processes  1;
worker_rlimit_nofile 51200;

events {
	use epoll;
     	worker_connections  1024;
}


http {
    	include       mime.types;
    	default_type  application/octet-stream;
    	server_names_hash_bucket_size 3526;
    	server_names_hash_max_size 4096;
    	log_format combined_realip '\$remote_addr \$http_x_forwarded_for [\$time_local]'
    	'\$host "\$request_uri" \$status'
	'"\$http_referer" "\$http_user_agent"';
		sendfile        on;
		tcp_nopush on;
    	keepalive_timeout  65;
        server_tokens off;
		client_header_timeout 3m;
    	client_body_timeout 3m;
    	send_timeout 3m;
    	connection_pool_size 256;
    	client_header_buffer_size 1k;
    	large_client_header_buffers 8 4k;
    	request_pool_size 4k;
    	output_buffers 4 32k;
    	postpone_output 1460;
    	client_max_body_size 10m;
    	client_body_buffer_size 256k;
    	client_body_temp_path /usr/local/nginx/client_body_temp;
    	proxy_temp_path /usr/local/nginx/proxy_temp;
    	fastcgi_temp_path /usr/local/nginx/fastcgi_temp;
    	fastcgi_intercept_errors on;
    	tcp_nodelay on;
    	gzip on;
    	gzip_min_length 1k;
    	gzip_buffers 4 8k;
    	gzip_comp_level 5;
    	gzip_http_version 1.1;
    	gzip_types text/plain application/x-javascript text/css text/htm application/xml;
	
	upstream lamp {
		server 127.0.0.1:8080 weight=1 max_fails=2 fail_timeout=30s;
	}

    	server {
        listen       80;
        server_name  localhost;
	
	location / {
		root   /usr/local/httpd/htdocs;
		index	index.htm index.html index.php;
	}

	location ~.*\.(php|jsp|cgi)?\$ {
		proxy_redirect off;
		proxy_set_header Host	\$host;
		proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_pass 	http://lamp;
	}
	
	location ~.*\.(html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css)\$ {
		root /usr/local/httpd/htdocs;
		expires	3d;
	}

        #location ~ \.php$ {
        #    	root           html;
        #    	fastcgi_pass   127.0.0.1:9000;
        #    	fastcgi_index  index.php;
        #    	fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        #    	include        fastcgi_params;
        #}
    }
}
EOF

#加上解析php 的类型
sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.php/g' /usr/local/httpd/conf/httpd.conf

#添加php解析：
sed -i 's/AddType application\/x-gzip .gz .tgz/AddType application\/x-gzip .gz .tgz\n    AddType application\/x-httpd-php .php/g'  /usr/local/httpd/conf/httpd.conf

#整合apache  和 nginx 
sed -i 's/80/8080/g' /usr/local/httpd/conf/httpd.conf

#添加普通用户apache
useradd -s /sbin/nologin apache

#将web目录所属主和组都修改为apache
chown -R apache:apache /usr/local/httpd/htdocs

#替换配置文件中的所属主和组
sed -i 's/User daemon/User apache/g'  /usr/local/httpd/conf/httpd.conf
sed -i 's/Group daemon/Group apache/'  /usr/local/httpd/conf/httpd.conf

#PHP 测试页面
echo "<?php  echo phpinfo();  ?>" >> /usr/local/httpd/htdocs/index.php

#备份默认的index.html 文件：
mv  /usr/local/httpd/htdocs/index.html{,.bak}

#测试apache：
service httpd configtest

#重启apache:
service httpd restart

#再次测试nginx配置是否OK：
service nginx configtest &>>$INSLOG

FAILED

#启动nginx:
service nginx restart

#重启系统
reboot


