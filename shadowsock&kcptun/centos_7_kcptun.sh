#!/bin/bash

# @see https://github.com/xtaci/kcptun ;

KCPTUN_HOME=/home/kcptun ;
KCPTUN_SYSTEMD=/usr/lib/systemd/system/kcptun.service ;
KCPTUN_URL=https://github.com/xtaci/kcptun/releases/download/v20161207/kcptun-linux-amd64-20161207.tar.gz ;
KCPTUN_PORT=8381 ;
KCPTUN_SS_LOCAL=127.0.0.1:8380 ;

mkdir -p "$KCPTUN_HOME/log";
wget "$KCPTUN_URL" -O "$KCPTUN_HOME/kcptun-linux-amd64.tar.gz" ;

tar -axvf "$KCPTUN_HOME/kcptun-linux-amd64.tar.gz" -C "$KCPTUN_HOME" ;

echo "[Unit]
Description=kcptun services
After=syslog.target network.target

[Service]
Type=simple
ExecStart=$KCPTUN_HOME/server_linux_amd64 -l :$KCPTUN_PORT -t $KCPTUN_SS_LOCAL --crypt none --mtu 1350 --nocomp --mode fast --dscp 46 --log $KCPTUN_HOME/log/kcptun.log
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
Restart=on-failure
SuccessExitStatus=SIGTERM

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/kcptun.service ;

systemctl enable kcptun ;
systemctl start kcptun ;

firewall-cmd --permanent --add-port=$KCPTUN_PORT/tcp ;
firewall-cmd --permanent --add-port=$KCPTUN_PORT/udp ;
firewall-cmd --reload ;