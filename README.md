# 常用命令集

## 通用
#### 按行替换文件
perl -p -i -e "s;匹配项(正则表达式);目标值;g" "文件路径";

#### 删除过老的文件/目录

find 查找目录 -name "通配符表达式" -mtime +天数 -type f -delete;
find 查找目录 -empty -type d -delete;

```bash
find $(readlink -f -n $HOME/logs) -name "*" -mtime +30 -type f -delete;
find $(readlink -f -n $HOME/logs) -empty -type d -delete;
```

## 代理

### 代理环境变量设置

```bash
export http_proxy=http://127.0.0.1:12759
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export rsync_proxy=$http_proxy
# export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com,10.*.*.*,::1*,fc00:*,fe80:*"
export no_proxy="localhost,localaddress,.localdomain.com,0.0.0.0/8,10.0.0.0/8,127.0.0.0/8,100.64.0.0/10,172.16.0.0/12,169.254.0.0/16,192.0.0.0/24,192.0.2.0/24,192.168.0.0/16,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,::1/128,fc00::/7,fe80::/10"

# sudo 保留环境变量
Defaults env_keep += "http_proxy https_proxy ftp_proxy rsync_proxy no_proxy"
```

### ssh代理

```bash
# SSH over http-proxy
## 下面提供的使用方式和安装命令请根据自己的环境选择，都是任选一个即可
## + Windows: choco install
## + Arch/Manjaro/MSYS2: pacman -S
## + Debian/Ubuntu: apt install
## + CentOS/Redhat: yum install
## + macOS: brew install
## + 其他环境请参照各自的包管理工具，如: dnf/snap/pkg_add等

## 1. (推荐) 使用 socat => pacman -S/yum|apt|brew install socat后使用下面的配置(认证选项: proxyauth=<username>:<password> , 其他选项见)
echo "ProxyCommand socat - PROXY:$PROXYSERVER:%h:%p,proxyport=$PROXYPORT" >> ~/.ssh/config ;
## 2. (推荐) 使用 nmap/ncat => pacman -S/yum|apt|brew|choco install nmap-ncat/ncat/nmap 后使用下面的配置(认证选项: --proxy-auth)
### Windows版域编译包: https://nmap.org/book/inst-windows.html
echo "ProxyCommand ncat --proxy $PROXYSERVER:$PROXYPORT --proxy-type http %h %p" >> ~/.ssh/config ;
## 3. 使用 connect/connect-proxy => pacman -S/yum|apt|brew install connect-proxy/connect (Windows版本的git自带)
echo "ProxyCommand connect-proxy/connect -H $PROXYSERVER:$PROXYPORT  %h %p" >> ~/.ssh/config ;
## 4. 使用 corkscrew => pacman -S/yum|apt|brew install corkscrew
echo "ProxyCommand corkscrew $PROXYSERVER $PROXYPORT %h %p" >> ~/.ssh/config ;
## 5. 使用 nc => pacman -S/yum|apt|brew|choco install nmap-netcat/gnu-netcat/openbsd-netcat/netcat/net-tools
### 不建议使用nc，因为不同平台版本、功能和使用参数不完全一样，建议使用下一代的nmap/ncat为替代品
echo "ProxyCommand /usr/bin/nc -X connect -x $PROXYSERVER:$PROXYPORT %h %p" >> ~/.ssh/config ;

# SSH over sock5-proxy
## 1. (推荐) 使用 socat => pacman -S/yum|apt|brew install socat后使用下面的配置(认证选项: socksuser=nobody)
echo "ProxyCommand SOCKS4A:$PROXYSERVER:%h:%p,socksport=$PROXYPORT" >> ~/.ssh/config ;
## 2. (推荐) 使用 nmap/ncat => pacman -S/yum|apt|brew|choco install nmap-ncat/ncat/nmap 后使用下面的配置(认证选项: --proxy-auth)
### Windows版域编译包: https://nmap.org/book/inst-windows.html
echo "ProxyCommand ncat --proxy $PROXYSERVER:$PROXYPORT --proxy-type socks5 %h %p" >> ~/.ssh/config ;
## 3. 使用 nc => pacman -S/yum|apt|brew|choco install nmap-netcat/gnu-netcat/openbsd-netcat/netcat/net-tools
### 不建议使用nc，因为不同平台版本、功能和使用参数不完全一样，建议使用下一代的nmap/ncat为替代品
echo "ProxyCommand nc -X 5 -x $PROXYSERVER:$PROXYPORT %h %p" >> ~/.ssh/config ;

# SSH over httptunnel
## server
hts -F localhost:22 80
## client
htc -P proxy.corp.com:80 -F 8022 server.at.home:80

## 也可以通过更专用的代理软件
## + https://github.com/rofl0r/proxychains-ng
## + https://github.com/haad/proxychains
## + https://www.torproject.org/
```

