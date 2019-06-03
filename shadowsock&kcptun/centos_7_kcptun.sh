#!/bin/bash

# @see https://github.com/xtaci/kcptun ;

if [ -z "$KCPTUN_VERSION" ]; then
      KCPTUN_VERSION=20171201;
fi
KCPTUN_HOME=/home/kcptun ;
KCPTUN_SYSTEMD=/usr/lib/systemd/system/kcptun.service ;
KCPTUN_URL=https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz ;
KCPTUN_PORTS=($@) ;
KCPTUN_PORT_OFF=200 ;
KCPTUN_OPTIONS="--crypt none --mtu 1350 --nocomp --mode fast --dscp 46";
KCPTUN_SS_LOCAL=127.0.0.1 ;

mkdir -p "$KCPTUN_HOME/log";

FILENAME="$(basename $KCPTUN_URL)";

if [ ! -e "$KCPTUN_HOME/$FILENAME" ]; then
    wget "$KCPTUN_URL" -O "$KCPTUN_HOME/$FILENAME" ;
fi

tar -xvf "$KCPTUN_HOME/$FILENAME" -C "$KCPTUN_HOME" ;

function gen_kcptun_port() {
    KCPTUN_PORT=$1;
    let LOCAL_PORT=$KCPTUN_PORT+$KCPTUN_PORT_OFF;
    if [ -e "/usr/lib/systemd/system" ]; then
        echo "[Unit]
Description=kcptun-$KCPTUN_PORTS services
After=syslog.target network.target

[Service]
Type=simple
ExecStart=$KCPTUN_HOME/server_linux_amd64 -l :$LOCAL_PORT -t $KCPTUN_SS_LOCAL:$KCPTUN_PORT $KCPTUN_OPTIONS --log $KCPTUN_HOME/log/kcptun-$KCPTUN_PORTS.log
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
Restart=on-failure
SuccessExitStatus=SIGTERM

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/kcptun-$KCPTUN_PORT.service ;
        sudo sudo systemctl daemon-reload ;
        sudo systemctl enable kcptun-$KCPTUN_PORT ;
        sudo systemctl start kcptun-$KCPTUN_PORT ;
        echo "systemd configured at /usr/lib/systemd/system/kcptun-$KCPTUN_PORT.service, please run systemctl daemon-reload or systemctl disable/enable/restart kcptun-$KCPTUN_PORT after edit it";
    fi

    if [ -e "/etc/firewalld/services" ] && [ ! -e "/etc/firewalld/services/kcptun-$KCPTUN_PORT.xml" ]; then
        echo "setup firewalld";
        sudo echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<service>
    <short>kcptun-$KCPTUN_PORT</short>
    <description>kcptun-$KCPTUN_PORT</description>
    <port protocol=\"tcp\" port=\"$LOCAL_PORT\"/>
    <port protocol=\"udp\" port=\"$LOCAL_PORT\"/>
</service>" > "/etc/firewalld/services/kcptun-$KCPTUN_PORT.xml" ;
        sudo firewall-cmd --reload ;
        sudo firewall-cmd --permanent --add-service "kcptun-$KCPTUN_PORT" ;
        sudo firewall-cmd --reload ;
    fi

    if [ -e "/etc/firewalld/services/kcptun-$KCPTUN_PORT.xml" ]; then
        echo "firewalld configured at /etc/firewalld/services/kcptun-$KCPTUN_PORT.xml, please run firewall-cmd --reload after edit it";
    fi
}

for PORT in ${KCPTUN_PORTS[@]}; do
    gen_kcptun_port $PORT;
done
