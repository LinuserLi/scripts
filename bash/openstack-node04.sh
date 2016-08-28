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
[root@node02 ~ 10:25:55&&87]#openstack endpoint create --region RegionOne compute public http://10.10.10.14:8774/v2.1/%\(tenant_id\)s   #这里要指向nova-controll 节点服务器
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

[root@node04 ~ 10:20:33&&1]#yum install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient -y

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
host=10.10.10.13
port=9292
[guestfs]
[hyperv]
[image_file_url]
[ironic]
[keymgr]
[keystone_authtoken]
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = bMdwBJb9b/SjxN7nsHwKDUojjyc=
[libvirt]
virt_type=qemu
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

[root@node04 ~ 11:56:43&&11]#systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
[root@node04 ~ 11:59:22&&12]#systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-api.service to /usr/lib/systemd/system/openstack-nova-api.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-cert.service to /usr/lib/systemd/system/openstack-nova-cert.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-consoleauth.service to /usr/lib/systemd/system/openstack-nova-consoleauth.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-scheduler.service to /usr/lib/systemd/system/openstack-nova-scheduler.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-conductor.service to /usr/lib/systemd/system/openstack-nova-conductor.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-novncproxy.service to /usr/lib/systemd/system/openstack-nova-novncproxy.servic

[root@node04 ~ 11:59:41&&13]#ss -lntp|egrep nova
LISTEN     0      100          *:6080                     *:*                   users:(("nova-novncproxy",pid=5686,fd=4))
LISTEN     0      128          *:8774                     *:*                   users:(("nova-api",pid=5769,fd=6),("nova-api",pid=5768,fd=6),("nova-api",pid=5
751,fd=6),("nova-api",pid=5750,fd=6),("nova-api",pid=5681,fd=6))
LISTEN     0      128          *:8775                     *:*                   users:(("nova-api",pid=5769,fd=7),("nova-api",pid=5768,fd=7),("nova-api",pid=5
681,fd=7))

==============================================================================================================================================
#Install cinder controll

MariaDB [(none)]> create database cinder character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> grant all privileges on cinder.* to 'cinder'@'localhost' identified by 'cgA63A4juHrz0Q4YOr3UM6MvD28=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> grant all privileges on cinder.* to 'cinder'@'%' identified by 'cgA63A4juHrz0Q4YOr3UM6MvD28=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> use cinder;
Database changed
MariaDB [cinder]> show tables;
Empty set (0.00 sec)

[root@node02 ~ 18:34:12&&71]#source admin-openrc.sh
[root@node02 ~ 21:09:31&&72]#openstack user create --domain default --password-prompt cinder
User Password:             zwti4fpvcKlt2Wa9p9WsWOOtAv4=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 33db68a8b300495cbee1f2ef01b4f1ea |
| name      | cinder                           |
+-----------+----------------------------------+

[root@node02 ~ 21:10:15&&73]#openstack role add --project service --user cinder admin
[root@node02 ~ 21:10:50&&74]#openstack service create --name cinder --description "OpenStack Block Storage" volume
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Block Storage          |
| enabled     | True                             |
| id          | e8697b33eaeb497db8f4d85e9dbb2f3e |
| name        | cinder                           |
| type        | volume                           |
+-------------+----------------------------------+
[root@node02 ~ 21:11:16&&75]#openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Block Storage          |
| enabled     | True                             |
| id          | 55d0adc22c08440fb8ba59c437e3beba |
| name        | cinderv2                         |
| type        | volumev2                         |
+-------------+----------------------------------+

[root@node02 ~ 21:11:30&&76]#openstack endpoint create --region RegionOne volume public http://10.10.10.14:8776/v1/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | 4675fbe000f64b798484078be5b0c3f2         |
| interface    | public                                   |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | e8697b33eaeb497db8f4d85e9dbb2f3e         |
| service_name | cinder                                   |
| service_type | volume                                   |
| url          | http://10.10.10.14:8776/v1/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node02 ~ 21:12:13&&77]#openstack endpoint create --region RegionOne volume internal http://10.10.10.14:8776/v1/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | f3be1b8770394559b7ffdb1867e0ff16         |
| interface    | internal                                 |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | e8697b33eaeb497db8f4d85e9dbb2f3e         |
| service_name | cinder                                   |
| service_type | volume                                   |
| url          | http://10.10.10.14:8776/v1/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node02 ~ 21:12:40&&78]#openstack endpoint create --region RegionOne volume admin http://10.10.10.14:8776/v1/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | 4fcd2b092fd94202a38cb3f588f1fed0         |
| interface    | admin                                    |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | e8697b33eaeb497db8f4d85e9dbb2f3e         |
| service_name | cinder                                   |
| service_type | volume                                   |
| url          | http://10.10.10.14:8776/v1/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node02 ~ 21:13:09&&79]#openstack endpoint create --region RegionOne volumev2 public http://10.10.10.14:8776/v2/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | 2b464128ea8d4929a64ed734cb54ac11         |
| interface    | public                                   |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | 55d0adc22c08440fb8ba59c437e3beba         |
| service_name | cinderv2                                 |
| service_type | volumev2                                 |
| url          | http://10.10.10.14:8776/v2/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node02 ~ 21:13:42&&80]#openstack endpoint create --region RegionOne volumev2 internal http://10.10.10.14:8776/v2/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | b210072f80414a3f878a946cfb2848a6         |
| interface    | internal                                 |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | 55d0adc22c08440fb8ba59c437e3beba         |
| service_name | cinderv2                                 |
| service_type | volumev2                                 |
| url          | http://10.10.10.14:8776/v2/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node02 ~ 21:14:12&&81]#openstack endpoint create --region RegionOne volumev2 admin http://10.10.10.14:8776/v2/%\(tenant_id\)s
+--------------+------------------------------------------+
| Field        | Value                                    |
+--------------+------------------------------------------+
| enabled      | True                                     |
| id           | b6fca0fefa6f4d58915fb28218378352         |
| interface    | admin                                    |
| region       | RegionOne                                |
| region_id    | RegionOne                                |
| service_id   | 55d0adc22c08440fb8ba59c437e3beba         |
| service_name | cinderv2                                 |
| service_type | volumev2                                 |
| url          | http://10.10.10.14:8776/v2/%(tenant_id)s |
+--------------+------------------------------------------+