## 软件源

### 同步开源镜像

rsync -arh --progress 源地址 目标地址 ; # 比如：rsync -arh --progress rsync://mirrors.tuna.tsinghua.edu.cn/msys2 .

**注意和说明：**

ssl_cert 里是使用openssl生成服务器证书的脚本和配置文件, 请先阅读 ssl_cert/mk_ssl_cert.sh 内的注释

### MSYS2 国内源

```bash
echo "##
## MSYS2 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/msys/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/\$arch
Server = http://mirror.bit.edu.cn/msys2/REPOS/MSYS2/\$arch
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MSYS2/\$arch
Server = http://repo.msys2.org/msys/\$arch" > /etc/pacman.d/mirrorlist.msys ;

echo "##
##
## 32-bit Mingw-w64 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/mingw/i686
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/i686
Server = http://mirror.bit.edu.cn/msys2/REPOS/MINGW/i686
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MINGW/i686
Server = http://repo.msys2.org/mingw/i686" > /etc/pacman.d/mirrorlist.mingw32 ;

echo "##
## 64-bit Mingw-w64 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/mingw/x86_64
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/x86_64
Server = http://mirror.bit.edu.cn/msys2/REPOS/MINGW/x86_64
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MINGW/x86_64
Server = http://repo.msys2.org/mingw/x86_64" > /etc/pacman.d/mirrorlist.mingw64 ;
```

### Ubuntu & Debian & WSL

#### Ubuntu 18.04

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb https://mirrors.cloud.tencent.com/ubuntu/ bionic main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ bionic main main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://mirrors.cloud.tencent.com/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.cloud.tencent.com/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.cloud.tencent.com/ubuntu/ bionic-proposed main restricted universe multiverse
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
# deb https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic main main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
 
# 预发布软件源，不建议启用
# deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

#### Debian 10

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb http://mirrors.tencent.com/debian buster main contrib non-free
deb http://mirrors.tencent.com/debian buster-updates main contrib non-free
deb http://mirrors.tencent.com/debian buster-backports main contrib non-free
# deb http://mirrors.tencent.com/debian buster-proposed-updates main contrib non-free
deb-src http://mirrors.tencent.com/debian buster main contrib non-free
deb-src http://mirrors.tencent.com/debian buster-updates main contrib non-free
deb-src http://mirrors.tencent.com/debian buster-backports main contrib non-free
# deb-src http://mirrors.tencent.com/debian buster-proposed-updates main contrib non-free**
deb http://mirrors.tencent.com/debian-security buster/updates main
deb-src http://mirrors.tencent.com/debian-security buster/updates main
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb http://mirrors.aliyun.com/debian/ buster main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib
deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib
deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib
deb http://mirrors.aliyun.com/debian-security buster/updates main
deb-src http://mirrors.aliyun.com/debian-security buster/updates main
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb http://mirrors.ustc.edu.cn/debian buster main non-free contrib
deb http://mirrors.ustc.edu.cn/debian buster-updates main non-free contrib
deb http://mirrors.ustc.edu.cn/debian buster-backports main non-free contrib
deb http://mirrors.ustc.edu.cn/debian-security/ buster/updates main non-free contrib
deb-src http://mirrors.ustc.edu.cn/debian buster main non-free contrib
deb-src http://mirrors.ustc.edu.cn/debian buster-updates main non-free contrib
deb-src http://mirrors.ustc.edu.cn/debian buster-backports main non-free contrib
deb-src http://mirrors.ustc.edu.cn/debian-security/ buster/updates main non-free contrib
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

