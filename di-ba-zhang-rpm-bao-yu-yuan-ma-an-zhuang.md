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

卸载包，注：只需要包名，无需版本号那些：

```bash
[root@centos ~]# rpm -evh vim-common
Preparing...                          ################################# [100%]
Cleaning up / removing...
   1:vim-common-2:7.4.160-2.el7       ################################# [100%]
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

查看包的描述信息：

```bash
[root@centos ~]# rpm -qpi vim-common-7.4.160-2.el7.x86_64.rpm
Name        : vim-common
Epoch       : 2
Version     : 7.4.160
Release     : 2.el7
Architecture: x86_64
Install Date: (not installed)
Group       : Applications/Editors
Size        : 22146173
License     : Vim
Signature   : RSA/SHA256, Thu 10 Aug 2017 04:15:28 PM EDT, Key ID 24c6a8a7f4a80eb5
Source RPM  : vim-7.4.160-2.el7.src.rpm
Build Date  : Tue 01 Aug 2017 08:46:12 PM EDT
Build Host  : c1bm.rdu2.centos.org
Relocations : (not relocatable)
Packager    : CentOS BuildSystem <http://bugs.centos.org>
Vendor      : CentOS
URL         : http://www.vim.org/
Summary     : The common files needed by any version of the VIM editor
Description :
VIM (VIsual editor iMproved) is an updated and improved version of the
vi editor.  Vi was the first real screen-based editor for UNIX, and is
still very popular.  VIM improves on vi by adding new features:
multiple windows, multi-level undo, block highlighting and more.  The
vim-common package contains files which every VIM binary will need in
order to run.
If you are installing vim-enhanced or vim-X11, you'll also need
to install the vim-common package.
```

查看包的依赖关系：

```bash
[root@centos ~]# rpm -qpR vim-common-7.4.160-2.el7.x86_64.rpm
/bin/sh
config(vim-common) = 2:7.4.160-2.el7
libc.so.6()(64bit)
libc.so.6(GLIBC_2.2.5)(64bit)
libc.so.6(GLIBC_2.3)(64bit)
libc.so.6(GLIBC_2.3.4)(64bit)
rpmlib(CompressedFileNames) <= 3.0.4-1
rpmlib(FileDigests) <= 4.6.0-1
rpmlib(PayloadFilesHavePrefix) <= 4.0-1
rtld(GNU_HASH)
vim-filesystem
rpmlib(PayloadIsXz) <= 5.2-1
```



**第二种方式：yum**

yum 是专用于线安装，直接解决包的依赖关系， 在fedore 上已经变更为 dnf ，在red-hat 上是需要授权才可以使用yum 在线安装的。它的配置文件：/etc/yum.conf

**使用格式：【yum 参数 命令 包名】：常用参数和命令：**

**命令参数：**

clean：清除源缓存数据

erase：删除包

groups：显示，使用组信息

install：安装包

list：列表

makecache：生产缓存数据

provides：根据命令查找包名

reinstall：重新安装

update：升级包

upgrade：系统级升级

**参数：**

-y：询问确认时使用，无需交互

--downloadonly：只下载，不安装

--downloaddir=DLDIR：指定下载目录，默认存放在 /var/cache/yum/x86\_64/7/base/packages/

**实例：**

安装vim 包：

```bash
[root@centos ~]# yum -y install vim
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror1.ku.ac.th
 * extras: mirror1.ku.ac.th
 * updates: mirror1.ku.ac.th
Resolving Dependencies
--> Running transaction check
---> Package vim-enhanced.x86_64 2:7.4.160-2.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

==================================================================================================================================================================================================================================================
 Package                                                      Arch                                                   Version                                                           Repository                                            Size
==================================================================================================================================================================================================================================================
Installing:
 vim-enhanced                                                 x86_64                                                 2:7.4.160-2.el7                                                   base                                                 1.0 M

Transaction Summary
==================================================================================================================================================================================================================================================
Install  1 Package

Total download size: 1.0 M
Installed size: 2.2 M
Downloading packages:
vim-enhanced-7.4.160-2.el7.x86_64.rpm                                                                                                                                                                                      | 1.0 MB  00:00:01
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : 2:vim-enhanced-7.4.160-2.el7.x86_64                                                                                                                                                                                            1/1
  Verifying  : 2:vim-enhanced-7.4.160-2.el7.x86_64                                                                                                                                                                                            1/1

Installed:
  vim-enhanced.x86_64 2:7.4.160-2.el7

Complete!
```

卸载vim 包：

```bash
[root@centos ~]# yum -y erase vim
Loaded plugins: fastestmirror
Resolving Dependencies
--> Running transaction check
---> Package vim-enhanced.x86_64 2:7.4.160-2.el7 will be erased
--> Finished Dependency Resolution

Dependencies Resolved

==================================================================================================================================================================================================================================================
 Package                                                      Arch                                                   Version                                                          Repository                                             Size
==================================================================================================================================================================================================================================================
Removing:
 vim-enhanced                                                 x86_64                                                 2:7.4.160-2.el7                                                  @base                                                 2.2 M

Transaction Summary
==================================================================================================================================================================================================================================================
Remove  1 Package

Installed size: 2.2 M
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Erasing    : 2:vim-enhanced-7.4.160-2.el7.x86_64                                                                                                                                                                                            1/1
  Verifying  : 2:vim-enhanced-7.4.160-2.el7.x86_64                                                                                                                                                                                            1/1

Removed:
  vim-enhanced.x86_64 2:7.4.160-2.el7

Complete!
```

根据命令查找包名：

```bash
[root@centos ~]# yum provides vim
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror1.ku.ac.th
 * extras: mirror1.ku.ac.th
 * updates: mirror1.ku.ac.th
2:vim-enhanced-7.4.160-2.el7.x86_64 : A version of the VIM editor which includes recent enhancements
Repo        : base
Matched from:
Provides    : vim = 7.4.160-2.el7
```



**第三种方式：源码或者二进制包**

源码包：顾名思义就是使用源代码写好的文件，只是经过测试安装后就将源代码打包发布的一种软件包。因为大部分包都是用C 语言写的，所以，我们需要有 c 语言编译环境，即系统必须要安装 gcc gcc-c++ make 这三个包。这种软件包的特点就是：发布软件的同时发布了源代码，你可以自行修改，但不允许用于商业应用。它的优点是：安装灵活，可以自由选择要安装的组件，指定安装路径，易卸载（只需要删除安装目录即可）；缺点就是：需要有Linux 基础支持，懂源码编译流程，耗时！

