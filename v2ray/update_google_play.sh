#!/bin/bash

# crontab -e 
# 13 * * * * /root/update_google_play.sh > /root/update_google_play.log 2>&1

RESOLVE_IPS=($(dig services.googleapis.com | grep -e "IN\\s*AA*\\s*..*" | awk '{ print $(NF) }'));

if [ ${#RESOLVE_IPS} -gt 0 ]; then
    echo "${#RESOLVE_IPS} address detected.";
    sed -i "/services\\.googleapis\\.cn/d" /etc/hosts;
    echo "#  ============ redirect services.googleapis.cn ============" >> /etc/hosts;
    for IP in ${RESOLVE_IPS[@]}; do
        IP_PADDING=$(printf "%-48s" $IP);
        echo "$IP_PADDING services.googleapis.cn" >> /etc/hosts;
        echo "$IP_PADDING services.googleapis.cn";
    done
fi