### Proxmox VE 6

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb http://mirrors.aliyun.com/debian/ buster main contrib
deb http://mirrors.aliyun.com/debian/ buster-updates main contrib
deb http://mirrors.aliyun.com/debian-security/ buster/updates main contrib
" > /etc/apt/sources.list ;

if [ ! -e  /etc/apt/sources.list.d/pve-enterprise.list ]; then mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak ; fi
echo "
deb http://mirrors.ustc.edu.cn/proxmox/debian/pve/ buster pve-no-subscription
" > /etc/apt/sources.list.d/pve-community.list ;

```bash
if [ ! -e  /etc/apt/sources.list.bak ]; then mv /etc/apt/sources.list /etc/apt/sources.list.bak ; fi
echo "
deb http://mirrors.ustc.edu.cn/debian/ buster main contrib
deb http://mirrors.ustc.edu.cn/debian/ buster-updates main contrib
deb http://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib
" > /etc/apt/sources.list ;

if [ ! -e  /etc/apt/sources.list.d/pve-enterprise.list ]; then mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak ; fi
echo "
deb http://download.proxmox.wiki/debian/ buster pve-no-subscription
" > /etc/apt/sources.list.d/pve-community.list ;


# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

### nodejs 替换淘宝软件源

```bash
npm install -g cnpm --registry=https://registry.npm.taobao.org

npm config set registry https://registry.npm.taobao.org
```

### ruby和gem源

```bash
# 安装脚本（通过rvm） https://github.com/huacnlee/init.d/blob/master/install_rvm
command gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
command curl -L https://get.rvm.io | bash -s stable

source /usr/local/rvm/scripts/rvm ;

rvm list known;

rvm install 2.6 ;

rvm ruby-2.6.0 ;

# gem
gem sources --remove https://rubygems.org/

gem sources --add https://gems.ruby-china.org/
gem sources --add http://mirrors.aliyun.com/rubygems/

# bundle
bundle config mirror.https://rubygems.org https://gems.ruby-china.org 
bundle config mirror.https://rubygems.org http://mirrors.aliyun.com/rubygems/

