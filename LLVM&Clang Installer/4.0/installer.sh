#!/bin/bash

# Dependency: libedit-devel libxml2-devel ncurses-devel python-devel swig

# ======================================= 配置 =======================================
LLVM_VERSION=4.0.0;
PREFIX_DIR=/usr/local/llvm-$LLVM_VERSION;
BUILD_TARGET_COMPOMENTS="llvm clang compiler_rt libcxx libcxxabi clang_tools_extra lldb lld libunwind";

# ======================= 非交叉编译 ======================= 
CHECK_TOTAL_MEMORY=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}');
CHECK_AVAILABLE_MEMORY=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}');
BUILD_LLVM_LLVM_OPTION="-DLLVM_ENABLE_CXX1Y=ON -DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_PIC=ON -DLLVM_USE_INTEL_JITEVENTS=ON"; # -DLLVM_ENABLE_LTO=ON ,this may failed in llvm 3.9 
BUILD_LLVM_CMAKE_OPTION_STAGE_3=""; #  -DBUILD_SHARED_LIBS=ON";
BUILD_OTHER_CONF_OPTION="";
 
# ======================= 内存大于13GB，使用动态链接库（linking libLLVM-XXX.so的时候会消耗巨量内存） =======================
if [ -z "$CHECK_AVAILABLE_MEMORY" ]; then
    CHECK_AVAILABLE_MEMORY=0;
fi

if [ -z "$CHECK_TOTAL_MEMORY" ]; then
    CHECK_TOTAL_MEMORY=0;
fi

if [ $CHECK_AVAILABLE_MEMORY -gt 13631488 ] || [ $CHECK_TOTAL_MEMORY -gt 13631488 ]; then
    BUILD_LLVM_LLVM_OPTION="$BUILD_LLVM_LLVM_OPTION -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON";
fi
  
# ======================================= 检测 ======================================= 
 
# ======================= 检测完后等待时间 ======================= 
CHECK_INFO_SLEEP=3
 
# ======================= 安装目录初始化/工作目录清理 ======================= 
while getopts "p:cht:l:g:m:" OPTION; do
    case $OPTION in
        p)
            PREFIX_DIR="$OPTARG";
        ;;
        c)
            rm -rf $(ls -A -d -p * | grep -E "(.*)/$" | grep -v "addition/");
            echo -e "\\033[32;1mnotice: clear work dir(s) done.\\033[39;49;0m";
            exit 0;
        ;;
        h)
            echo "usage: $0 [options] -p=prefix_dir -c -h";
            echo "options:";
            echo "-p [prefix_dir]             set prefix directory.";
            echo "-c                          clean build cache.";
            echo "-h                          help message.";
            echo "-t [build target]           set build target(llvm clang compiler_rt libcxx libcxxabi lldb polly openmp clang_tools_extra llvm_test_suite libunwind).";
            echo "-l [llvm cpnfigure option]  add llvm build options.";
            echo "-m [llvm cmake option]      add llvm build options.";
            echo "-g [gnu option]             add gcc,binutils,gdb build options.";
            exit 0;
        ;;
        t)
            if [ "+" == "${OPTARG:0:1}" ]; then
                BUILD_TARGET_COMPOMENTS="$BUILD_TARGET_COMPOMENTS ${OPTARG:1}";
			else
				BUILD_TARGET_COMPOMENTS="$OPTARG";
            fi
        ;;
        l)
            BUILD_LLVM_CONF_OPTION="$BUILD_LLVM_CONF_OPTION $OPTARG";
        ;;
        m)
            BUILD_LLVM_CMAKE_OPTION="$BUILD_LLVM_CMAKE_OPTION $OPTARG";
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

mkdir -p "$PREFIX_DIR"
PREFIX_DIR="$( cd "$PREFIX_DIR" && pwd )";

# llvm 脚本fix 
BUILD_LLVM_CONF_OPTION="$BUILD_LLVM_CONF_OPTION -DLLVM_PREFIX=$PREFIX_DIR";

# ======================= 转到脚本目录 ======================= 
WORKING_DIR="$PWD";

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 ======================= 
SYS_LONG_BIT=$(getconf LONG_BIT);
 
