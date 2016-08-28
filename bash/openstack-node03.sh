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

[root@node02 ~ 09:42:14&&80]#openstack endpoint create --region RegionOne image public http://10.10.10.13:9292  #注意这里的地址要指向glace 服务服务器，即内网的10.10.10.13
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
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
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
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
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
....................................
| tasks                            |
+----------------------------------+
20 rows in set (0.00 sec)

[root@node03 ~ 10:03:16&&11]#systemctl start openstack-glance-api.service && systemctl enable openstack-glance-api.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-glance-api.service to /usr/lib/systemd/system/openstack-glance-api.service

[root@node03 ~ 10:04:16&&12]#systemctl start openstack-glance-registry.service && systemctl enable openstack-glance-registry.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-glance-registry.service to /usr/lib/systemd/system/openstack-glance-registry.service.

[root@node03 ~ 10:05:01&&13]#ss -lntp |egrep glance
LISTEN     0      128          *:9292                     *:*                   users:(("glance-api",pid=5337,fd=4),("glance-api",pid=5336,fd=4),("gl
ance-api",pid=5327,fd=4))
LISTEN     0      128          *:9191                     *:*                   users:(("glance-registry",pid=5439,fd=4),("glance-registry",pid=5438,
fd=4),("glance-registry",pid=5429,fd=4))

[root@node02 ~ 13:51:06&&9]#source admin-openrc.sh

[root@node02 ~ 13:54:12&&13]#wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

[root@node02 ~ 14:12:35&&18]#openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --pub
lic
+------------------+------------------------------------------------------+
| Field            | Value                                                |
+------------------+------------------------------------------------------+
| checksum         | ee1eca47dc88f4879d8a229cc70a07c6                     |
| container_format | bare                                                 |
| created_at       | 2016-08-27T18:27:31Z                                 |
| disk_format      | qcow2                                                |
| file             | /v2/images/99bb5bd7-3437-4f12-a126-6bf8f23336db/file |
| id               | 99bb5bd7-3437-4f12-a126-6bf8f23336db                 |
| min_disk         | 0                                                    |
| min_ram          | 0                                                    |
| name             | cirros                                               |
| owner            | 978d28c8f46f4c2daff556bb6b26e35c                     |
| protected        | False                                                |
| schema           | /v2/schemas/image                                    |
| size             | 13287936                                             |
| status           | active                                               |
| updated_at       | 2016-08-27T18:27:32Z                                 |
| virtual_size     | None                                                 |
| visibility       | public                                               |
+------------------+------------------------------------------------------+

[root@node02 ~ 14:27:29&&19]#glance image-list
+--------------------------------------+--------+
| ID                                   | Name   |
+--------------------------------------+--------+
| 99bb5bd7-3437-4f12-a126-6bf8f23336db | cirros |
+--------------------------------------+--------+

[root@node03 ~ 14:29:11&&4]#du -sh /data/glance/images/99bb5bd7-3437-4f12-a126-6bf8f23336db
13M     /data/glance/images/99bb5bd7-3437-4f12-a126-6bf8f23336db


========================================================================================================================
#Install nova-compute

[root@node03 ~ 10:05:14&&14]#yum install openstack-nova-compute sysfsutils -y

[root@node03 ~ 13:15:08&&2]#mkdir -p /data/nova/tmp && chown -R nova:nova /data/nova/

[root@node03 ~ 13:15:20&&3]#cat << eof > /etc/nova/nova.conf
[DEFAULT]
my_ip=10.10.10.13
auth_strategy = keystone
network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
verbose=true
rpc_backend=rabbit
[api_database]
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
host=10.10.10.13      #glance 所在服务器
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
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 10.10.10.13  #这里是nova 计算节点IP
novncproxy_base_url = http://10.10.10.14:6080/vnc_auto.html  #这里配置nova 控制节点IP
[workarounds]
[xenserver]
[zookeeper]
eof

[root@node03 ~ 13:22:56&&8]#systemctl start libvirtd.service openstack-nova-compute.service

[root@node03 ~ 13:23:55&&9]#systemctl enable libvirtd.service openstack-nova-compute.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-nova-compute.service to /usr/lib/systemd/system/openstack-nova-compute.service.

[root@node03 ~ 13:24:59&&13]#ps aux|egrep 'nova|libvirt' |egrep -v grep
root      6591  0.1  0.9 1137020 18936 ?       Ssl  13:23   0:00 /usr/sbin/libvirtd
nova      6608  3.9  5.8 1686440 119964 ?      Ssl  13:23   0:03 /usr/bin/python2 /usr/bin/nova-compute

[root@node02 ~ 13:26:01&&1]#source admin-openrc.sh

[root@node02 ~ 13:48:26&&6]# nova service-list
+----+------------------+------------+----------+---------+-------+----------------------------+-----------------+
| Id | Binary           | Host       | Zone     | Status  | State | Updated_at                 | Disabled Reason |
+----+------------------+------------+----------+---------+-------+----------------------------+-----------------+
| 1  | nova-conductor   | node04.com | internal | enabled | up    | 2016-08-27T17:49:17.000000 | -               |
| 2  | nova-consoleauth | node04.com | internal | enabled | up    | 2016-08-27T17:49:08.000000 | -               |
| 3  | nova-cert        | node04.com | internal | enabled | up    | 2016-08-27T17:49:08.000000 | -               |
| 4  | nova-scheduler   | node04.com | internal | enabled | up    | 2016-08-27T17:49:18.000000 | -               |
| 5  | nova-compute     | node03.com | nova     | enabled | up    | 2016-08-27T17:49:11.000000 | -               |
+----+------------------+------------+----------+---------+-------+----------------------------+-----------------+

[root@node02 ~ 13:49:16&&7]#nova endpoints
WARNING: nova has no endpoint in ! Available endpoints for this service:
+-----------+---------------------------------------------------------------+
| nova      | Value                                                         |
+-----------+---------------------------------------------------------------+
| id        | 0055f145e7b64733aff85fbab42434f7                              |
| interface | public                                                        |
| region    | RegionOne                                                     |
| region_id | RegionOne                                                     |
| url       | http://10.10.10.14:8774/v2.1/978d28c8f46f4c2daff556bb6b26e35c |
+-----------+---------------------------------------------------------------+
+-----------+---------------------------------------------------------------+
| nova      | Value                                                         |
+-----------+---------------------------------------------------------------+
| id        | 174173fd89c84c8f910ab55b167542ab                              |
| interface | admin                                                         |
| region    | RegionOne                                                     |
| region_id | RegionOne                                                     |
| url       | http://10.10.10.14:8774/v2.1/978d28c8f46f4c2daff556bb6b26e35c |
+-----------+---------------------------------------------------------------+
+-----------+---------------------------------------------------------------+
| nova      | Value                                                         |
+-----------+---------------------------------------------------------------+
| id        | b4773fc6cd6e4a3ea44715b78bcee5cb                              |
| interface | internal                                                      |
| region    | RegionOne                                                     |
| region_id | RegionOne                                                     |
| url       | http://10.10.10.14:8774/v2.1/978d28c8f46f4c2daff556bb6b26e35c |
+-----------+---------------------------------------------------------------+
WARNING: keystone has no endpoint in ! Available endpoints for this service:
+-----------+----------------------------------+
| keystone  | Value                            |
+-----------+----------------------------------+
| id        | 0d4819a076394bf1bfde5299bc6b340f |
| interface | internal                         |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.12:5000/v3       |
+-----------+----------------------------------+
+-----------+----------------------------------+
| keystone  | Value                            |
+-----------+----------------------------------+
| id        | b6745c68ede34439a52b0cfe1225ba91 |
| interface | admin                            |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.12:5000/v3       |
+-----------+----------------------------------+
+-----------+----------------------------------+
| keystone  | Value                            |
+-----------+----------------------------------+
| id        | c25274c6804e4716a5518b7276eba1a5 |
| interface | public                           |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.12:5000/v3       |
+-----------+----------------------------------+
WARNING: glance has no endpoint in ! Available endpoints for this service:
+-----------+----------------------------------+
| glance    | Value                            |
+-----------+----------------------------------+
| id        | 170fec80a7dd4f54a69a199e5d267ed1 |
| interface | public                           |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.13:9292          |
+-----------+----------------------------------+
+-----------+----------------------------------+
| glance    | Value                            |
+-----------+----------------------------------+
| id        | 3521cd850fdb498eb37bd4c4996a2501 |
| interface | internal                         |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.13:9292          |
+-----------+----------------------------------+
+-----------+----------------------------------+
| glance    | Value                            |
+-----------+----------------------------------+
| id        | 3e3c42dd47294a718df25d31493cfb0c |
| interface | admin                            |
| region    | RegionOne                        |
| region_id | RegionOne                        |
| url       | http://10.10.10.13:9292          |
+-----------+----------------------------------+

[root@node02 ~ 14:28:34&&20]#nova image-list
+--------------------------------------+--------+--------+--------+
| ID                                   | Name   | Status | Server |
+--------------------------------------+--------+--------+--------+
| 99bb5bd7-3437-4f12-a126-6bf8f23336db | cirros | ACTIVE |        |
+--------------------------------------+--------+--------+--------+
====================================================================================================
#install neutron
[root@node03 ~ 17:26:33&&3]#yum install openstack-neutron openstack-neutron-linuxbridge ebtables ipset
[root@node03 ~ 17:29:51&&4]#cp /etc/neutron/neutron.conf{,.bak}
[root@node03 ~ 17:33:37&&5]#cat << eof > /etc/neutron/neutron.conf
[DEFAULT]
verbose = True
auth_strategy = keystone
rpc_backend=rabbit
[matchmaker_redis]
[matchmaker_ring]
[quotas]
[agent]
[keystone_authtoken]
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = j+AgyK9uRXv2CEmlGHGyL7e0/aY=
[database]
[nova]
[oslo_concurrency]
lock_path = /data/neutron/tmp
[oslo_policy]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.11
rabbit_userid = openstack
rabbit_password = I1EeXw3H2O7CQrkrz6BF3M8LJns=
[qos]
eof

[root@node03 ~ 17:37:30&&6]#mkdir -p /data/neutron/tmp && chown -R neutron:neutron /data/neutron

[root@node03 ~ 17:38:05&&9]#cat << eof > /etc/nova/nova.conf
url = http://10.10.10.12:9696            #指向neutron 主节点
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = neutron
password = j+AgyK9uRXv2CEmlGHGyL7e0/aY=
eof

[root@node03 ~ 17:43:12&&11]#cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini{,.bak}
[root@node03 ~ 17:43:20&&12]#cat << eof > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
[linux_bridge]
physical_interface_mappings = public:eth0
[vxlan]
enable_vxlan = False
[agent]
prevent_arp_spoofing = True
[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
eof


[root@node03 ~ 17:40:44&&10]#systemctl restart openstack-nova-compute.service
[root@node03 ~ 17:41:15&&11]#systemctl start neutron-linuxbridge-agent.service && systemctl enable neutron-linuxbridge-agent.service

[root@node02 ~ 17:40:05&&56]#source admin-openrc.sh
[root@node02 ~ 17:48:08&&57]#neutron ext-list
+-----------------------+--------------------------+
| alias                 | name                     |
+-----------------------+--------------------------+
| flavors               | Neutron Service Flavors  |
| security-group        | security-group           |
| dns-integration       | DNS Integration          |
| net-mtu               | Network MTU              |
| port-security         | Port Security            |
| binding               | Port Binding             |
| provider              | Provider Network         |
| agent                 | agent                    |
| quotas                | Quota management support |
| subnet_allocation     | Subnet Allocation        |
| dhcp_agent_scheduler  | DHCP Agent Scheduler     |
| rbac-policies         | RBAC Policies            |
| external-net          | Neutron external network |
| multi-provider        | Multi Provider Network   |
| allowed-address-pairs | Allowed Address Pairs    |
| extra_dhcp_opt        | Neutron Extra DHCP opts  |
+-----------------------+--------------------------+

[root@node02 ~ 17:48:50&&58]#neutron agent-list
+--------------------------------------+--------------------+------------+-------+----------------+---------------------------+
| id                                   | agent_type         | host       | alive | admin_state_up | binary                    |
+--------------------------------------+--------------------+------------+-------+----------------+---------------------------+
| 3c22d3cd-5cc7-49f3-8112-fe23a61ae6dd | DHCP agent         | node02.com | :-)   | True           | neutron-dhcp-agent        |
| 57db24c1-1e15-4ed0-a7ea-f7262442d1e7 | Linux bridge agent | node02.com | :-)   | True           | neutron-linuxbridge-agent |
| 86548615-1420-468c-be7a-2b5b53a15857 | Linux bridge agent | node03.com | :-)   | True           | neutron-linuxbridge-agent |
| f733202f-5e21-4244-8303-21e717338cab | Metadata agent     | node02.com | :-)   | True           | neutron-metadata-agent    |
+--------------------------------------+--------------------+------------+-------+----------------+---------------------------+