# or in Gemfile, edit source 'https://rubygems.org/' to 'https://gems.ruby-china.org' or 'http://mirrors.aliyun.com/rubygems/'
```

## 环境

### MSYS2

下载地址： http://mirrors.ustc.edu.cn/msys2/distrib/

#### utils

```bash
pacman -Syy --noconfirm curl wget tar vim zip unzip rsync openssh;
```

#### utils optional

```bash
pacman -Syy --noconfirm p7zip texinfo lzip m4;
```

#### dev

```bash
pacman -Syy --noconfirm cmake m4 autoconf automake python git make tig;
```

#### gcc

```bash
pacman -Syy --noconfirm gcc gdb global;
```

#### mingw x86_64

```bash
pacman -Syy --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-libtool mingw-w64-x86_64-cmake mingw-w64-x86_64-extra-cmake-modules mingw-w64-x86_64-global;
```

#### mingw i686

```bash
pacman -Syy --noconfirm mingw-w64-i686-toolchain  mingw-w64-i686-libtool mingw-w64-i686-cmake  mingw-w64-i686-extra-cmake-modules mingw-w64-i686-global;
```

#### clang x86_64

```bash
pacman -Syy --noconfirm mingw64/mingw-w64-x86_64-compiler-rt mingw64/mingw-w64-x86_64-clang mingw64/mingw-w64-x86_64-clang-analyzer mingw64/mingw-w64-x86_64-clang-tools-extra mingw64/mingw-w64-x86_64-libc++ mingw64/mingw-w64-x86_64-libc++abi ; 
```

#### clang i686

```bash
pacman -Syy --noconfirm mingw32/mingw-w64-i686-clang mingw32/mingw-w64-i686-clang-analyzer mingw32/mingw-w64-i686-clang-tools-extra mingw32/mingw-w64-i686-compiler-rt mingw32/mingw-w64-i686-libc++ mingw32/mingw-w64-i686-libc++abi;
```

#### ruby

```bash
pacman -S --noconfirm ruby;
```

### Arch/Manjaro

```bash
sudo pacman -Syy --noconfirm manjaro-aur-support yay;
yay -Syy --noconfirm visual-studio-code-bin
yay -Syy --noconfirm global
```


#### 通过Proxy更新GPG密钥

dirmngr 增加启动参数 ```--honor-http-proxy``` 或 ```pacman/yay --nopgpfetch```

#### 中文输入

##### 中文输入 - ibus

```bash
sudo pacman -Syy --noconfirm ibus ibus-qt ibus-googlepinyin ibus-pinyin # kimtoy ibus-rime
./ibus-setup
echo "
export GTK_IM_MODULE=ibus
export XMODIFIERS=\"@im=ibus\"
export QT_IM_MODULE=ibus

ibus-daemon --xim -d
#ibus-daemon --panel=/usr/lib/kimpanel-ibus-panel --xim -d
" >> ~/.xprofile ; # or edit /etc/environment and add these configures for wayland
```

##### 中文输入 - fcitx

```bash
sudo pacman -Syy --noconfirm kcm-fcitx fcitx-qt5 fcitx-rime fcitx-gtk3 fcitx-gtk2 fcitx
echo "
export GTK_IM_MODULE=fcitx
export XMODIFIERS=\"@im=fcitx\"
export QT_IM_MODULE=fcitx

fcitx-autostart
" >> ~/.xprofile ; # or edit /etc/environment and add these configures for wayland
```

#### 虚拟机

```bash
pacman -Syy --noconfirm qemu qemu-arch-extra qemu-block-iscsi qemu-guest-agent qemu-block-rbd libvirt virt-install virt-manager
```

Client端下载 https://www.spice-space.org/download.html 以支持剪切板共享等高级功能

图形化还是建议用 VrtualBox 或者 VMWare Workstation Player, qemu的驱动性能很差.

VrtualBox 需要额外安装 ```sudo pacman -Syy --noconfirm linux当前内核版本号-virtualbox-host-modules```

VMWare 需要额外安装 

```bash
sudo pacman -Syy --noconfirm linux当前内核版本号-headers linux当前内核版本号-rt-headers
yay -Syy --noconfirm vmware-systemd-services # vmware-modules-dkms

# Guest package open-vm-tools

# patch 
sudo ln -s /usr/lib/modules/$(uname -r)/build/include/generated/uapi/linux/version.h /usr/lib/modules/$(uname -r)/build/include/linux/version.h
```

一些log和配置文件的位置 ```/var/log/vmware-installer``` ```/etc/vmware/config```

#### CrossOver / wine

```bash
sudo pacman -Syy --noconfirm libxcomposite lib32-libxcomposite libxslt lib32-libxslt lib32-libxinerama libxinerama sane cups lib32-libcups
yay -Syy --noconfirm libgphoto2 lib32-libgphoto2 gsm lib32-gsm 
yay -Syy --noconfirm vulkan-headers lib32-vulkan-validation-layers vulkan-tools vulkan-validation-layers vulkan-trace vulkan-icd-loader lib32-vulkan-icd-loader lib32-vkd3d vkd3d vulkan-extra-layers
```

### CentOS

```bash
## basic
sudo yum install -y vim curl wget libuuid-devel perl unzip lzip lunzip p7zip p7zip-plugins autoconf telnet iotop htop libtool pkgconfig m4 net-tools python python-setuptools python-pip python-requests python-devel python3-rpm-macros python34 python34-setuptools python34-pip python34-devel texinfo asciidoc xmlto

