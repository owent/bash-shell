#!/bin/bash

SYSCTL_CONF=/etc/sysctl.conf ;

sed -i "/net.core.default_qdisc/d" "$SYSCTL_CONF";
sed -i "/net.ipv4.tcp_congestion_control/d" "$SYSCTL_CONF";

echo "net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr" >> "$SYSCTL_CONF";

# cat /proc/sys/net/ipv4/tcp_congestion_control
# cat cat /proc/sys/net/core/default_qdisc