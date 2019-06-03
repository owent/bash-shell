#!/bin/bash

yum repolist | grep "\\belrepo\\b" ;
if [ 0 -ne $? ]; then
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org ;
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm ;
fi

yum --enablerepo=elrepo-kernel install -y kernel-ml ;

yum remove -y kernel-headers kernel-tools kernel-tools-libs ;

yum --enablerepo=elrepo-kernel install -y kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs ;

# 装回gcc
yum install -y gcc gcc-c++ libtool ;

yum --enablerepo=elrepo-kernel update -y;

# 确认一遍启动顺序
awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg ;
SELECT_KERNEL_INDEXS=($(awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg | grep -n '[(]\s*[4-9]\.' | cut -d: -f 1));
if [ ${#SELECT_KERNEL_INDEXS} -gt 0 ]; then
    ((SELECT_KERNEL_INDEX=${SELECT_KERNEL_INDEXS[0]}-1));
    grub2-set-default $SELECT_KERNEL_INDEX ;
    echo "Now, you can reboot to use kernel $(awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg | grep '[(]\s*[4-9]\.' | head -n 1) ";
    echo -e "Please to rerun this script if you want to update componments in this system, or use \\033[33;1myum --enablerepo=elrepo-kernel update -y\\033[0m to update system";
else
    echo -e "\\033[31;1mError: kernel 4.X or upper not found.\\033[0m";
fi