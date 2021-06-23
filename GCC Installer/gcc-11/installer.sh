#!/bin/bash

# ======================================= 配置 =======================================
BUILD_TARGET_COMPOMENTS="";
COMPOMENTS_M4_VERSION=latest;
COMPOMENTS_AUTOCONF_VERSION=latest;
COMPOMENTS_AUTOMAKE_VERSION=1.16.3;
COMPOMENTS_LIBTOOL_VERSION=2.4.6;
COMPOMENTS_PKGCONFIG_VERSION=0.29.2;
COMPOMENTS_GMP_VERSION=6.2.1;
COMPOMENTS_MPFR_VERSION=4.1.0;
COMPOMENTS_MPC_VERSION=1.2.1;
COMPOMENTS_ISL_VERSION=0.18;
COMPOMENTS_LIBATOMIC_OPS_VERSION=7.6.10;
COMPOMENTS_BDWGC_VERSION=8.0.4;
COMPOMENTS_GCC_VERSION=11.1.0;
COMPOMENTS_BINUTILS_VERSION=2.36.1;
COMPOMENTS_OPENSSL_VERSION=1.1.1k;
COMPOMENTS_ZLIB_VERSION=1.2.11;
COMPOMENTS_LIBFFI_VERSION=3.3;
COMPOMENTS_NCURSES_VERSION=6.2;
COMPOMENTS_LIBEXPAT_VERSION=2.4.1;
COMPOMENTS_LIBXCRYPT_VERSION=4.4.23;
COMPOMENTS_GDBM_VERSION=latest;
COMPOMENTS_PYTHON_VERSION=3.9.5;
COMPOMENTS_GDB_VERSION=10.2;
COMPOMENTS_GLOBAL_VERSION=6.6.6;
COMPOMENTS_ZSTD_VERSION=1.5.0;
COMPOMENTS_LZ4_VERSION=1.9.3;
if [ "owent$COMPOMENTS_GDB_STATIC_BUILD" == "owent" ]; then
    COMPOMENTS_GDB_STATIC_BUILD=0;
fi

PREFIX_DIR=/usr/local/gcc-$COMPOMENTS_GCC_VERSION;
# ======================= 非交叉编译 =======================
BUILD_TARGET_CONF_OPTION="";
BUILD_OTHER_CONF_OPTION="";
BUILD_DOWNLOAD_ONLY=0;
# BUILD_LDFLAGS="-Wl,-rpath,../lib64:../lib -Wl,-rpath-link,../lib64:../lib";
# if [ "owent$LDFLAGS" == "owent" ]; then
#     export LDFLAGS="$BUILD_LDFLAGS";
# else
#     export LDFLAGS="$LDFLAGS $BUILD_LDFLAGS";
# fi

# ======================= 交叉编译配置示例(暂不可用) =======================
# BUILD_TARGET_CONF_OPTION="--target=arm-linux --enable-multilib --enable-interwork --disable-shared"
# BUILD_OTHER_CONF_OPTION="--disable-shared"

# ======================================= 检测 =======================================

# ======================= 检测完后等待时间 =======================
CHECK_INFO_SLEEP=3

# ======================= 安装目录初始化/工作目录清理 =======================
while getopts "dp:cht:d:g:n" OPTION; do
    case $OPTION in
        p)
            PREFIX_DIR="$OPTARG";
        ;;
        c)
            rm -rf $(ls -A -d -p * | grep -E "(.*)/$" | grep -v "addition/");
            echo -e "\\033[32;1mnotice: clear work dir(s) done.\\033[39;49;0m";
            exit 0;
        ;;
        d)
            BUILD_DOWNLOAD_ONLY=1;
            echo -e "\\033[32;1mDownload mode.\\033[39;49;0m";
        ;;
        h)
            echo "usage: $0 [options] -p=prefix_dir -c -h";
            echo "options:";
            echo "-p [prefix_dir]             set prefix directory.";
            echo "-c                          clean build cache.";
            echo "-d                          download only.";
            echo "-h                          help message.";
            echo "-t [build target]           set build target(m4 autoconf automake libtool pkgconfig gmp mpfr mpc isl zstd lz4 zlib libffi gcc binutils openssl ncurses libexpat libxcrypt gdbm gdb libatomic_ops bdw-gc global).";
            echo "-d [compoment option]       add dependency compoments build options.";
            echo "-g [gnu option]             add gcc,binutils,gdb build options.";
            echo "-n                          print toolchain version and exit.";
            exit 0;
        ;;
        t)
            BUILD_TARGET_COMPOMENTS="$BUILD_TARGET_COMPOMENTS $OPTARG";
        ;;
        d)
            BUILD_OTHER_CONF_OPTION="$BUILD_OTHER_CONF_OPTION $OPTARG";
        ;;
        g)
            BUILD_TARGET_CONF_OPTION="$BUILD_TARGET_CONF_OPTION $OPTARG";
        ;;
        n)
            echo $COMPOMENTS_GCC_VERSION;
            exit 0;
        ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    mkdir -p "$PREFIX_DIR"
    PREFIX_DIR="$( cd "$PREFIX_DIR" && pwd )";
fi

# ======================= 转到脚本目录 =======================
WORKING_DIR="$PWD";
if [[ -z "$CC" ]]; then
    export CC=gcc;
    export CXX=g++;
