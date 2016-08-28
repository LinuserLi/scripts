#!/usr/bin/env bash

mv /etc/chrony.conf{,.bak}

cat << eof > /etc/chrony.conf
server 10.10.10.11 iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
noclientlog
logchange 0.5
logdir /var/log/chrony
eof

systemctl start chronyd.service && systemctl enable chronyd.service

chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^? node01                        3   6     3     1   -225us[ -225us] +/-   29ms
================================================================================================================
#Install nova

MariaDB [glance]> create database nova character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [glance]> grant all privileges on nova.* to 'nova'@'localhost' identified by '3fXOSGPn4vqBxbZ8Wgwln8o5iYk=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [glance]> grant all privileges on nova.* to 'nova'@'%' identified by '3fXOSGPn4vqBxbZ8Wgwln8o5iYk=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [glance]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [glance]> use nova;
Database changed
MariaDB [nova]> show tables;
Empty set (0.00 sec)

[root@node02 ~ 09:44:40&&83]#source admin-openrc.sh

[root@node02 ~ 10:24:28&&84]#openstack user create --domain default --password-prompt nova
User Password:                   bMdwBJb9b/SjxN7nsHwKDUojjyc=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 104156f5d96742faaf539b4139fac434 |
| name      | nova                             |
+-----------+----------------------------------+

[root@node02 ~ 10:25:35&&85]#openstack role add --project service --user nova admin
[root@node02 ~ 10:25:45&&86]#openstack service create --name nova --description "OpenStack Compute" compute
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Compute                |
| enabled     | True                             |
| id          | 0b36e088c6af46e28a86d1757c692e13 |
| name        | nova                             |
| type        | compute                          |
+-------------+----------------------------------+
[root@node02 ~ 10:25:55&&87]#openstack endpoint create --region RegionOne compute public http://10.10.10.14:8774/v2.1/%\(tenant_id\)s
+--------------+--------------------------------------------+
| Field        | Value                                      |
+--------------+--------------------------------------------+
| enabled      | True                                       |
| id           | 0055f145e7b64733aff85fbab42434f7           |
| interface    | public                                     |
| region       | RegionOne                                  |
| region_id    | RegionOne                                  |
| service_id   | 0b36e088c6af46e28a86d1757c692e13           |
| service_name | nova                                       |
| service_type | compute                                    |
| url          | http://10.10.10.14:8774/v2.1/%(tenant_id)s |
+--------------+--------------------------------------------+

[root@node02 ~ 10:26:19&&88]#openstack endpoint create --region RegionOne compute internal http://10.10.10.14:8774/v2.1/%\(tenant_id\)s
+--------------+--------------------------------------------+
| Field        | Value                                      |
+--------------+--------------------------------------------+
| enabled      | True                                       |
| id           | b4773fc6cd6e4a3ea44715b78bcee5cb           |
| interface    | internal                                   |
| region       | RegionOne                                  |
| region_id    | RegionOne                                  |
| service_id   | 0b36e088c6af46e28a86d1757c692e13           |
| service_name | nova                                       |
| service_type | compute                                    |
| url          | http://10.10.10.14:8774/v2.1/%(tenant_id)s |
+--------------+--------------------------------------------+

[root@node02 ~ 10:26:54&&89]#openstack endpoint create --region RegionOne compute admin http://10.10.10.14:8774/v2.1/%\(tenant_id\)s
+--------------+--------------------------------------------+
| Field        | Value                                      |
+--------------+--------------------------------------------+
| enabled      | True                                       |
| id           | 174173fd89c84c8f910ab55b167542ab           |
| interface    | admin                                      |
| region       | RegionOne                                  |
| region_id    | RegionOne                                  |
| service_id   | 0b36e088c6af46e28a86d1757c692e13           |
| service_name | nova                                       |
| service_type | compute                                    |
| url          | http://10.10.10.14:8774/v2.1/%(tenant_id)s |
+--------------+--------------------------------------------+

[root@node04 ~ 10:20:33&&1]#yum install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncp
roxy openstack-nova-scheduler python-novaclient -y

[root@node04 ~ 10:32:28&&2]#cp /etc/nova/nova.conf{,.bak}

