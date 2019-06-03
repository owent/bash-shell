Write-Output "Try loading environment ARIA2_HOME,ARIA2_BIN,ARIA2_CONF ...";

if ([string]::IsNullOrEmpty($Env:ARIA2_HOME)) {
    $Env:ARIA2_HOME = Split-Path $MyInvocation.MyCommand.Path
}

if ([string]::IsNullOrEmpty($Env:ARIA2_BIN)) {
    $Env:ARIA2_BIN = "aria2c"
}

if ([string]::IsNullOrEmpty($Env:ARIA2_CONF)) {
    if (Test-Path "$Env:ARIA2_HOME/etc/aria2.conf") {
        $Env:ARIA2_CONF = "$Env:ARIA2_HOME/etc/aria2.conf";
    }
    elseif (Test-Path "$Env:ARIA2_HOME/conf/aria2.conf") {
        $Env:ARIA2_CONF = "$Env:ARIA2_HOME/conf/aria2.conf";
    }
    else {
        $Env:ARIA2_CONF = "$Env:ARIA2_HOME/aria2.conf";
    }
}

if (-Not (Test-Path "$Env:ARIA2_HOME/log")) {
    mkdir "$Env:ARIA2_HOME/log"
}
if (-Not (Test-Path "$Env:ARIA2_HOME/download")) {
    mkdir "$Env:ARIA2_HOME/download"
}
if (-Not (Test-Path "$Env:ARIA2_HOME/session")) {
    mkdir "$Env:ARIA2_HOME/session"
}

# client
# https://github.com/ziahamza/webui-aria2
#   https://ziahamza.github.io/webui-aria2/
# https://github.com/mayswind/AriaNg
#   http://ariang.mayswind.net

Write-Output "Clients: "
Write-Output "    WebUI-Aria2: https://ziahamza.github.io/webui-aria2/"
Write-Output "    AriaNg:      http://ariang.mayswind.net"

if (Test-Path "$Env:ARIA2_HOME/session/aria2.session") {
    Write-Output "Run: $Env:ARIA2_BIN --conf-path=$Env:ARIA2_CONF --daemon --input-file=$Env:ARIA2_HOME/session/aria2.session"
    . $Env:ARIA2_BIN --conf-path=$Env:ARIA2_CONF --daemon --input-file=$Env:ARIA2_HOME/session/aria2.session
}
else {
    Write-Output "Run: $Env:ARIA2_BIN --conf-path=$Env:ARIA2_CONF --daemon"
    . $Env:ARIA2_BIN --conf-path=$Env:ARIA2_CONF --daemon
}