## GCC
sudo yum install -y gcc gdb valgrind automake make libcurl-devel expat-devel expat-static re2c gettext glibc glibc-devel glibc-static

# External development tools
sudo yum install -y zlib-devel zlib-static;

# git
GIT_VERSION=2.23.0 ;
GIT_LFS_VERSION=2.9.0 ;
GIT_INSTALL_PREFIX=/opt ;
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.xz;
tar -axvf git-$GIT_VERSION.tar.xz ;
cd git-$GIT_VERSION;
./configure --prefix=$GIT_INSTALL_PREFIX/git/$GIT_VERSION --with-curl --with-expat --with-openssl --with-libpcre2 --with-editor=vim ;
make -j8 all doc;
sudo make install install-doc install-html;
cd contrib/subtree;
sudo make install install-doc install-html;
sudo ln -s $GIT_INSTALL_PREFIX/git/$GIT_VERSION $GIT_INSTALL_PREFIX/git/latest ;
cd ../../../ ;
mkdir -p git-lfs;
cd git-lfs;
# git lfs
wget https://github.com/git-lfs/git-lfs/releases/download/v$GIT_LFS_VERSION/git-lfs-linux-amd64-v$GIT_LFS_VERSION.tar.gz ;
mkdir git-lfs-v$GIT_LFS_VERSION;
cd git-lfs-v$GIT_LFS_VERSION ; 
tar -axvf ../git-lfs-linux-amd64-v$GIT_LFS_VERSION.tar.gz ;
sudo env PREFIX=$GIT_INSTALL_PREFIX/git-lfs/v$GIT_LFS_VERSION ./install.sh ;
sudo ln -s $GIT_INSTALL_PREFIX/git-lfs/v$GIT_LFS_VERSION $GIT_INSTALL_PREFIX/git-lfs/latest ;
cd ../../ ;
```

### Ubuntu & Debian &  WSL

```bash
## basic
apt install -y vim curl wget uuid-dev libssl-dev python3-setuptools python3-pip python3-mako perl automake gdb valgrind git git-lfs unzip lunzip p7zip-full autoconf telnet iotop htop libtool build-essential pkg-config gettext

## clang-llvm

# LLVM_VER=-9;
apt install -y llvm$LLVM_VER lldb$LLVM_VER libc++abi1$LLVM_VER libc++abi$LLVM_VER-dev libc++$LLVM_VER-dev libc++1$LLVM_VER clang$LLVM_VER clang-format$LLVM_VER clang-tidy$LLVM_VER clang-tools$LLVM_VER ;

## clang-llvm-可选
apt install -y lld$LLVM_VER ;
```

下载离线包和离线安装

```bash

APT_DOWNLOAD_CACHE="";
function APT_DOWNLOAD_IN_LIST() {
    ele="$1";
    shift;

    for i in $@; do
        if [ "$ele" == "$i" ]; then
            echo "0";
            return 0;
        fi
    done
    echo "1";
    return 1;
}

