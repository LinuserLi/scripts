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
admin_token = yqFpg853RDm7b8NXygngeK2VT8Y=
verbose = true
[assignment]
[auth]
[cache]
[catalog]
[cors]
[cors.subdomain]
[credential]
[database]
connection = mysql://keystone:CeI8J9zWJduxuw8+D6gn6QNXgR4=@10.10.10.11/keystone
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
No handlers could be found for logger "oslo_config.cfg"

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
| consumer               |
| credential             |
| domain                 |
| endpoint               |
| endpoint_group         |
| federation_protocol    |
| group                  |
| id_mapping             |
| identity_provider      |
| idp_remote_ids         |
| mapping                |
| migrate_version        |
| policy                 |
| policy_association     |
| project                |
| project_endpoint       |
| project_endpoint_group |
| region                 |
| request_token          |
| revocation_event       |
| role                   |
| sensitive_config       |
| service                |
| service_provider       |
| token                  |
| trust                  |
| trust_role             |
| user                   |
| user_group_membership  |
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

systemctl start httpd.service && systemctl restart httpd.service

[root@node02 ~ 08:58:56&&17]#ss -lntp |egrep httpd
LISTEN     0      128         :::80                      :::*                   users:(("httpd",pid=5604,fd=4),("httpd",pid=5603,fd=4),("httpd",pid=5602,fd=4),("httpd
",pid=5601,fd=4),("httpd",pid=5600,fd=4),("httpd",pid=5589,fd=4))
LISTEN     0      128         :::35357                   :::*                   users:(("httpd",pid=5604,fd=8),("httpd",pid=5603,fd=8),("httpd",pid=5602,fd=8),("httpd
",pid=5601,fd=8),("httpd",pid=5600,fd=8),("httpd",pid=5589,fd=8))
LISTEN     0      128         :::5000                    :::*                   users:(("httpd",pid=5604,fd=6),("httpd",pid=5603,fd=6),("httpd",pid=5602,fd=6),("httpd
",pid=5601,fd=6),("httpd",pid=5600,fd=6),("httpd",pid=5589,fd=6))


[root@node02 ~ 09:05:13&&32]#export OS_TOKEN=yqFpg853RDm7b8NXygngeK2VT8Y=
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





























