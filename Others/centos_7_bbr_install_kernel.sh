#!/bin/bash

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org ;

rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm ;

yum --enablerepo=elrepo-kernel install -y kernel-ml ;

yum remove -y kernel-headers kernel-tools kernel-tools-libs ;

yum --enablerepo=elrepo-kernel install -y kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs ;

# 装回gcc
yum install -y gcc gcc-c++ libtool ;

# 确认一遍启动顺序
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg ;
grub2-set-default 0 ;

echo "now, you can reboot to enable kernel 4.9.0";