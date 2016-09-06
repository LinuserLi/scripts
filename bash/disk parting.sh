#!/bin/sh

#Author:Grom
#Date	:2015-05-26
#User	:Monitor disk 

#定义磁盘所有分区的百分比
USE=`df -P | awk '{print $5}' | awk '{sum+=$1}END{print sum}'`

#定义nginx 日志目录
LOGDIR="/data/nginx/logs"

whiel :;do

#如果磁盘使用量大于90%，则判断日志目录是否存在，如存在，则删除10天前的nginx 日志
if [ $USE -gt 90 ];then
        [ -d $LOGDIR ] && find $LOGDIR/*.log -atime +10 -type f | xargs rm -f
fi

sleep 1800

done
