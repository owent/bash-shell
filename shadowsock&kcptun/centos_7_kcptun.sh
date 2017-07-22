#!/bin/bash

# @see https://github.com/xtaci/kcptun ;

KCPTUN_HOME=/home/kcptun ;
KCPTUN_SYSTEMD=/usr/lib/systemd/system/kcptun.service ;
KCPTUN_URL=https://github.com/xtaci/kcptun/releases/download/v20170525/kcptun-linux-amd64-20170525.tar.gz ;
KCPTUN_PORTS=(8350 8351 8352) ;
KCPTUN_PORT_OFF=1000 ;
KCPTUN_SS_LOCAL=127.0.0.1 ;

mkdir -p "$KCPTUN_HOME/log";
wget "$KCPTUN_URL" -O "$KCPTUN_HOME/kcptun-linux-amd64.tar.gz" ;

tar -axvf "$KCPTUN_HOME/kcptun-linux-amd64.tar.gz" -C "$KCPTUN_HOME" ;

function gen_kcptun_port() {
    KCPTUN_PORT=$1;
    let LOCAL_PORT=$KCPTUN_PORT+$KCPTUN_PORT_OFF;
    echo "[Unit]
Description=kcptun-$KCPTUN_PORTS services
After=syslog.target network.target

[Service]
Type=simple
ExecStart=$KCPTUN_HOME/server_linux_amd64 -l :$KCPTUN_PORT -t $KCPTUN_SS_LOCAL:$LOCAL_PORT --crypt none --mtu 1350 --nocomp --mode fast --dscp 46 --log $KCPTUN_HOME/log/kcptun-$KCPTUN_PORTS.log
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
Restart=on-failure
SuccessExitStatus=SIGTERM

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/kcptun-$KCPTUN_PORT.service ;

    systemctl enable kcptun-$KCPTUN_PORT ;
    systemctl start kcptun-$KCPTUN_PORT ;

    firewall-cmd --permanent --add-port=$KCPTUN_PORT/tcp ;
    firewall-cmd --permanent --add-port=$KCPTUN_PORT/udp ;
    firewall-cmd --reload ;

    if [ -e "/usr/lib/firewalld/services" ] && [ ! -e "/usr/lib/firewalld/services/kcptun-$KCPTUN_PORT.xml" ]; then
        echo "setup firewalld";
        sudo echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <service>
    <short>kcptun-$KCPTUN_PORT</short>
    <description>kcptun-$KCPTUN_PORT</description>
    <port protocol=\"tcp\" port=\"$KCPTUN_PORT\"/>
    <port protocol=\"udp\" port=\"$KCPTUN_PORT\"/>
    </service>" > "/usr/lib/firewalld/services/kcptun-$KCPTUN_PORT.xml" ;
        sudo firewall-cmd --permanent --add-service=kcptun-$KCPTUN_PORT ;
        sudo firewall-cmd --reload ;
    fi
}

for PORT in ${KCPTUN_PORTS[@]}; do
    gen_kcptun_port $PORT;
done