=============================================================================================================================================
#Install cinder-compute

[root@node03 ~ 21:38:02&&18]#yum install lvm2 -y
[root@node03 ~ 21:38:14&&18]#systemctl enable lvm2-lvmetad.service && systemctl start lvm2-lvmetad.service
Created symlink from /etc/systemd/system/sysinit.target.wants/lvm2-lvmetad.service to /usr/lib/systemd/system/lvm2-lvmetad.service.
[root@node03 ~ 21:38:17&&19]#ps aux|egrep lvm
root       617  0.0  0.0 126676  1336 ?        Ss   06:00   0:00 /usr/sbin/lvmetad -f
root      8067  0.0  0.0 112652   976 pts/2    S+   21:38   0:00 grep -E --color=auto lvm
[root@node03 ~ 21:38:27&&20]#init 0

[root@node03 ~ 06:23:35&&1]#fdisk -l

Disk /dev/sdb: 107.4 GB, 107374182400 bytes, 209715200 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/sda: 53.7 GB, 53687091200 bytes, 104857600 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disk label type: dos
Disk identifier: 0x000318aa

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048      976895      487424   83  Linux
/dev/sda2          976896   104857599    51940352   8e  Linux LVM

Disk /dev/mapper/centos-root: 38.8 GB, 38839255040 bytes, 75857920 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos-swap: 4097 MB, 4097835008 bytes, 8003584 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes


