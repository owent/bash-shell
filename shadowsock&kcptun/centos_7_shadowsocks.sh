#!/bin/bash

# @see https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/ ;

SHADOWSOCKS_PORT=8380 ;
SHADOWSOCKS_CONF=/etc/shadowsocks-libev/config.json ;

wget https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo -O /etc/yum.repos.d/librehat-shadowsocks-epel-7.repo ;

yum install shadowsocks-libev ;

systemctl enable shadowsocks-libev ;
systemctl start shadowsocks-libev ;

sed -i "/\"server\"\\s*:\\s*.*/d" "$SHADOWSOCKS_CONF";
sed -i "s/\"server_port\"\\s*:\\s*[0-9]*/\"server_port\":$SHADOWSOCKS_PORT/" "$SHADOWSOCKS_CONF";

firewall-cmd --permanent --add-port=$SHADOWSOCKS_PORT/tcp ;
firewall-cmd --permanent --add-port=$SHADOWSOCKS_PORT/udp ;
firewall-cmd --reload ;

echo "please edit $SHADOWSOCKS_CONF and then run systemctl restart shadowsocks-libev";