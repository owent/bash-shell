#!/bin/sh

echo "Mirror of msys2 base:
  https://mirrors.tuna.tsinghua.edu.cn/msys2/distrib/
  http://mirrors.ustc.edu.cn/msys2
  http://mirror.bit.edu.cn/msys2/Base/
  http://mirrors.zju.edu.cn/msys2/msys2/Base/";
# package source
echo "##
## MSYS2 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/msys/\$arch
Server = http://mirror.bit.edu.cn/msys2/REPOS/MSYS2/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/msys/\$arch
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MSYS2/\$arch" > /etc/pacman.d/mirrorlist.msys ;

echo "##
##
## 32-bit Mingw-w64 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/mingw/i686
Server = http://mirror.bit.edu.cn/msys2/REPOS/MINGW/i686
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/i686
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MINGW/i686" > /etc/pacman.d/mirrorlist.mingw32 ;

echo "##
## 64-bit Mingw-w64 repository mirrorlist
##

## Primary
## msys2.org
Server = http://mirrors.ustc.edu.cn/msys2/mingw/x86_64
Server = http://mirror.bit.edu.cn/msys2/REPOS/MINGW/x86_64
Server = https://mirrors.tuna.tsinghua.edu.cn/msys2/mingw/x86_64
Server = http://mirrors.zju.edu.cn/msys2/msys2/REPOS/MINGW/x86_64" > /etc/pacman.d/mirrorlist.mingw64 ;

# utils
pacman -S curl wget tar vim zip unzip rsync openssh;

# utils optional
pacman -S p7zip texinfo lzip m4;

# dev
pacman -S cmake m4 autoconf automake python git make tig;

# gcc
pacman -S gcc gdb;

# mingw x86_64
pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-libtool;

# mingw i686
pacman -S mingw-w64-i686-toolchain  mingw-w64-i686-libtool;

# clang x86_64
pacman -S mingw64/mingw-w64-x86_64-compiler-rt mingw64/mingw-w64-x86_64-clang mingw64/mingw-w64-x86_64-clang-analyzer mingw64/mingw-w64-x86_64-clang-tools-extra mingw64/mingw-w64-x86_64-libc++ mingw64/mingw-w64-x86_64-libc++abi ; 

# clang i686
pacman -S mingw32/mingw-w64-i686-clang mingw32/mingw-w64-i686-clang-analyzer mingw32/mingw-w64-i686-clang-tools-extra mingw32/mingw-w64-i686-compiler-rt mingw32/mingw-w64-i686-libc++ mingw32/mingw-w64-i686-libc++abi;

# ruby
pacman -S ruby;
# ruby - gem
gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/ ;
gem sources -l;
# ruby - bundle 
bundle config mirror.https://rubygems.org https://gems.ruby-china.org ; # or in Gemfile, edit source 'https://rubygems.org/'

# ruby - rvm
echo "ruby_url=https://cache.ruby-china.org/pub/ruby" > ~/.rvm/user/db

# atom = mingw + clang + dev + git-scm
# git can be found in https://git-scm.com, for example https://github.com/git-for-windows/git/releases/download/v2.7.4.windows.1/Git-2.7.4-64-bit.exe
# my atom config use these binaries:
## gcc,clang: msys2/mingw64, C:\msys64\mingw64\\bin\[gcc or clang].exe
## lua: C:\Program Files\Lua\luac5.1.exe
## pandoc: C:\Program Files (x86)\Pandoc\pandoc.exe

apm config set git "C:\Program Files\Git\bin\git.exe"
