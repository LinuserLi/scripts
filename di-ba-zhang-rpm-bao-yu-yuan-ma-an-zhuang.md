---
description: >-
  安装完系统后，要学会怎么安装软件包。Linux 命令行模式不想 GUI 模式，有包管理界面，可以直接搜索点击安装。所以，大家必须学会如何在Linux
  如何在命令模式下安装所需的软件包
---

# 第八章：rpm 包与源码安装

**第一种方式： rpm ：**

rpm 包是专用于 red-hat 系列的软件包，包名以 .rpm 结尾。 常用于服务器无法连接外网，只能讲包下载安装到服务器上，然后用这种方式安装。缺点就是：不能自动安装包的依赖

**使用格式：【rpm 参数 包名】，常用参数：**

-U ：升级包

-i：安装软件包

-h：

-v：显示安装进度

-e：卸载包

**查询相关参数：**

-q：表示查询

-a：查询效验系统所有的安装包中是否有安装要查询的包

-f：根据文件，查找所属包。注：要文件绝对路径

-l： 查询列出安装包的所有文件

**例如：这里以 vim-common-7.4.160-2.el7.x86\_64.rpm 为例：**

**说明：** vim-common：是包的名称； 7.4.160：版本号，依次为主版本号、次版本号、修订号；el7：表示这个软件包是在RHEL 7.x/CentOS 7.x 下使用； x86\_64：指使用平台，也就是64位的操作系统

升级安装包：

```bash
[root@centos packages]# rpm -Uvh vim-common-7.4.160-2.el7.x86_64.rpm vim-filesystem-7.4.160-2.el7.x86_64.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:vim-filesystem-2:7.4.160-2.el7   ################################# [ 50%]
   2:vim-common-2:7.4.160-2.el7       ################################# [100%]
```

查询vim-common 包是否有安装。注：需要写包名，可以不写版本信息那些：

```bash
[root@centos ~]# rpm -qa vim-common
vim-common-7.4.160-2.el7.x86_64
```

查询 vim 目录是属于哪个包的：

```bash
[root@centos ~]# rpm -qf /usr/share/vim
vim-common-7.4.160-2.el7.x86_64
```

列出包的安装文件：

```bash
[root@centos ~]# rpm -ql vim-common |less
/etc/vimrc
/usr/bin/xxd
/usr/share/doc/vim-common-7.4.160
/usr/share/doc/vim-common-7.4.160/Changelog.rpm
/usr/share/doc/vim-common-7.4.160/LICENSE
/usr/share/doc/vim-common-7.4.160/README.patches
......................................................
/usr/share/vim/vim74/tutor/tutor.zh_tw.utf-8
/usr/share/vim/vim74/vimrc_example.vim
/usr/share/vim/vimfiles/template.spec
```





**第二种方式：yum**

yum 是专用于在线安装，查找命令所在包的工具。但是在fedore 上已经变更为 dnf ，在red-hat 上是需要授权才可以使用yum 在线安装的

使用格式：yum 



第三种方式：源码或者二进制包

