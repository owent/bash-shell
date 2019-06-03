#!/bin/sh
 
# @see https://www.vultr.com/docs/setup-swap-file-on-linux
WORKING_DIR="$PWD";

SWAPFILE_PATH=/swapfile ;
SWAPFILE_COUNT=1M;
SWAPFILE_BS=2048;
FSTAB_PATH=/etc/fstab ;

# try to detect physic memory
PHY_MEM=$(cat /proc/meminfo | grep MemTotal | grep -v grep | awk '{print $2}');
if [ ! -z "$PHY_MEM" ]; then
    ((PHY_MEM=$PHY_MEM/1024));
    ((SWAPFILE_BS=$PHY_MEM*3/2));
    echo "Detect physic memory=$PHY_MEM MB";
fi

while getopts "p:h:b:c:" arg; do
        case $arg in
             c)
                SWAPFILE_COUNT="$OPTARG";
                ;;
             b)
                SWAPFILE_BS="$OPTARG";
                ;;
             p)
                SWAPFILE_PATH="$OPTARG";
                ;;
             h)
                echo "usage: $0 [options]
options:
-c  <block count of swapfile>   path of php.ini(default: $SWAPFILE_COUNT)
-b  <block size of swapfile>    dir path of php.d(default: $SWAPFILE_BS)
-p  <path of swapfile>          path of php-fpm.conf(default: $SWAPFILE_PATH)
-h                              help message
                ";
                exit 0;
                ;;
             ?)  #当有不认识的选项的时候arg为?
                echo "unkonw argument $arg";
                ;;
        esac
done

echo "Try to setup swapfile \"$SWAPFILE_PATH\" with block number = $SWAPFILE_COUNT and block size = $SWAPFILE_BS.";

mkdir -p "$(dirname $SWAPFILE_PATH)";

swapoff -a ;
dd if=/dev/zero of="$SWAPFILE_PATH" bs=$SWAPFILE_BS count=$SWAPFILE_COUNT ;
chmod 600 "$SWAPFILE_PATH";
mkswap "$SWAPFILE_PATH" ;
swapon "$SWAPFILE_PATH" ;

# auto setup
sed -i "/\\bswap\\b/d" "$FSTAB_PATH";
echo "$SWAPFILE_PATH   none    swap    sw    0   0" >> "$FSTAB_PATH";

swapon -s ;
echo "vm.swappiness=$(cat /proc/sys/vm/swappiness)" ;
echo "Setup swapfile \"$SWAPFILE_PATH\" done. now you can run";
echo -e "\techo 'sysctl vm.swappiness=PERCENT' > /etc/sysctl.d/99-swapfile.conf";
echo -e "\tsysctl -p /etc/sysctl.d/99-swapfile.conf";
echo "to control swappiness policy";
# sysctl vm.swappiness=10 ;
# cat /proc/sys/vm/swappiness

free -h ;