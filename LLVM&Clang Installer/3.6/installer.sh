#!/bin/bash

# Dependency: swig libedit Python

# ======================================= 配置 ======================================= 
PREFIX_DIR=/usr/local/llvm-3.6.0
BUILD_TARGET_COMPOMENTS="llvm clang compiler_rt libcxx libcxxabi lldb clang_tools_extra";
BUILD_GCC="gcc-4.6";

# ======================= 非交叉编译 ======================= 
BUILD_LLVM_CONF_OPTION="--enable-optimized --disable-assertions";
BUILD_LLVM_CMAKE_OPTION="-DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_PIC=ON"; #  -DBUILD_SHARED_LIBS=ON";
BUILD_OTHER_CONF_OPTION="";
 
# ======================= 交叉编译配置示例(暂不可用) ======================= 
  
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
            echo "-t [build target]           set build target(llvm clang compiler_rt libcxx libcxxabi lldb lld polly openmp clang_tools_extra llvm_test_suite)."; # dragonegg safecode 
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
 
# ======================= 转到脚本目录 ======================= 
WORKING_DIR="$PWD";

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 ======================= 
SYS_LONG_BIT=$(getconf LONG_BIT);
 
# ======================= 检测CPU数量，编译线程数不能大于CPU数量的2倍，否则可能出问题 ======================= 
BUILD_THREAD_OPT=1;
BUILD_CPU_NUMBER=$(cat /proc/cpuinfo | grep -c "^processor[[:space:]]*:[[:space:]]*[0-9]*");
BUILD_THREAD_OPT=$(($BUILD_CPU_NUMBER));
if [ $BUILD_THREAD_OPT -gt 4 ]; then
    BUILD_THREAD_OPT=4;
fi
BUILD_THREAD_OPT="-j$BUILD_THREAD_OPT";
echo -e "\\033[32;1mnotice: $BUILD_CPU_NUMBER cpu(s) detected. use $BUILD_THREAD_OPT for multi-thread compile.";
 
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
echo "BUILD_CPU_NUMBER = $BUILD_CPU_NUMBER";
echo "BUILD_THREAD_OPT = $BUILD_THREAD_OPT";
echo "SYS_LONG_BIT = $SYS_LONG_BIT";
 
echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m"; 
sleep $CHECK_INFO_SLEEP
  
# ======================= 关闭交换分区，否则就爽死了 ======================= 
swapoff -a
 
