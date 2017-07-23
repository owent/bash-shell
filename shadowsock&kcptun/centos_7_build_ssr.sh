#!/bin/bash

which yum;

PREFIX="/usr/local/shadowsocksr-libev";
MAXFD=32768;
USER=shadowsocksr;
VERSION="2.4.1";
DOWN_URL="https://github.com/shadowsocksr/shadowsocksr-libev/archive/$VERSION.tar.gz"

if [ 0 -eq $? ]; then
    sudo yum install -y gcc autoconf libtool automake make zlib-devel openssl-devel asciidoc xmlto wget;
else
    which apt;
    if [ 0 -eq $? ]; then
        sudo apt install -y --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev asciidoc xmlto wget;
    fi
fi

if [ -e "shadowsocksr-libev-$VERSION" ]; then
    rm -rf "shadowsocksr-libev-$VERSION";
fi

if [ ! -e "shadowsocksr-libev-$VERSION.tar.gz" ]; then
    wget "$DOWN_URL" -O "shadowsocksr-libev-$VERSION.tar.gz" --no-check-certificate;
fi

tar -xvf "shadowsocksr-libev-$VERSION.tar.gz";

cd "shadowsocksr-libev-$VERSION";

./autogen.sh ;
./configure  --prefix="$PREFIX" && make;

exit 0;

sudo make install;

cd .. ;

# add systemd
echo "#  This file is part of Shadowsocksr-libev.
#
#  Shadowsocksr-libev is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This file is default for Debian packaging. See also
#  /etc/default/Shadowsocksr-libev for environment variables.

[Unit]
Description=Shadowsocksr-libev Default Server Service
Documentation=man:Shadowsocksr-libev(8)
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/default/shadowsocksr-libev
User=$USER
Group=$USER
LimitNOFILE=$MAXFD
ExecStart=$PREFIX/bin/ss-server -c \$CONFFILE \$DAEMON_ARGS

[Install]
WantedBy=multi-user.target
" > shadowsocksr-libev.service;

if [ ! -e /etc/default ]; then
    sudo mkdir -p /etc/default;
fi

# add env file
sudo echo "# Defaults for shadowsocks initscript
# sourced by /etc/init.d/shadowsocksr-libev
# installed at /etc/default/shadowsocksr-libev by the maintainer scripts

#
# This is a POSIX shell fragment
#
# Note: 'START', 'GROUP' and 'MAXFD' options are not recognized by systemd.
# Please change those settings in the corresponding systemd unit file.

# Enable during startup?
START=yes

# Configuration file
CONFFILE=\"/etc/shadowsocksr-libev/config.json\"

# Extra command line arguments
DAEMON_ARGS=\"-u\"

# User and group to run the server as
USER=$USER
GROUP=$USER

# Number of maximum file descriptors
MAXFD=$MAXFD
" > /etc/default/shadowsocksr-libev;

# add config file
if [ ! -e "/etc/shadowsocksr-libev/config.json" ]; then
    sudo mkdir -p /etc/shadowsocksr-libev ;

    sudo echo '{
    "server": "0.0.0.0",
    "server_ipv6": "[::]",
    "local_port": 1080,
    "port_password": {
        "8350": "your password of port 8350",
        "8351": "your password of port 8351",
        "8352": "your password of port 8352"
    },
    "timeout": 60,
    "udp_timeout": 60,
    "method": "chacha20",
    "obfs": "tls1.2_ticket_auth",
    "obfs_param": "baidu.com,163.com,qq.com",
    "protocol": "auth_sha1_v4",
    "protocol_param": ""
}' > /etc/shadowsocksr-libev/config.json;
fi

# add user
cat /etc/passwd | grep $USER ;
if [ 0 -ne $? ]; then
    sudo useradd $USER -M -s /sbin/nologin ;
fi
chown $USER:$USER -R "$PREFIX";

# systemd and firewall
if [ -e "/usr/lib/systemd/system" ] && [ ! -e "/usr/lib/systemd/system/shadowsocksr-libev.service" ]; then
    sudo cp shadowsocksr-libev.service "/usr/lib/systemd/system/shadowsocksr-libev.service" -f;
    systemctl enable shadowsocksr-libev ;
    systemctl restart shadowsocksr-libev ;
fi

if [ -e "/usr/lib/firewalld/services" ] && [ ! -e "/usr/lib/firewalld/services/shadowsocksr-libev.xml" ]; then
    echo "setup firewalld";
    sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>shadowsocksr-libev</short>
  <description>shadowsocksr-libev.</description>
  <port protocol="tcp" port="8350"/>
  <port protocol="udp" port="8350"/>
  <port protocol="tcp" port="8351"/>
  <port protocol="udp" port="8351"/>
  <port protocol="tcp" port="8352"/>
  <port protocol="udp" port="8352"/>
</service>' > "/usr/lib/firewalld/services/shadowsocksr-libev.xml" ;
    sudo firewall-cmd --permanent --add-service=shadowsocksr-libev ;
    sudo firewall-cmd --reload ;
fi