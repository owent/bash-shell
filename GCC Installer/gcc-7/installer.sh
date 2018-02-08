#!/bin/bash

# ======================================= 配置 =======================================
BUILD_TARGET_COMPOMENTS="";
COMPOMENTS_GMP_VERSION=6.1.2;
COMPOMENTS_MPFR_VERSION=4.0.0;
COMPOMENTS_MPC_VERSION=1.1.0;
COMPOMENTS_ISL_VERSION=0.18;
COMPOMENTS_LIBATOMIC_OPS_VERSION=7.6.2;
COMPOMENTS_BDWGC_VERSION=7.6.4;
COMPOMENTS_GCC_VERSION=7.3.0;
COMPOMENTS_BINUTILS_VERSION=2.30;
COMPOMENTS_PYTHON_VERSION=2.7.14;
COMPOMENTS_GDB_VERSION=8.1;
if [ "owent$COMPOMENTS_GDB_STATIC_BUILD" == "owent" ]; then
    COMPOMENTS_GDB_STATIC_BUILD=0;
fi

PREFIX_DIR=/usr/local/gcc-$COMPOMENTS_GCC_VERSION;
# ======================= 非交叉编译 =======================
BUILD_TARGET_CONF_OPTION=""
BUILD_OTHER_CONF_OPTION=""
BUILD_DOWNLOAD_ONLY=0;

# ======================= 交叉编译配置示例(暂不可用) =======================
# BUILD_TARGET_CONF_OPTION="--target=arm-linux --enable-multilib --enable-interwork --disable-shared"
# BUILD_OTHER_CONF_OPTION="--disable-shared"

# ======================================= 检测 =======================================

# ======================= 检测完后等待时间 =======================
CHECK_INFO_SLEEP=3

# ======================= 安装目录初始化/工作目录清理 =======================
while getopts "dp:cht:d:g:" OPTION; do
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
            echo "-t [build target]           set build target(gmp mpfr mpc isl gcc binutils gdb libatomic_ops bdw-gc).";
            echo "-d [compoment option]       add dependency compoments build options.";
            echo "-g [gnu option]             add gcc,binutils,gdb build options.";
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
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
    mkdir -p "$PREFIX_DIR"
    PREFIX_DIR="$( cd "$PREFIX_DIR" && pwd )";
fi

# ======================= 转到脚本目录 =======================
WORKING_DIR="$PWD";

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 =======================
SYS_LONG_BIT=$(getconf LONG_BIT);
GCC_OPT_DISABLE_MULTILIB="";
if [ $SYS_LONG_BIT == "64" ]; then
    GCC_OPT_DISABLE_MULTILIB="--disable-multilib";
    echo "int main() { return 0; }" > conftest.c;
    gcc -m32 -o conftest ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} conftest.c > /dev/null 2>&1;
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
if [ ! -z "$GCC_OPT_DISABLE_MULTILIB" ] && [ "$GCC_OPT_DISABLE_MULTILIB"=="--disable-multilib" ] ; then
    for opt in $BUILD_TARGET_CONF_OPTION ; do
        if [ "$opt" == "--enable-multilib" ]; then
            echo -e "\\033[32;1mwarning: 32 bit build test failed, but --enable-multilib enabled in GCC_OPT_DISABLE_MULTILIB.\\033[39;49;0m"
            GCC_OPT_DISABLE_MULTILIB="";
            break;
        fi
        echo $f;
    done
fi

# ======================= 检测CPU数量，编译线程数不能大于CPU数量的2倍，否则可能出问题 =======================
BUILD_THREAD_OPT=8;
BUILD_CPU_NUMBER=$(cat /proc/cpuinfo | grep -c "^processor[[:space:]]*:[[:space:]]*[0-9]*");
BUILD_THREAD_OPT=$(($BUILD_CPU_NUMBER*2));
if [ $BUILD_THREAD_OPT -gt 8 ]; then
    BUILD_THREAD_OPT=8;