# unpack llvm
if [ "0" == $(is_in_list llvm $BUILD_TARGET_COMPOMENTS) ]; then
    LLVM_PKG=$(check_and_download "llvm" "llvm-*.tar.xz" "http://llvm.org/releases/3.6.0/llvm-3.6.0.src.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$LLVM_PKG";
        exit -1;
    fi
    tar -axvf $LLVM_PKG;
fi
LLVM_SRC_DIR_NAME=$(ls -d llvm-* | grep -v \.tar\.xz);

if [ "" == "$LLVM_SRC_DIR_NAME" ]; then
	echo -e "\\033[31;1mError: build llvm src dir not found.\\033[39;49;0m";
	exit -1;
fi
LLVM_DIR="$WORKING_DIR/$LLVM_SRC_DIR_NAME";

# unpack clang
if [ "0" == $(is_in_list clang $BUILD_TARGET_COMPOMENTS) ]; then
    CLANG_PKG=$(check_and_download "clang" "cfe-*.tar.xz" "http://llvm.org/releases/3.6.0/cfe-3.6.0.src.tar.xz" );
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
    CLANG_TOOLS_EXTRA_PKG=$(check_and_download "clang tools extra" "clang-tools-extra-*.tar.xz" "http://llvm.org/releases/3.6.0/clang-tools-extra-3.6.0.src.tar.xz" );
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
    COMPILER_RT_PKG=$(check_and_download "compiler rt" "compiler-rt-*.tar.xz" "http://llvm.org/releases/3.6.0/compiler-rt-3.6.0.src.tar.xz" );
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

LLVM_BUILD_DIR="$WORKING_DIR/llvm_build_dir";

function build_llvm() {
	if [ -e "$LLVM_BUILD_DIR" ]; then
		rm -rf "$LLVM_BUILD_DIR";
	fi

	MAKE_TOOLS="$1";
	shift;
	STAGE_STEP_NAME="$1";
	shift;
	
	mkdir -p "$LLVM_BUILD_DIR";
	cd "$LLVM_BUILD_DIR";
	echo -e "\\033[32;1m$STAGE_STEP_NAME: start to build llvm\\033[39;49;0m";
	
	for any_file in $(ls *); do
		echo "remove old cache file $any_file";
		rm -rf $any_file;
	done
	
	# llvm 源码有bug，会导致开启exception时编译通不过，所以修正一下 
	# perl -p -i -e "s;::name\(\)\s*const\s*[{];::name\(\) const LLVM_NOEXCEPT {;g" $(find "$LLVM_DIR" -name Error.cpp);

    CLANG_PREFIX_FLAGS="";
    if [ ! -z "$LLD_PKG" ]; then
        CLANG_PREFIX_FLAGS="$CLANG_PREFIX_FLAGS LD=lld";
    fi
            
	sleep 1;
	if [ "${MAKE_TOOLS}" == "cmake" ]; then
		cmake $LLVM_DIR -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR $BUILD_LLVM_CMAKE_OPTION $@;
	elif [ "${MAKE_TOOLS}" == "cmake_clang" ]; then
		CC=clang CXX=clang++ CXXFLAGS="-stdlib=libc++ -lc++abi -fPIC" CFLAGS="-fPIC" cmake $LLVM_DIR -D_CMAKE_TOOLCHAIN_PREFIX=llvm- -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$PREFIX_DIR $BUILD_LLVM_CMAKE_OPTION $@;
	elif [ "${MAKE_TOOLS}" == "automake_clang" ]; then
		CC=clang CXX=clang++ CXXFLAGS="-stdlib=libc++ -lc++abi -fPIC" CFLAGS="-fPIC" ../$LLVM_SRC_DIR_NAME/configure --prefix=$PREFIX_DIR $BUILD_LLVM_CONF_OPTION $@;
	else
		../$LLVM_SRC_DIR_NAME/configure --prefix=$PREFIX_DIR $BUILD_LLVM_CONF_OPTION $@;
	fi 

    make clean;    
	make $BUILD_THREAD_OPT;
	
	# 这也是llvm的install脚本写得2b才加的hack
	mkdir -p lib/python2.7;
	
	make install;
	if [ $? -ne 0 ]; then
	    echo -e "\\033[31;1mError: build llvm failed in $STAGE_STEP_NAME.\\033[39;49;0m";
	    exit -1;
	fi
	cd "$WORKING_DIR";
}

# unpack lld
if [ "0" == $(is_in_list lld $BUILD_TARGET_COMPOMENTS) ]; then
    LLD_PKG=$(check_and_download "lld" "lld-*.tar.xz" "http://llvm.org/releases/3.6.0/lld-3.6.0.src.tar.xz" );
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
if [ "0" == $(is_in_list polly $BUILD_TARGET_COMPOMENTS) ]; then
    POLLY_PKG=$(check_and_download "polly" "polly-*.tar.xz" "http://llvm.org/releases/3.6.0/polly-3.6.0.src.tar.xz" );
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
    	exit -1;
	fi
	
	export BASE=$WORKING_DIR;
	export LLVM_SRC=$LLVM_DIR;
	export POLLY_SRC=$LLVM_DIR/tools/polly;
	
	export CLANG_SRC=$CLANG_DIR;
	
	# install gmp
	# install cloog
	export CLOOG_SRC=$BASE/cloog_src;
	export CLOOG_INSTALL=$PREFIX_DIR;
	
	$POLLY_SRC/utils/checkout_cloog.sh $CLOOG_SRC;
	cd $CLOOG_SRC;
	./configure --prefix=$CLOOG_INSTALL;
	make $BUILD_THREAD_OPT;
	make install;
	if [ $? -ne 0 ]; then
	    echo -e "\\033[31;1mError: build cloog failed in polly.\\033[39;49;0m";
	    exit -1;
	fi
	cd "$WORKING_DIR";
	
	export LLVM_BUILD=$LLVM_BUILD_DIR;
fi
POLLY_DIR="$LLVM_DIR/tools/polly";

# openmp 集成在clang内，略过
# llvm_test_suite 略过

# build dragonegg
if [ ! -z "$BUILD_GCC" ] && [ "0" == $(is_in_list dragonegg $BUILD_TARGET_COMPOMENTS) ]; then
    DRAGONEGG_PKG=$(check_and_download "dragonegg" "dragonegg-*.tar.xz" "http://llvm.org/releases/3.6.0/dragonegg-3.6.0.src.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$DRAGONEGG_PKG";
        exit -1;
    fi

	tar -axvf $DRAGONEGG_PKG;
    DRAGONEGG_DIR=$(ls -d dragonegg-* | grep -v \.tar\.xz);
    mv "$DRAGONEGG_DIR" "$LLVM_DIR/projects/dragonegg";
fi


# unpack libcxx
if [ ! -e "$LLVM_DIR/projects/libcxx" ] && [ "0" == $(is_in_list libcxx $BUILD_TARGET_COMPOMENTS) ]; then
    if [ -e "$LLVM_DIR/projects/libcxx" ]; then
	    return
	fi
    LIBCXX_PKG=$(check_and_download "libc++" "libcxx-*.tar.xz" "http://llvm.org/releases/3.6.0/libcxx-3.6.0.src.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$LIBCXX_PKG";
        exit -1;
    fi

	tar -axvf $LIBCXX_PKG;
	LIBCXX_DIR=$(ls -d libcxx-* | grep -v \.tar\.xz);
	mv "$LIBCXX_DIR" "$LLVM_DIR/projects/libcxx";
    LIBCXX_DIR="$LLVM_DIR/projects/libcxx";
fi

# unpack libcxxabi
if [ ! -e "$LLVM_DIR/projects/libcxxabi" ] && [ "0" == $(is_in_list libcxxabi $BUILD_TARGET_COMPOMENTS) ]; then
	if [ -e "$LLVM_DIR/projects/libcxxabi" ]; then
	    return
	fi
	
    LIBCXXABI_PKG=$(check_and_download "libc++abi" "libcxxabi-*.tar.xz" "http://llvm.org/releases/3.6.0/libcxxabi-3.6.0.src.tar.xz" );
    if [ $? -ne 0 ]; then
        echo -e "$LIBCXXABI_PKG";
        exit -1;
    fi
    
    tar -axvf $LIBCXXABI_PKG;
    LIBCXXABI_DIR=$(ls -d libcxxabi-* | grep -v \.tar\.xz);
	mv "$LIBCXXABI_DIR" "$LLVM_DIR/projects/libcxxabi";
    LIBCXXABI_DIR="$LLVM_DIR/projects/libcxxabi";
fi


## unpack lldb, gcc 编译不过，所以clang编译好后用clang编译
if [ "0" == $(is_in_list lldb $BUILD_TARGET_COMPOMENTS) ]; then
    LLDB_PKG=$(check_and_download "lldb" "lldb-*.tar.xz" "http://llvm.org/releases/3.6.0/lldb-3.6.0.src.tar.xz" );
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
    	echo -e "\\033[31;1mlldb src not found but lldb enabled.\\033[39;49;0m";
    	exit -1;
	fi
fi
LLDB_DIR="$LLVM_DIR/tools/lldb";

# 初始包准备完毕-开始第一次编译
# Stage 1 -- compiling llvm & clang using gcc
echo -e "\\033[31;1mStage 1: Ready to compile llvm, clang and etc. using gcc.\\033[39;49;0m";
 build_llvm "cmake" "Stage 1"; # -DLLVM_ENABLE_LIBCXX=ON;

# 编译 libcxx 和libcxxabi
export LD_LIBRARY_PATH=$PREFIX_DIR/lib:$LD_LIBRARY_PATH
export PATH=$PREFIX_DIR/bin:$PATH

echo "add $PREFIX_DIR/bin to PTAH";
echo "add $PREFIX_DIR/lib to LD_LIBRARY_PATH";

# Stage 2 -- compiling tools
# echo -e "\\033[31;1mStage 2: Ready to compile tools. using llvm & clang.\\033[39;49;0m";
# build_llvm "cmake_clang" "Stage 2" -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DLLVM_ENABLE_LIBCXX=ON;

# Stage 3 -- self compiling
# 阶段三  -- 自举编译，这样就能脱离对gcc的依赖(貌似这步结束以后llvm和clang仍然依赖c++，不过libcxx和libcxxabi不依赖了)
# libcxx 和 libcxxabi准备完毕-开始第二次编译
echo -e "\\033[31;1mStage 3: Ready to compile tools. using llvm & clang & libcxx & libcxxabi.\\033[39;49;0m";
build_llvm "cmake_clang" "Stage 3" -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DLLVM_ENABLE_LIBCXX=ON -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBCXXABI_INCLUDE_PATHS="$PREFIX_DIR/include/c++/v1" -DLIBCXX_CXX_ABI_LIBRARY_PATH="$PREFIX_DIR/lib" -DLLVM_TOOLS_BINARY_DIR="$PREFIX_DIR/bin";

echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m"
echo -e "\\033[31;1mexport PATH=$PREFIX_DIR/bin:$PATH\\033[39;49;0m"
echo -e "\\033[31;1mexport LD_LIBRARY_PATH=$PREFIX_DIR/lib:$LD_LIBRARY_PATH\\033[39;49;0m"
echo -e "\tor you can add $PREFIX_DIR/lib to file [/etc/ld.so.conf] and then run [ldconfig]"
echo -e "\\033[33;1mBuild LLVM done.\\033[39;49;0m"
