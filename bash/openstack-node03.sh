#!/usr/bin/env bash

mv /etc/chrony.conf{,.bak}

cat << eof > /etc/chrony.conf
server 0.10.10.10.11 iburst
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
==================================================================================================
#Install Glance
MariaDB [keystone]> create database glance character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [keystone]> grant all privileges on glance.* to 'glance'@'localhost' identified by 'f7epf8yLlSLsE6T0yNz1/+W1ZTA=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [keystone]> grant all privileges on glance.* to 'glance'@'%' identified by 'f7epf8yLlSLsE6T0yNz1/+W1ZTA=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [keystone]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [keystone]> use glance
Database changed
MariaDB [glance]> show tables;
Empty set (0.00 sec)

[root@node02 ~ 09:29:40&&74]#source admin-openrc.sh

[root@node02 ~ 09:35:06&&75]#openstack user create --domain default --password-prompt glance
User Password:                 ixViksr9B+ge0G/8HLmMVgDdlAo=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 788c4590667c47eb972539067d6d65e5 |
| name      | glance                           |
+-----------+----------------------------------+

[root@node02 ~ 09:39:16&&78]#openstack role add --project service --user glance admin
[root@node02 ~ 09:39:25&&79]#openstack service create --name glance --description "OpenStack Image service" image
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Image service          |
| enabled     | True                             |
| id          | e4dd0cc6706f44ecba8109db84b6e10b |
| name        | glance                           |
| type        | image                            |
+-------------+----------------------------------+

[root@node02 ~ 09:42:14&&80]#openstack endpoint create --region RegionOne image public http://10.10.10.13:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 170fec80a7dd4f54a69a199e5d267ed1 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e4dd0cc6706f44ecba8109db84b6e10b |
| service_name | glance                           |
| service_type | image                            |
| url          | http://10.10.10.13:9292          |
+--------------+----------------------------------+

[root@node02 ~ 09:42:49&&81]#openstack endpoint create --region RegionOne image internal  http://10.10.10.13:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 3521cd850fdb498eb37bd4c4996a2501 |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e4dd0cc6706f44ecba8109db84b6e10b |
| service_name | glance                           |
| service_type | image                            |
| url          | http://10.10.10.13:9292          |
+--------------+----------------------------------+

[root@node02 ~ 09:44:01&&82]#openstack endpoint create --region RegionOne image admin http://10.10.10.13:9292
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 3e3c42dd47294a718df25d31493cfb0c |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | e4dd0cc6706f44ecba8109db84b6e10b |
| service_name | glance                           |
| service_type | image                            |
| url          | http://10.10.10.13:9292          |
+--------------+----------------------------------+

[root@node03 ~ 09:45:28&&2]#yum install openstack-glance python-glance python-glanceclient python-memcached -y
[root@node03 ~ 09:48:14&&3]#cp /etc/glance/glance-api.conf{,.bak}

[root@node03 ~ 09:56:44&&5]#mkdir -p /data/glance/images/ && chown -R glance:glance /data/glance
[root@node03 ~ 09:57:08&&6]#cat << eof > /etc/glance/glance-api.conf
[DEFAULT]
verbose=True
notification_driver = noop
[database]
connection=mysql://glance:f7epf8yLlSLsE6T0yNz1/+W1ZTA=@10.10.10.11/glance
[glance_store]
default_store = file
filesystem_store_datadir=/data/glance/images/
[image_format]
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = ixViksr9B+ge0G/8HLmMVgDdlAo=
[matchmaker_redis]
[matchmaker_ring]
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
[oslo_policy]
[paste_deploy]
flavor = keystone
[store_type_location_strategy]
[task]
[taskflow_executor]
eof

[root@node03 ~ 09:57:27&&7]#cp /etc/glance/glance-registry.conf{,.bak}
[root@node03 ~ 10:01:01&&9]#cat << eof >/etc/glance/glance-registry.conf
[DEFAULT]
verbose=True
notification_driver = noop
[database]
connection=mysql://glance:f7epf8yLlSLsE6T0yNz1/+W1ZTA=@10.10.10.11/glance
[glance_store]
[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = ixViksr9B+ge0G/8HLmMVgDdlAo=
[matchmaker_redis]
[matchmaker_ring]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
[oslo_policy]
[paste_deploy]
flavor = keystone
eof

[root@node03 ~ 10:02:05&&10]#su -s /bin/sh -c "glance-manage db_sync" glance
No handlers could be found for logger "oslo_config.cfg"
/usr/lib64/python2.7/site-packages/sqlalchemy/engine/default.py:450: Warning: Duplicate index 'ix_image_properties_image_id_name' defined on the tabl
e 'glance.image_properties'. This is deprecated and will be disallowed in a future release.
  cursor.execute(statement, parameters)

MariaDB [glance]> show tables;
+----------------------------------+
| Tables_in_glance                 |
+----------------------------------+
| artifact_blob_locations          |
| artifact_blobs                   |
| artifact_dependencies            |
| artifact_properties              |
| artifact_tags                    |
| artifacts                        |
| image_locations                  |
| image_members                    |
| image_properties                 |
| image_tags                       |
| images                           |
| metadef_namespace_resource_types |
| metadef_namespaces               |
| metadef_objects                  |
| metadef_properties               |
| metadef_resource_types           |
| metadef_tags                     |
| migrate_version                  |
| task_info                        |
| tasks                            |
+----------------------------------+
20 rows in set (0.00 sec)

[root@node03 ~ 10:03:16&&11]#systemctl start openstack-glance-api.service && systemctl enable openstack-glance-api.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-glance-api.service to /usr/lib/systemd/system/openstack-glance-api.service

[root@node03 ~ 10:04:16&&12]#systemctl start openstack-glance-registry.service && systemctl enable openstack-glance-registry.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-glance-registry.service to /usr/lib/systemd/system/openstack-glance-regist
ry.service.

[root@node03 ~ 10:05:01&&13]#ss -lntp |egrep glance
LISTEN     0      128          *:9292                     *:*                   users:(("glance-api",pid=5337,fd=4),("glance-api",pid=5336,fd=4),("gl
ance-api",pid=5327,fd=4))
LISTEN     0      128          *:9191                     *:*                   users:(("glance-registry",pid=5439,fd=4),("glance-registry",pid=5438,
fd=4),("glance-registry",pid=5429,fd=4))

========================================================================================================================
#Install nova-compute

[root@node03 ~ 10:05:14&&14]#yum install openstack-nova-compute sysfsutils -y

.................

http://docs.openstack.org/liberty/install-guide-rdo/nova-compute-install.html