fi

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 =======================
SYS_LONG_BIT=$(getconf LONG_BIT);
GCC_OPT_DISABLE_MULTILIB="";
if [[ $SYS_LONG_BIT == "64" ]]; then
    GCC_OPT_DISABLE_MULTILIB="--disable-multilib";
    echo "int main() { return 0; }" > conftest.c;
    $CC -m32 -o conftest ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} conftest.c > /dev/null 2>&1;
    if test $? = 0 ; then
        echo -e "\\033[32;1mnotice: check 32 bit build test success, multilib enabled.\\033[39;49;0m";
        GCC_OPT_DISABLE_MULTILIB="--enable-multilib";
        rm -f conftest;
    else
        echo -e "\\033[32;1mwarning: check 32 bit build test failed, --disable-multilib is added when build gcc.\\033[39;49;0m";
        let CHECK_INFO_SLEEP=$CHECK_INFO_SLEEP+1;
    fi
    rm -f conftest.c;
fi

# ======================= 如果强制开启，则开启 =======================
if [[ ! -z "$GCC_OPT_DISABLE_MULTILIB" ]] && [[ "$GCC_OPT_DISABLE_MULTILIB"=="--disable-multilib" ]] ; then
    for opt in $BUILD_TARGET_CONF_OPTION ; do
        if [[ "$opt" == "--enable-multilib" ]]; then
            echo -e "\\033[32;1mwarning: 32 bit build test failed, but --enable-multilib enabled in GCC_OPT_DISABLE_MULTILIB.\\033[39;49;0m"
            GCC_OPT_DISABLE_MULTILIB="";
            break;
        fi
        echo $f;
    done
fi

# ======================= 检测CPU数量，编译线程数按CPU核心数来 =======================
BUILD_THREAD_OPT=6;
BUILD_CPU_NUMBER=$(cat /proc/cpuinfo | grep -c "^processor[[:space:]]*:[[:space:]]*[0-9]*");
BUILD_THREAD_OPT=$BUILD_CPU_NUMBER;
if [[ $BUILD_THREAD_OPT -gt 6 ]]; then
    BUILD_THREAD_OPT=$(($BUILD_CPU_NUMBER-1));
fi
BUILD_THREAD_OPT="-j$BUILD_THREAD_OPT";
# BUILD_THREAD_OPT="";
echo -e "\\033[32;1mnotice: $BUILD_CPU_NUMBER cpu(s) detected. use $BUILD_THREAD_OPT for multi-process compile.";

