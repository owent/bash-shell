#!/bin/bash

if [ -z "$DISTCCD_PREFIX" ]; then
    DISTCCD_PREFIX="/data/prebuilt/distcc-3.3.2";
fi

if [ -z "$DISTCCD_PORT" ]; then
    DISTCCD_PORT=6371;
fi

if [ -z "$DISTCCD_HOST" ]; then
    DISTCCD_HOST=();
else
    DISTCCD_HOST=($(echo "$DISTCCD_HOST" | awk -F "[[:blank:],;]" '{$1=$1; print $0}'));
fi

if [ -z "$DISTCCD_PIDFILE" ]; then
    DISTCCD_PIDFILE="$DISTCCD_PREFIX/run/distccd.pid";
fi

# DISTCCD_USER = distcc
# 

DISTCCD_HOST_STR="";

for HOST in ${DISTCCD_HOST[@]}; do
    DISTCCD_HOST_STR="$DISTCCD_HOST_STR -a $HOST";
done


if [ ! -z "$DISTCCD_USER" ]; then
    DISTCCD_USER="--user $DISTCCD_USER";
fi

TEMPLATE_CONTENT="$(cat $(dirname $0)/distccd.service.tmpl)";

# TEMPLATE_CONTENT="$(echo "$TEMPLATE_CONTENT" | perl -p -e "s;\\%DISTCCD_PREFIX\\%;$DISTCCD_PREFIX;g")";
# echo "$TEMPLATE_CONTENT"

echo "$TEMPLATE_CONTENT" | perl -p -e "s;\\%DISTCCD_PREFIX\\%;$DISTCCD_PREFIX;g"    | 
    perl -p -e "s;\\%DISTCCD_PORT\\%;$DISTCCD_PORT;g"                               | 
    perl -p -e "s;\\%DISTCCD_HOST_STR\\%;$DISTCCD_HOST_STR;g"                       |
    perl -p -e "s;\\%DISTCCD_USER\\%;$DISTCCD_USER;g"                               |
    perl -p -e "s;\\%DISTCCD_PIDFILE\\%;$DISTCCD_PIDFILE;g"