# ======================= 统一的包检查和下载函数 ======================= 
function check_and_download(){
    PKG_NAME="$1";
    PKG_MATCH_EXPR="$2";
    PKG_URL="$3";
     
    PKG_VAR_VAL=$(ls -d $PKG_MATCH_EXPR);
    if [ ! -z "$PKG_VAR_VAL" ]; then
        echo "$PKG_VAR_VAL"
        return 0;
    fi
     
    if [ -z "$PKG_URL" ]; then
        echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m" 
        return -1;
    fi
     
    wget -c "$PKG_URL";
    PKG_VAR_VAL=$(ls -d $PKG_MATCH_EXPR);
     
    if [ -z "$PKG_VAR_VAL" ]; then
        echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m" 
        return -1;
    fi
     
    echo "$PKG_VAR_VAL";
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
echo "WORKING_DIR = $WORKING_DIR";
echo "PREFIX_DIR = $PREFIX_DIR";
echo "BUILD_TARGET_COMPOMENTS = $BUILD_TARGET_COMPOMENTS";
echo "BUILD_LLVM_CONF_OPTION = $BUILD_LLVM_CONF_OPTION";
echo "BUILD_LLVM_CMAKE_OPTION = $BUILD_LLVM_CMAKE_OPTION";
echo "BUILD_OTHER_CONF_OPTION = $BUILD_OTHER_CONF_OPTION";
echo "CHECK_INFO_SLEEP = $CHECK_INFO_SLEEP";
echo "SYS_LONG_BIT = $SYS_LONG_BIT";
 
echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m"; 
sleep $CHECK_INFO_SLEEP
  
# ======================= 关闭交换分区，否则就爽死了 ======================= 
swapoff -a

export STAGE_BUILD_PREFIX_DIR="$PREFIX_DIR";
export STAGE_BUILD_CMAKE_OPTION="";

function build_llvm_toolchain() {
    STAGE_BUILD_EXT_CMAKE_OPTION="";
    if [ ! -z "$CC" ]; then
        STAGE_BUILD_EXT_CMAKE_OPTION="$STAGE_BUILD_EXT_CMAKE_OPTION -DCMAKE_C_COMPILER=$CC";
    fi
    if [ ! -z "$CXX" ]; then
        STAGE_BUILD_EXT_CMAKE_OPTION="$STAGE_BUILD_EXT_CMAKE_OPTION -DCMAKE_CXX_COMPILER=$CXX";
    fi

    # unpack llvm
    if [ "0" == $(is_in_list llvm $BUILD_TARGET_COMPOMENTS) ]; then
        LLVM_PKG=$(check_and_download "llvm" "llvm-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/llvm-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$LLVM_PKG";
            return -1;
        fi
        LLVM_SRC_DIR_NAME=$(ls -d llvm-* | grep -v \.tar\.xz);
        if [ -z "$LLVM_SRC_DIR_NAME" ]; then
            tar -axvf $LLVM_PKG;
            LLVM_SRC_DIR_NAME=$(ls -d llvm-* | grep -v \.tar\.xz);
        fi

        if [ "" == "$LLVM_SRC_DIR_NAME" ]; then
            echo -e "\\033[31;1mError: build llvm src dir not found.\\033[39;49;0m";
            exit -1;
        fi
        LLVM_DIR="$WORKING_DIR/$LLVM_SRC_DIR_NAME";
    fi

    # unpack clang
    if [ "0" == $(is_in_list clang $BUILD_TARGET_COMPOMENTS) ]; then
        CLANG_PKG=$(check_and_download "clang" "cfe-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/cfe-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$CLANG_PKG";
            exit -1;
        fi
        if [ ! -e "$LLVM_DIR/tools/clang" ]; then
            tar -axvf $CLANG_PKG;
            CLANG_DIR=$(ls -d cfe-* | grep -v \.tar\.xz);
            mv "$CLANG_DIR" "$LLVM_DIR/tools/clang";
        fi
    fi
    CLANG_DIR="$LLVM_DIR/tools/clang";

    # unpack clang tools extra
    if [ "0" == $(is_in_list clang_tools_extra $BUILD_TARGET_COMPOMENTS) ]; then
        CLANG_TOOLS_EXTRA_PKG=$(check_and_download "clang tools extra" "clang-tools-extra-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/clang-tools-extra-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$CLANG_TOOLS_EXTRA_PKG";
            exit -1;
        fi
        
        if [ ! -e "$CLANG_DIR/tools/extra" ]; then
            tar -axvf $CLANG_TOOLS_EXTRA_PKG;
            CLANG_TOOLS_EXTRA_DIR=$(ls -d clang-tools-extra-* | grep -v \.tar\.xz);
            mv "$CLANG_TOOLS_EXTRA_DIR" "$CLANG_DIR/tools/extra";
        fi
        
        if [ ! -e "$CLANG_DIR/tools/extra" ]; then
            echo -e "\\033[31;1mclang src not found but clang tools extra enabled.\\033[39;49;0m";
            exit -1;
        fi
    fi
    CLANG_TOOLS_EXTRA_DIR="$CLANG_DIR/tools/extra";

    # unpack compiler rt
    if [ "0" == $(is_in_list compiler_rt $BUILD_TARGET_COMPOMENTS) ]; then
        COMPILER_RT_PKG=$(check_and_download "compiler rt" "compiler-rt-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/compiler-rt-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$COMPILER_RT_PKG";
            exit -1;
        fi

        if [ ! -e "$LLVM_DIR/projects/compiler-rt" ]; then
            tar -axvf $COMPILER_RT_PKG;
            COMPILER_RT_DIR=$(ls -d compiler-rt-* | grep -v \.tar\.xz);
            mv "$COMPILER_RT_DIR" "$LLVM_DIR/projects/compiler-rt";
        fi
        
        if [ ! -e "$LLVM_DIR/projects/compiler-rt" ]; then
            echo -e "\\033[31;1mcompiler-rt src not found but compiler-rt enabled.\\033[39;49;0m";
            exit -1;
        fi
    fi
    COMPILER_RT_DIR="$LLVM_DIR/projects/compiler-rt";

    # unpack libcxxabi
    if [ "0" == $(is_in_list libcxxabi $BUILD_TARGET_COMPOMENTS) ]; then
        LIBCXXABI_PKG=$(check_and_download "libc++abi" "libcxxabi-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/libcxxabi-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$LIBCXXABI_PKG";
            exit -1;
        fi
        
        if [ ! -e "$LLVM_DIR/projects/libcxxabi" ]; then
            tar -axvf $LIBCXXABI_PKG;
            LIBCXXABI_DIR=$(ls -d libcxxabi-* | grep -v \.tar\.xz);
            mv "$LIBCXXABI_DIR" "$LLVM_DIR/projects/libcxxabi";
        fi

        # STAGE_BUILD_EXT_CMAKE_OPTION="$STAGE_BUILD_EXT_CMAKE_OPTION -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$LLVM_DIR/projects/libcxxabi/include";
    fi

    # unpack libcxx
    if [ "0" == $(is_in_list libcxx $BUILD_TARGET_COMPOMENTS) ]; then
        LIBCXX_PKG=$(check_and_download "libc++" "libcxx-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/libcxx-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$LIBCXX_PKG";
            exit -1;
        fi

        if [ ! -e "$LLVM_DIR/projects/libcxx" ]; then
            tar -axvf $LIBCXX_PKG;
            LIBCXX_DIR=$(ls -d libcxx-* | grep -v \.tar\.xz);
            mv "$LIBCXX_DIR" "$LLVM_DIR/projects/libcxx";
        fi
    fi

    # unpack lld
    if [ "0" == $(is_in_list lld $BUILD_TARGET_COMPOMENTS) ]; then
        LLD_PKG=$(check_and_download "lld" "lld-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/lld-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$LLD_PKG";
            exit -1;
        fi

        if [ ! -e "$LLVM_DIR/tools/lld" ]; then
            tar -axvf $LLD_PKG;
            LLD_DIR=$(ls -d lld-* | grep -v \.tar\.xz);
            mv "$LLD_DIR" "$LLVM_DIR/tools/lld";
        fi
        
        if [ ! -e "$LLVM_DIR/tools/lld" ]; then
            echo -e "\\033[31;1mlld src not found but lld enabled.\\033[39;49;0m";
            exit -1;
        fi
    fi
    LLD_DIR="$LLVM_DIR/tools/lld";

    # unpack polly (require gmp,cloog-isl)
    if [ "0" == $(is_in_list polly $BUILD_TARGET_COMPOMENTS) ] && [ -e /usr/bin/python2 ] && [ -e "$CLANG_DIR" ]; then
        POLLY_PKG=$(check_and_download "polly" "polly-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/polly-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$POLLY_PKG";
            exit -1;
        fi

        if [ ! -e "$LLVM_DIR/tools/polly" ]; then
            tar -axvf $POLLY_PKG;
            POLLY_DIR=$(ls -d polly-* | grep -v \.tar\.xz);
            mv "$POLLY_DIR" "$LLVM_DIR/tools/polly";
        fi
        
        if [ ! -e "$LLVM_DIR/tools/polly" ]; then
            echo -e "\\033[31;1mpolly src not found but polly enabled.\\033[39;49;0m";
        else
            STAGE_BUILD_EXT_CMAKE_OPTION="$STAGE_BUILD_EXT_CMAKE_OPTION -DPYTHON_EXECUTABLE=/usr/bin/python2";
        fi        
    fi
    POLLY_DIR="$LLVM_DIR/tools/polly";

    # ready to build 
    # if [ ! -e "$STAGE_BUILD_PREFIX_DIR/bin/llvm-config" ]; then
        cd "$LLVM_DIR";
        # clean build cache
        if [ -e build ]; then
            rm -rf build;
        fi
        mkdir -p build ;
        cd build ;
        cmake .. -DCMAKE_INSTALL_PREFIX=$STAGE_BUILD_PREFIX_DIR -DCMAKE_BUILD_TYPE=Release $BUILD_LLVM_LLVM_OPTION $STAGE_BUILD_CMAKE_OPTION $STAGE_BUILD_EXT_CMAKE_OPTION;
        if [ 0 -ne $? ]; then
            echo -e "\\033[31;1mError: build llvm $STAGE_BUILD_PREFIX_DIR failed when run cmake.\\033[39;49;0m";
            return $?;
        fi

        # 这里会消耗茫茫多内存，所以尝试先开启多进程编译，失败之后降级到单进程
        make -j4;
        make -j2;
        make;
        if [ 0 -ne $? ]; then
            echo -e "\\033[31;1mError: build llvm $STAGE_BUILD_PREFIX_DIR failed when run make.\\033[39;49;0m";
            return $?;
        fi

        # llvm script bug
        if [ ! -e "lib/python2.7" ]; then
            mkdir -p lib/python2.7 ;
        fi
        make install;
        if [ 0 -ne $? ]; then
            echo -e "\\033[31;1mError: build llvm $STAGE_BUILD_PREFIX_DIR failed when install.\\033[39;49;0m";
            return $?;
        fi

        # cd ..;
        # rm -rf build;
    # fi
    return 0 ;
}

build_llvm_toolchain ;
if [ ! -e "$STAGE_BUILD_PREFIX_DIR/bin/clang" ] || [ 0 -ne $?] ; then
    echo -e "\\033[31;1mError: build llvm $STAGE_BUILD_PREFIX_DIR failed on step 1.\\033[39;49;0m";
    exit 1;
fi
CXX_ABI_PATH=$(find "$STAGE_BUILD_PREFIX_DIR/include" -name "cxxabi.h");
if [ ! -z "$CXX_ABI_PATH" ]; then
    CXX_ABI_DIR=${CXX_ABI_PATH%%/cxxabi.h};
    # export LDFLAGS="$LDFLAGS -lc++ -lc++abi";
    export STAGE_BUILD_CMAKE_OPTION="$STAGE_BUILD_CMAKE_OPTION -DCMAKE_CXX_FLAGS=-stdlib=libc++ -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$CXX_ABI_DIR";
fi
export STAGE_BUILD_CMAKE_OPTION="$STAGE_BUILD_CMAKE_OPTION -DLLVM_TOOLS_BINARY_DIR=$STAGE_BUILD_PREFIX_DIR/bin";

# ================================== 自举编译使用的额外模块 ==================================
# unpack lldb
if [ "0" == $(is_in_list lldb $BUILD_TARGET_COMPOMENTS) ]; then
    which python2;
    LLDB_DEP_PYTHON2=$?;
    which swig;
    LLDB_DEP_SWIG=$?;
    LLDB_DEP_LIBEDIT=$(whereis libedit.* | awk '{print $2}');
    LLDB_DEP_LIBXML2=$(whereis libxml2.* | awk '{print $2}');
    LLDB_DEP_NCURSES=$(whereis libncurses.* | awk '{print $2}');
    if [ 0 -eq $LLDB_DEP_PYTHON2 ] && [ 0 -eq $LLDB_DEP_SWIG ] && [ ! -z "$LLDB_DEP_LIBEDIT" ] && [ ! -z "$LLDB_DEP_LIBXML2" ] && [ ! -z "$LLDB_DEP_NCURSES" ] ; then
        LLDB_PKG=$(check_and_download "lldb" "lldb-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/lldb-$LLVM_VERSION.src.tar.xz" );
        if [ $? -ne 0 ]; then
            echo -e "$LLDB_PKG";
            exit -1;
        fi

        if [ ! -e "$LLVM_DIR/tools/lldb" ]; then
            tar -axvf $LLDB_PKG;
            LLDB_DIR=$(ls -d lldb-* | grep -v \.tar\.xz);
            mv "$LLDB_DIR" "$LLVM_DIR/tools/lldb";
        fi
        
        if [ ! -e "$LLVM_DIR/tools/lldb" ]; then
            echo -e "\\033[31;1mlld src not found but lldb enabled.\\033[39;49;0m";
            exit -1;
        fi
    fi
fi
LLDB_DIR="$LLVM_DIR/tools/lldb";

# unpack libunwind
if [ "0" == $(is_in_list libunwind $BUILD_TARGET_COMPOMENTS) ]; then
    LIBUNWIND_PKG=$(check_and_download "libunwind" "libunwind-*.tar.xz" "http://llvm.org/releases/$LLVM_VERSION/libunwind-$LLVM_VERSION.src.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$LLDB_PKG";
        exit -1;
    fi

    LIBUNWIND_DIR=$(ls -d libunwind-* | grep -v \.tar\.xz);
    if [ -z "$LIBUNWIND_DIR" ]; then
        tar -axvf $LIBUNWIND_PKG;
        LIBUNWIND_DIR=$(ls -d libunwind-* | grep -v \.tar\.xz);
    fi
    if [ ! -z "$LIBUNWIND_DIR" ]; then
        export STAGE_BUILD_CMAKE_OPTION="$STAGE_BUILD_CMAKE_OPTION -DLLVM_EXTERNAL_LIBUNWIND_SOURCE_DIR=$PWD/$LIBUNWIND_DIR";
    fi
fi

# openmp 集成在clang内，略过
# llvm_test_suite 略过

# ================================== 环境覆盖 ==================================
export LD_LIBRARY_PATH=$STAGE_BUILD_PREFIX_DIR/lib:$LD_LIBRARY_PATH
export PATH=$STAGE_BUILD_PREFIX_DIR/bin:$PATH

echo "add $STAGE_BUILD_PREFIX_DIR/bin to PTAH";
echo "add $STAGE_BUILD_PREFIX_DIR/lib to LD_LIBRARY_PATH";

export CC=$STAGE_BUILD_PREFIX_DIR/bin/clang ;
export CXX=$STAGE_BUILD_PREFIX_DIR/bin/clang++ ;

# 自举编译， 脱离对gcc的依赖
# export STAGE_BUILD_PREFIX_DIR="$PREFIX_DIR";
build_llvm_toolchain ;

if [ ! -e "$PREFIX_DIR/bin/clang" ] ; then
    echo -e "\\033[31;1mError: build llvm $STAGE_BUILD_PREFIX_DIR failed on step 2.\\033[39;49;0m";
    exit 1;
fi

LLVM_CONFIG_PATH="$PREFIX_DIR/bin/llvm-config";
echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m";
echo -e "\\033[31;1mexport PATH=$($LLVM_CONFIG_PATH --bindir):$PATH\\033[39;49;0m";
echo -e "\\033[33;1mBuild LLVM done.\\033[39;49;0m";
echo "";
echo -e "\\033[32;1mSample flags to build exectable file:.\\033[39;49;0m";
echo -e "\\033[35;1m\tCC=$STAGE_BUILD_PREFIX_DIR/bin/clang\\033[39;49;0m";
echo -e "\\033[35;1m\tCXX=$STAGE_BUILD_PREFIX_DIR/bin/clang++\\033[39;49;0m";
echo -e "\\033[35;1m\tCFLAGS=$($LLVM_CONFIG_PATH --cflags) -std=libc++\\033[39;49;0m";
if [ ! -z "$(find $($LLVM_CONFIG_PATH --libdir) -name libc++abi.so)" ]; then
    echo -e "\\033[35;1m\tCXXFLAGS=$($LLVM_CONFIG_PATH --cxxflags) -std=libc++\\033[39;49;0m";
    echo -e "\\033[35;1m\tLDFLAGS=$($LLVM_CONFIG_PATH --ldflags) -lc++ -lc++abi\\033[39;49;0m";
else
    echo -e "\\033[35;1m\tCXXFLAGS=$($LLVM_CONFIG_PATH --cxxflags)\\033[39;49;0m";
    echo -e "\\033[35;1m\tLDFLAGS=$($LLVM_CONFIG_PATH --ldflags)\\033[39;49;0m";
fi 
