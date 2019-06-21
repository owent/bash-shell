#!/bin/bash

# All available environments
# PREFIX
# V2RAY_USER
# VERSION
# ARCH

export LC_ALL="zh_CN.UTF-8";
export LC_CTYPE="zh_CN.UTF-8";
export LANG="zh_CN.UTF-8";

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local/v2ray";
fi
if [ -z "$V2RAY_USER" ]; then
    V2RAY_USER="v2ray";
fi
if [ -z "$VERSION" ]; then
    VERSION="4.19.1";
fi
if [ -z "$ARCH" ]; then
    ARCH="linux-64";
fi
DOWN_URL="https://github.com/v2ray/v2ray-core/releases/download/v$VERSION/v2ray-$ARCH.zip"
HOME_DIR="v2ray-v$VERSION-$ARCH";
if [ -z "$V2RAY_PKG_NAME" ]; then
    V2RAY_PKG_NAME="$(basename $DOWN_URL)";
fi

which yum > /dev/null 2>&1;
if [ 0 -eq $? ]; then
    sudo yum install -y zlib-devel openssl openssl-devel openssl-libs wget curl vim unzip perl;
else
    which apt;
    which apt > /dev/null 2>&1;
    if [ 0 -eq $? ]; then
        sudo apt install -y --no-install-recommends openssl libssl-dev libpcre3-dev wget curl vim unzip perl;
    fi
fi

mkdir -p "$PREFIX";
cd "$PREFIX";

# download pkg
if [ ! -e "$PREFIX/$HOME_DIR" ]; then
    curl -k -L "$DOWN_URL" -o "$V2RAY_PKG_NAME";
    if [ 0 -ne $? ]; then
        rm -f "$V2RAY_PKG_NAME";
        exit 1;
    fi
    
    # unzip
    unzip -uo "$V2RAY_PKG_NAME" -d "$PREFIX/$HOME_DIR";
    if [ ! -e "$HOME_DIR" ]; then
        echo "Can not find $HOME_DIR";
        exit 1;
    fi
fi

chmod +x $PREFIX/$HOME_DIR/v2* ;

mkdir -p log;
mkdir -p etc;
mkdir -p run;

# add user
cat /etc/passwd | grep $V2RAY_USER ;
if [ 0 -ne $? ]; then
    sudo useradd $V2RAY_USER -M -s /sbin/nologin ;
fi

# setup config.json
if [ ! -e "$PREFIX/etc/config.json" ]; then
    cp -f "$PREFIX/$HOME_DIR/vpoint_vmess_freedom.json" "$PREFIX/etc/config.json";
    perl -p -i -e "s;\"access\"\\s*\\:.*;\"access\": \"$PREFIX\\/log\\/access.log\",;g" "$PREFIX/etc/config.json";
    perl -p -i -e "s;\"error\"\\s*\\:.*;\"error\": \"$PREFIX\\/log\\/error.log\",;g" "$PREFIX/etc/config.json";
fi

# chown ... 
chown $V2RAY_USER:$V2RAY_USER -R "$PREFIX";

# setup systemd
SYSTEMD_CONFIG_PATH="/usr/lib/systemd/system/v2ray.service";

# systemd and firewall
if [ -e "/usr/lib/systemd/system" ] && [ ! -e "$SYSTEMD_CONFIG_PATH" ]; then
    sudo cp -f "$PREFIX/$HOME_DIR/systemd/v2ray.service" "$SYSTEMD_CONFIG_PATH";
    sudo perl -p -i -e "s;.*User\\s*\\=.*;User=$V2RAY_USER;"  "$SYSTEMD_CONFIG_PATH";
    sudo perl -p -i -e "s;.*Group\\s*\\=.*;Group=$V2RAY_USER;" "$SYSTEMD_CONFIG_PATH";
    sudo perl -p -i -e "s;.*PIDFile\\s*\\=.*;PIDFile=$PREFIX/run/v2ray-server.pid;" "$SYSTEMD_CONFIG_PATH";
    sudo perl -p -i -e "s;.*ExecStart\\s*\\=.*;ExecStart=$PREFIX/$HOME_DIR/v2ray -config $PREFIX/etc/config.json;" "$SYSTEMD_CONFIG_PATH";

    sudo systemctl daemon-reload ;
    sudo systemctl enable v2ray ;
    sudo systemctl start v2ray ;
elif [ -e "$SYSTEMD_CONFIG_PATH" ]; then
    sudo perl -p -i -e "s;.*ExecStart\\s*\\=.*;ExecStart=$PREFIX/$HOME_DIR/v2ray -config $PREFIX/etc/config.json;" "$SYSTEMD_CONFIG_PATH";
    sudo systemctl daemon-reload ;
    sudo systemctl restart v2ray ;
fi

FIREWALLD_CONF_FILE_PATH=/etc/firewalld/services/v2ray.xml;
if [ -e "/etc/firewalld/services" ] && [ ! -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo "setup firewalld";
    sudo echo '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>v2ray</short>
  <description>v2ray</description>
</service>' > "$FIREWALLD_CONF_FILE_PATH" ;
    sudo firewall-cmd --reload ;
    sudo firewall-cmd --permanent --add-service v2ray ;
    sudo firewall-cmd --reload ;
fi

echo "All configure done.";
echo "Please edit $PREFIX/etc/config.json to change your vpoints";
if [ -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo "firewalld configured at $FIREWALLD_CONF_FILE_PATH, please run firewall-cmd --reload after edit it";
fi
if [ -e "$SYSTEMD_CONFIG_PATH" ]; then
    echo "systemd configured at $SYSTEMD_CONFIG_PATH, please run systemctl daemon-reload or systemctl disable/enable/restart v2ray after edit it";
fi
echo "Example:";
echo "  inbound.port: 10086, inbound.protocol: vmess";
if [ -e "$FIREWALLD_CONF_FILE_PATH" ]; then
    echo '  sed -i "/<\\/service>/i <port protocol=\"tcp\" port=\"10086\"/>' $FIREWALLD_CONF_FILE_PATH;
fi
