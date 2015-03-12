#!/bin/sh
 
# ======================================= 检测 ======================================= 
CHECK_INFO_SLEEP=3
 
# 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库
SYS_LONG_BIT=$(getconf LONG_BIT)
GCC_OPT_DISABLE_MULTILIB=""
if [ $SYS_LONG_BIT == "64" ]; then
    GCC_OPT_DISABLE_MULTILIB="--disable-multilib"
    GCC_OPT_DISABLE_MULTILIB_DEV_LIBS=($(whereis librt))
    if [ ${#GCC_OPT_DISABLE_MULTILIB_DEV_LIBS[@]} -lt 2 ]; then
        echo -e "\\033[31;1mglibc-devel is required.\\033[39;49;0m"
        exit -1
    fi
    for FILE_PATH in ${GCC_OPT_DISABLE_MULTILIB_DEV_LIBS[@]}; do
        if [ ${FILE_PATH:0:9} == "/usr/lib/" ]; then
            echo -e "\\033[32;1mnotice: librt x86_64 found multilib enabled.\\033[39;49;0m"
            GCC_OPT_DISABLE_MULTILIB=""
        fi
    done
    GCC_OPT_DISABLE_MULTILIB_DEV_LIBS=""
    if [ "$GCC_OPT_DISABLE_MULTILIB" == "--disable-multilib" ]; then
        echo -e "\\033[32;1mwarning: --disable-multilib is added when build gcc.\\033[39;49;0m"
        let CHECK_INFO_SLEEP=$CHECK_INFO_SLEEP+1
    fi
fi
 
# 检测CPU数量，编译线程数不能大于CPU数量的2倍，否则可能出问题
BUILD_THREAD_OPT=8;
BUILD_CPU_NUMBER=$(cat /proc/cpuinfo | grep -c "^processor[[:space:]]*:[[:space:]]*[0-9]*");
let BUILD_THREAD_OPT=$BUILD_CPU_NUMBER*2;
if [ $BUILD_THREAD_OPT -gt 8 ]; then
    BUILD_THREAD_OPT=8;
fi
BUILD_THREAD_OPT="-j$BUILD_THREAD_OPT";
echo -e "\\033[32;1mnotice: $BUILD_CPU_NUMBER detected. use $BUILD_THREAD_OPT for multi-thread compile."
 
# ======================================= 搞起 ======================================= 
echo -e "\\033[31;1mcheck complete.\\033[39;49;0m"
if [ $CHECK_INFO_SLEEP -gt 3 ]; then
    sleep $CHECK_INFO_SLEEP
fi
 
# 关闭交换分区，否则就爽死了
swapoff -a
 
PREFIX_DIR=/usr/local/gcc-4.7.2
 
if [ $# -gt 0 ]; then
    PREFIX_DIR=$1
fi
 
mkdir -p $PREFIX_DIR
  
# install gmp
GMP_PKG=$(ls -d gmp-*.tar.bz2)
if [ -z "$GMP_PKG" ]; then
    echo "gmp src not found."
    exit 0;
fi
tar -jxvf $GMP_PKG
GMP_DIR=$(ls -d gmp-* | grep -v \.tar\.bz2)
cd $GMP_DIR
CPPFLAGS=-fexceptions ./configure --prefix=$PREFIX_DIR --enable-cxx --enable-assert
make $BUILD_THREAD_OPT && make check && make install
cd ..
  
# install mpfr
MPFR_PKG=$(ls -d mpfr-*.tar.gz)
if [ -z "$MPFR_PKG" ]; then
    echo "mpfr src not found."
    exit 0;
fi
tar -zxvf $MPFR_PKG
MPFR_DIR=$(ls -d mpfr-* | grep -v \.tar\.gz)
cd $MPFR_DIR
./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --enable-assert
make $BUILD_THREAD_OPT && make install
cd ..
  
# install mpc
MPC_PKG=$(ls -d mpc-*.tar.gz)
if [ -z "$MPC_PKG" ]; then
    echo "mpc src not found."
    exit 0;
fi
tar -zxvf $MPC_PKG
MPC_DIR=$(ls -d mpc-* | grep -v \.tar\.gz)
cd $MPC_DIR
./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpfr=$PREFIX_DIR
make $BUILD_THREAD_OPT && make install
cd ..
  
# install ppl
# 注意，如果系统m4的版本在 1.4.5 以前请手动安装m4，安装包在addition文件夹中
PPL_PKG=$(ls -d ppl-*.tar.gz)
if [ -z "$PPL_PKG" ]; then
    echo "ppl src not found."
    exit 0;
fi
tar -zxvf $PPL_PKG
PPL_DIR=$(ls -d ppl-* | grep -v \.tar\.gz)
cd $PPL_DIR
./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --enable-assertions
make $BUILD_THREAD_OPT && make install
cd ..
 
# install isl
ISL_PKG=$(ls -d isl-*.tar.bz2)
if [ -z "$ISL_PKG" ]; then
    echo "isl 0.10 src not found."
    exit 0;
fi
tar -jxvf $ISL_PKG
ISL_DIR=$(ls -d isl-* | grep -v \.tar\.bz2)
cd $ISL_DIR
./configure --prefix=$PREFIX_DIR --with-gmp-prefix=$PREFIX_DIR
make $BUILD_THREAD_OPT && make install
cd .. 
 
# install cloog
CLOOG_PKG=$(ls -d cloog-0.16*.tar.gz)
if [ -z "$CLOOG_PKG" ]; then
    echo "cloog 0.16 src not found."
    exit 0;
fi
tar -zxvf $CLOOG_PKG
CLOOG_DIR=$(ls -d cloog-0.16* | grep -v \.tar\.gz)
cd $CLOOG_DIR
./configure --prefix=$PREFIX_DIR --with-gmp=system --with-gmp-prefix=$PREFIX_DIR --with-bits=gmp --with-isl=$PREFIX_DIR
make $BUILD_THREAD_OPT && make check && make install
cd ..
  
# install gcc
# 这里要注意把库和二进制目录导入，否则编译会找不到库或文件
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PREFIX_DIR/lib
export PATH=$PREFIX_DIR/lib:$PATH
 
# gcc包
GCC_PKG=$(ls -d gcc-*.tar.bz2)
if [ -z "$GCC_PKG" ]; then
    echo "gcc src not found."
    exit 0;
fi
tar -jxvf $GCC_PKG
GCC_DIR=$(ls -d gcc-* | grep -v \.tar\.bz2)
mkdir objdir
cd objdir
# 这一行的最后一个参数请注意，如果要支持其他语言要安装依赖库并打开对该语言的支持
../$GCC_DIR/configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-ppl=$PREFIX_DIR --with-cloog=$PREFIX_DIR --enable-bootstrap --enable-build-with-cxx --enable-cloog-backend=isl --disable-libjava-multilib --enable-checking=release $GCC_OPT_DISABLE_MULTILIB
make $BUILD_THREAD_OPT && make install
cd ..
  
# 应该就编译完啦
# 64位系统内，如果编译java支持的话可能在gmp上会有问题，可以用这个选项关闭java支持 --enable-languages=c,c++,objc,obj-c++,fortran,ada
# 再把$PREFIX_DIR/bin放到PATH
# $PREFIX_DIR/lib （如果是64位机器还有$PREFIX_DIR/lib64）[另外还有$PREFIX_DIR/libexec我也不知道要不要加，反正我加了]放到LD_LIBRARY_PATH或者/etc/ld.so.conf里
# 再执行ldconfig就可以用新的gcc啦
