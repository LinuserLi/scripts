#!/usr/bin/env bash
#Author:Linuser
#Date  :2016-09-06 10:25
#Effect:Install MongoDB-3.2.9

#定义mongodb 数据目录及源目录：
DATE="$(date +%Y%m%d%H%M%S)"
DATA='/data/postgresql/data'
BASE='/usr/local/postgresql'
LOGS='/data/postgresql/logs'

useradd -s /bin/bash postgres

yum install -y perl-ExtUtils-Embed  perl-ExtUtils-MakeMake perl-ExtUtils-MakeMaker-Coverage readline readline-devel pam pam-devel libxml2 libxml-devel libxml2-python libxml2-static  libxslt libxslt-devel  tcl tcl-devel python-devel
#https://ftp.postgresql.org/pub/source/v9.5.4/postgresql-9.5.4.tar.gz
wget -O /usr/local/src/postgresql-9.5.4.tar.gz https://ftp.postgresql.org/pub/source/v9.5.4/postgresql-9.5.4.tar.gz

mkdir -p $DATA $BASE $LOGS

chown -R postgres:postgres  $DATA $BASE $LOGS

tar zxf /usr/local/src/postgresql-9.5.4.tar.gz -C $BASE --strip-components=1

cd $BASE

./configure --prefix=/usr/local/postgresql  --with-pgport=1921 --with-perl --with-tcl --with-python --with-openssl --with-pam --without-ladp --with-libxml --with-libxslt --enable-thread-safety --with-wal-blocksize=16 --with-blocksize=16

gmake world

gmake install-world

su - postgres

initdb -D /data/pgdb/ -U postgres -E UTF8 --locale=C -W
