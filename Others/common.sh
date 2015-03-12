#!/bin/sh

# 公共变量
WORKING_DIR=$PWD

# 获取当前脚本目录
function get_script_dir()
{
	echo "$( cd "$( dirname "$0" )" && pwd )";
}

# 设置本地语言
function set_local_lang()
{
	TARGET_LANG="zh_CN.UTF-8";
	if [ $# -gt 0 ]; then
		TARGET_LANG="$1";
	fi
	
	export LANG="$TARGET_LANG"
	export LC_CTYPE="$TARGET_LANG"
	export LC_NUMERIC="$TARGET_LANG"
	export LC_TIME="$TARGET_LANG"
	export LC_COLLATE="$TARGET_LANG"
	export LC_MONETARY="$TARGET_LANG"
	export LC_MESSAGES="$TARGET_LANG"
	export LC_PAPER="$TARGET_LANG"
	export LC_NAME="$TARGET_LANG"
	export LC_ADDRESS="$TARGET_LANG"
	export LC_TELEPHONE="$TARGET_LANG"
	export LC_MEASUREMENT="$TARGET_LANG"
	export LC_IDENTIFICATION="$TARGET_LANG"
	export LC_ALL="$TARGET_LANG"
	export RC_LANG="$TARGET_LANG"
	export RC_LC_CTYPE="$TARGET_LANG"
	export AUTO_DETECT_UTF8="yes"
}

# 保留指定个数的文件
function remove_more_than()
{
    filter="$1";
    number_left=$2
    
    FILE_LIST=( $(ls -dt $filter) );
    for (( i=$number_left; i<${#FILE_LIST[@]}; i++)); do
    	rm -rf "${FILE_LIST[$i]}";
    done
}

# 远程指令
function auto_scp()
{
    src="$1";
    dst="$2";
    pass="$3";
    port=""
    if [ $# -gt 3 ]; then
        port="-P $4";
    fi
    expect -c "set timeout -1;
            spawn scp -p -o StrictHostKeyChecking=no -r $port $src $dst;
            expect "*assword:*" { send $pass\r\n; };
            expect eof {exit;};
            "
}

function auto_ssh_exec()
{
    host_ip="$1";
    host_port="$2";
    host_user="$3";
    host_pwd="$4";
    cmd="$5";
    cmd="${cmd//\\/\\\\}";
    cmd="${cmd//\"/\\\"}";
    cmd="${cmd//\$/\\\$}";
    expect -c "set timeout -1;
            spawn ssh -o StrictHostKeyChecking=no ${host_user}@${host_ip} -p ${host_port} \"${cmd}\";
            expect "*assword:*" { send $host_pwd\r\n; };
            expect eof {exit;};
            "
}

# 清空Linux缓存
function free_useless_memory()
{
	CURRENT_USER_NAME=$(whoami)
	if [ "$CURRENT_USER_NAME" != "root" ]; then
		echo "Must run as root";
		exit -1;
	fi

	sync
	echo 3 > /proc/sys/vm/drop_caches
}

# 清空未被引用的用户共享内存
function remove_user_empty_ipc()
{
	CURRENT_USER_NAME=$(whoami)
	for i in $(ipcs | grep $CURRENT_USER_NAME | awk '{ if( $6 == 0 ) print $2}'); do
		ipcrm -m $i
		ipcrm -s $i
	done
}

# 清空用户共享内存
function remove_user_ipc()
{
	CURRENT_USER_NAME=$(whoami)
	for i in $(ipcs | grep $CURRENT_USER_NAME | awk '{print $2}'); do
		ipcrm -m $i
		ipcrm -s $i
	done
}

# 获取系统IPv4地址
function get_ipv4_address()
{
	ALL_IP_ADDRESS=($(/sbin/ifconfig | grep 'inet addr' | awk '{print $2}' | cut -d: -f2));
	if [ $# -gt 0 ]; then
		if [ "$1" == "count" ] || [ "$1" == "number" ]; then
			echo ${#ALL_IP_ADDRESS[@]};
		else
			echo ${ALL_IP_ADDRESS[$1]};
		fi
		return;
	fi
	echo ${ALL_IP_ADDRESS[@]};
}

# 获取系统IPv6地址
function get_ipv6_address()
{
	ALL_IP_ADDRESS=($(/sbin/ifconfig | grep 'inet6 addr' | awk '{print $3}' | cut -d/ -f1));
	if [ $# -gt 0 ]; then
		if [ "$1" == "count" ] || [ "$1" == "number" ]; then
			echo ${#ALL_IP_ADDRESS[@]};
		else
			echo ${ALL_IP_ADDRESS[$1]};
		fi
		return;
	fi
	echo ${ALL_IP_ADDRESS[@]};
}