# ======================= 统一的包检查和下载函数 =======================
function check_and_download(){
    PKG_NAME="$1";
    PKG_MATCH_EXPR="$2";
    PKG_URL="$3";
     
    PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"));
    if [[ ${#PKG_VAR_VAL} -gt 0 ]]; then
        echo "${PKG_VAR_VAL[0]}"
        return 0;
    fi
     
    if [[ -z "$PKG_URL" ]]; then
        echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m" 
        return 1;
    fi
     
    if [[ -z "$4" ]]; then
        curl --retry 3 -kL "$PKG_URL" -o "$(basename "$PKG_URL")";
    else
        curl --retry 3 -kL "$PKG_URL" -o "$4";
    fi
    
    PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"));
     
    if [[ ${#PKG_VAR_VAL} -eq 0 ]]; then
        echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m" 
        return 1;
    fi
     
    echo "${PKG_VAR_VAL[0]}";
}

# ======================= 列表检查函数 =======================
function is_in_list() {
    ele="$1";
    shift;

    for i in $*; do
        if [[ "$ele" == "$i" ]]; then
            echo 0;
            exit 0;
        fi
    done

    echo 1;
    exit 1;
}

# ======================================= 搞起 =======================================
echo -e "\\033[31;1mcheck complete.\\033[39;49;0m"

# ======================= 准备环境, 把库和二进制目录导入，否则编译会找不到库或文件 =======================
if [[ "x$LD_LIBRARY_PATH" == "x" ]]; then
    export LD_LIBRARY_PATH="$PREFIX_DIR/lib:$PREFIX_DIR/lib64"
else
    export LD_LIBRARY_PATH="$PREFIX_DIR/lib:$PREFIX_DIR/lib64:$LD_LIBRARY_PATH"
fi
export PATH=$PREFIX_DIR/bin:$PATH

echo -e "\\033[32;1mnotice: reset env LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m";
echo -e "\\033[32;1mnotice: reset env PATH=$PATH\\033[39;49;0m";

echo "WORKING_DIR               = $WORKING_DIR"
echo "PREFIX_DIR                = $PREFIX_DIR"
echo "BUILD_TARGET_CONF_OPTION  = $BUILD_TARGET_CONF_OPTION"
echo "BUILD_OTHER_CONF_OPTION   = $BUILD_OTHER_CONF_OPTION"
echo "CHECK_INFO_SLEEP          = $CHECK_INFO_SLEEP"
echo "BUILD_CPU_NUMBER          = $BUILD_CPU_NUMBER"
echo "BUILD_THREAD_OPT          = $BUILD_THREAD_OPT"
echo "GCC_OPT_DISABLE_MULTILIB  = $GCC_OPT_DISABLE_MULTILIB"
echo "SYS_LONG_BIT              = $SYS_LONG_BIT"
echo "CC                        = $CC";
echo "CXX                       = $CXX";

echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m";
sleep $CHECK_INFO_SLEEP

# ======================= 关闭交换分区，否则就爽死了 =======================
swapoff -a

# install m4
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list m4 $BUILD_TARGET_COMPOMENTS) ]]; then
    M4_PKG=$(check_and_download "m4" "m4-*.tar.gz" "https://ftp.gnu.org/gnu/m4/m4-${COMPOMENTS_M4_VERSION}.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$M4_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $M4_PKG;
        M4_DIR=$(ls -d m4-* | grep -v \.tar\.gz);
        cd $M4_DIR;
        ./configure --prefix=$PREFIX_DIR --enable-c++ ;
        make $BUILD_THREAD_OPT && make $BUILD_THREAD_OPT check && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build m4 failed.\\033[39;49;0m";
            # exit -1; # m4 is optional, maybe can use m4 on system
        fi
        cd "$WORKING_DIR";
    fi
fi

# install autoconf
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list autoconf $BUILD_TARGET_COMPOMENTS) ]]; then
    AUTOCONF_PKG=$(check_and_download "autoconf" "autoconf-*.tar.gz" "https://ftp.gnu.org/gnu/autoconf/autoconf-${COMPOMENTS_AUTOCONF_VERSION}.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$AUTOCONF_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $AUTOCONF_PKG;
        AUTOCONF_DIR=$(ls -d autoconf-* | grep -v \.tar\.gz);
        cd $AUTOCONF_DIR;
        ./configure --prefix=$PREFIX_DIR ;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build autoconf failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install automake
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list automake $BUILD_TARGET_COMPOMENTS) ]]; then
    AUTOMAKE_PKG=$(check_and_download "automake" "automake-*.tar.gz" "https://ftp.gnu.org/gnu/automake/automake-${COMPOMENTS_AUTOMAKE_VERSION}.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$AUTOMAKE_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $AUTOMAKE_PKG;
        AUTOMAKE_DIR=$(ls -d automake-* | grep -v \.tar\.gz);
        cd $AUTOMAKE_DIR;
        ./configure --prefix=$PREFIX_DIR ;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build automake failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install libtool
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libtool $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBTOOL_PKG=$(check_and_download "libtool" "libtool-*.tar.gz" "https://ftp.gnu.org/gnu/libtool/libtool-${COMPOMENTS_LIBTOOL_VERSION}.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$LIBTOOL_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $LIBTOOL_PKG;
        LIBTOOL_DIR=$(ls -d libtool-* | grep -v \.tar\.gz);
        cd $LIBTOOL_DIR;
        ./configure --prefix=$PREFIX_DIR --with-pic=yes ;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build libtool failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install pkgconfig
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list pkgconfig $BUILD_TARGET_COMPOMENTS) ]]; then
    PKGCONFIG_PKG=$(check_and_download "pkgconfig" "pkg-config-*.tar.gz" "https://pkg-config.freedesktop.org/releases/pkg-config-${COMPOMENTS_PKGCONFIG_VERSION}.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$PKGCONFIG_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $PKGCONFIG_PKG;
        PKGCONFIG_DIR=$(ls -d pkg-config-* | grep -v \.tar\.gz);
        cd $PKGCONFIG_DIR;
        ./configure --prefix=$PREFIX_DIR --with-pic=yes --with-internal-glib ;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build pkgconfig failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install gmp
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gmp $BUILD_TARGET_COMPOMENTS) ]]; then
    GMP_PKG=$(check_and_download "gmp" "gmp-*.tar.xz" "https://ftp.gnu.org/gnu/gmp/gmp-$COMPOMENTS_GMP_VERSION.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$GMP_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -Jxvf $GMP_PKG;
        GMP_DIR=$(ls -d gmp-* | grep -v \.tar\.xz);
        cd $GMP_DIR;
        CPPFLAGS=-fexceptions ./configure --prefix=$PREFIX_DIR --enable-cxx --enable-assert $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make $BUILD_THREAD_OPT check && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build gmp failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install mpfr
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list mpfr $BUILD_TARGET_COMPOMENTS) ]]; then
    MPFR_PKG=$(check_and_download "mpfr" "mpfr-*.tar.xz" "https://ftp.gnu.org/gnu/mpfr/mpfr-$COMPOMENTS_MPFR_VERSION.tar.xz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$MPFR_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -Jxvf $MPFR_PKG;
        MPFR_DIR=$(ls -d mpfr-* | grep -v \.tar\.xz);
        cd $MPFR_DIR;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --enable-assert $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build mpfr failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install mpc
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list mpc $BUILD_TARGET_COMPOMENTS) ]]; then
    MPC_PKG=$(check_and_download "mpc" "mpc-*.tar.gz" "https://ftp.gnu.org/gnu/mpc/mpc-$COMPOMENTS_MPC_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$MPC_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $MPC_PKG;
        MPC_DIR=$(ls -d mpc-* | grep -v \.tar\.gz);
        cd $MPC_DIR;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpfr=$PREFIX_DIR $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build mpc failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install isl
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list isl $BUILD_TARGET_COMPOMENTS) ]]; then
    ISL_PKG=$(check_and_download "isl" "isl-*.tar.bz2" "https://gcc.gnu.org/pub/gcc/infrastructure/isl-$COMPOMENTS_ISL_VERSION.tar.bz2" );
    if [[ $? -ne 0 ]]; then
        echo -e "$ISL_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -jxvf $ISL_PKG;
        ISL_DIR=$(ls -d isl-* | grep -v \.tar\.bz2);
        cd $ISL_DIR;
        autoreconf -i ;
        ./configure --prefix=$PREFIX_DIR --with-gmp-prefix=$PREFIX_DIR $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build isl failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install libatomic_ops
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list libatomic_ops $BUILD_TARGET_COMPOMENTS) ]; then
    LIBATOMIC_OPS_PKG=$(check_and_download "libatomic_ops" "libatomic_ops-*.tar.gz" "https://github.com/ivmai/libatomic_ops/releases/download/v$COMPOMENTS_LIBATOMIC_OPS_VERSION/libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz" "libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$LIBATOMIC_OPS_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $LIBATOMIC_OPS_PKG;
        LIBATOMIC_OPS_DIR=$(ls -d libatomic_ops-* | grep -v \.tar\.gz);
        # cd $LIBATOMIC_OPS_DIR;
        # bash ./autogen.sh ;
        # ./configure --prefix=$PREFIX_DIR ;
        # make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build libatomic_ops failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install bdw-gc
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list bdw-gc $BUILD_TARGET_COMPOMENTS) ]]; then
    BDWGC_PKG=$(check_and_download "bdw-gc" "gc-*.tar.gz" "https://github.com/ivmai/bdwgc/releases/download/v$COMPOMENTS_BDWGC_VERSION/gc-$COMPOMENTS_BDWGC_VERSION.tar.gz" "gc-$COMPOMENTS_BDWGC_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$BDWGC_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $BDWGC_PKG;
        BDWGC_DIR=$(ls -d gc-* | grep -v \.tar\.gz);
        cd $BDWGC_DIR;
        if [[ ! -z "$LIBATOMIC_OPS_DIR" ]]; then
            if [[ -e libatomic_ops ]]; then
                rm -rf libatomic_ops;
            fi
            mv -f ../$LIBATOMIC_OPS_DIR libatomic_ops;
            $(cd libatomic_ops && bash ./autogen.sh );
            autoreconf -i;
            BDWGC_LIBATOMIC_OPS=no ;
        else
            BDWGC_LIBATOMIC_OPS=check ;
        fi

        if [[ -e Makefile ]]; then
            make clean;
            make distclean;
        fi

        ./configure --prefix=$PREFIX_DIR/multilib/$SYS_LONG_BIT --enable-cplusplus --with-pic=yes --enable-shared=no --enable-static=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS ;
        make $BUILD_THREAD_OPT && make install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build bdw-gc failed.\\033[39;49;0m";
            exit -1;
        fi

        if [[ $SYS_LONG_BIT == "64" ]] && [[ "$GCC_OPT_DISABLE_MULTILIB" == "--enable-multilib" ]] ; then
            make clean;
            make distclean;
            env CFLAGS=-m32 CPPFLAGS=-m32 ./configure --prefix=$PREFIX_DIR/multilib/32 --enable-cplusplus --with-pic=yes --enable-shared=no --enable-static=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS ;

            make $BUILD_THREAD_OPT && make install;
            if [[ $? -ne 0 ]]; then
                echo -e "\\033[31;1mError: build bdw-gc with -m32 failed.\\033[39;49;0m";
                exit -1;
            fi
            BDWGC_PREBIUILT="--with-target-bdw-gc=$PREFIX_DIR/multilib/$SYS_LONG_BIT,32=$PREFIX_DIR/multilib/32";
        else
            BDWGC_PREBIUILT="--with-target-bdw-gc=$PREFIX_DIR/multilib/$SYS_LONG_BIT";
        fi
        cd "$WORKING_DIR";
    fi
fi


# install zstd
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]]|| [[ "0" == $(is_in_list zstd $BUILD_TARGET_COMPOMENTS) ]]; then
    ZSTD_PKG=$(check_and_download "zstd" "zstd-*.tar.gz" "https://github.com/facebook/zstd/releases/download/v$COMPOMENTS_ZSTD_VERSION/zstd-$COMPOMENTS_ZSTD_VERSION.tar.gz" "zstd-$COMPOMENTS_ZSTD_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$ZSTD_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $ZSTD_PKG;
        ZSTD_DIR=$(ls -d zstd-* | grep -v \.tar\.gz);
        cd $ZSTD_DIR;

        if [[ -e Makefile ]]; then
            make clean;
        fi

        # mkdir build_jobs_dir;
        # cd build_jobs_dir;
        # cmake ../build/cmake "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR" -DZSTD_BUILD_PROGRAMS=ON -DZSTD_BUILD_TESTS=OFF
        # cmake --build . -j -- install
        make $BUILD_THREAD_OPT PREFIX=$PREFIX_DIR install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build zstd failed.\\033[39;49;0m";
            exit -1;
        fi

        cd "$WORKING_DIR";
    fi
fi

# install lz4
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list lz4 $BUILD_TARGET_COMPOMENTS) ]]; then
    LZ4_PKG=$(check_and_download "lz4" "lz4-*.tar.gz" "https://github.com/lz4/lz4/archive/v$COMPOMENTS_LZ4_VERSION.tar.gz" "lz4-$COMPOMENTS_LZ4_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$LZ4_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $LZ4_PKG;
        LZ4_DIR=$(ls -d lz4-* | grep -v \.tar\.gz);
        cd $LZ4_DIR;

        if [[ -e Makefile ]]; then
            make clean;
        fi

        make $BUILD_THREAD_OPT PREFIX=$PREFIX_DIR install;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build lz4 failed.\\033[39;49;0m";
            # exit -1;
        fi

        cd "$WORKING_DIR";
    fi
fi

# ======================= install gcc =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gcc $BUILD_TARGET_COMPOMENTS) ]]; then
    # ======================= gcc包 =======================
    GCC_PKG=$(check_and_download "gcc" "gcc-*.tar.xz" "https://gcc.gnu.org/pub/gcc/releases/gcc-$COMPOMENTS_GCC_VERSION/gcc-$COMPOMENTS_GCC_VERSION.tar.xz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$GCC_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        GCC_DIR=$(ls -d gcc-* | grep -v \.tar\.xz);
        if [[ -z "$GCC_DIR" ]]; then
            tar -axvf $GCC_PKG;
            GCC_DIR=$(ls -d gcc-* | grep -v \.tar\.xz);
        fi
        mkdir -p objdir;
        cd objdir;
        # ======================= 这一行的最后一个参数请注意，如果要支持其他语言要安装依赖库并打开对该语言的支持 =======================
        GCC_CONF_OPTION_ALL="--prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-isl=$PREFIX_DIR --with-zstd=$PREFIX_DIR $BDWGC_PREBIUILT --enable-bootstrap --enable-build-with-cxx --disable-libjava-multilib --enable-checking=release --enable-gold --enable-ld --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify --enable-shared --enable-static --enable-gnu-unique-object --enable-linker-build-id $GCC_OPT_DISABLE_MULTILIB $BUILD_TARGET_CONF_OPTION";
        # env CFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" CXXFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" 老版本的gcc没有这个选项
        # env LDFLAGS="$LDFLAGS -Wl,-rpath,../../../../lib64:../../../../lib -Wl,-rpath-link,../../../../lib64:../../../../lib" ../$GCC_DIR/configure $GCC_CONF_OPTION_ALL ;
        ../$GCC_DIR/configure $GCC_CONF_OPTION_ALL ;
        make $BUILD_THREAD_OPT && make install;
        cd "$WORKING_DIR";

        ls $PREFIX_DIR/bin/*gcc
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build gcc failed.\\033[39;49;0m";
            exit -1;
        fi

        # ======================= 建立cc软链接 =======================
        ln -s $PREFIX_DIR/bin/gcc $PREFIX_DIR/bin/cc;
    fi
fi

export CC=$PREFIX_DIR/bin/gcc ;
export CXX=$PREFIX_DIR/bin/g++ ;
if [[ "x$PKG_CONFIG_PATH" == "x" ]]; then
    export PKG_CONFIG_PATH="$PREFIX_DIR/internal-packages/lib/pkgconfig"
else
    export PKG_CONFIG_PATH="$PREFIX_DIR/internal-packages/lib/pkgconfig:$PKG_CONFIG_PATH"
fi
for ADDITIONAL_PKGCONFIG_PATH in $(find $PREFIX_DIR -name pkgconfig); do
    export PKG_CONFIG_PATH="$ADDITIONAL_PKGCONFIG_PATH:$PKG_CONFIG_PATH"
done

if [[ -z "$CFLAGS" ]]; then
    export CFLAGS="-fPIC";
else
    export CFLAGS="$CFLAGS -fPIC";
fi
if [[ -z "$CXXFLAGS" ]]; then
    export CXXFLAGS="-fPIC";
else
    export CXXFLAGS="$CXXFLAGS -fPIC";
fi
if [[ -z "$LDFLAGS" ]]; then
    export LDFLAGS="-L$PREFIX_DIR/lib64 -L$PREFIX_DIR/lib";
else
    export LDFLAGS="$LDFLAGS -L$PREFIX_DIR/lib64 -L$PREFIX_DIR/lib";
fi

# ======================= install binutils(链接器,汇编器 等) =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list binutils $BUILD_TARGET_COMPOMENTS) ]]; then
    BINUTILS_PKG=$(check_and_download "binutils" "binutils-*.tar.xz" "https://ftp.gnu.org/gnu/binutils/binutils-$COMPOMENTS_BINUTILS_VERSION.tar.xz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$BINUTILS_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -Jxvf $BINUTILS_PKG;
        BINUTILS_DIR=$(ls -d binutils-* | grep -v \.tar\.xz);
        cd $BINUTILS_DIR;
        make clean || true;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-build-with-cxx --enable-gold --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify --enable-plugins --disable-werror $BUILD_TARGET_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        # ---- 新版本的GCC编译器会激发binutils内某些组件的werror而导致编译失败 ----
        # ---- 另外某个版本的make check有failed用例就被发布了,应该gnu的自动化测试有遗漏 ----
        make $BUILD_THREAD_OPT check;
        cd "$WORKING_DIR";

        ls $PREFIX_DIR/bin/ld
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build binutils failed.\\033[39;49;0m";
        fi
    fi
fi

# ======================= install openssl [后面有些组件依赖] =======================
# openssl的依赖太广泛了，所以不放进默认的查找目录，以防外部使用者会使用到这里的版本。如果需要使用，可以手动导入这里的openssl
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list openssl $BUILD_TARGET_COMPOMENTS) ]]; then
    OPENSSL_PKG=$(check_and_download "openssl" "openssl-*.tar.gz" "https://www.openssl.org/source/openssl-$COMPOMENTS_OPENSSL_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$OPENSSL_PKG";
        exit -1;
    fi
    mkdir -p $PREFIX_DIR/internal-packages ;
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $OPENSSL_PKG;
        OPENSSL_SRC_DIR=$(ls -d openssl-* | grep -v \.tar\.gz);
        cd $OPENSSL_SRC_DIR;
        make clean || true;
        # @see https://wiki.openssl.org/index.php/Compilation_and_Installation
        ./config "--prefix=$PREFIX_DIR/internal-packages" "--openssldir=$PREFIX_DIR/internal-packages/ssl" "--release" "no-dso" "no-tests"  \
                "no-external-tests" "no-shared" "no-idea" "no-md4" "no-mdc2" "no-rc2"                                                       \
                "no-ssl2" "no-ssl3" "no-weak-ssl-ciphers" "enable-ec_nistp_64_gcc_128" "enable-static-engine" ; # "--api=1.1.1"
        make $BUILD_THREAD_OPT || make ;
        make install_sw install_ssldirs;
        if [[ $? -eq 0 ]]; then
            OPENSSL_INSTALL_DIR=$PREFIX_DIR/internal-packages ;
            mkdir -p "$OPENSSL_INSTALL_DIR/ssl";
            for COPY_SSL_DIR in "/etc/pki/tls/" "/usr/lib/ssl" "/etc/ssl/" ; do
                if [[ -e "$COPY_SSL_DIR/cert.pem" ]]; then
                    rsync -rL "$COPY_SSL_DIR/cert.pem" "$OPENSSL_INSTALL_DIR/ssl/";
                fi

                if [[ -e "$COPY_SSL_DIR/certs" ]]; then
                    mkdir -p "$OPENSSL_INSTALL_DIR/ssl/certs/" ;
                    rsync -rL "$COPY_SSL_DIR/certs/"* "$OPENSSL_INSTALL_DIR/ssl/certs/";
                fi
            done
        fi
        cd "$WORKING_DIR";
    fi
fi

# ======================= install zlib [后面有些组件依赖] =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list zlib $BUILD_TARGET_COMPOMENTS) ]]; then
    ZLIB_PKG=$(check_and_download "zlib" "zlib-*.tar.gz" "http://zlib.net/zlib-$COMPOMENTS_ZLIB_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$ZLIB_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $ZLIB_PKG;
        ZLIB_DIR=$(ls -d zlib-* | grep -v \.tar\.gz);
        cd "$ZLIB_DIR";
        make clean || true;
        ./configure --prefix=$PREFIX_DIR --static ;
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild zlib failed.\\033[39;49;0m";
            exit 1;
        fi
        make install ;
        cd "$WORKING_DIR";
    fi
fi

# ======================= install libffi [后面有些组件依赖] =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libffi $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBFFI_PKG=$(check_and_download "libffi" "libffi-*.tar.gz" "https://github.com/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$LIBFFI_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $LIBFFI_PKG;
        LIBFFI_DIR=$(ls -d libffi-* | grep -v \.tar\.gz);
        cd "$LIBFFI_DIR";
        make clean || true;
        ./configure --prefix=$PREFIX_DIR --with-pic=yes ;
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild libffi failed.\\033[39;49;0m";
            exit 1;
        fi
        make install;
        cd "$WORKING_DIR";
    fi
fi

# ======================= install ncurses =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list ncurses $BUILD_TARGET_COMPOMENTS) ]]; then
    NCURSES_PKG=$(check_and_download "ncurses" "ncurses-*.tar.gz" "https://invisible-mirror.net/archives/ncurses/ncurses-$COMPOMENTS_NCURSES_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$NCURSES_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf "$NCURSES_PKG";
        NCURSES_DIR=$(ls -d ncurses-* | grep -v \.tar\.gz);
        cd $NCURSES_DIR;
        make clean || true;

        # Pyhton require shared libraries
        ./configure "--prefix=$PREFIX_DIR" "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig"     \
            --with-normal --without-debug --without-ada --with-termlib --enable-termcap             \
            --enable-pc-files --with-cxx-binding --with-shared --with-cxx-shared                    \
            --enable-ext-colors --enable-ext-mouse --enable-bsdpad --enable-opaque-curses           \
            --with-terminfo-dirs=/etc/terminfo:/usr/share/terminfo:/lib/terminfo                    \
            --with-termpath=/etc/termcap:/usr/share/misc/termcap ;
        
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild ncurse failed.\\033[39;49;0m";
            exit 1;
        fi
        make install ;

        make clean ;
        # Pyhton require shared libraries
        ./configure "--prefix=$PREFIX_DIR" "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig"     \
            --with-normal --without-debug --without-ada --with-termlib --enable-termcap             \
            --enable-widec --enable-pc-files --with-cxx-binding --with-shared --with-cxx-shared     \
            --enable-ext-colors --enable-ext-mouse --enable-bsdpad --enable-opaque-curses           \
            --with-terminfo-dirs=/etc/terminfo:/usr/share/terminfo:/lib/terminfo                    \
            --with-termpath=/etc/termcap:/usr/share/misc/termcap ;
        
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild ncursew failed.\\033[39;49;0m";
            exit 1;
        fi
        make install ;
        cd "$WORKING_DIR";
    fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libexpat $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBEXPAT_PKG=$(check_and_download "expat" "expat-*.tar.gz" "https://github.com/libexpat/libexpat/releases/download/R_${COMPOMENTS_LIBEXPAT_VERSION//./_}/expat-$COMPOMENTS_LIBEXPAT_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$LIBEXPAT_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf "$LIBEXPAT_PKG";
        LIBEXPAT_DIR=$(ls -d expat-* | grep -v \.tar\.gz);
        if [[ -e "$LIBEXPAT_DIR/build_jobs_dir" ]]; then
            rm -rf "$LIBEXPAT_DIR/build_jobs_dir";
        fi
        mkdir -p "$LIBEXPAT_DIR/build_jobs_dir";
        cd "$LIBEXPAT_DIR/build_jobs_dir";

        cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=YES "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR" -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_FUZZERS=OFF -DEXPAT_LARGE_SIZE=ON ;
        cmake --build . $BUILD_THREAD_OPT || cmake --build . ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild libexpat failed.\\033[39;49;0m";
            exit 1;
        fi
        cmake --build . -- install ;

        cd "$WORKING_DIR";
    fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libxcrypt $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBXCRYPT_PKG=$(check_and_download "libxcrypt" "libxcrypt-*.tar.gz" "https://github.com/besser82/libxcrypt/archive/v$COMPOMENTS_LIBXCRYPT_VERSION.tar.gz" "libxcrypt-$COMPOMENTS_LIBXCRYPT_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$LIBXCRYPT_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf "$LIBXCRYPT_PKG";
        LIBXCRYPT_DIR=$(ls -d libxcrypt-* | grep -v \.tar\.gz);
        cd "$LIBXCRYPT_DIR";
        make clean || true;
        ./autogen.sh ;
        ./configure "--prefix=$PREFIX_DIR" --with-pic=yes ;
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild libxcrypt failed.\\033[39;49;0m";
            exit 1;
        fi
        make install ;

        cd "$WORKING_DIR";
    fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gdbm $BUILD_TARGET_COMPOMENTS) ]]; then
    GDBM_PKG=$(check_and_download "gdbm" "gdbm-*.tar.gz" "https://ftp.gnu.org/gnu/gdbm/gdbm-$COMPOMENTS_GDBM_VERSION.tar.gz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$GDBM_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf "$GDBM_PKG";
        GDBM_DIR=$(ls -d gdbm-* | grep -v \.tar\.gz);
        cd "$GDBM_DIR";
        make clean || true;
        # add -fcommon to solve multiple definition of `parseopt_program_args'
        env CFLAGS="$CFLAGS -fcommon" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes ;
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild gdbm failed.\\033[39;49;0m";
            exit 1;
        fi
        make install ;

        cd "$WORKING_DIR";
    fi
fi

# ------------------------ patch for global 6.6.5/Python linking error ------------------------
echo "int main() { return 0; }" | gcc -x c -ltinfow -o /dev/null - 2>/dev/null;
if [[ $? -eq 0 ]]; then
    BUILD_TARGET_COMPOMENTS_PATCH_TINFO=tinfow;
else
    echo "int main() { return 0; }" | gcc -x c -ltinfo -o /dev/null - 2>/dev/null;
    if [[ $? -eq 0 ]]; then
        BUILD_TARGET_COMPOMENTS_PATCH_TINFO=tinfo;
    else
        BUILD_TARGET_COMPOMENTS_PATCH_TINFO=0;
    fi
fi

# ======================= install gdb =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gdb $BUILD_TARGET_COMPOMENTS) ]]; then
    # =======================  尝试编译安装python  =======================
    PYTHON_PKG=$(check_and_download "python" "Python-*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$PYTHON_PKG";
        exit -1;
    fi

    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -Jxvf $PYTHON_PKG;
        PYTHON_DIR=$(ls -d Python-* | grep -v \.tar.xz);
        cd $PYTHON_DIR;
        # --enable-optimizations require gcc 8.1.0 or later
        PYTHON_CONFIGURE_OPTIONS=("--prefix=$PREFIX_DIR" "--enable-optimizations" "--with-ensurepip=install" "--enable-shared" "--with-system-expat" "--with-dbmliborder=gdbm:ndbm:bdb");
        if [[ ! -z "$OPENSSL_INSTALL_DIR" ]]; then
            PYTHON_CONFIGURE_OPTIONS=(${PYTHON_CONFIGURE_OPTIONS[@]} "--with-openssl=$OPENSSL_INSTALL_DIR");
        fi
        make clean || true;
        ./configure ${PYTHON_CONFIGURE_OPTIONS[@]}  ;
        make $BUILD_THREAD_OPT || make ;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild python failed.\\033[39;49;0m";
            exit 1;
        fi
        make install && GDB_DEPS_OPT=(${GDB_DEPS_OPT[@]} "--with-python=$PREFIX_DIR/bin/python3");

        cd "$WORKING_DIR";
    fi

    # ======================= 正式安装GDB =======================
    GDB_PKG=$(check_and_download "gdb" "gdb-*.tar.xz" "https://ftp.gnu.org/gnu/gdb/gdb-$COMPOMENTS_GDB_VERSION.tar.xz" );
    if [[ $? -ne 0 ]]; then
        echo -e "$GDB_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -Jxvf $GDB_PKG;
        GDB_DIR=$(ls -d gdb-* | grep -v \.tar\.xz);
        cd $GDB_DIR;
        if [[ $COMPOMENTS_GDB_STATIC_BUILD -ne 0 ]]; then
            COMPOMENTS_GDB_STATIC_BUILD_FLAGS="LDFLAGS=\"-static $LDFLAGS\"";
            COMPOMENTS_GDB_STATIC_BUILD_PREFIX="env LDFLAGS=\"-static $LDFLAGS\"";
        else
            COMPOMENTS_GDB_STATIC_BUILD_FLAGS='';
            COMPOMENTS_GDB_STATIC_BUILD_PREFIX='';
        fi
        if [[ -e build_jobs_dir ]]; then
            rm -rf build_jobs_dir;
        fi
        mkdir -p build_jobs_dir;
        cd build_jobs_dir;
        make clean || true;
        $COMPOMENTS_GDB_STATIC_BUILD_PREFIX ../configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR \
                                                --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-build-with-cxx --enable-gold --enable-libada       \
                                                --enable-objc-gc --enable-libssp --enable-lto --enable-vtable-verify --with-curses=$PREFIX_DIR      \
                                                $COMPOMENTS_GDB_STATIC_BUILD_FLAGS ${GDB_DEPS_OPT[@]} $BUILD_TARGET_CONF_OPTION;
        $COMPOMENTS_GDB_STATIC_BUILD_PREFIX make $BUILD_THREAD_OPT || $COMPOMENTS_GDB_STATIC_BUILD_PREFIX make;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mBuild gdb failed.\\033[39;49;0m";
            exit 1;
        fi
        make install;
        cd "$WORKING_DIR";

        ls $PREFIX_DIR/bin/gdb;
        if [[ $? -ne 0 ]]; then
            echo -e "\\033[31;1mError: build gdb failed.\\033[39;49;0m"
        fi
    fi
fi

# ======================= install global tool =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list global $BUILD_TARGET_COMPOMENTS) ]]; then
    GLOBAL_PKG=$(check_and_download "global" "global-*.tar.gz" "https://ftp.gnu.org/gnu/global/global-$COMPOMENTS_GLOBAL_VERSION.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$GLOBAL_PKG";
        exit -1;
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
        tar -zxvf $GLOBAL_PKG;
        GLOBAL_DIR=$(ls -d global-* | grep -v \.tar\.gz);
        cd $GLOBAL_DIR;
        make clean || true;
        # patch for global 6.6.5 linking error
        echo "int main() { return 0; }" | gcc -x c -ltinfo -o /dev/null - 2>/dev/null;
        if [[ "$BUILD_TARGET_COMPOMENTS_PATCH_TINFO" != "0" ]]; then
            env "LIBS=$LIBS -l$BUILD_TARGET_COMPOMENTS_PATCH_TINFO" ./configure --prefix=$PREFIX_DIR --with-pic=yes;
        else
            ./configure --prefix=$PREFIX_DIR --with-pic=yes;
        fi
        make $BUILD_THREAD_OPT && make install;
        cd "$WORKING_DIR";
    fi
fi


# 应该就编译完啦
# 64位系统内，如果编译java支持的话可能在gmp上会有问题，可以用这个选项关闭java支持 --enable-languages=c,c++,objc,obj-c++,fortran,ada
# 再把$PREFIX_DIR/bin放到PATH
# $PREFIX_DIR/lib （如果是64位机器还有$PREFIX_DIR/lib64）[另外还有$PREFIX_DIR/libexec我也不知道要不要加，反正我加了]放到LD_LIBRARY_PATH或者/etc/ld.so.conf里
# 再执行ldconfig就可以用新的gcc啦
echo '#!/bin/bash
GCC_HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )";

if [[ "x$LD_LIBRARY_PATH" == "x" ]]; then
    export LD_LIBRARY_PATH="$GCC_HOME_DIR/lib:$GCC_HOME_DIR/lib64" ;
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GCC_HOME_DIR/lib:$GCC_HOME_DIR/lib64" ;
fi

export PATH="$GCC_HOME_DIR/bin:$PATH" ;


if [[ $# -gt 0 ]]; then
  env CC="$GCC_HOME_DIR/bin/gcc"        \
  CXX="$GCC_HOME_DIR/bin/g++"           \
  AR="$GCC_HOME_DIR/bin/ar"             \
  AS="$GCC_HOME_DIR/bin/as"             \
  LD="$(which ld.gold || which ld)"     \
  RANLIB="$GCC_HOME_DIR/bin/ranlib"     \
  NM="$GCC_HOME_DIR/bin/nm"             \
  STRIP="$GCC_HOME_DIR/bin/strip"       \
  OBJCOPY="$GCC_HOME_DIR/bin/objcopy"   \
  OBJDUMP="$GCC_HOME_DIR/bin/objdump"   \
  READELF="$GCC_HOME_DIR/bin/readelf"   \
  "$@"
fi
' > "$PREFIX_DIR/load-gcc-envs.sh" ;
chmod +x "$PREFIX_DIR/load-gcc-envs.sh" ;

echo "# -*- python -*-
import sys
import os
import glob

for stdcxx_path in glob.glob('$PREFIX_DIR/share/gcc-*/python'):
dir_ = os.path.expanduser(stdcxx_path)
if os.path.exists(dir_) and not dir_ in sys.path:
    sys.path.insert(0, dir_)
    from libstdcxx.v6.printers import register_libstdcxx_printers
    register_libstdcxx_printers(None)
" > "$PREFIX_DIR/load-libstdc++-gdb-printers.py" ;
chmod +x "$PREFIX_DIR/load-libstdc++-gdb-printers.py" ;

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m" ;
    echo -e "\\033[31;1mexport PATH=$PATH\\033[39;49;0m" ;
    echo -e "\\033[31;1mexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m" ;
    echo -e "\tor you can add $PREFIX_DIR/lib, $PREFIX_DIR/lib64 (if in x86_64) and $PREFIX_DIR/libexec to file [/etc/ld.so.conf] and then run [ldconfig]" ;
    echo -e "\\033[33;1mBuild Gnu Compile Collection done.\\033[39;49;0m" ;
    echo -e "If you want to use openssl $COMPOMENTS_OPENSSL_VERSION built by this toolchain, just add \\033[33;1m$PREFIX_DIR/internal-packages\\033[0m to search path."
else
    echo -e "\\033[35;1mAll packages downloaded.\\033[39;49;0m";
fi

PAKCAGE_NAME="$(dirname "$PREFIX_DIR")";
PAKCAGE_NAME="${PAKCAGE_NAME//\//-}-gcc";
if [[ "x${PAKCAGE_NAME:0:1}" == "x-" ]]; then
    PAKCAGE_NAME="${PAKCAGE_NAME:1}";
fi
mkdir -p "$PREFIX_DIR/SPECS";
echo "Name:           $PAKCAGE_NAME
Version:        $COMPOMENTS_GCC_VERSION
Release:        1%{?dist}
Summary:        gcc $COMPOMENTS_GCC_VERSION

Group:          Development Tools
License:        BSD
URL:            https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer
BuildRoot:      %_topdir/BUILDROOT
Prefix:         $PREFIX_DIR
# Source0:

# BuildRequires:
Requires:       gcc,make

%description
gcc $COMPOMENTS_GCC_VERSION

%install
  mkdir -p %{buildroot}$(dirname "$PREFIX_DIR")
  ln -s $PREFIX_DIR %{buildroot}$PREFIX_DIR
  exit 0

%files
%defattr  (-,root,root,0755)
$PREFIX_DIR/*
%exclude $PREFIX_DIR

%global __requires_exclude_from ^$PREFIX_DIR/.*

%global __provides_exclude_from ^$PREFIX_DIR/.*

" > "$PREFIX_DIR/SPECS/rpm.spec";

echo "Using:"
echo "    mkdir -pv \$HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}"
echo "    cd $PREFIX_DIR && rpmbuild -bb --target=x86_64 SPECS/rpm.spec"
echo "to build rpm package."