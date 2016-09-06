#!/usr/bin/env bash
#Author:Linuser
#Date  :2016-09-06 10:25
#Effect:Install httpd-2.4.20

set -e

#定义httpd 数据目录及源目录：
DATE="$(date +%Y%m%d%H%M%S)"
DATA='/data/httpd/down/{windows,linux}'
BASE='/usr/local/src'
LOGS='/data/httpd/logs'

mkdir -p $DATA $LOGS

#先安装一些必要的工具包：
yum install -y epel-release wget gcc gcc-c++ zlib zlib-devel pcre pcre-devel

#下载所需的包
cat << eof > /data/httpd/down/down.txt
http://apache.fayea.com/apr/apr-1.5.2.tar.gz
http://apache.fayea.com/apr/apr-util-1.5.4.tar.gz
http://apache.fayea.com/httpd/httpd-2.4.20.tar.gz
eof

cd $BASE

wget -i /data/httpd/down/down.txt

#解压：
tar zxf ${BASE}/apr-1.5.2.tar.gz  -C ${BASE}/
tar zxf ${BASE}/apr-util-1.5.4.tar.gz  -C ${BASE}/
tar zxf ${BASE}/httpd-2.4.20.tar.gz -C ${BASE}/

#编译安装apr 和 apr-util：
cd ${BASE}/apr-1.5.2 && ./configure --prefix=/usr/local/apr && make && make install
cd ${BASE}/apr-util-1.5.4 && ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr/ && make && make install

#编译安装
cd ${BASE}/httpd-2.4.20

./configure --prefix=/usr/local/apache2 --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --enable-deflate=shared --enable-expires=shared --enable-rewrite=shared --with-pcreble-deflate=shared --enable-expires=shared --enable-rewrite=shared --with-pcre --enable-so

make && make install

#将下载的源码包移动到下载目录中
mv $BASE/*.tar.gz /data/httpd/down/linux/

#替换一些设置：
sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/' /usr/local/apache2/conf/httpd.conf
sed -i 's@#Include conf/extra/httpd-vhosts.conf@Include conf/extra/httpd-vhosts.conf@' /usr/local/apache2/conf/httpd.conf
sed -i 's@#Include conf/extra/httpd-autoindex.conf@Include conf/extra/httpd-autoindex.conf@' /usr/local/apache2/conf/httpd.conf
sed -i 's@IndexOptions FancyIndexing HTMLTable VersionSort@IndexOptions FancyIndexing HTMLTable VersionSort NameWidth=* FoldersFirst Charset=UTF-8 SuppressDescription SuppressHTMLPreamble@' /usr/local/apache2/conf/extra/httpd-autoindex.conf

#创建目录浏览的虚拟主机
cat << eof > /usr/local/apache2/conf/extra/httpd-vhosts.conf
<VirtualHost *:80>
    DocumentRoot "/data/httpd/down/linux"
    ServerName down.linux.com
    directoryIndex index.htm index.html index.php
        <Directory "/data/httpd/down/linux">
                Options Indexes FollowSymLinks
                IndexOptions Charset=GB2312
                AllowOverride All
                Require all granted
        </Directory>
    ErrorLog "/data/httpd/logs/down.err"
    CustomLog "/data/httpd/logs/down.log" common
</VirtualHost>
eof

#创建启动脚本
cat << eof > /usr/lib/systemd/system/httpd.service
[Unit]
Description=Apache
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/usr/local/apache2/bin/apachectl
ExecReload=/usr/local/apache2/bin/apachectl -k restart
ExecStop=/usr/local/apache2/bin/apachectl -k stop

[Install]
WantedBy=multi-user.target
eof

#清空/usr/local/src 目录下的所有内容
rm -rf $BASE/*

#清空脚本内容
echo > /usr/local/sbin/httpd.sh