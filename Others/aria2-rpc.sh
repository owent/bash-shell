#!/bin/bash

echo "Try loading environment ARIA2_HOME,ARIA2_BIN,ARIA2_CONF ...";

if [ -z "$ARIA2_HOME" ]; then
    export ARIA2_HOME="$(dirname $0)";
fi

if [ -z "$ARIA2_BIN" ]; then
    export ARIA2_BIN="aria2c";
fi

if [ -z "$ARIA2_CONF" ]; then
    if [ -e "$ARIA2_HOME/etc/aria2.conf" ]; then
        export ARIA2_CONF="$ARIA2_HOME/etc/aria2.conf";
    elif [ -e "$ARIA2_HOME/conf/aria2.conf" ]; then
        export ARIA2_CONF="$ARIA2_HOME/conf/aria2.conf";
    else
        export ARIA2_CONF="$ARIA2_HOME/aria2.conf";
    fi
fi

if [ ! -e "$ARIA2_CONF" ]; then
    echo "aria2 configure file $ARIA2_CONF not found.";
    exit 1;
fi

mkdir -p "$ARIA2_HOME/log";
mkdir -p "$ARIA2_HOME/download";
mkdir -p "$ARIA2_HOME/session";

# client
# https://github.com/ziahamza/webui-aria2
#   https://ziahamza.github.io/webui-aria2/
# https://github.com/mayswind/AriaNg
#   http://ariang.mayswind.net

echo "Clients:";
echo "    WebUI-Aria2: https://ziahamza.github.io/webui-aria2/";
echo "    AriaNg:      http://ariang.mayswind.net/";

if [ -e "$ARIA2_HOME/session/aria2.session" ]; then
    echo "Run: $ARIA2_BIN --conf-path=$ARIA2_CONF --daemon --input-file=$ARIA2_HOME/session/aria2.session;";
    chmod +x "$ARIA2_BIN";
    $ARIA2_BIN --conf-path=$ARIA2_CONF --daemon --input-file=$ARIA2_HOME/session/aria2.session;
else
    echo "Run: $ARIA2_BIN --conf-path=$ARIA2_CONF --daemon;";
    chmod +x "$ARIA2_BIN";
    $ARIA2_BIN --conf-path=$ARIA2_CONF --daemon;
fi
