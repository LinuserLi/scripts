#!/usr/bin/env bash

#设置环境变量
set -e

#定义named 主配置文件路径
DATE="$(date +%Y%m%d%H%M%S)"
CONF='/etc/named.conf'
read -p 'please input you domain: ' DOMAIN
read -p 'Please input your DNS address: ' IP
IP_3=$(echo $IP|awk -F '.' '{print $1"."$2"."$3}')

#开始安装Bind
yum install -y bind bind-libs bind-utils bind-devel

#备份主配置文件
cp $CONF{,.${DATE}_bak}

sed -i "s@listen-on port 53 { 127.0.0.1; };@listen-on port 53 { ${IP}; };@" $CONF
sed -i "s@listen-on-v6 port 53 { ::1; };@// listen-on-v6 port 53 { ::1; };@" $CONF
sed -i "s@allow-query     { localhost; };@allow-query     { ${IP_3}.0/24; };@" $CONF

#写入正向解析配置
cat << eof >> /etc/named.rfc1912.zones
zone "${DOMAIN}" IN {
        type master;
        file "${DOMAIN}";
};

#写入反向解析配置
zone "137.168.192.in-addr.arpa" IN {
        type master;
        file "${IP_3}.zone";
};
eof

#写入正向配置的内容
cat << eof > /var/named/"${DOMAIN}"
$TTL 1D
@               IN  SOA  ns.${DOMAIN}.  root.${DOMAIN}. (
                                              0
                                              1D
                                              1H
                                              1W
                                              3H )
                IN       NS            ns.${DOMAIN}.
ns              IN       A             ${IP}
011-centos      IN       A             ${IP}
012-centos      IN       A             ${IP_3}.12
013-centos      IN       A             ${IP_3}.13
014-centos      IN       A             ${IP_3}.14
015-centos      IN       A             ${IP_3}.15
eof

#配置反向文件：
cat << eof > /var/named/${IP_3}.zone
$TTL 1D
@               IN  SOA  ${DOMAIN}.   root.${DOMAIN}. (
                                            0       ; serial
                                            1D      ; refresh
                                            1H      ; retry
                                            1W      ; expire
                                            3H )    ; minimum
                IN        NS            ns.${DOMAIN}.
11              IN        PTR           ns.${DOMAIN}.
11              IN        PTR           011-centos.${DOMAIN}.
12              IN        PTR           012-centos.${DOMAIN}.
13              IN        PTR           013-centos.${DOMAIN}.
14              IN        PTR           014-centos.${DOMAIN}.
15              IN        PTR           015-centos.${DOMAIN}.
eof

#检查named 主配置是否有问题：
named-checkconf

#检查正向和反向是否有问题：
named-checkzone "${DOMAIN}" /var/named/${DOMAIN}
named-checkzone '137.168.192.in-addr.apra' /var/named/${IP_3}.zone

systemctl start named && systemctl enable named


#在脚本中，如果是自定义的变量，将其写入到某些配置文件中是不需要在变量前加脱意符号的。同时，在配置文件中，如果需要将变量放到双引号内，我们只需要在该双引号内写入变量即可。