[root@node04 ~ 21:15:51&&14]#yum install openstack-cinder python-cinderclient python-oslo-policy -y

[root@node04 ~ 21:21:08&&15]#mkdir -p /data/cinder/tmp && chown -R cinder:cinder /data/cinder
[root@node04 ~ 21:21:14&&16]#cp /etc/cinder/cinder.conf{,.bak}
[root@node04 ~ 21:21:19&&17]#cat << eof > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = 10.10.10.14
auth_strategy = keystone
verbose = true
rpc_backend = rabbit
[BRCD_FABRIC_EXAMPLE]
[CISCO_FABRIC_EXAMPLE]
[cors]
[cors.subdomain]
[database]
connection = mysql://cinder:cgA63A4juHrz0Q4YOr3UM6MvD28=@10.10.10.11/cinder
[fc-zone-manager]
[keymgr]
[keystone_authtoken]
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = zwti4fpvcKlt2Wa9p9WsWOOtAv4=
[matchmaker_redis]
[matchmaker_ring]
[oslo_concurrency]
lock_path = /data/cinder/tmp
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.11
rabbit_userid = openstack
rabbit_password = I1EeXw3H2O7CQrkrz6BF3M8LJns=
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[profiler]
eof

[root@node04 ~ 21:30:13&&21]#su -s /bin/sh -c "cinder-manage db sync" cinder
No handlers could be found for logger "oslo_config.cfg"
/usr/lib/python2.7/site-packages/oslo_db/sqlalchemy/enginefacade.py:241: NotSupportedWarning: Configuration option(s) ['use_tpool'] not supported
  exception.NotSupportedWarning
2016-08-27 21:30:19.053 7278 INFO migrate.versioning.api [-] 0 -> 1...
2016-08-27 21:30:24.937 7278 INFO migrate.versioning.api [-] done
2016-08-27 21:30:24.937 7278 INFO migrate.versioning.api [-] 1 -> 2...
........................................................................
2016-08-27 21:30:56.246 7278 INFO migrate.versioning.api [-] 32 -> 33...
/usr/lib64/python2.7/site-packages/sqlalchemy/sql/schema.py:2999: SAWarning: Table 'encryption' specifies columns 'volume_type_id' as primary_key=True,
 not matching locally specified columns 'encryption_id'; setting the current primary key columns to 'encryption_id'. This warning may become an excepti
on in a future release
  ", ".join("'%s'" % c.name for c in self.columns)
2016-08-27 21:30:58.764 7278 INFO migrate.versioning.api [-] done
2016-08-27 21:30:58.764 7278 INFO migrate.versioning.api [-] 33 -> 34...
........................................................................
2016-08-27 21:31:18.704 7278 INFO migrate.versioning.api [-] 59 -> 60...
2016-08-27 21:31:18.756 7278 INFO migrate.versioning.api [-] done


MariaDB [cinder]> show tables;
+----------------------------+
| Tables_in_cinder           |
+----------------------------+
| backups                    |
..............................
| volumes                    |
+----------------------------+
25 rows in set (0.00 sec)

[root@node04 ~ 21:31:18&&22]#vim /etc/nova/nova.conf
[cinder]
os_region_name=RegionOne

[root@node04 ~ 21:34:51&&23]#systemctl restart openstack-nova-api.service
[root@node04 ~ 21:35:05&&24]#systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
[root@node04 ~ 21:35:58&&25]#systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-cinder-api.service to /usr/lib/systemd/system/openstack-cinder-api.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-cinder-scheduler.service to /usr/lib/systemd/system/openstack-cinder-scheduler.service.

[root@node04 ~ 21:36:09&&26]#ss -lntp|egrep cinder
LISTEN     0      128          *:8776                     *:*                   users:(("cinder-api",pid=7421,fd=7),("cinder-api",pid=7420,fd=7),("cind
er-api",pid=7401,fd=7))

[root@node04 ~ 21:36:24&&27]#ps aux|egrep cinder |egrep -v egrep
cinder    7401  5.2  3.6 467196 75140 ?        Ss   21:35   0:02 /usr/bin/python2 /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf
--config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log
cinder    7402  5.5  3.4 443120 69896 ?        Ss   21:35   0:02 /usr/bin/python2 /usr/bin/cinder-scheduler --config-file /usr/share/cinder/cinder-dist
.conf --config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/scheduler.log
cinder    7420  0.0  3.3 467196 68312 ?        S    21:35   0:00 /usr/bin/python2 /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf
--config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log
cinder    7421  0.0  3.3 467196 68312 ?        S    21:35   0:00 /usr/bin/python2 /usr/bin/cinder-api --config-file /usr/share/cinder/cinder-dist.conf
--config-file /etc/cinder/cinder.conf --logfile /var/log/cinder/api.log
root      7444  0.0  0.0 112648   976 pts/2    S+   21:36   0:00 grep -E --color=auto cinder


