[root@node04 ~ 11:48:41&&4]#cat << eof > /etc/nova/nova.conf
[DEFAULT]
network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
my_ip=10.10.10.14
enabled_apis=osapi_compute,metadata
auth_strategy=keystone
verbose=true
rpc_backend=rabbit
[api_database]
[database]
connection=mysql://nova:3fXOSGPn4vqBxbZ8Wgwln8o5iYk=@10.10.10.11/nova
[barbican]
[cells]
[cinder]
[conductor]
[cors]
[cors.subdomain]
[database]
[ephemeral_storage_encryption]
[glance]
host=$my_ip
port=9292
[guestfs]
[hyperv]
[image_file_url]
[ironic]
[keymgr]
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = I1EeXw3H2O7CQrkrz6BF3M8LJns=
[libvirt]
[matchmaker_redis]
[matchmaker_ring]
[metrics]
[neutron]
[osapi_v21]
[oslo_concurrency]
lock_path=/data/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
rabbit_host=10.10.10.11
rabbit_port=5672
rabbit_userid=openstack
rabbit_password=I1EeXw3H2O7CQrkrz6BF3M8LJns=
[oslo_middleware]
[rdp]
[serial_console]
[spice]
[ssl]
[trusted_computing]
[upgrade_levels]
[vmware]
[vnc]
vncserver_listen=$my_ip
vncserver_proxyclient_address=$my_ip
[workarounds]
[xenserver]
[zookeeper]
eof

[root@node04 ~ 11:48:49&&5]#mkdir -p /data/nova/tmp && chown -R nova:nova /data/nova

[root@node04 ~ 11:53:57&&10]#su -s /bin/sh -c "nova-manage db sync" nova
No handlers could be found for logger "oslo_config.cfg"
/usr/lib64/python2.7/site-packages/sqlalchemy/engine/default.py:450: Warning: Duplicate index 'block_device_mapping_instance_uuid_virtual_name_device_name_idx
' defined on the table 'nova.block_device_mapping'. This is deprecated and will be disallowed in a future release.
  cursor.execute(statement, parameters)
/usr/lib64/python2.7/site-packages/sqlalchemy/engine/default.py:450: Warning: Duplicate index 'uniq_instances0uuid' defined on the table 'nova.instances'. Thi
s is deprecated and will be disallowed in a future release.
  cursor.execute(statement, parameters)

MariaDB [nova]> show tables;
+--------------------------------------------+
| Tables_in_nova                             |
+--------------------------------------------+
| agent_builds                               |
| aggregate_hosts                            |
| aggregate_metadata                         |
| aggregates                                 |
..............................................
| volume_usage_cache                         |
+--------------------------------------------+
105 rows in set (0.02 sec)

[root@node04 ~ 11:56:43&&11]#systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-schedul
er.service openstack-nova-conductor.service openstack-nova-novncproxy.service
[root@node04 ~ 11:59:22&&12]#systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-schedu
ler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-api.service to /usr/lib/systemd/system/openstack-nova-api.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-cert.service to /usr/lib/systemd/system/openstack-nova-cert.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-consoleauth.service to /usr/lib/systemd/system/openstack-nova-consoleauth.serv
ice.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-scheduler.service to /usr/lib/systemd/system/openstack-nova-scheduler.service.

Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-conductor.service to /usr/lib/systemd/system/openstack-nova-conductor.service.

Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-novncproxy.service to /usr/lib/systemd/system/openstack-nova-novncproxy.servic

[root@node04 ~ 11:59:41&&13]#ss -lntp|egrep nova
LISTEN     0      100          *:6080                     *:*                   users:(("nova-novncproxy",pid=5686,fd=4))
LISTEN     0      128          *:8774                     *:*                   users:(("nova-api",pid=5769,fd=6),("nova-api",pid=5768,fd=6),("nova-api",pid=5
751,fd=6),("nova-api",pid=5750,fd=6),("nova-api",pid=5681,fd=6))
LISTEN     0      128          *:8775                     *:*                   users:(("nova-api",pid=5769,fd=7),("nova-api",pid=5768,fd=7),("nova-api",pid=5
681,fd=7))























