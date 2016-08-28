#!/usr/bin/env bash

Mariadb + Mecached + MongoDB + RabbitMQ-server ：192.168.137.11  10.10.10.11 node01 node01.com CentOS-7.2 1511 3.10.0-327.4.5.el7.x86_64 selinux=disabled
Keystone + Httpd + Neutron + Dashboard：         192.168.137.12  10.10.10.12 node02 node02.com CentOS-7.2 1511 3.10.0-327.4.5.el7.x86_64 selinux=disabled
Glance-node + Nova-compute + cinder  ：          192.168.137.13  10.10.10.13 node03 node03.com CentOS-7.2 1511 3.10.0-327.4.5.el7.x86_64 selinux=disabled
Nova-controll + cinder ：                        192.168.137.14  10.10.10.14 node04 node04.com CentOS-7.2 1511 3.10.0-327.4.5.el7.x86_64 selinux=disabled


systemctl stop firewalld.service
systemctl enable firealld.service
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service

echo '10.10.10.11 node01 node01.com' >> /etc/hosts
echo '10.10.10.12 node02 node02.com' >> /etc/hosts
echo '10.10.10.13 node03 node03.com' >> /etc/hosts
echo '10.10.10.14 node04 node04.com' >> /etc/hosts

sed -i 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

yum install -y chrony centos-release-openstack-liberty && yum upgrade -y  && yum install -y python-openstackclient openstack-selinux

MariaDB_Password        NpV6Shs4EsaAoApqauQ+4Yx7CK4=        Rabbitmq_password       I1EeXw3H2O7CQrkrz6BF3M8LJns=
KeystoneDB_password     CeI8J9zWJduxuw8+D6gn6QNXgR4=        Admin_password          yqFpg853RDm7b8NXygngeK2VT8Y=
Demo_password           9Put5FyFX3jUiN836UZoKF2fPMI=        GlanceDB_password       f7epf8yLlSLsE6T0yNz1/+W1ZTA=
Glance_password         ixViksr9B+ge0G/8HLmMVgDdlAo=
NovaDB_password         3fXOSGPn4vqBxbZ8Wgwln8o5iYk=        Nova_password           bMdwBJb9b/SjxN7nsHwKDUojjyc=
NeutronDB_password      cO1qxHjbl/5dsP0Avm5x2DpSass=        Neutron_password        j+AgyK9uRXv2CEmlGHGyL7e0/aY=
Metadata_secret         hzRxBpSgrokA59/CQkUEbSts2OY=
CinderDB_password       cgA63A4juHrz0Q4YOr3UM6MvD28=        Cinder_password         zwti4fpvcKlt2Wa9p9WsWOOtAv4=

CeilometerDB_password   YMVUjnZq+OW5+9CvnrWBrkfGc78=        Ceilometer_password     fh5oQH8hH3lszT4ml0qkLbJXrbQ=
DashDB_password         v33f8NU8iwtNtklaHEfrCqyNz1g=        Dash_password           XamIPjiBsgyTYeCbXra7LYNgGeU=
HeatDB_password         fr4xpv4PU04xLAKnEIe7fkcrkgg=
Heat_password           SI2FI8ovQgBDlBvboKhH/fG8aIY=        Heat_domin_password     85zJJ1UZ0IHt73H/1C13pdbfh+g=

Swift_password          IJrvE+6ybf6XdZLW/Rv4/Ru2bgQ=

# 请参考：http://docs.openstack.org/liberty/install-guide-rdo/environment-security.html