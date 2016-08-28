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
==================================================================================================================
#Install keystone

MariaDB [(none)]> create database keystone character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> grant all privileges on keystone.* to 'keystone'@'localhost' identified by 'CeI8J9zWJduxuw8+D6gn6QNXgR4=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> grant all privileges on keystone.* to 'keystone'@'%' identified by 'CeI8J9zWJduxuw8+D6gn6QNXgR4=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> use keystone;
Database changed

MariaDB [keystone]> select user,host from mysql.user where user='keystone';
+----------+-----------+
| user     | host      |
+----------+-----------+
| keystone | %         |
| keystone | localhost |
+----------+-----------+
2 rows in set (0.00 sec)

[root@node02 ~ 08:44:41&&17]# yum install openstack-keystone httpd mod_wsgi python-memcached -y

[root@node02 ~ 08:44:41&&18]# cp /etc/keystone/keystone.conf{,.bak}

[root@node02 ~ 08:44:41&&19]# cat << eof > /etc/keystone/keystone.conf
[DEFAULT]
admin_token = 'yqFpg853RDm7b8NXygngeK2VT8Y='
verbose = true
[assignment]
[auth]
[cache]
[catalog]
[cors]
[cors.subdomain]
[credential]
[database]
connection = mysql://keystone:'CeI8J9zWJduxuw8+D6gn6QNXgR4='@10.10.10.11/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[eventlet_server_ssl]
[federation]
[fernet_tokens]
[identity]
[identity_mapping]
[kvs]
[ldap]
[matchmaker_redis]
[matchmaker_ring]
[memcache]
servers = 10.10.10.11:11211
[oauth1]
[os_inherit]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
[policy]
[resource]
[revoke]
driver = sql
[role]
[saml]
[signing]
[ssl]
[token]
provider = uuid
driver = memcache
[tokenless_auth]
[trust]
eof

[root@node02 ~ 08:46:35&&20]#su -s /bin/sh -c "keystone-manage db_sync" keystone
No handlers could be found for logger "oslo_config.cfg"    #忽略这行的输出，只要没error 就没问题

MariaDB [keystone]> update mysql.user set password=PASSWORD("CeI8J9zWJduxuw8+D6gn6QNXgR4=") where user='keystone';
Query OK, 2 rows affected (0.00 sec)
Rows matched: 2  Changed: 2  Warnings: 0

MariaDB [keystone]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [keystone]> show tables;
+------------------------+
| Tables_in_keystone     |
+------------------------+
| access_token           |
| assignment             |
| config_register        |
..........................
| whitelisted_config     |
+------------------------+
33 rows in set (0.00 sec)

[root@node02 ~ 08:55:47&&11]#sed -i 's/^#ServerName www.example.com:80/ServerName localhost:80/' /etc/httpd/conf/httpd.conf

[root@node02 ~ 08:57:41&&13]# cat <<  eof > /etc/httpd/conf.d/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
eof

[root@node02 ~ 08:58:56&&17]#systemctl start httpd.service && systemctl restart httpd.service