Disk /dev/mapper/centos-home: 10.2 GB, 10242490368 bytes, 20004864 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes

[root@node03 ~ 06:23:39&&2]#pvcreate /dev/sdb
Physical volume "/dev/sdb" successfully created

[root@node03 ~ 06:24:10&&3]#vgcreate cinder-volumes /dev/sdb
Volume group "cinder-volumes" successfully created

[root@node03 ~ 06:24:32&&4]#cp /etc/lvm/lvm.conf{,.bak}
        filter = [ "a/sdb/","r/.*/"]

[root@node03 ~ 06:56:39&&14]#systemctl restart lvm2-lvmetad.service

[root@node03 ~ 06:27:19&&6]#yum install openstack-cinder targetcli python-oslo-policy -y

[root@node03 ~ 06:30:07&&7]#cp  /etc/cinder/cinder.conf{,.bak}
[root@node03 ~ 06:30:25&&8]#cat << eof > /etc/cinder/cinder.conf
[DEFAULT]
my_ip = 10.10.10.13
glance_host = 10.10.10.13
auth_strategy = keystone
enabled_backends = lvm
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
[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = lioadm
eof

[root@node03 ~ 06:36:18&&10]#mkdir -p /data/cinder/tmp && chown -R cinder:cinder /data/cinder

[root@node03 ~ 06:36:46&&11]#systemctl start openstack-cinder-volume.service target.service
[root@node03 ~ 06:37:14&&12]#systemctl enable openstack-cinder-volume.service target.service
Created symlink from /etc/systemd/system/multi-user.target.wants/openstack-cinder-volume.service to /usr/lib/systemd/system/openstack-cinder-volume.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/target.service to /usr/lib/systemd/system/target.service.

[root@node02 ~ 21:14:40&&82]#source admin-openrc.sh

[root@node02 ~ 22:59:46&&94]#cinder service-list
+------------------+----------------+------+---------+-------+----------------------------+-----------------
+
|      Binary      |      Host      | Zone |  Status | State |         Updated_at         | Disabled Reason
|
+------------------+----------------+------+---------+-------+----------------------------+-----------------
+
| cinder-scheduler |   node04.com   | nova | enabled |   up  | 2016-08-28T11:25:18.000000 |        -
|
|  cinder-volume   | node03.com@lvm | nova | enabled |   up  | 2016-08-28T11:25:22.000000 |        -
|
+------------------+----------------+------+---------+-------+----------------------------+-----------------
+







.................

http://docs.openstack.org/liberty/install-guide-rdo/nova-compute-install.html