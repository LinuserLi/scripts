#!/usr/bin/env bash
#Author:Linuser
#Date  :2016-09-06 10:25
#Effect:Install MongoDB-3.2.9

# https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.9.tgz

#定义mongodb 数据目录及源目录：
DATE="$(date +%Y%m%d%H%M%S)"
DATA='/data/mongodb/data'
BASE='/usr/local/mongodb'
LOGS='/data/mongodb/logs'

#创建mongodb 解压目录及数据目录：
if [ -d "${BASE}" ] && [ -d "${DATA}" ] ;then
        echo MongoDB was installed
        exit
    else
        useradd -s /sbin/nologin mongodb
        mkdir -p ${BASE} ${DATA} ${LOGS}
        chown -R mongodb:mongodb ${BASE} ${DATA} ${LOGS}
fi

#从官网下载Mongodb 二进制包
#wget -O /usr/local/src/mongodb-linux-x86_64-rhel70-3.2.9.tgz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.2.9.tgz

#解压到指定目录
tar xf /usr/local/src/mongodb-linux-x86_64-rhel70-3.2.9.tgz -C ${BASE} --strip-components=1

#设置为系统环境变量：
echo 'PATH=$PATH:/usr/local/mongodb/bin' >> /etc/profile

#设置启动脚本
cat << eof > /usr/lib/systemd/system/mongodb.service
[Unit]
Description=mongodb
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/data/mongodb/mongod.lock
ExecStart="\${BASE}"/bin/mongod --dbpath="\${DATA}" --logpath="\${LOGS}/mongodb.log --port=22177  --httpinterface --logappend --fork
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
eof

14b8cc7ac569df7979192c3a83898e0047752110 s