[root@node02 ~ 08:58:56&&17]#ss -lntp |egrep httpd
LISTEN     0      128         :::80                      :::*                   users:(("httpd",pid=5604,fd=4),("httpd",pid=5603,fd=4),("httpd",pid=5602,fd=4),("httpd
",pid=5601,fd=4),("httpd",pid=5600,fd=4),("httpd",pid=5589,fd=4))
LISTEN     0      128         :::35357                   :::*                   users:(("httpd",pid=5604,fd=8),("httpd",pid=5603,fd=8),("httpd",pid=5602,fd=8),("httpd
",pid=5601,fd=8),("httpd",pid=5600,fd=8),("httpd",pid=5589,fd=8))
LISTEN     0      128         :::5000                    :::*                   users:(("httpd",pid=5604,fd=6),("httpd",pid=5603,fd=6),("httpd",pid=5602,fd=6),("httpd
",pid=5601,fd=6),("httpd",pid=5600,fd=6),("httpd",pid=5589,fd=6))


[root@node02 ~ 09:05:13&&32]#export OS_TOKEN='yqFpg853RDm7b8NXygngeK2VT8Y='
[root@node02 ~ 09:05:51&&33]#export OS_URL=http://10.10.10.12:35357/v3
[root@node02 ~ 09:05:51&&34]#export OS_IDENTITY_API_VERSION=3


[root@node02 ~ 09:05:52&&35]#openstack service create --name keystone --description "OpenStack Identity" identity
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Identity               |
| enabled     | True                             |
| id          | 8f948b446bdd40848247134a98b91fc1 |
| name        | keystone                         |
| type        | identity                         |
+-------------+----------------------------------+

[root@node02 ~ 09:12:35&&36]#openstack endpoint create --region RegionOne identity public http://10.10.10.12:5000/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | c25274c6804e4716a5518b7276eba1a5 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8f948b446bdd40848247134a98b91fc1 |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://10.10.10.12:5000/v3       |
+--------------+----------------------------------+

[root@node02 ~ 09:13:01&&37]#openstack endpoint create --region RegionOne identity internal http://10.10.10.12:5000/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 0d4819a076394bf1bfde5299bc6b340f |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8f948b446bdd40848247134a98b91fc1 |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://10.10.10.12:5000/v3       |
+--------------+----------------------------------+

[root@node02 ~ 09:14:16&&38]#openstack endpoint create --region RegionOne identity admin http://10.10.10.12:5000/v3
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | b6745c68ede34439a52b0cfe1225ba91 |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | 8f948b446bdd40848247134a98b91fc1 |
| service_name | keystone                         |
| service_type | identity                         |
| url          | http://10.10.10.12:5000/v3       |
+--------------+----------------------------------+

[root@node02 ~ 09:14:41&&39]#openstack project create --domain default   --description "Admin Project" admin
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Admin Project                    |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 978d28c8f46f4c2daff556bb6b26e35c |
| is_domain   | False                            |
| name        | admin                            |
| parent_id   | None                             |
+-------------+----------------------------------+

[root@node02 ~ 09:15:00&&40]#openstack user create --domain default --password-prompt admin
User Password:               yqFpg853RDm7b8NXygngeK2VT8Y=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 480388cbc5ef40959174d3e71256b1f5 |
| name      | admin                            |
+-----------+----------------------------------+

[root@node02 ~ 09:16:04&&41]#openstack role create admin
+-------+----------------------------------+
| Field | Value                            |
+-------+----------------------------------+
| id    | fc4e303357e440478b9a7ebf4c8a72db |
| name  | admin                            |
+-------+----------------------------------+
[root@node02 ~ 09:16:31&&42]#openstack role add --project admin --user admin admin

[root@node02 ~ 09:16:41&&43]#openstack project create --domain default --description "Service Project" service
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Service Project                  |
| domain_id   | default                          |
| enabled     | True                             |
| id          | 906791fafba0444cb1e6160808d991d3 |
| is_domain   | False                            |
| name        | servic                           |
| parent_id   | None                             |
+-------------+----------------------------------+

[root@node02 ~ 09:17:02&&44]#openstack project create --domain default --description "Demo Project" demo
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | Demo Project                     |
| domain_id   | default                          |
| enabled     | True                             |
| id          | a86429936d5f410eaf863ca40cd72111 |
| is_domain   | False                            |
| name        | demo                             |
| parent_id   | None                             |
+-------------+----------------------------------+

[root@node02 ~ 09:18:21&&46]#openstack user create --domain default --password-prompt demo
User Password:                  9Put5FyFX3jUiN836UZoKF2fPMI=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | d2d9d5fb001b4b50940e73dbcbe94aca |
| name      | demo                             |
+-----------+----------------------------------+

[root@node02 ~ 09:18:36&&47]#openstack role create user
+-------+----------------------------------+
| Field | Value                            |
+-------+----------------------------------+
| id    | 15ac3dab2a054e24a3482b8a5ee1851e |
| name  | user                             |
+-------+----------------------------------+
[root@node02 ~ 09:19:07&&48]#openstack role add --project demo --user demo user

[root@node02 ~ 09:19:15&&49]#cp /usr/share/keystone/keystone-dist-paste.ini{,.bak}
[root@node02 ~ 09:20:45&&52]#cat << eof > /usr/share/keystone/keystone-dist-paste.ini
[filter:debug]
[filter:request_id]
[filter:build_auth_context]
[filter:token_auth]
[filter:admin_token_auth]
[filter:json_body]
[filter:user_crud_extension]
[filter:crud_extension]
[filter:ec2_extension]
[filter:ec2_extension_v3]
[filter:federation_extension]
[filter:oauth1_extension]
[filter:s3_extension]
[filter:endpoint_filter_extension]
[filter:simple_cert_extension]
[filter:revoke_extension]
[filter:url_normalize]
[filter:sizelimit]
[app:public_service]
[app:service_v3]
[app:admin_service]
[pipeline:public_api]
pipeline = sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension user_crud_extension public_service
[pipeline:admin_api]
pipeline = sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension crud_extension admin_service
[pipeline:api_v3]
pipeline = sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension simple_cert_extension revoke_extension fe
deration_extension oauth1_extension endpoint_filter_extension service_v3
[app:public_version_service]
[app:admin_version_service]
[pipeline:public_version_api]
pipeline = sizelimit url_normalize public_version_service
[pipeline:admin_version_api]
pipeline = sizelimit url_normalize admin_version_service
[composite:main]
/v2.0 = public_api
/v3 = api_v3
/ = public_version_api
[composite:admin]
/v2.0 = admin_api
/v3 = api_v3
/ = admin_version_api
eof

[root@node02 ~ 09:20:56&&53]#unset OS_TOKEN  OS_URL OS_IDENTITY_API_VERSION

[root@node02 ~ 09:24:07&&59]#openstack --os-auth-url http://10.10.10.12:35357/v3 --os-project-domain-name default --os-user-domain-name default --os-project
-name admin --os-username admin token issue
Password:                                             yqFpg853RDm7b8NXygngeK2VT8Y=
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2016-08-27T14:24:16.410462Z      |
| id         | b1e273e8eec641b48357ffcfe8acfa2d |
| project_id | 978d28c8f46f4c2daff556bb6b26e35c |
| user_id    | 480388cbc5ef40959174d3e71256b1f5 |
+------------+----------------------------------+

[root@node02 ~ 09:24:16&&60]#openstack --os-auth-url http://10.10.10.12:5000/v3 --os-project-domain-name default --os-user-domain-name default --os-project-
name demo --os-username demo token issue
Password:                                             9Put5FyFX3jUiN836UZoKF2fPMI=
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2016-08-27T14:24:52.147842Z      |
| id         | 5ab8c5053b4a49e199045a478ee2c17e |
| project_id | a86429936d5f410eaf863ca40cd72111 |
| user_id    | d2d9d5fb001b4b50940e73dbcbe94aca |
+------------+----------------------------------+

[root@node02 ~ 09:24:52&&61]#cat << eof > admin-openrc.sh
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD='yqFpg853RDm7b8NXygngeK2VT8Y='
export OS_AUTH_URL=http://10.10.10.12:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
eof

[root@node02 ~ 09:27:03&&62]#cat << eof > demo-openrc.sh
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD='9Put5FyFX3jUiN836UZoKF2fPMI='
export OS_AUTH_URL=http://node02:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
eof

[root@node02 ~ 09:27:05&&63]#source admin-openrc.sh
[root@node02 ~ 09:29:15&&71]#openstack token issue
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2016-08-27T14:29:26.846776Z      |
| id         | 4d76d7164a6547a0974121bce5f48aa5 |
| project_id | 978d28c8f46f4c2daff556bb6b26e35c |
| user_id    | 480388cbc5ef40959174d3e71256b1f5 |
+------------+----------------------------------+

[root@node02 ~ 09:29:26&&72]#source demo-openrc.sh
[root@node02 ~ 09:29:31&&73]#openstack token issue
+------------+----------------------------------+
| Field      | Value                            |
+------------+----------------------------------+
| expires    | 2016-08-27T14:29:40.418103Z      |
| id         | 28309bd1b8114a9ca7f0e66ae251d404 |
| project_id | a86429936d5f410eaf863ca40cd72111 |
| user_id    | d2d9d5fb001b4b50940e73dbcbe94aca |
+------------+----------------------------------+

===========================================================================================================
#Install neutron:

MariaDB [(none)]> create database neutron character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> grant all privileges on neutron.* to 'neutron'@'localhost' identified by 'cO1qxHjbl/5dsP0Avm5x2DpSass=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> grant all privileges on neutron.* to 'neutron'@'%' identified by 'cO1qxHjbl/5dsP0Avm5x2DpSass=';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> use neutron;
Database changed
MariaDB [neutron]> show tables;
Empty set (0.00 sec)

[root@node02 ~ 14:29:41&&21]#source admin-openrc.sh

#创建用户
[root@node02 ~ 16:18:59&&22]#openstack user create --domain default --password-prompt neutron
User Password:                   j+AgyK9uRXv2CEmlGHGyL7e0/aY=
Repeat User Password:
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| enabled   | True                             |
| id        | 8447250003e6402caeb16b1cd64804a9 |
| name      | neutron                          |
+-----------+----------------------------------+

[root@node02 ~ 16:19:33&&23]#openstack role add --project service --user neutron admin

[root@node02 ~ 16:20:24&&24]#openstack service create --name neutron --description "OpenStack Networking" network
+-------------+----------------------------------+
| Field       | Value                            |
+-------------+----------------------------------+
| description | OpenStack Networking             |
| enabled     | True                             |
| id          | f8546d8f9660442696381cf459064485 |
| name        | neutron                          |
| type        | network                          |
+-------------+----------------------------------+

[root@node02 ~ 16:20:50&&25]#openstack endpoint create --region RegionOne network public http://10.10.10.12:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 982db3f719814cb9a66669fd26321802 |
| interface    | public                           |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | f8546d8f9660442696381cf459064485 |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://10.10.10.12:9696          |
+--------------+----------------------------------+

[root@node02 ~ 16:21:28&&26]#openstack endpoint create --region RegionOne network internal http://10.10.10.12:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | a6ab24b4731640f48281c461a595800d |
| interface    | internal                         |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | f8546d8f9660442696381cf459064485 |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://10.10.10.12:9696          |
+--------------+----------------------------------+

[root@node02 ~ 16:22:27&&27]#openstack endpoint create --region RegionOne network admin http://10.10.10.12:9696
+--------------+----------------------------------+
| Field        | Value                            |
+--------------+----------------------------------+
| enabled      | True                             |
| id           | 1262a54b7e0a4ba1a438c454a41f516a |
| interface    | admin                            |
| region       | RegionOne                        |
| region_id    | RegionOne                        |
| service_id   | f8546d8f9660442696381cf459064485 |
| service_name | neutron                          |
| service_type | network                          |
| url          | http://10.10.10.12:9696          |
+--------------+----------------------------------+

[root@node02 ~ 16:23:29&&29]#yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge python-neutronclient ebtables ipset

[root@node02 ~ 16:31:11&&30]#cp /etc/neutron/neutron.conf{,.bak}

[root@node02 ~ 16:44:28&&34]#cat << eof > /etc/neutron/neutron.conf
[DEFAULT]
verbose = True
core_plugin = ml2
service_plugins =
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://10.10.10.14:8774/v2
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
password = 'j+AgyK9uRXv2CEmlGHGyL7e0/aY='
[database]
connection = mysql://neutron:'cO1qxHjbl/5dsP0Avm5x2DpSass='@10.10.10.11:3306/neutron
[nova]
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = nova
password = 'bMdwBJb9b/SjxN7nsHwKDUojjyc='
[oslo_concurrency]
lock_path = /data/neutron/tmp
[oslo_policy]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.11
rabbit_port = 5672
rabbit_userid = openstack
rabbit_password = 'I1EeXw3H2O7CQrkrz6BF3M8LJns='
[qos]
eof

[root@node02 ~ 16:44:22&&33]#mkdir -p /data/neutron/tmp && chown -R neutron:neutron /data/neutron

[root@node02 ~ 16:44:48&&35]#cp /etc/neutron/plugins/ml2/ml2_conf.ini{,.bak}
[root@node02 ~ 16:46:23&&36]#cat << eof >/etc/neutron/plugins/ml2/ml2_conf.ini
[ml2]
type_drivers = flat,vlan
tenant_network_types =
mechanism_drivers = linuxbridge
extension_drivers = port_security
[ml2_type_flat]
flat_networks = public
[ml2_type_vlan]
[ml2_type_gre]
[ml2_type_vxlan]
[ml2_type_geneve]
[securitygroup]
enable_ipset = True
eof

[root@node02 ~ 16:49:17&&39]#cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini{,.bak}
[root@node02 ~ 16:50:39&&40]#cat << eof > /etc/neutron/plugins/ml2/linuxbridge_agent.ini
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

[root@node02 ~ 16:52:31&&42]#cp /etc/neutron/dhcp_agent.ini{,.bak}
[root@node02 ~ 16:57:15&&43]#cat << eof >  /etc/neutron/dhcp_agent.ini
[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
verbose = True
[AGENT]
eof

[root@node02 ~ 16:58:38&&45]#cp /etc/neutron/metadata_agent.ini{,.bak}
[root@node02 ~ 16:59:33&&46]#cat << eof > /etc/neutron/metadata_agent.ini
[DEFAULT]
verbose = True
auth_uri = http://10.10.10.12:5000
auth_url = http://10.10.10.12:35357
auth_region = RegionOne
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = 'j+AgyK9uRXv2CEmlGHGyL7e0/aY='
nova_metadata_ip = 10.10.10.14
nova_metadata_port = 8775
metadata_proxy_shared_secret = 'hzRxBpSgrokA59/CQkUEbSts2OY='
[AGENT]
eof

[root@node04 ~ 16:38:19&&12]#vim /etc/nova/nova.conf
[neutron]
url = http://10.10.10.12:9696         #neutron 服务器
auth_url = http://10.10.10.12:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = neutron
password = 'j+AgyK9uRXv2CEmlGHGyL7e0/aY='
service_metadata_proxy = True
metadata_proxy_shared_secret = 'hzRxBpSgrokA59/CQkUEbSts2OY='

[root@node02 ~ 17:09:03&&49]#ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

[root@node02 ~ 17:11:03&&51]#su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --
config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
INFO  [alembic.runtime.migration] Context impl MySQLImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
  Running upgrade for neutron ...
INFO  [alembic.runtime.migration] Context impl MySQLImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> juno, juno_initial
INFO  [alembic.runtime.migration] Running upgrade juno -> 44621190bc02, add_uniqueconstraint_ipavailability_
ranges
INFO  [alembic.runtime.migration] Running upgrade 44621190bc02 -> 1f71e54a85e7, ml2_network_segments models
change for multi-segment network.
INFO  [alembic.runtime.migration] Running upgrade 1f71e54a85e7 -> 408cfbf6923c, remove ryu plugin
INFO  [alembic.runtime.migration] Running upgrade 408cfbf6923c -> 28c0ffb8ebbd, remove mlnx plugin
INFO  [alembic.runtime.migration] Running upgrade 28c0ffb8ebbd -> 57086602ca0a, scrap_nsx_adv_svcs_models
INFO  [alembic.runtime.migration] Running upgrade 57086602ca0a -> 38495dc99731, ml2_tunnel_endpoints_table
INFO  [alembic.runtime.migration] Running upgrade 38495dc99731 -> 4dbe243cd84d, nsxv
INFO  [alembic.runtime.migration] Running upgrade 4dbe243cd84d -> 41662e32bce2, L3 DVR SNAT mapping
INFO  [alembic.runtime.migration] Running upgrade 41662e32bce2 -> 2a1ee2fb59e0, Add mac_address unique const
raint
INFO  [alembic.runtime.migration] Running upgrade 2a1ee2fb59e0 -> 26b54cf9024d, Add index on allocated
INFO  [alembic.runtime.migration] Running upgrade 26b54cf9024d -> 14be42f3d0a5, Add default security group t
able
INFO  [alembic.runtime.migration] Running upgrade 14be42f3d0a5 -> 16cdf118d31d, extra_dhcp_options IPv6 supp
ort
INFO  [alembic.runtime.migration] Running upgrade 16cdf118d31d -> 43763a9618fd, add mtu attributes to networ
k
INFO  [alembic.runtime.migration] Running upgrade 43763a9618fd -> bebba223288, Add vlan transparent property
 to network
INFO  [alembic.runtime.migration] Running upgrade bebba223288 -> 4119216b7365, Add index on tenant_id column

INFO  [alembic.runtime.migration] Running upgrade 4119216b7365 -> 2d2a8a565438, ML2 hierarchical binding
INFO  [alembic.runtime.migration] Running upgrade 2d2a8a565438 -> 2b801560a332, Remove Hyper-V Neutron Plugi
n
INFO  [alembic.runtime.migration] Running upgrade 2b801560a332 -> 57dd745253a6, nuage_kilo_migrate
INFO  [alembic.runtime.migration] Running upgrade 57dd745253a6 -> f15b1fb526dd, Cascade Floating IP Floating
 Port deletion
INFO  [alembic.runtime.migration] Running upgrade f15b1fb526dd -> 341ee8a4ccb5, sync with cisco repo
INFO  [alembic.runtime.migration] Running upgrade 341ee8a4ccb5 -> 35a0f3365720, add port-security in ml2
INFO  [alembic.runtime.migration] Running upgrade 35a0f3365720 -> 1955efc66455, weight_scheduler
INFO  [alembic.runtime.migration] Running upgrade 1955efc66455 -> 51c54792158e, Initial operations for subne
tpools
INFO  [alembic.runtime.migration] Running upgrade 51c54792158e -> 589f9237ca0e, Cisco N1kv ML2 driver tables

INFO  [alembic.runtime.migration] Running upgrade 589f9237ca0e -> 20b99fd19d4f, Cisco UCS Manager Mechanism
Driver
INFO  [alembic.runtime.migration] Running upgrade 20b99fd19d4f -> 034883111f, Remove allow_overlap from subn
etpools
INFO  [alembic.runtime.migration] Running upgrade 034883111f -> 268fb5e99aa2, Initial operations in support
of subnet allocation from a pool
INFO  [alembic.runtime.migration] Running upgrade 268fb5e99aa2 -> 28a09af858a8, Initial operations to suppor
t basic quotas on prefix space in a subnet pool
INFO  [alembic.runtime.migration] Running upgrade 28a09af858a8 -> 20c469a5f920, add index for port
INFO  [alembic.runtime.migration] Running upgrade 20c469a5f920 -> kilo, kilo
INFO  [alembic.runtime.migration] Running upgrade kilo -> 354db87e3225, nsxv_vdr_metadata.py
INFO  [alembic.runtime.migration] Running upgrade 354db87e3225 -> 599c6a226151, neutrodb_ipam
INFO  [alembic.runtime.migration] Running upgrade 599c6a226151 -> 52c5312f6baf, Initial operations in suppor
t of address scopes
INFO  [alembic.runtime.migration] Running upgrade 52c5312f6baf -> 313373c0ffee, Flavor framework
INFO  [alembic.runtime.migration] Running upgrade 313373c0ffee -> 8675309a5c4f, network_rbac
INFO  [alembic.runtime.migration] Running upgrade kilo -> 30018084ec99, Initial no-op Liberty contract rule.

INFO  [alembic.runtime.migration] Running upgrade 30018084ec99, 8675309a5c4f -> 4ffceebfada, network_rbac
INFO  [alembic.runtime.migration] Running upgrade 4ffceebfada -> 5498d17be016, Drop legacy OVS and LB plugin
 tables
INFO  [alembic.runtime.migration] Running upgrade 5498d17be016 -> 2a16083502f3, Metaplugin removal
INFO  [alembic.runtime.migration] Running upgrade 2a16083502f3 -> 2e5352a0ad4d, Add missing foreign keys
INFO  [alembic.runtime.migration] Running upgrade 2e5352a0ad4d -> 11926bcfe72d, add geneve ml2 type driver
INFO  [alembic.runtime.migration] Running upgrade 11926bcfe72d -> 4af11ca47297, Drop cisco monolithic tables

INFO  [alembic.runtime.migration] Running upgrade 8675309a5c4f -> 45f955889773, quota_usage
INFO  [alembic.runtime.migration] Running upgrade 45f955889773 -> 26c371498592, subnetpool hash
INFO  [alembic.runtime.migration] Running upgrade 26c371498592 -> 1c844d1677f7, add order to dnsnameservers
INFO  [alembic.runtime.migration] Running upgrade 1c844d1677f7 -> 1b4c6e320f79, address scope support in sub
netpool
INFO  [alembic.runtime.migration] Running upgrade 1b4c6e320f79 -> 48153cb5f051, qos db changes
INFO  [alembic.runtime.migration] Running upgrade 48153cb5f051 -> 9859ac9c136, quota_reservations
INFO  [alembic.runtime.migration] Running upgrade 9859ac9c136 -> 34af2b5c5a59, Add dns_name to Port
  OK

MariaDB [neutron]> show tables;
+-----------------------------------------+
| Tables_in_neutron                       |
+-----------------------------------------+
| address_scopes                          |
| agents                                  |
...........................................
| vpnservices                             |
+-----------------------------------------+
155 rows in set (0.00 sec)

[root@node02 ~ 17:14:10&&52]#systemctl start neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service

[root@node02 ~ 17:14:10&&52]#systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service

===================================================================================================================================
#install Dashboard:
[root@node02 ~ 17:49:16&&59]# yum install openstack-dashboard -y
[root@node02 ~ 17:49:16&&60]# cp /etc/openstack-dashboard/local_settings{,.bak}

[root@node02 ~ 18:14:43&&61]#cat << eof > /etc/openstack-dashboard/local_settings
import os
from django.utils.translation import ugettext_lazy as _
from openstack_dashboard import exceptions
from openstack_dashboard.settings import HORIZON_CONFIG
DEBUG = False
TEMPLATE_DEBUG = DEBUG
WEBROOT = '/dashboard/'
ALLOWED_HOSTS = ['*', ]                         #修改项
OPENSTACK_API_VERSIONS = {                      #增加项
    "identity": 3,
    "volume": 2,
}
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True                         #修改项
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'user'                            #修改项
LOCAL_PATH = '/tmp'
SECRET_KEY='2482409461873a9e49fa'
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': '10.10.10.11:11211',                              #增加项
    }
}
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
OPENSTACK_HOST = "10.10.10.12"                                        #修改项
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v2.0" % OPENSTACK_HOST
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"
OPENSTACK_KEYSTONE_BACKEND = {
    'name': 'native',
    'can_edit_user': True,
    'can_edit_group': True,
    'can_edit_project': True,
    'can_edit_domain': True,
    'can_edit_role': True,
}
OPENSTACK_HYPERVISOR_FEATURES = {
    'can_set_mount_point': False,
    'can_set_password': False,
    'requires_keypair': False,
}
OPENSTACK_CINDER_FEATURES = {
    'enable_backup': False,
}
OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': True,
    'enable_quotas': True,
    'enable_ipv6': True,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': True,
    'enable_firewall': True,
    'enable_vpn': True,
    'enable_fip_topology_check': True,
    'default_ipv4_subnet_pool_label': None,
    'default_ipv6_subnet_pool_label': None,
    'profile_support': None,
    'supported_provider_types': ['*'],
    'supported_vnic_types': ['*']
}
IMAGE_CUSTOM_PROPERTY_TITLES = {
    "architecture": _("Architecture"),
    "kernel_id": _("Kernel ID"),
    "ramdisk_id": _("Ramdisk ID"),
    "image_state": _("Euca2ools state"),
    "project_id": _("Project ID"),
    "image_type": _("Image Type"),
}
IMAGE_RESERVED_CUSTOM_PROPERTIES = []
API_RESULT_LIMIT = 1000
API_RESULT_PAGE_SIZE = 20
SWIFT_FILE_TRANSFER_CHUNK_SIZE = 512 * 1024
DROPDOWN_MAX_ITEMS = 30
TIME_ZONE = "Asia/Shanghai"                         #修改项
POLICY_FILES_PATH = '/etc/openstack-dashboard'
POLICY_FILES_PATH = '/etc/openstack-dashboard'
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'null': {
            'level': 'DEBUG',
            'class': 'django.utils.log.NullHandler',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.db.backends': {
            'handlers': ['null'],
            'propagate': False,
        },
        'requests': {
            'handlers': ['null'],
            'propagate': False,
        },
        'horizon': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_dashboard': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'novaclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'cinderclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'keystoneclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'glanceclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'neutronclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'heatclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'ceilometerclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'troveclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'swiftclient': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'openstack_auth': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'nose.plugins.manager': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'django': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'iso8601': {
            'handlers': ['null'],
            'propagate': False,
        },
        'scss': {
            'handlers': ['null'],
            'propagate': False,
        },
    }
}
SECURITY_GROUP_RULES = {
    'all_tcp': {
        'name': _('All TCP'),
        'ip_protocol': 'tcp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_udp': {
        'name': _('All UDP'),
        'ip_protocol': 'udp',
        'from_port': '1',
        'to_port': '65535',
    },
    'all_icmp': {
        'name': _('All ICMP'),
        'ip_protocol': 'icmp',
        'from_port': '-1',
        'to_port': '-1',
    },
    'ssh': {
        'name': 'SSH',
        'ip_protocol': 'tcp',
        'from_port': '22',
        'to_port': '22',
    },
    'smtp': {
        'name': 'SMTP',
        'ip_protocol': 'tcp',
        'from_port': '25',
        'to_port': '25',
    },
    'dns': {
        'name': 'DNS',
        'ip_protocol': 'tcp',
        'from_port': '53',
        'to_port': '53',
    },
    'http': {
        'name': 'HTTP',
        'ip_protocol': 'tcp',
        'from_port': '80',
        'to_port': '80',
    },
    'pop3': {
        'name': 'POP3',
        'ip_protocol': 'tcp',
        'from_port': '110',
        'to_port': '110',
    },
    'imap': {
        'name': 'IMAP',
        'ip_protocol': 'tcp',
        'from_port': '143',
        'to_port': '143',
    },
    'ldap': {
        'name': 'LDAP',
        'ip_protocol': 'tcp',
        'from_port': '389',
        'to_port': '389',
    },
    'https': {
        'name': 'HTTPS',
        'ip_protocol': 'tcp',
        'from_port': '443',
        'to_port': '443',
    },
    'smtps': {
        'name': 'SMTPS',
        'ip_protocol': 'tcp',
        'from_port': '465',
        'to_port': '465',
    },
    'imaps': {
        'name': 'IMAPS',
        'ip_protocol': 'tcp',
        'from_port': '993',
        'to_port': '993',
    },
    'pop3s': {
        'name': 'POP3S',
        'ip_protocol': 'tcp',
        'from_port': '995',
        'to_port': '995',
    },
    'ms_sql': {
        'name': 'MS SQL',
        'ip_protocol': 'tcp',
        'from_port': '1433',
        'to_port': '1433',
    },
    'mysql': {
        'name': 'MYSQL',
        'ip_protocol': 'tcp',
        'from_port': '3306',
        'to_port': '3306',
    },
    'rdp': {
        'name': 'RDP',
        'ip_protocol': 'tcp',
        'from_port': '3389',
        'to_port': '3389',
    },
}
REST_API_REQUIRED_SETTINGS = ['OPENSTACK_HYPERVISOR_FEATURES']
eof

[root@node02 ~ 18:23:38&&63]#systemctl restart httpd

==================================================================================================
#Start Template service

[root@node02 ~ 07:25:25&&95]#source admin-openrc.sh

[root@node02 ~ 07:39:15&&96]#neutron net-create public --shared --provider:physical_network public --provid
er:network_type flat
Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | 8489e3af-704a-4bbb-8b89-1b9280555c56 |
| mtu                       | 0                                    |
| name                      | public                               |
| port_security_enabled     | True                                 |
| provider:network_type     | flat                                 |
| provider:physical_network | public                               |
| provider:segmentation_id  |                                      |
| router:external           | False                                |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 978d28c8f46f4c2daff556bb6b26e35c     |
+---------------------------+--------------------------------------+

[root@node02 ~ 07:41:42&&97]#neutron subnet-create public 192.168.137.0/24 --name public --allocation-pool start=192.168.137.200,end=192.168.137.254 --dns-nameserver 202.101.103.55 --gateway 192.168.137.1
Created a new subnet:
+-------------------+--------------------------------------------------------+
| Field             | Value                                                  |
+-------------------+--------------------------------------------------------+
| allocation_pools  | {"start": "192.168.137.200", "end": "192.168.137.254"} |
| cidr              | 192.168.137.0/24                                       |
| dns_nameservers   | 202.101.103.55                                         |
| enable_dhcp       | True                                                   |
| gateway_ip        | 192.168.137.1                                          |
| host_routes       |                                                        |
| id                | 9d2e27bd-e821-4dc3-8c14-0986baf58a2f                   |
| ip_version        | 4                                                      |
| ipv6_address_mode |                                                        |
| ipv6_ra_mode      |                                                        |
| name              | public                                                 |
| network_id        | 8489e3af-704a-4bbb-8b89-1b9280555c56                   |
| subnetpool_id     |                                                        |
| tenant_id         | 978d28c8f46f4c2daff556bb6b26e35c                       |
+-------------------+--------------------------------------------------------+

[root@node02 ~ 07:42:36&&99]#source demo-openrc.sh

[root@node02 ~ 07:42:39&&100]#ssh-keygen -q -N ""
Enter file in which to save the key (/root/.ssh/id_rsa):

[root@node02 ~ 07:42:50&&101]#nova keypair-add --pub-key ~/.ssh/id_rsa.pub mykey

[root@node02 ~ 07:43:03&&102]#nova keypair-list
+-------+------+-------------------------------------------------+
| Name  | Type | Fingerprint                                     |
+-------+------+-------------------------------------------------+
| mykey | ssh  | 40:91:e8:74:88:ed:5e:80:86:35:87:60:f9:61:0d:05 |
+-------+------+-------------------------------------------------+

[root@node02 ~ 20:09:06&&7]#nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
+-------------+-----------+---------+-----------+--------------+
| IP Protocol | From Port | To Port | IP Range  | Source Group |
+-------------+-----------+---------+-----------+--------------+
| icmp        | -1        | -1      | 0.0.0.0/0 |              |
+-------------+-----------+---------+-----------+--------------+

[root@node02 ~ 20:21:26&&118]#nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
+-------------+-----------+---------+-----------+--------------+
| IP Protocol | From Port | To Port | IP Range  | Source Group |
+-------------+-----------+---------+-----------+--------------+
| tcp         | 22        | 22      | 0.0.0.0/0 |              |
+-------------+-----------+---------+-----------+--------------+

[root@node02 ~ 20:25:32&&120]#nova flavor-list
+----+-----------+-----------+------+-----------+------+-------+-------------+-----------+
| ID | Name      | Memory_MB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public |
+----+-----------+-----------+------+-----------+------+-------+-------------+-----------+
| 1  | m1.tiny   | 512       | 1    | 0         |      | 1     | 1.0         | True      |
| 2  | m1.small  | 2048      | 20   | 0         |      | 1     | 1.0         | True      |
| 3  | m1.medium | 4096      | 40   | 0         |      | 2     | 1.0         | True      |
| 4  | m1.large  | 8192      | 80   | 0         |      | 4     | 1.0         | True      |
| 5  | m1.xlarge | 16384     | 160  | 0         |      | 8     | 1.0         | True      |
+----+-----------+-----------+------+-----------+------+-------+-------------+-----------+

[root@node02 ~ 20:25:49&&121]#nova image-list
+--------------------------------------+--------+--------+--------+
| ID                                   | Name   | Status | Server |
+--------------------------------------+--------+--------+--------+
| 99bb5bd7-3437-4f12-a126-6bf8f23336db | cirros | ACTIVE |        |
+--------------------------------------+--------+--------+--------+
[root@node02 ~ 20:26:07&&122]#neutron net-list
+--------------------------------------+--------+-------------------------------------------------------+
| id                                   | name   | subnets                                               |
+--------------------------------------+--------+-------------------------------------------------------+
| 8489e3af-704a-4bbb-8b89-1b9280555c56 | public | 9d2e27bd-e821-4dc3-8c14-0986baf58a2f 192.168.137.0/24 |
+--------------------------------------+--------+-------------------------------------------------------+

[root@node02 ~ 20:26:10&&123]#nova secgroup-list
+--------------------------------------+---------+------------------------+
| Id                                   | Name    | Description            |
+--------------------------------------+---------+------------------------+
| a85b5ed4-ea78-4c27-998d-6509c9a807f9 | default | Default security group |
+--------------------------------------+---------+------------------------+

[root@node02 ~ 20:26:28&&124]#nova boot --flavor m1.tiny --image cirros --nic net-id=8489e3af-704a-4bbb-8b8
9-1b9280555c56  --security-group default --key-name mykey public-instance
+--------------------------------------+-----------------------------------------------+
| Property                             | Value                                         |
+--------------------------------------+-----------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                        |
| OS-EXT-AZ:availability_zone          |                                               |
| OS-EXT-STS:power_state               | 0                                             |
| OS-EXT-STS:task_state                | scheduling                                    |
| OS-EXT-STS:vm_state                  | building                                      |
| OS-SRV-USG:launched_at               | -                                             |
| OS-SRV-USG:terminated_at             | -                                             |
| accessIPv4                           |                                               |
| accessIPv6                           |                                               |
| adminPass                            | 3QTZdm5QcDv2                                  |
| config_drive                         |                                               |
| created                              | 2016-08-28T12:27:13Z                          |
| flavor                               | m1.tiny (1)                                   |
| hostId                               |                                               |
| id                                   | 1c2db785-ae29-4f07-a5b2-14508c2edbda          |
| image                                | cirros (99bb5bd7-3437-4f12-a126-6bf8f23336db) |
| key_name                             | mykey                                         |
| locked                               | False                                         |
| metadata                             | {}                                            |
| name                                 | public-instance                               |
| os-extended-volumes:volumes_attached | []                                            |
| progress                             | 0                                             |
| security_groups                      | default                                       |
| status                               | BUILD                                         |
| tenant_id                            | a86429936d5f410eaf863ca40cd72111              |
| updated                              | 2016-08-28T12:27:14Z                          |
| user_id                              | d2d9d5fb001b4b50940e73dbcbe94aca              |
+--------------------------------------+-----------------------------------------------+

[root@node02 ~ 20:27:14&&125]#nova list
+--------------------------------------+-----------------+--------+------------+-------------+----------+
| ID                                   | Name            | Status | Task State | Power State | Networks |
+--------------------------------------+-----------------+--------+------------+-------------+----------+
| 1c2db785-ae29-4f07-a5b2-14508c2edbda | public-instance | ERROR  | -          | NOSTATE     |          |
+--------------------------------------+-----------------+--------+------------+-------------+----------+

[root@node02 ~ 20:51:40&&128]#nova show fc9e0c6d-d2a6-49f2-b8ba-99e853d3007c
+--------------------------------------+--------------------------------------------------------------------
-----------------------------------------------------------+
| Property                             | Value
                                                           |
+--------------------------------------+--------------------------------------------------------------------
-----------------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL
                                                           |
| OS-EXT-AZ:availability_zone          |
                                                           |
| OS-EXT-STS:power_state               | 0
                                                           |
| OS-EXT-STS:task_state                | -
                                                           |
| OS-EXT-STS:vm_state                  | error
                                                           |
| OS-SRV-USG:launched_at               | -
                                                           |
| OS-SRV-USG:terminated_at             | -
                                                           |
| accessIPv4                           |
                                                           |
| accessIPv6                           |
                                                           |
| config_drive                         |
                                                           |
| created                              | 2016-08-28T12:37:20Z
                                                           |
| fault                                | {"message": "No valid host was found. There are not enough hosts av
ailable.", "code": 500, "created": "2016-08-28T12:37:24Z"} |
| flavor                               | m1.tiny (1)
                                                           |
| hostId                               |
                                                           |
| id                                   | fc9e0c6d-d2a6-49f2-b8ba-99e853d3007c
                                                           |
| image                                | cirros (99bb5bd7-3437-4f12-a126-6bf8f23336db)
                                                           |
| key_name                             | mykey
                                                           |
| locked                               | False
                                                           |
| metadata                             | {}
                                                           |
| name                                 | public-instance
                                                           |
| os-extended-volumes:volumes_attached | []
                                                           |
| status                               | ERROR
                                                           |
| tenant_id                            | a86429936d5f410eaf863ca40cd72111
                                                           |
| updated                              | 2016-08-28T12:37:24Z
                                                           |
| user_id                              | d2d9d5fb001b4b50940e73dbcbe94aca
                                                           |
+--------------------------------------+--------------------------------------------------------------------
-----------------------------------------------------------+







