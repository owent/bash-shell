mkdir -p log;
mkdir -p download;
mkdir -p session;
if [ -e "session/aria2.session" ]; then
    aria2c --conf-path=aria2.conf --daemon --input-file=session/aria2.session;
else
    aria2c --conf-path=aria2.conf --daemon;
fi
# aria2c --conf-path=aria2.conf;

# client
# https://github.com/ziahamza/webui-aria2
#   https://ziahamza.github.io/webui-aria2/
# https://github.com/mayswind/AriaNg
#   http://ariang.mayswind.net