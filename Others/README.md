# 常用命令集

#### 按行替换文件
perl -p -i -e "s;匹配项(正则表达式);目标值;g" "文件路径";

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
```
mv /etc/apt/sources.list /etc/apt/sources.list.bak

echo "
deb https://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse

deb-src https://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
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

# gem
gem sources --remove https://rubygems.org/

gem sources --add https://gems.ruby-china.org/
gem sources --add http://mirrors.aliyun.com/rubygems/

# bundle
bundle config mirror.https://rubygems.org https://gems.ruby-china.org 

# or in Gemfile, edit source 'https://rubygems.org/' to 'https://gems.ruby-china.org' or 'http://mirrors.aliyun.com/rubygems/'
```

# 环境

## MSYS2

下载地址： http://mirrors.ustc.edu.cn/msys2/distrib/

### utils
pacman -S curl wget tar vim zip unzip rsync openssh;

### utils optional
pacman -S p7zip texinfo lzip m4;

### dev
pacman -S cmake m4 autoconf automake python git make tig;

### gcc
pacman -S gcc gdb;

### mingw x86_64
pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-libtool mingw-w64-x86_64-cmake mingw-w64-x86_64-extra-cmake-modules;

### mingw i686
pacman -S mingw-w64-i686-toolchain  mingw-w64-i686-libtool mingw-w64-i686-cmake  mingw-w64-i686-extra-cmake-modules;

### clang x86_64
pacman -S mingw64/mingw-w64-x86_64-compiler-rt mingw64/mingw-w64-x86_64-clang mingw64/mingw-w64-x86_64-clang-analyzer mingw64/mingw-w64-x86_64-clang-tools-extra mingw64/mingw-w64-x86_64-libc++ mingw64/mingw-w64-x86_64-libc++abi ; 

### clang i686
pacman -S mingw32/mingw-w64-i686-clang mingw32/mingw-w64-i686-clang-analyzer mingw32/mingw-w64-i686-clang-tools-extra mingw32/mingw-w64-i686-compiler-rt mingw32/mingw-w64-i686-libc++ mingw32/mingw-w64-i686-libc++abi;

### ruby
pacman -S ruby;

## CentOS

## Ubuntu & WSL
```
## basic
apt-get install -y vim curl wget uuid-dev libuuid1 libcurl4-openssl-dev libssl-dev python3-setuptools python3-pip python3-mako perl automake gdb valgrind libncurses5-dev git unzip lunzip p7zip-full gcc cpp autoconf colorgcc telnet iotop htop g++ make libtool build-essential

## clang-llvm

# LLVM_VER=-4.0;
apt-get install -y llvm$LLVM_VER lldb$LLVM_VER  libc++abi1 libc++abi-dev libc++-dev clang$LLVM_VER ;

## clang-llvm-可选
apt-get install -y lld$LLVM_VER ;
```

## Windows & Chocolatey

https://chocolatey.org

https://chocolatey.org/install#install-with-powershellexe

```ps
# Don't forget to ensure ExecutionPolicy above
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco update chocolatey
choco upgrade chocolatey
```

```
chroco install --yes 7zip VisualStudioCode vim-tux pandoc foobar2000 Graphviz

# dev (anaconda3 also can be used instead of python3)
chroco install --yes git git-lfs TortoiseGit python3

# dev - network
chroco install --yes wireshark WinPcap

# c & c++
chroco install --yes cmake doxygen

# nodejs
chroco install --yes nodejs npm

# java
chroco install --yes jdk8
```

## Atom Editor
# my atom config use these binaries:
## gcc,clang: msys2/mingw64, C:\msys64\mingw64\\bin\[gcc or clang].exe
## lua: C:\Program Files\Lua\luac5.1.exe
## pandoc: C:\Program Files (x86)\Pandoc\pandoc.exe

apm config set git "C:\Program Files\Git\bin\git.exe"

# 其他软件记录

多国语言编辑器: [Poedit](https://poedit.net/)