fi
BUILD_THREAD_OPT="-j$BUILD_THREAD_OPT";
# BUILD_THREAD_OPT="";
echo -e "\\033[32;1mnotice: $BUILD_CPU_NUMBER cpu(s) detected. use $BUILD_THREAD_OPT for multi-thread compile.";

# ======================= 统一的包检查和下载函数 =======================
function check_and_download(){
    PKG_NAME="$1";
    PKG_MATCH_EXPR="$2";
    PKG_URL="$3";
     
    PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"));
    if [ ${#PKG_VAR_VAL} -gt 0 ]; then
        echo "${PKG_VAR_VAL[0]}"
        return 0;
    fi
     
    if [ -z "$PKG_URL" ]; then
        echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m" 
        return 1;
    fi
     
    if [ -z "$4" ]; then
        wget -c "$PKG_URL";
    else
        wget -c "$PKG_URL" -O "$4";
    fi
    
    PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"));
     
    if [ ${#PKG_VAR_VAL} -eq 0 ]; then
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
        if [ "$ele" == "$i" ]; then
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
export LD_LIBRARY_PATH=$PREFIX_DIR/lib:$PREFIX_DIR/lib64:$LD_LIBRARY_PATH
export PATH=$PREFIX_DIR/bin:$PATH

echo -e "\\033[32;1mnotice: reset env LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m";
echo -e "\\033[32;1mnotice: reset env PATH=$PATH\\033[39;49;0m";

echo "WORKING_DIR = $WORKING_DIR"
echo "PREFIX_DIR = $PREFIX_DIR"
echo "BUILD_TARGET_CONF_OPTION = $BUILD_TARGET_CONF_OPTION"
echo "BUILD_OTHER_CONF_OPTION = $BUILD_OTHER_CONF_OPTION"
echo "CHECK_INFO_SLEEP = $CHECK_INFO_SLEEP"
echo "BUILD_CPU_NUMBER = $BUILD_CPU_NUMBER"
echo "BUILD_THREAD_OPT = $BUILD_THREAD_OPT"
echo "GCC_OPT_DISABLE_MULTILIB = $GCC_OPT_DISABLE_MULTILIB"
echo "SYS_LONG_BIT = $SYS_LONG_BIT"

echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m";
sleep $CHECK_INFO_SLEEP

# ======================= 关闭交换分区，否则就爽死了 =======================
swapoff -a

# install gmp
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list gmp $BUILD_TARGET_COMPOMENTS) ]; then
    GMP_PKG=$(check_and_download "gmp" "gmp-*.tar.xz" "https://ftp.gnu.org/gnu/gmp/gmp-$COMPOMENTS_GMP_VERSION.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$GMP_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -Jxvf $GMP_PKG;
        GMP_DIR=$(ls -d gmp-* | grep -v \.tar\.xz);
        cd $GMP_DIR;
        CPPFLAGS=-fexceptions ./configure --prefix=$PREFIX_DIR --enable-cxx --enable-assert $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make check && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build gmp failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install mpfr
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list mpfr $BUILD_TARGET_COMPOMENTS) ]; then
    MPFR_PKG=$(check_and_download "mpfr" "mpfr-*.tar.xz" "https://ftp.gnu.org/gnu/mpfr/mpfr-$COMPOMENTS_MPFR_VERSION.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$MPFR_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -Jxvf $MPFR_PKG;
        MPFR_DIR=$(ls -d mpfr-* | grep -v \.tar\.xz);
        cd $MPFR_DIR;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --enable-assert $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build mpfr failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install mpc
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list mpc $BUILD_TARGET_COMPOMENTS) ]; then
    MPC_PKG=$(check_and_download "mpc" "mpc-*.tar.gz" "https://ftp.gnu.org/gnu/mpc/mpc-$COMPOMENTS_MPC_VERSION.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$MPC_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -zxvf $MPC_PKG;
        MPC_DIR=$(ls -d mpc-* | grep -v \.tar\.gz);
        cd $MPC_DIR;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpfr=$PREFIX_DIR $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build mpc failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install isl
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list isl $BUILD_TARGET_COMPOMENTS) ]; then
    ISL_PKG=$(check_and_download "isl" "isl-*.tar.bz2" "https://gcc.gnu.org/pub/gcc/infrastructure/isl-$COMPOMENTS_ISL_VERSION.tar.bz2" );
    if [ $? -ne 0 ]; then
        echo -e "$ISL_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -jxvf $ISL_PKG;
        ISL_DIR=$(ls -d isl-* | grep -v \.tar\.bz2);
        cd $ISL_DIR;
        autoreconf -i ;
        ./configure --prefix=$PREFIX_DIR --with-gmp-prefix=$PREFIX_DIR $BUILD_OTHER_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build isl failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install libatomic_ops
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list libatomic_ops $BUILD_TARGET_COMPOMENTS) ]; then
    LIBATOMIC_OPS_PKG=$(check_and_download "libatomic_ops" "libatomic_ops-*.tar.gz" "https://github.com/ivmai/libatomic_ops/releases/download/v$COMPOMENTS_LIBATOMIC_OPS_VERSION/libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz" "libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$LIBATOMIC_OPS_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -zxvf $LIBATOMIC_OPS_PKG;
        LIBATOMIC_OPS_DIR=$(ls -d libatomic_ops-* | grep -v \.tar\.gz);
        # cd $LIBATOMIC_OPS_DIR;
        # bash ./autogen.sh ;
        # ./configure --prefix=$PREFIX_DIR ;
        # make $BUILD_THREAD_OPT && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build libatomic_ops failed.\\033[39;49;0m";
            exit -1;
        fi
        cd "$WORKING_DIR";
    fi
fi

# install bdw-gc
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list bdw-gc $BUILD_TARGET_COMPOMENTS) ]; then
    BDWGC_PKG=$(check_and_download "bdw-gc" "gc-*.tar.gz" "https://github.com/ivmai/bdwgc/releases/download/v$COMPOMENTS_BDWGC_VERSION/gc-$COMPOMENTS_BDWGC_VERSION.tar.gz" "gc-$COMPOMENTS_BDWGC_VERSION.tar.gz" );
    if [ $? -ne 0 ]; then
        echo -e "$BDWGC_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -zxvf $BDWGC_PKG;
        BDWGC_DIR=$(ls -d gc-* | grep -v \.tar\.gz);
        cd $BDWGC_DIR;
        if [ ! -z "$LIBATOMIC_OPS_DIR" ]; then
            if [ -e libatomic_ops ]; then
                rm -rf libatomic_ops;
            fi
            mv -f ../$LIBATOMIC_OPS_DIR libatomic_ops;
            $(cd libatomic_ops && bash ./autogen.sh );
            autoreconf -i;
            BDWGC_LIBATOMIC_OPS=no ;
        else
            BDWGC_LIBATOMIC_OPS=check ;
        fi
        # patch configure synax error for 7.6.4
        if [ "$COMPOMENTS_BDWGC_VERSION" == "7.6.4" ]; then
            sed -i "19732c echo 'patch synax error';" configure;
        fi
        ./configure --prefix=$PREFIX_DIR/multilib/$SYS_LONG_BIT --enable-cplusplus --with-pic=yes --enable-shared=no --enable-static=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS ;
        make $BUILD_THREAD_OPT && make install;
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build bdw-gc failed.\\033[39;49;0m";
            exit -1;
        fi

        if [ $SYS_LONG_BIT == "64" ] && [ "$GCC_OPT_DISABLE_MULTILIB" == "--enable-multilib" ] ; then
            make clean;
            make distclean;
            env CFLAGS=-m32 CPPFLAGS=-m32 ./configure --prefix=$PREFIX_DIR/multilib/32 --enable-cplusplus --with-pic=yes --enable-shared=no --enable-static=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS ;

            make $BUILD_THREAD_OPT && make install;
            if [ $? -ne 0 ]; then
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

# ======================= install gcc =======================
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list gcc $BUILD_TARGET_COMPOMENTS) ]; then
    # ======================= gcc包 =======================
    GCC_PKG=$(check_and_download "gcc" "gcc-*.tar.xz" "https://gcc.gnu.org/pub/gcc/releases/gcc-$COMPOMENTS_GCC_VERSION/gcc-$COMPOMENTS_GCC_VERSION.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$GCC_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        GCC_DIR=$(ls -d gcc-* | grep -v \.tar\.xz);
        if [ -z "$GCC_DIR" ]; then
            tar -axvf $GCC_PKG;
            GCC_DIR=$(ls -d gcc-* | grep -v \.tar\.xz);
        fi
        mkdir -p objdir;
        cd objdir;
        # ======================= 这一行的最后一个参数请注意，如果要支持其他语言要安装依赖库并打开对该语言的支持 =======================
        GCC_CONF_OPTION_ALL="--prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-bootstrap --enable-build-with-cxx --disable-libjava-multilib --enable-checking=release --enable-gold --enable-ld --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify --enable-shared --enable-static --enable-gnu-unique-object --enable-linker-build-id $GCC_OPT_DISABLE_MULTILIB $BUILD_TARGET_CONF_OPTION";
        # env CFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" CXXFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" 老版本的gcc没有这个选项
        ../$GCC_DIR/configure $GCC_CONF_OPTION_ALL ;
        make $BUILD_THREAD_OPT && make install;
        cd "$WORKING_DIR";

        ls $PREFIX_DIR/bin/*gcc
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build gcc failed.\\033[39;49;0m";
            exit -1;
        fi

        # ======================= 建立cc软链接 =======================
        ln -s $PREFIX_DIR/bin/gcc $PREFIX_DIR/bin/cc;
    fi
fi

export CC=$PREFIX_DIR/bin/gcc ;
export CXX=$PREFIX_DIR/bin/g++ ;

# ======================= install binutils(链接器,汇编器 等) =======================
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list binutils $BUILD_TARGET_COMPOMENTS) ]; then
    BINUTILS_PKG=$(check_and_download "binutils" "binutils-*.tar.xz" "https://ftp.gnu.org/gnu/binutils/binutils-$COMPOMENTS_BINUTILS_VERSION.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$BINUTILS_PKG";
        exit -1;
    fi
    if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
        tar -Jxvf $BINUTILS_PKG;
        BINUTILS_DIR=$(ls -d binutils-* | grep -v \.tar\.xz);
        cd $BINUTILS_DIR;
        ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-build-with-cxx --enable-gold --enable-libada --enable-libssp --enable-lto --enable-objc-gc --enable-vtable-verify --disable-werror $BUILD_TARGET_CONF_OPTION;
        make $BUILD_THREAD_OPT && make install;
        # ---- 新版本的GCC编译器会激发binutils内某些组件的werror而导致编译失败 ----
        # ---- 另外某个版本的make check有failed用例就被发布了,应该gnu的自动化测试有遗漏 ----
        make check;
        cd "$WORKING_DIR";

        ls $PREFIX_DIR/bin/ld
        if [ $? -ne 0 ]; then
            echo -e "\\033[31;1mError: build binutils failed.\\033[39;49;0m";
        fi
    fi
fi

# ======================= install gdb(调试器) [依赖 ncurses-devel 包] =======================
if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list gdb $BUILD_TARGET_COMPOMENTS) ]; then
    if [ -z "$(whereis ncurses | awk '{print $2;}')" ]; then
	    echo -e "\\033[32;1mwarning: libncurses not found, skip build [gdb].\\033[39;49;0m";
    else
	    # ======================= 检查Python开发包，如果存在，则增加 --with-pyton 选项 =======================
        if [ $BUILD_DOWNLOAD_ONLY -ne 0 ]; then
            PYTHON_PKG=$(check_and_download "python" "Python-*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz" );
        else
            if [ ! -z "$(find /usr/include -name Python.h)" ]; then
                GDB_PYTHON_OPT="--with-python";
            elif [ ! -z "$(find $PREFIX_DIR -name Python.h)" ]; then
                GDB_PYTHON_OPT="--with-python=$PREFIX_DIR";
            else
                # =======================  尝试编译安装python  =======================
                PYTHON_PKG=$(check_and_download "python" "Python-*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz" );
                if [ $? -ne 0 ]; then
                    return;
                fi

                tar -Jxvf $PYTHON_PKG;
                PYTHON_DIR=$(ls -d Python-* | grep -v \.tar.xz);
                cd $PYTHON_DIR;
                ./configure --prefix=$PREFIX_DIR;
                make $BUILD_THREAD_OPT && make install && GDB_PYTHON_OPT="--with-python=$PREFIX_DIR";

                cd "$WORKING_DIR";
            fi
        fi

	    # ======================= 正式安装GDB =======================
	    GDB_PKG=$(check_and_download "gdb" "gdb-*.tar.xz" "https://ftp.gnu.org/gnu/gdb/gdb-$COMPOMENTS_GDB_VERSION.tar.xz" );
	    if [ $? -ne 0 ]; then
		    echo -e "$GDB_PKG";
		    exit -1;
	    fi
        if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
            tar -Jxvf $GDB_PKG;
            GDB_DIR=$(ls -d gdb-* | grep -v \.tar\.xz);
            cd $GDB_DIR;
            if [ $COMPOMENTS_GDB_STATIC_BUILD -ne 0 ]; then
                COMPOMENTS_GDB_STATIC_BUILD_FLAGS='LDFLAGS="-static"';
                COMPOMENTS_GDB_STATIC_BUILD_PREFIX='env LDFLAGS="-static"';
            else
                COMPOMENTS_GDB_STATIC_BUILD_FLAGS='';
                COMPOMENTS_GDB_STATIC_BUILD_PREFIX='';
            fi
            $COMPOMENTS_GDB_STATIC_BUILD_PREFIX ./configure --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-build-with-cxx --enable-gold --enable-libada --enable-objc-gc --enable-libssp --enable-lto $COMPOMENTS_GDB_STATIC_BUILD_FLAGS $GDB_PYTHON_OPT $BUILD_TARGET_CONF_OPTION;
            $COMPOMENTS_GDB_STATIC_BUILD_PREFIX make $BUILD_THREAD_OPT && make install;
            cd "$WORKING_DIR";

            ls $PREFIX_DIR/bin/gdb;
            if [ $? -ne 0 ]; then
                echo -e "\\033[31;1mError: build gdb failed.\\033[39;49;0m"
            fi
        fi
    fi
fi


# 应该就编译完啦
# 64位系统内，如果编译java支持的话可能在gmp上会有问题，可以用这个选项关闭java支持 --enable-languages=c,c++,objc,obj-c++,fortran,ada
# 再把$PREFIX_DIR/bin放到PATH
# $PREFIX_DIR/lib （如果是64位机器还有$PREFIX_DIR/lib64）[另外还有$PREFIX_DIR/libexec我也不知道要不要加，反正我加了]放到LD_LIBRARY_PATH或者/etc/ld.so.conf里
# 再执行ldconfig就可以用新的gcc啦
if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
    echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m" ;
    echo -e "\\033[31;1mexport PATH=$PATH\\033[39;49;0m" ;
    echo -e "\\033[31;1mexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m" ;
    echo -e "\tor you can add $PREFIX_DIR/lib, $PREFIX_DIR/lib64 (if in x86_64) and $PREFIX_DIR/libexec to file [/etc/ld.so.conf] and then run [ldconfig]" ;
    echo -e "\\033[33;1mBuild Gnu Compile Collection done.\\033[39;49;0m" ;
else
    echo -e "\\033[35;1mAll packages downloaded.\\033[39;49;0m";
fi
