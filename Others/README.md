# 常用命令集

#### 按行替换文件
perl -p -i -e "s;匹配项(正则表达式);目标值;g" "文件路径";

#### 删除过老的文件/目录

find 查找目录 -name "通配符表达式" -mtime +天数 -type f -delete;
find 查找目录 -empty -type d -delete;

```bash
find $(readlink -f -n $HOME/logs) -name "*" -mtime +30 -type f -delete;
find $(readlink -f -n $HOME/logs) -empty -type d -delete;
```

#### 同步开源镜像
rsync -arh --progress 源地址 目标地址 ; # 比如：rsync -arh --progress rsync://mirrors.tuna.tsinghua.edu.cn/msys2 .

注意和说明：
------

ssl_cert 里是使用openssl生成服务器证书的脚本和配置文件, 请先阅读 ssl_cert/mk_ssl_cert.sh 内的注释

# 软件源

## MSYS2 国内源
```
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
## Ubuntu & WSL

### 18.04
```
mv /etc/apt/sources.list /etc/apt/sources.list.bak
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

```
mv /etc/apt/sources.list /etc/apt/sources.list.bak

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

```
mv /etc/apt/sources.list /etc/apt/sources.list.bak
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

### 16.04
```
mv /etc/apt/sources.list /etc/apt/sources.list.bak

echo "
deb https://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
# deb https://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

```
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo "
deb https://mirrors.ustc.edu.cn/ubuntu/ xenial main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ xenial main main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
 
# 预发布软件源，不建议启用
# deb https://mirrors.ustc.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
# deb-src https://mirrors.ustc.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
" > /etc/apt/sources.list ;

# apt-add-repository -y "ppa:ubuntu-toolchain-r/test" ;

apt-get update -y ;
```

## nodejs 替换淘宝软件源

```
npm install -g cnpm --registry=https://registry.npm.taobao.org

npm config set registry https://registry.npm.taobao.org
```

## ruby和gem源
```
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

# 环境

## MSYS2

下载地址： http://mirrors.ustc.edu.cn/msys2/distrib/

### utils
pacman -Syy --noconfirm curl wget tar vim zip unzip rsync openssh;

### utils optional
pacman -Syy --noconfirm p7zip texinfo lzip m4;

### dev
pacman -Syy --noconfirm cmake m4 autoconf automake python git make tig;

### gcc
pacman -Syy --noconfirm gcc gdb;

### mingw x86_64
pacman -Syy --noconfirm mingw-w64-x86_64-toolchain mingw-w64-x86_64-libtool mingw-w64-x86_64-cmake mingw-w64-x86_64-extra-cmake-modules;

### mingw i686
pacman -Syy --noconfirm mingw-w64-i686-toolchain  mingw-w64-i686-libtool mingw-w64-i686-cmake  mingw-w64-i686-extra-cmake-modules;

### clang x86_64
pacman -Syy --noconfirm mingw64/mingw-w64-x86_64-compiler-rt mingw64/mingw-w64-x86_64-clang mingw64/mingw-w64-x86_64-clang-analyzer mingw64/mingw-w64-x86_64-clang-tools-extra mingw64/mingw-w64-x86_64-libc++ mingw64/mingw-w64-x86_64-libc++abi ; 

### clang i686
pacman -Syy --noconfirm mingw32/mingw-w64-i686-clang mingw32/mingw-w64-i686-clang-analyzer mingw32/mingw-w64-i686-clang-tools-extra mingw32/mingw-w64-i686-compiler-rt mingw32/mingw-w64-i686-libc++ mingw32/mingw-w64-i686-libc++abi;

### ruby
pacman -S --noconfirm ruby;

## Arch/Manjaro
pacman -Syy --noconfirm yaourt;
pacman -Syy --noconfirm yaourt-gui-manjaro;
yaourt -Syy --noconfirm code vscode-css-languageserver-bin vscode-html-languageserver-bin vscode-json-languageserver-bin

## CentOS

```bash
## basic
sudo yum install -y vim curl wget libuuid-devel perl unzip lzip lunzip p7zipn p7zip-plugins autoconf telnet iotop htop libtool pkgconfig texinfo m4 net-tools python python-setuptools python-pip python-requests python-devel python3-rpm-macros python34 python34-setuptools python34-pip python34-devel

## GCC
sudo yum install -y gcc gdb valgrind automake make libcurl-devel expat-devel expat-static re2c gettext glibc glibc-devel glibc-static

# External development tools
sudo yum install -y zlib-devel zlib-static;

# git 
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.21.0.tar.xz;
tar -axvf git-2.21.0.tar.xz ;
cd git-2.21.0;
env LDFLAGS="-static" ./configure --prefix=/usr --with-curl --with-expat --with-openssl --with-libpcre2 ;
make -j8;
sudo make install;
cd contrib/subtree;
sudo make install;
cd ../../../ ;
# git lfs
sudo rpm -ivh https://packagecloud.io/github/git-lfs/packages/el/7/git-lfs-2.7.1-1.el7.x86_64.rpm/download
```

## Ubuntu & WSL

```bash
## basic
apt install -y vim curl wget uuid-dev libssl-dev python3-setuptools python3-pip python3-mako perl automake gdb valgrind git unzip lunzip p7zip-full autoconf telnet iotop htop libtool build-essential pkg-config gettext

## clang-llvm

# LLVM_VER=-6.0;
apt install -y llvm$LLVM_VER lldb$LLVM_VER  libc++abi1 libc++abi-dev libc++-dev libc++1 clang$LLVM_VER ;

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

## Windows & Chocolatey

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
choco install --yes 7zip vim-tux pandoc foobar2000 Graphviz powershell-core

# dev (anaconda3 also can be used instead of python3)
choco install --yes MobaXterm git git-lfs TortoiseGit python3 ConEmu

# dev - network
choco install --yes wireshark WinPcap

# c & c++
choco install --yes cmake doxygen.install llvm ninja

# nodejs
choco install --yes nodejs npm

# java
choco install --yes jdk8 jdk10
```

## Atom Editor
# my atom config use these binaries:
## gcc,clang: msys2/mingw64, C:\msys64\mingw64\\bin\[gcc or clang].exe
## lua: C:\Program Files\Lua\luac5.1.exe
## pandoc: C:\Program Files (x86)\Pandoc\pandoc.exe

apm config set git "C:\Program Files\Git\bin\git.exe"

# 其他软件记录

多国语言编辑器: [Poedit](https://poedit.net/)

## SSH/SFTP:
 
+ [xshell/xftp](https://www.netsarang.com/download/software.html)
+ [mobaxterm](http://mobaxterm.mobatek.net/)
