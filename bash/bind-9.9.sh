#!/usr/bin/env bash

set -e

#定义路径
BASE='/usr/local/src'
NAMED='/usr/local/named'

#安装必要的组件
yum install -y openssl openssl-devel gcc gcc-c++ wget

#从官网下载bind-9.9.9-p2 版本
wget -O $BASE/bind-9.9.2-p2.tar.gz https://www.isc.org/downloads/file/bind-9-9-9-p2/?version=tar-gz

#解压
tar zxf $BASE/bind-9.9.9-p2.tar.gz -C $BASE

#进入解压目录配置编译参数，编译及安装
cd $BASE/bind-9.9.9-P2

./configure --prefix=$NAMED --enable-threads --enable-largefile --disable-ipv6

make  &&  make install

#生产rndc.conf 文件
$NAMED/sbin/rndc-confgen > $NAMED/etc/rndc.conf

#将上面生产的文件内容重写到 rndc.key 文件中：
cat $NAMED/etc/rndc.conf > $NAMED/etc/rndc.key

#将rndc.conf 文件中有被启用的配置重写到新文件 named.conf 文件中：
tail -10 $NAMED/etc/rndc.conf | head -9 | sed s/#\ //g > $NAMED/etc/named.conf

cat << eof >> $NAMED/etc/named.conf
options {
directory "/usr/local/named/var";         //域名文件存放的绝对路径
pid-file "named.pid";              	  //如果bind启动，自动会在/usr/local/named/var目录生成一个named.pid文件，打开文件就是named进程的ID
};

zone "." IN {
        type hint;               	  //根域名服务器
        file "named.root"; 		  //存放在//usr/local/named/var目录，文件名为named.root
};

zone "localhost" IN {
        type master;                      //类型为主域名服务器
        file "localhost.zone";            //本地正向解析的文件
        allow-update { none; };
};

zone "0.0.127.in-addr.arpa" IN {
        type master;                      //类型为主域名服务器
        file "named.local";               //本地反向解析的文件
        allow-update { none; };
};

zone "linuser.com" IN {                 //建立linuser.com域
        type master;
        file "linuser.zone";            //linuser.com域映射IP地址可在此文件编写
        allow-update { none; };
};


zone "192.168.137.in-addr.arpa" in {      //反向解析
        type master;
        file "linuser.local";           //存放反向解析的文件
        allow-update { none; };
};
eof

#生成根解析文件
$NAMED/bin/dig > $NAMED/var/named.root

#生产本地正向解析文件
cat << eof > $NAMED/var/localhost.zone
\$TTL    86400
\$ORIGIN localhost.
@                       1D IN SOA       @ root (
                                        42              ; serial (d. adams)
                                        3H              ; refresh
                                        15M             ; retry
                                        1W              ; expiry
                                        1D )            ; minimum
                        1D IN NS        @
                        1D IN A         127.0.0.1
eof

#生产本地反向解析文件
cat << eof > $NAMED/var/named.local
\$TTL    86400
@       IN      SOA     localhost. root.localhost.  (
                                      1997022700 ; Serial
                                      28800      ; Refresh
                                      14400      ; Retry
                                      3600000    ; Expire
                                      86400 )    ; Minimum
         IN      NS      localhost.
1        IN      PTR     localhost.
eof

#生产自定义域名正向解析文件
cat << eof > $NAMED/var/linuser.com
\$ttl    1D
@               IN SOA  linuser.com.  root.linuser.com. (
                                       1053891162
                                        3H
                                        15M
                                        1W
                                        1D )
                        IN NS         ns.linuser.com.
                        IN MX    5    linuser.com.
                        IN A          3.3.3.3
ns                      IN A          1.2.3.4
www                     IN A         220.202.19.82
eof

#生产域名反向解析文件
cat << eof > $NAMED/var/linuser.local
$TTL 86400
@           IN    SOA     ns1.linuser.com.      root.linuser.com.(
                                                  20031001;
                                                  7200;
                                                  3600;
                                                  43200;
                                                  86400);
@           IN    NS       ns1.linuser.com.
100         IN    PTR      ns1.linuser.com.
101         IN    PTR      ns1.linuser.com.
eof