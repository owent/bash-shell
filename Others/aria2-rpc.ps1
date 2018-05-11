if (-Not (Test-Path "log")) {
    mkdir log
}
if (-Not (Test-Path "download")) {
    mkdir download
}
if (-Not (Test-Path "session")) {
    mkdir session
}

if (Test-Path "session/aria2.session") {
    aria2c --conf-path=aria2.conf --daemon --input-file=session/aria2.session
}
else {
    aria2c --conf-path=aria2.conf --daemon
}

# aria2c --conf-path=aria2.conf;

# client
# https://github.com/ziahamza/webui-aria2
#   https://ziahamza.github.io/webui-aria2/
# https://github.com/mayswind/AriaNg
#   http://ariang.mayswind.net
