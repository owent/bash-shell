#!/bin/bash

# All available environments
# PREFIX
# MAXFD
# USER
# VERSION
# LIBSODIUM_VERSION
# PYTHON_BIN

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local/shadowsocksr";
fi
if [ -z "$MAXFD" ]; then
    MAXFD=$(ulimit -n);
fi
if [ -z "$MAXFD" ]; then
    MAXFD=32768;
fi
if [ -z "$USER" ]; then
    USER="shadowsocksr";
fi
if [ -z "$VERSION" ]; then
    VERSION="3.2.1";
fi
if [ -z "$LIBSODIUM_VERSION" ]; then
    LIBSODIUM_VERSION="1.0.16";
fi
DOWN_URL="https://github.com/shadowsocksrr/shadowsocksr/archive/$VERSION.tar.gz"
LIBSODIUM_URL="https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VERSION.tar.gz";
SSR_HOME_DIR=ssr;

which yum > /dev/null 2>&1;
if [ 0 -eq $? ]; then
    sudo yum install -y gcc autoconf libtool automake make zlib-devel openssl-devel python wget;
else
    which apt;
    which apt > /dev/null 2>&1;
    if [ 0 -eq $? ]; then
        sudo apt install -y --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev python wget;
    fi
fi

if [ ! -e "$PREFIX/libsodium-$LIBSODIUM_VERSION" ]; then
    if [ ! -e "libsodium-$LIBSODIUM_VERSION.tar.gz" ]; then
        wget -c "$LIBSODIUM_URL";
    fi
    tar -axvf libsodium-$LIBSODIUM_VERSION.tar.gz;
    $(cd libsodium-$LIBSODIUM_VERSION && ./autogen.sh && ./configure --prefix=$PREFIX/libsodium-$LIBSODIUM_VERSION && make install -j4);
    echo "$PREFIX/libsodium-$LIBSODIUM_VERSION/lib" > /etc/ld.so.conf.d/libsodium.conf;
    ldconfig;
fi


PYTHON_BIN=$(which python);
if [ -z "$PYTHON_BIN" ]; then
    echo ""python not found;
    exit 1;
fi

# backup configure files
if [ -e "$PREFIX/$SSR_HOME_DIR/userapiconfig.py" ]; then
    cp -f "$PREFIX/userapiconfig.py" userapiconfig.py;
fi

if [ -e "$PREFIX/$SSR_HOME_DIR/mudb.json" ]; then
    cp -f "$PREFIX/mudb.json" mudb.json;
fi

if [ -e "$PREFIX/$SSR_HOME_DIR/user-config.json" ]; then
    cp -f "$PREFIX/$SSR_HOME_DIR/user-config.json" user-config.json;
fi

if [ -e "shadowsocksr-$VERSION" ]; then
    rm -rf "shadowsocksr-$VERSION";
fi

if [ ! -e "shadowsocksr-$VERSION.tar.gz" ]; then
    wget "$DOWN_URL" -O "shadowsocksr-$VERSION.tar.gz" --no-check-certificate;
fi

tar -xvf "shadowsocksr-$VERSION.tar.gz";

mkdir -p "$PREFIX/log";

if [ -e "$PREFIX/$SSR_HOME_DIR" ]; then
    rm -rf "$PREFIX/$SSR_HOME_DIR";
fi
cp -rf "shadowsocksr-$VERSION" "$PREFIX/$SSR_HOME_DIR";
cd "shadowsocksr-$VERSION";

chmod +x *;
./initcfg.sh;

# restore configure
if [ -e userapiconfig.py ]; then
    mv -f userapiconfig.py "$PREFIX/$SSR_HOME_DIR/userapiconfig.py";
fi

if [ -e mudb.json ]; then
    mv -f mudb.json "$PREFIX/$SSR_HOME_DIR/mudb.json";
fi

if [ -e user-config.json ]; then
    mv -f user-config.json "$PREFIX/$SSR_HOME_DIR/user-config.json";
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
User=$USER
Group=$USER
LimitNOFILE=$MAXFD
ExecStart=$PYTHON_BIN $PREFIX/$SSR_HOME_DIR/server.py m > /dev/null 2>&1
ExecStop=/bin/kill -s QUIT
PrivateTmp=true
Restart=on-failure
RestartPreventExitStatus=SIGTERM

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
    sudo systemctl daemon-reload ;
    sudo systemctl enable shadowsocksr ;
    sudo systemctl restart shadowsocksr ;
fi

FIREWALLD_CONF_FILE_PATH=/etc/firewalld/services/shadowsocksr.xml;
if [ -e "/etc/firewalld/services" ] && [ ! -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo "setup firewalld";
    sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>shadowsocksr</short>
  <description>shadowsocksr</description>
  <port protocol="tcp" port="8388"/>
  <port protocol="udp" port="8388"/>
</service>' > "$FIREWALLD_CONF_FILE_PATH" ;
    sudo firewall-cmd --reload ;
    sudo firewall-cmd --permanent --add-service shadowsocksr ;
    sudo firewall-cmd --reload ;
fi

echo "All configure done.";
echo "Please edit $PREFIX/$SSR_HOME_DIR/userapiconfig.py and set API_INTERFACE = 'mudbjson', SERVER_PUB_ADDR = 'your ip address'";
echo "You can edit $PREFIX/$SSR_HOME_DIR/mudb.json to set multi-user configure or using mujson_mgr.py";
if [ -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo "firewalld configured at $FIREWALLD_CONF_FILE_PATH, please run firewall-cmd --reload after edit it";
fi
if [ -e "/usr/lib/systemd/system/shadowsocksr.service" ]; then
    echo "systemd configured at /usr/lib/systemd/system/shadowsocksr.service, please run systemctl daemon-reload or systemctl disable/enable/restart shadowsocksr after edit it";
fi
echo "Example:";
echo "  $PYTHON_BIN mujson_mgr.py -a -m chacha20-ietf-poly1305 -O auth_sha1_v4 -o tls1.2_ticket_auth -p 8351 -k YOURPASSWORD";
if [ -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo '  sed -i "/<\\/service>/i <port protocol=\"tcp\" port=\"8351\"/>' $FIREWALLD_CONF_FILE_PATH;
fi