function APT_DOWNLOAD_INNER() {
    for PKG in "$@"; do
        if [ "0" != $(APT_DOWNLOAD_IN_LIST $PKG $APT_DOWNLOAD_CACHE) ]; then
            APT_DOWNLOAD_CACHE="$APT_DOWNLOAD_CACHE $PKG";
            # 下载离线包
            DEPPKGS="$(apt-cache depends -i $PKG 2>/dev/null | grep -v 'PreDepends:' | awk '/Depends:/ {print $2}' | xargs echo)";
            if [ -z "$DEPPKGS" ]; then
                echo -e "\\033[32;1mDownloading: $PKG\\033[0m";
            else
                echo -e "\\033[32;1mDownloading: $PKG(depends: $DEPPKGS)\\033[0m";
            fi
            apt-get download $PKG ;

            # 依赖包
            for DEPPKG in $DEPPKGS; do
                APT_DOWNLOAD_INNER $DEPPKG;
            done
        fi
    done
}

function APT_DOWNLOAD() {
    APT_DOWNLOAD_CACHE="";
    APT_DOWNLOAD_INNER "$@";
}

# 安装
dpkg -i DEB包 ;
```

### Proxmox VE

```bash
# 常用工具
apt install -y vim curl wget iotop htop aptitude wpasupplicant wireless-tools;

# 网络重启
systemctl restart networking # systemctl restart network

# WLAN配置见 https://pve.proxmox.com/wiki/WLAN
# 设置无线网卡(DHCP)
ip address          # 查看无线网卡的interface name
WLAN_INTERFACE=...  # 无线网卡的interface name
echo "
allow-hotplug $WLAN_INTERFACE
auto $WLAN_INTERFACE
iface $WLAN_INTERFACE inet dhcp
iface $WLAN_INTERFACE inet6 auto
        wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
" >> /etc/network/interfaces # see man 5 interfaces or https://manpages.debian.org/buster/ifupdown/interfaces.5.en.html for detail

echo "ap_scan=1" > /etc/wpa_supplicant/wpa_supplicant.conf
# 带密码的连接设置
wpa_passphrase <ssid> <password> >> /etc/wpa_supplicant/wpa_supplicant.conf
# 不带密码的连接设置
echo 'network={
        ssid="<ssid>"
        key_mgmt=NONE
}' >> /etc/wpa_supplicant/wpa_supplicant.conf

# 获取已连接的DHCP（网关）地址信息
cat /var/lib/dhcp/dhclient.leases # cat /var/lib/dhcp/dhclient.$WLAN_INTERFACE.leases
WLAN_GATEWAY=...                 # 查到的网关(routers 字段对应的值)

# 设置默认路由
ip route change default via $WLAN_GATEWAY dev $WLAN_INTERFACE

# DNS
cat /etc/resolv.conf
```

### Windows & Chocolatey

https://chocolatey.org

https://chocolatey.org/install#install-with-powershellexe

```ps
# Don't forget to ensure ExecutionPolicy above
Set-ExecutionPolicy Unrestricted
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco update chocolatey
choco upgrade chocolatey
```

```
choco install --yes 7zip pandoc foobar2000 Graphviz powershell-core

# dev (anaconda3 also can be used instead of python3)
choco install --yes MobaXterm git git-lfs TortoiseGit python3 ConEmu

# dev - network
choco install --yes wireshark WinPcap

# c & c++
choco install --yes cmake doxygen.install llvm ninja

# nodejs
choco install --yes nodejs npm

# java
choco install --yes jdk8 openjdk  # jdk11
```

### Rust & Cargo 国内源

修改 ``` $HOME/.cargo/config``` 为:

```
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
```

### Atom Editor

```bash
# my atom config use these binaries:
## gcc,clang: msys2/mingw64, C:\msys64\mingw64\\bin\[gcc or clang].exe
## lua: C:\Program Files\Lua\luac5.1.exe
## pandoc: C:\Program Files (x86)\Pandoc\pandoc.exe
```

apm config set git "C:\Program Files\Git\bin\git.exe"

## 其他软件记录

多国语言编辑器: [Poedit](https://poedit.net/)

### SSH/SFTP

+ [xshell/xftp](https://www.netsarang.com/download/software.html)
+ [mobaxterm](http://mobaxterm.mobatek.net/)
