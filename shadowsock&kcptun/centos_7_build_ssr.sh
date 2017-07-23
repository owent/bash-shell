#!/bin/bash

which yum;

PREFIX="/usr/local/shadowsocksr";
MAXFD=32768;
USER=shadowsocksr;
VERSION="3.1.2";
DOWN_URL="https://github.com/shadowsocksr/shadowsocksr/archive/$VERSION.tar.gz"

if [ 0 -eq $? ]; then
    sudo yum install -y gcc autoconf libtool automake make zlib-devel openssl-devel python wget;
else
    which apt;
    if [ 0 -eq $? ]; then
        sudo apt install -y --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev python wget;
    fi
fi

# backup configure files
if [ -e "$PREFIX/src/userapiconfig.py" ]; then
    cp -f "$PREFIX/userapiconfig.py" userapiconfig.py;
fi

if [ -e "$PREFIX/src/mudb.json" ]; then
    cp -f "$PREFIX/mudb.json" mudb.json;
fi

if [ -e "$PREFIX/src/user-config.json" ]; then
    cp -f "$PREFIX/src/user-config.json" user-config.json;
fi

if [ -e "shadowsocksr-$VERSION" ]; then
    rm -rf "shadowsocksr-$VERSION";
fi

if [ ! -e "shadowsocksr-$VERSION.tar.gz" ]; then
    wget "$DOWN_URL" -O "shadowsocksr-$VERSION.tar.gz" --no-check-certificate;
fi

tar -xvf "shadowsocksr-$VERSION.tar.gz";

mkdir -p "$PREFIX/log";

if [ -e "$PREFIX/src" ]; then
    rm -rf "$PREFIX/src";
fi
cp -rf "shadowsocksr-$VERSION" "$PREFIX/src";
cd "shadowsocksr-$VERSION";

./initcfg.sh

# restore configure
if [ -e userapiconfig.py ]; then
    mv -f userapiconfig.py "$PREFIX/src/userapiconfig.py";
fi

if [ -e mudb.json ]; then
    mv -f mudb.json "$PREFIX/src/mudb.json";
fi

if [ -e user-config.json ]; then
    mv -f user-config.json "$PREFIX/src/user-config.json";
fi

# add systemd
echo "#  This file is part of shadowsocksr.
#
#  shadowsocksr is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This file is default for Debian packaging. See also
#  /etc/default/shadowsocksr for environment variables.

[Unit]
Description=shadowsocksr Default Server Service
Documentation=man:shadowsocksr(8)
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/default/shadowsocksr
User=$USER
Group=$USER
LimitNOFILE=$MAXFD
ExecStart=/usr/bin/python $PREFIX/src/server.py m > /dev/null 2>&1


[Install]
WantedBy=multi-user.target
" > shadowsocksr.service;

# add user
cat /etc/passwd | grep $USER ;
if [ 0 -ne $? ]; then
    sudo useradd $USER -M -s /sbin/nologin ;
fi
chown $USER:$USER -R "$PREFIX";

# systemd and firewall
if [ -e "/usr/lib/systemd/system" ] && [ ! -e "/usr/lib/systemd/system/shadowsocksr.service" ]; then
    sudo cp shadowsocksr.service "/usr/lib/systemd/system/shadowsocksr.service" -f;
    systemctl enable shadowsocksr ;
    systemctl restart shadowsocksr ;
fi

if [ -e "/usr/lib/firewalld/services" ] && [ ! -e "/usr/lib/firewalld/services/shadowsocksr.xml" ]; then
    echo "setup firewalld";
    sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>shadowsocksr</short>
  <description>shadowsocksr.</description>
  <port protocol="tcp" port="8388"/>
  <port protocol="udp" port="8388"/>
</service>' > "/usr/lib/firewalld/services/shadowsocksr.xml" ;
    sudo firewall-cmd --permanent --add-service=shadowsocksr ;
    sudo firewall-cmd --reload ;
fi

echo "All configure done.";
echo "Please edit $PREFIX/userapiconfig.py and set API_INTERFACE = 'mudbjson', SERVER_PUB_ADDR = 'your ip address'";
echo "You can edit $PREFIX/mudb.json to set multi-user configure or using mujson_mgr.py";
echo "firewalld configure can be found here /usr/lib/firewalld/services/shadowsocksr.xml, please run firewall-cmd --reload after edit it";
echo "systemd configure can be found here /usr/lib/systemd/system/shadowsocksr.service, please run systemctl disable/enable/restart shadowsocksr after edit it";