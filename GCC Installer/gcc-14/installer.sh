#!/bin/bash

# ======================================= 配置 =======================================
BUILD_TARGET_COMPOMENTS=""
COMPOMENTS_M4_VERSION=latest
COMPOMENTS_MAKE_VERSION=4.4.1
COMPOMENTS_AUTOCONF_VERSION=latest
COMPOMENTS_AUTOMAKE_VERSION=1.17
COMPOMENTS_LIBTOOL_VERSION=2.4.7
COMPOMENTS_PKGCONFIG_VERSION=0.29.2
COMPOMENTS_GMP_VERSION=6.3.0
COMPOMENTS_MPFR_VERSION=4.2.1
COMPOMENTS_MPC_VERSION=1.3.1
COMPOMENTS_ISL_VERSION=0.24
COMPOMENTS_LIBATOMIC_OPS_VERSION=7.8.2
COMPOMENTS_BDWGC_VERSION=8.2.6
COMPOMENTS_GCC_VERSION=14.2.0
COMPOMENTS_INTERNAL_GLIBC_VERSION=2.38
COMPOMENTS_BISON_VERSION=3.8.2
# binutils 2.40+ add --with-zstd=$INSTALL_PREFIX_PATH, maybe need env CXXFLAGS="-fpermissive"
COMPOMENTS_BINUTILS_STAGE1_VERSION=2.41
COMPOMENTS_BINUTILS_VERSION=2.43
COMPOMENTS_OPENSSL_VERSION=3.1.5
COMPOMENTS_ZLIB_VERSION=1.3.1
COMPOMENTS_LIBFFI_VERSION=3.4.6
COMPOMENTS_NCURSES_VERSION=6.5
COMPOMENTS_LIBEXPAT_VERSION=2.6.2
COMPOMENTS_LIBXCRYPT_VERSION=4.4.36
COMPOMENTS_GDBM_VERSION=latest
COMPOMENTS_READLINE_VERSION=8.2
# distcc 3.4 use distutils which is removed from python 3.12.2, we use python 3.11 by now
COMPOMENTS_PYTHON_VERSION=3.11.9
COMPOMENTS_GDB_VERSION=15.1 # Previous 14.2
COMPOMENTS_GLOBAL_VERSION=6.6.13
COMPOMENTS_LIBICONV_VERSION=1.17
COMPOMENTS_XZ_VERSION=5.6.2
COMPOMENTS_ZSTD_VERSION=1.5.6
COMPOMENTS_LZ4_VERSION=1.10.0
# 大多数发行版并没有开启 libssp , 开启会导致需要增加链接选项 -fstack-protector-all
# 为了兼容性考虑我们默认也不开
if [[ "x$COMPOMENTS_LIBSSP_ENABLE" == "x" ]]; then
  COMPOMENTS_LIBSSP_ENABLE=0
fi

if [[ "owent$COMPOMENTS_GDB_STATIC_BUILD" == "owent" ]]; then
  COMPOMENTS_GDB_STATIC_BUILD=0
fi

if [[ -z "$REPOSITORY_MIRROR_URL_GNU" ]]; then
  REPOSITORY_MIRROR_URL_GNU="https://ftp.gnu.org/gnu"
  # REPOSITORY_MIRROR_URL_GNU=http://mirrors.tencent.com/gnu
fi
if [[ -z "$REPOSITORY_MIRROR_URL_GITHUB" ]]; then
  REPOSITORY_MIRROR_URL_GITHUB="https://github.com"
  # REPOSITORY_MIRROR_URL_GITHUB=https://mirrors.tencent.com/github.com
fi

PREFIX_DIR=/usr/local/gcc-$COMPOMENTS_GCC_VERSION
# ======================= 非交叉编译 =======================
BUILD_TARGET_CONF_OPTION=""
BUILD_OTHER_CONF_OPTION=""
BUILD_DOWNLOAD_ONLY=0
BUILD_LDFLAGS="-Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"
# See https://stackoverflow.com/questions/42344932/how-to-include-correctly-wl-rpath-origin-linker-argument-in-a-makefile
if [[ "owent$LDFLAGS" == "owent" ]]; then
  export LDFLAGS="$BUILD_LDFLAGS"
else
  export LDFLAGS="$LDFLAGS $BUILD_LDFLAGS"
fi
export ORIGIN='$ORIGIN'
if [[ -z "$BUILD_WITH_INTERNAL_GLIBC" ]]; then
  BUILD_WITH_INTERNAL_GLIBC=0
fi

# ======================= 交叉编译配置示例(暂不可用) =======================
# BUILD_TARGET_CONF_OPTION="--target=arm-linux --enable-multilib --enable-interwork --disable-shared"
# BUILD_OTHER_CONF_OPTION="--disable-shared"

# ======================================= 检测 =======================================

# ======================= 检测完后等待时间 =======================
CHECK_INFO_SLEEP=3

# ======================= 安装目录初始化/工作目录清理 =======================
while getopts "dp:cht:u:g:ln" OPTION; do
  case $OPTION in
    p)
      PREFIX_DIR="$OPTARG"
      ;;
    c)
      rm -rf $(ls -A -d -p * | grep -E "(.*)/$" | grep -v "addition/")
      echo -e "\\033[32;1mnotice: clear work dir(s) done.\\033[39;49;0m"
      exit 0
      ;;
    d)
      BUILD_DOWNLOAD_ONLY=1
      echo -e "\\033[32;1mDownload mode.\\033[39;49;0m"
      ;;
    h)
      echo "usage: $0 [options] -p=prefix_dir -c -h"
      echo "options:"
      echo "-p [prefix_dir]             set prefix directory."
      echo "-c                          clean build cache."
      echo "-d                          download only."
      echo "-h                          help message."
      echo "-t [build target]           set build target(m4 autoconf automake libtool pkgconfig gmp mpfr mpc isl xz zstd lz4 zlib libiconv libffi gcc bison binutils make openssl readline ncurses libexpat libxcrypt gdbm gdb libatomic_ops bdw-gc global)."
      echo "-u [compoment option]       add dependency compoments build options."
      echo "-g [gnu option]             add gcc,binutils,gdb build options."
      echo "-n                          print toolchain version and exit."
      exit 0
      ;;
    t)
      BUILD_TARGET_COMPOMENTS="$BUILD_TARGET_COMPOMENTS $OPTARG"
      ;;
    u)
      BUILD_OTHER_CONF_OPTION="$BUILD_OTHER_CONF_OPTION $OPTARG"
      ;;
    g)
      BUILD_TARGET_CONF_OPTION="$BUILD_TARGET_CONF_OPTION $OPTARG"
      ;;
    l)
      BUILD_WITH_INTERNAL_GLIBC=1
      ;;
    n)
      echo $COMPOMENTS_GCC_VERSION
      exit 0
      ;;
    ?) #当有不认识的选项的时候arg为?
      echo "unkonw argument detected"
      exit 1
      ;;
  esac
done

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  mkdir -p "$PREFIX_DIR"
  PREFIX_DIR="$(cd "$PREFIX_DIR" && pwd)"
fi

# ======================= 转到脚本目录 =======================
WORKING_DIR="$PWD"
if [[ -z "$CC" ]]; then
  export CC=gcc
  export CXX=g++
fi

PREFIX_BASE_NAME="$(basename "$PREFIX_DIR")"
BUILD_STAGE1_LIBRARY_PREFIX="$WORKING_DIR/stage1-$PREFIX_BASE_NAME-library"
BUILD_STAGE1_TOOLS_PREFIX="$WORKING_DIR/stage1-$PREFIX_BASE_NAME-tools"
BUILD_STAGE1_GCC_PREFIX="$WORKING_DIR/stage1-$PREFIX_BASE_NAME-gcc"

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 =======================
SYS_LONG_BIT=$(getconf LONG_BIT)
GCC_OPT_DISABLE_MULTILIB=""
if [[ $SYS_LONG_BIT == "64" ]]; then
  GCC_OPT_DISABLE_MULTILIB="--disable-multilib"
  echo "int main() { return 0; }" >conftest.c
  $CC -m32 -o conftest ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} conftest.c >/dev/null 2>&1
  if test $? = 0; then
    echo -e "\\033[32;1mnotice: check 32 bit build test success, multilib enabled.\\033[39;49;0m"
    GCC_OPT_DISABLE_MULTILIB="--enable-multilib"
    rm -f conftest
  else
    echo -e "\\033[32;1mwarning: check 32 bit build test failed, --disable-multilib is added when build gcc.\\033[39;49;0m"
    let CHECK_INFO_SLEEP=$CHECK_INFO_SLEEP+1
  fi
  rm -f conftest.c
fi

# ======================= 如果强制开启，则开启 =======================
if [[ ! -z "$GCC_OPT_DISABLE_MULTILIB" ]] && [[ "$GCC_OPT_DISABLE_MULTILIB"=="--disable-multilib" ]]; then
  for opt in $BUILD_TARGET_CONF_OPTION; do
    if [[ "$opt" == "--enable-multilib" ]]; then
      echo -e "\\033[32;1mwarning: 32 bit build test failed, but --enable-multilib enabled in GCC_OPT_DISABLE_MULTILIB.\\033[39;49;0m"
      GCC_OPT_DISABLE_MULTILIB=""
      break
    fi
    echo $f
  done
fi

# ======================= 检测CPU数量，编译线程数按CPU核心数来 =======================
BUILD_THREAD_OPT=6
BUILD_CPU_NUMBER=$(cat /proc/cpuinfo | grep -c "^processor[[:space:]]*:[[:space:]]*[0-9]*")
BUILD_THREAD_OPT=$BUILD_CPU_NUMBER
if [[ $BUILD_THREAD_OPT -gt 6 ]]; then
  BUILD_THREAD_OPT=$(($BUILD_CPU_NUMBER - 1))
fi
BUILD_THREAD_OPT="-j$BUILD_THREAD_OPT"
# BUILD_THREAD_OPT="";
echo -e "\\033[32;1mnotice: $BUILD_CPU_NUMBER cpu(s) detected. use $BUILD_THREAD_OPT for multi-process compile."

# ======================= 统一的包检查和下载函数 =======================
function check_and_download() {
  PKG_NAME="$1"
  PKG_MATCH_EXPR="$2"
  PKG_URL="$3"

  PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"))
  if [[ ${#PKG_VAR_VAL[@]} -gt 0 ]]; then
    echo "${PKG_VAR_VAL[0]}"
    return 0
  fi

  if [[ -z "$PKG_URL" ]]; then
    echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m"
    return 1
  fi

  if [[ -z "$4" ]]; then
    OUTPUT_FILE="$(basename "$PKG_URL")"
  else
    OUTPUT_FILE="$4"
  fi

  DOWNLOAD_SUCCESS=1
  for ((i = 0; i < 5; ++i)); do
    if [[ $DOWNLOAD_SUCCESS -eq 0 ]]; then
      break
    fi
    DOWNLOAD_SUCCESS=0
    if [[ $i -ne 0 ]]; then
      echo "Retry to download from $PKG_URL to $OUTPUT_FILE again."
      sleep $i || true
    fi
    curl -kL "$PKG_URL" -o "$OUTPUT_FILE" || DOWNLOAD_SUCCESS=1
  done

  if [[ $DOWNLOAD_SUCCESS -ne 0 ]]; then
    echo -e "\\033[31;1mDownload $PKG_NAME from $PKG_URL failed.\\033[39;49;0m"
    rm -f "$OUTPUT_FILE" || true
    return $DOWNLOAD_SUCCESS
  fi

  PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"))

  if [[ ${#PKG_VAR_VAL} -eq 0 ]]; then
    echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m"
    return 1
  fi

  echo "${PKG_VAR_VAL[0]}"
}

# ======================= 列表检查函数 =======================
function is_in_list() {
  ele="$1"
  shift

  for i in $*; do
    if [[ "$ele" == "$i" ]]; then
      echo 0
      exit 0
    fi
  done

  echo 1
  exit 1
}

# ======================================= 搞起 =======================================
echo -e "\\033[31;1mcheck complete.\\033[39;49;0m"

# ======================= 准备环境, 把库和二进制目录导入，否则编译会找不到库或文件 =======================
BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
BUILD_BACKUP_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"

export PATH=$BUILD_STAGE1_GCC_PREFIX/bin:$BUILD_STAGE1_LIBRARY_PREFIX/bin:$BUILD_STAGE1_TOOLS_PREFIX/bin:$PATH
echo -e "\\033[32;1mNotice: reset env PATH=$PATH\\033[39;49;0m"

echo "WORKING_DIR                 = $WORKING_DIR"
echo "BUILD_STAGE1_LIBRARY_PREFIX = $BUILD_STAGE1_LIBRARY_PREFIX"
echo "BUILD_STAGE1_TOOLS_PREFIX   = $BUILD_STAGE1_TOOLS_PREFIX"
echo "BUILD_STAGE1_GCC_PREFIX     = $BUILD_STAGE1_GCC_PREFIX"
echo "PREFIX_DIR                  = $PREFIX_DIR"
echo "PKG_CONFIG_PATH             = $PKG_CONFIG_PATH"
echo "BUILD_TARGET_CONF_OPTION    = $BUILD_TARGET_CONF_OPTION"
echo "BUILD_OTHER_CONF_OPTION     = $BUILD_OTHER_CONF_OPTION"
echo "CHECK_INFO_SLEEP            = $CHECK_INFO_SLEEP"
echo "BUILD_CPU_NUMBER            = $BUILD_CPU_NUMBER"
echo "BUILD_THREAD_OPT            = $BUILD_THREAD_OPT"
echo "GCC_OPT_DISABLE_MULTILIB    = $GCC_OPT_DISABLE_MULTILIB"
echo "SYS_LONG_BIT                = $SYS_LONG_BIT"
echo "CC                          = $CC"
echo "CXX                         = $CXX"

echo -e "\\033[32;1mNotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m"
sleep $CHECK_INFO_SLEEP

# ======================= 关闭交换分区，否则就爽死了 =======================
swapoff -a
set -x

function cleanup_configure_cache() {
  if [[ -e "config.status" ]]; then
    make distclean || true
    if [[ $# -gt 0 ]]; then
      find "$1" -name config.cache | xargs -r rm || true
    else
      find . -name config.cache | xargs -r rm || true
    fi
  fi
  if [[ -e "Makefile" ]] || [[ -e "makefile" ]]; then
    make clean || true
  fi
}

# install m4
function build_m4() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS=""
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list m4 $BUILD_TARGET_COMPOMENTS) ]]; then
    M4_PKG=$(check_and_download "m4" "m4-*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/m4/m4-${COMPOMENTS_M4_VERSION}.tar.gz")
    if [ $? -ne 0 ]; then
      echo -e "$M4_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $M4_PKG
      M4_DIR=$(ls -d m4-* | grep -v \.tar\.gz)
      cd $M4_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        ./configure --prefix=$INSTALL_PREFIX_PATH --enable-c++ $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' || make O='$$$$O'
      make install
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build m4 failed.\\033[39;49;0m"
        # exit 1; # m4 is optional, maybe can use m4 on system
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install autoconf
function build_autoconf() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS=""
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list autoconf $BUILD_TARGET_COMPOMENTS) ]]; then
    AUTOCONF_PKG=$(check_and_download "autoconf" "autoconf-*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/autoconf/autoconf-${COMPOMENTS_AUTOCONF_VERSION}.tar.gz")
    if [ $? -ne 0 ]; then
      echo -e "$AUTOCONF_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $AUTOCONF_PKG
      AUTOCONF_DIR=$(ls -d autoconf-* | grep -v \.tar\.gz)
      cd $AUTOCONF_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build autoconf failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install automake
function build_automake() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS=""
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list automake $BUILD_TARGET_COMPOMENTS) ]]; then
    AUTOMAKE_PKG=$(check_and_download "automake" "automake-${COMPOMENTS_AUTOMAKE_VERSION}*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/automake/automake-${COMPOMENTS_AUTOMAKE_VERSION}.tar.gz")
    if [ $? -ne 0 ]; then
      echo -e "$AUTOMAKE_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $AUTOMAKE_PKG
      AUTOMAKE_DIR=$(ls -d automake-${COMPOMENTS_AUTOMAKE_VERSION}* | grep -v \.tar\.gz)
      cd $AUTOMAKE_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build automake failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install libtool
function build_libtool() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libtool $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBTOOL_PKG=$(check_and_download "libtool" "libtool-${COMPOMENTS_LIBTOOL_VERSION}*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/libtool/libtool-${COMPOMENTS_LIBTOOL_VERSION}.tar.gz")
    if [ $? -ne 0 ]; then
      echo -e "$LIBTOOL_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $LIBTOOL_PKG
      LIBTOOL_DIR=$(ls -d libtool-${COMPOMENTS_LIBTOOL_VERSION}* | grep -v \.tar\.gz)
      cd $LIBTOOL_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        ./configure --prefix=$INSTALL_PREFIX_PATH --with-pic=yes $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build libtool failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install pkgconfig
function build_pkgconfig() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list pkgconfig $BUILD_TARGET_COMPOMENTS) ]]; then
    PKGCONFIG_PKG=$(check_and_download "pkgconfig" "pkg-config-${COMPOMENTS_PKGCONFIG_VERSION}*.tar.gz" "https://pkg-config.freedesktop.org/releases/pkg-config-${COMPOMENTS_PKGCONFIG_VERSION}.tar.gz")
    if [ $? -ne 0 ]; then
      echo -e "$PKGCONFIG_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $PKGCONFIG_PKG
      PKGCONFIG_DIR=$(ls -d pkg-config-${COMPOMENTS_PKGCONFIG_VERSION}* | grep -v \.tar\.gz)
      cd $PKGCONFIG_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-pic=yes --with-internal-glib $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build pkgconfig failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install gmp
function build_gmp() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gmp $BUILD_TARGET_COMPOMENTS) ]]; then
    GMP_PKG=$(check_and_download "gmp" "gmp-$COMPOMENTS_GMP_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/gmp/gmp-$COMPOMENTS_GMP_VERSION.tar.xz")
    if [ $? -ne 0 ]; then
      echo -e "$GMP_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $GMP_PKG
      GMP_DIR=$(ls -d gmp-$COMPOMENTS_GMP_VERSION* | grep -v \.tar\.xz)
      cd $GMP_DIR
      cleanup_configure_cache

      env "CXXFLAGS=-fexceptions ${STAGE_CFLAGS}${CXXFLAGS}" \
        CFLAGS="${STAGE_CFLAGS}${CFLAGS}" \
        LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" \
        ./configure --prefix=$INSTALL_PREFIX_PATH --enable-cxx --enable-assert --with-pic=yes \
        $BUILD_OTHER_CONF_OPTION $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build gmp failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install mpfr
function build_mpfr() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list mpfr $BUILD_TARGET_COMPOMENTS) ]]; then
    MPFR_PKG=$(check_and_download "mpfr" "mpfr-$COMPOMENTS_MPFR_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/mpfr/mpfr-$COMPOMENTS_MPFR_VERSION.tar.xz")
    if [[ $? -ne 0 ]]; then
      echo -e "$MPFR_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $MPFR_PKG
      MPFR_DIR=$(ls -d mpfr-$COMPOMENTS_MPFR_VERSION* | grep -v \.tar\.xz)
      cd $MPFR_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-gmp=$INSTALL_PREFIX_PATH --enable-assert --with-pic=yes $BUILD_OTHER_CONF_OPTION $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build mpfr failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install mpc
function build_mpc() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list mpc $BUILD_TARGET_COMPOMENTS) ]]; then
    MPC_PKG=$(check_and_download "mpc" "mpc-$COMPOMENTS_MPC_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/mpc/mpc-$COMPOMENTS_MPC_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$MPC_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $MPC_PKG
      MPC_DIR=$(ls -d mpc-$COMPOMENTS_MPC_VERSION* | grep -v \.tar\.gz)
      cd $MPC_DIR
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-gmp=$INSTALL_PREFIX_PATH --with-mpfr=$INSTALL_PREFIX_PATH --with-pic=yes \
        $BUILD_OTHER_CONF_OPTION $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build mpc failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install isl
function build_isl() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list isl $BUILD_TARGET_COMPOMENTS) ]]; then
    ISL_PKG=$(check_and_download "isl" "isl-$COMPOMENTS_ISL_VERSION*.tar.bz2" "https://gcc.gnu.org/pub/gcc/infrastructure/isl-$COMPOMENTS_ISL_VERSION.tar.bz2")
    if [[ $? -ne 0 ]]; then
      echo -e "$ISL_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -jxvf $ISL_PKG
      ISL_DIR=$(ls -d isl-$COMPOMENTS_ISL_VERSION* | grep -v \.tar\.bz2)
      cd $ISL_DIR
      cleanup_configure_cache

      autoreconf -i
      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-gmp-prefix=$INSTALL_PREFIX_PATH --with-pic=yes $BUILD_OTHER_CONF_OPTION $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build isl failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install libatomic_ops
function build_libatomic_ops() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [ -z "$BUILD_TARGET_COMPOMENTS" ] || [ "0" == $(is_in_list libatomic_ops $BUILD_TARGET_COMPOMENTS) ]; then
    LIBATOMIC_OPS_PKG=$(check_and_download "libatomic_ops" "libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/ivmai/libatomic_ops/releases/download/v$COMPOMENTS_LIBATOMIC_OPS_VERSION/libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz" "libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$LIBATOMIC_OPS_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $LIBATOMIC_OPS_PKG
      LIBATOMIC_OPS_DIR=$(ls -d libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION* | grep -v \.tar\.gz)
      # cd $LIBATOMIC_OPS_DIR;
      # cleanup_configure_cache
      #
      # bash ./autogen.sh ;
      # env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
      #  --prefix=$INSTALL_PREFIX_PATH LDFLAGS="${LDFLAGS//\$/\$\$}" --with-pic=yes $STAGE_CONFIGURE_OPTIONS ;
      # make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O';
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build libatomic_ops failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install bdw-gc
function build_bdw_gc() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-shared=no --enable-static=yes "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS_M64="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
    STAGE_LDFLAGS_M32="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="--enable-shared=yes --enable-static=yes"
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS_M64="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
    STAGE_LDFLAGS_M32="-L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS_M64="$STAGE_LDFLAGS_M64 -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"
  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS_M32="$STAGE_LDFLAGS_M32 -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list bdw-gc $BUILD_TARGET_COMPOMENTS) ]]; then
    BDWGC_PKG=$(check_and_download "bdw-gc" "gc-$COMPOMENTS_BDWGC_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/ivmai/bdwgc/releases/download/v$COMPOMENTS_BDWGC_VERSION/gc-$COMPOMENTS_BDWGC_VERSION.tar.gz" "gc-$COMPOMENTS_BDWGC_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$BDWGC_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $BDWGC_PKG
      BDWGC_DIR=$(ls -d gc-$COMPOMENTS_BDWGC_VERSION* | grep -v \.tar\.gz)
      LIBATOMIC_OPS_DIR=$(ls -d libatomic_ops-$COMPOMENTS_LIBATOMIC_OPS_VERSION* | grep -v \.tar\.gz)

      cd $BDWGC_DIR
      if [[ ! -z "$LIBATOMIC_OPS_DIR" ]]; then
        if [[ -e libatomic_ops ]]; then
          rm -rf libatomic_ops
        fi
        mv -f ../$LIBATOMIC_OPS_DIR libatomic_ops
        $(cd libatomic_ops && bash ./autogen.sh)
        autoreconf -i
        BDWGC_LIBATOMIC_OPS=no
      else
        BDWGC_LIBATOMIC_OPS=check
      fi

      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS_M64}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH/multilib/$SYS_LONG_BIT --enable-cplusplus --with-pic=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS \
        $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build bdw-gc failed.\\033[39;49;0m"
        exit 1
      fi

      if [[ $SYS_LONG_BIT == "64" ]] && [[ "$GCC_OPT_DISABLE_MULTILIB" == "--enable-multilib" ]]; then
        cleanup_configure_cache

        env "CFLAGS=-m32 ${STAGE_CFLAGS}${CFLAGS}" "CXXFLAGS=-m32 ${STAGE_CFLAGS}${CXXFLAGS}" LDFLAGS="${STAGE_LDFLAGS_M32}${LDFLAGS//\$/\$\$}" ./configure \
          --prefix=$INSTALL_PREFIX_PATH/multilib/32 --enable-cplusplus --with-pic=yes --with-libatomic-ops=$BDWGC_LIBATOMIC_OPS \
          $STAGE_CONFIGURE_OPTIONS

        make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
        if [[ $? -ne 0 ]]; then
          echo -e "\\033[31;1mError: build bdw-gc with -m32 failed.\\033[39;49;0m"
          exit 1
        fi
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install zlib
function build_zlib() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=OFF "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=ON "
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list zlib $BUILD_TARGET_COMPOMENTS) ]]; then
    ZLIB_PKG=$(check_and_download "zlib" "zlib-$COMPOMENTS_ZLIB_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/madler/zlib/archive/refs/tags/v$COMPOMENTS_ZLIB_VERSION.tar.gz" "zlib-$COMPOMENTS_ZLIB_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$ZLIB_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $ZLIB_PKG
      ZLIB_DIR=$(ls -d zlib-$COMPOMENTS_ZLIB_VERSION* | grep -v \.tar\.gz)
      cd "$ZLIB_DIR"
      mkdir -p build_jobs_dir
      cd build_jobs_dir

      if [[ -e CMakeCache.txt ]]; then
        cmake --build . --target clean
        rm -f CMakeCache.txt
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake .. "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DBUILD_TESTING=OFF" "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_PATH" \
        "-DCMAKE_FIND_ROOT_PATH=$INSTALL_PREFIX_PATH" "-DCMAKE_PREFIX_PATH=$INSTALL_PREFIX_PATH" $STAGE_CONFIGURE_OPTIONS
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: configure zlib failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --build . $BUILD_THREAD_OPT
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build zlib failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --install . --prefix "$INSTALL_PREFIX_PATH"

      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: install zlib failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# install xz utils
function build_xz() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CONFIGURE_OPTIONS=""
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--disable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="--disable-static "
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list xz $BUILD_TARGET_COMPOMENTS) ]]; then
    XZ_PKG=$(check_and_download "xz" "xz-$COMPOMENTS_XZ_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/tukaani-project/xz/releases/download/v$COMPOMENTS_XZ_VERSION/xz-$COMPOMENTS_XZ_VERSION.tar.gz" "xz-$COMPOMENTS_XZ_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$XZ_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $XZ_PKG
      XZ_DIR=$(ls -d xz-$COMPOMENTS_XZ_VERSION* | grep -v \.tar\.gz)
      cd $XZ_DIR

      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-pic=yes $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build xz failed.\\033[39;49;0m"
        exit 1
      fi

      cd "$WORKING_DIR"
    fi
  fi
}

# install zstd
function build_zstd() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=OFF "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=ON "
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list zstd $BUILD_TARGET_COMPOMENTS) ]]; then
    ZSTD_PKG=$(check_and_download "zstd" "zstd-$COMPOMENTS_ZSTD_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/facebook/zstd/releases/download/v$COMPOMENTS_ZSTD_VERSION/zstd-$COMPOMENTS_ZSTD_VERSION.tar.gz" "zstd-$COMPOMENTS_ZSTD_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$ZSTD_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $ZSTD_PKG
      ZSTD_DIR=$(ls -d zstd-$COMPOMENTS_ZSTD_VERSION* | grep -v \.tar\.gz)
      cd $ZSTD_DIR
      mkdir -p build_jobs_dir
      cd build_jobs_dir

      if [[ -e CMakeCache.txt ]]; then
        cmake --build . --target clean
        rm -f CMakeCache.txt
      fi

      # Using -DCMAKE_INSTALL_LIBDIR=lib to keep the same output directory as configure settings
      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake ../build/cmake "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DZSTD_BUILD_TESTS=OFF" "-DZSTD_BUILD_CONTRIB=0" "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_PATH" \
        -DCMAKE_INSTALL_LIBDIR=lib \
        "-DCMAKE_FIND_ROOT_PATH=$INSTALL_PREFIX_PATH" "-DCMAKE_PREFIX_PATH=$INSTALL_PREFIX_PATH" $STAGE_CONFIGURE_OPTIONS
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: configure zstd failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --build . $BUILD_THREAD_OPT
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build zstd failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --install . --prefix "$INSTALL_PREFIX_PATH"

      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: install zstd failed.\\033[39;49;0m"
        exit 1
      fi

      cd "$WORKING_DIR"
    fi
  fi
}

# install lz4
function build_lz4() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=OFF "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="-DBUILD_SHARED_LIBS=ON "
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list lz4 $BUILD_TARGET_COMPOMENTS) ]]; then
    LZ4_PKG=$(check_and_download "lz4" "lz4-$COMPOMENTS_LZ4_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/lz4/lz4/archive/v$COMPOMENTS_LZ4_VERSION.tar.gz" "lz4-$COMPOMENTS_LZ4_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$LZ4_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $LZ4_PKG
      LZ4_DIR=$(ls -d lz4-$COMPOMENTS_LZ4_VERSION* | grep -v \.tar\.gz)
      cd $LZ4_DIR
      mkdir -p build_jobs_dir
      cd build_jobs_dir

      if [[ -e CMakeCache.txt ]]; then
        cmake --build . --target clean
        rm -f CMakeCache.txt
      fi

      # Using -DCMAKE_INSTALL_LIBDIR=lib to keep the same output directory as configure settings
      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake ../build/cmake "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DLZ4_POSITION_INDEPENDENT_LIB=ON" "-DLZ4_BUILD_CLI=ON" "-DLZ4_BUILD_LEGACY_LZ4C=ON" \
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX_PATH" "-DCMAKE_FIND_ROOT_PATH=$INSTALL_PREFIX_PATH" "-DCMAKE_PREFIX_PATH=$INSTALL_PREFIX_PATH" \
        -DCMAKE_INSTALL_LIBDIR=lib $STAGE_CONFIGURE_OPTIONS
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: configure lz4 failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --build . $BUILD_THREAD_OPT
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build lz4 failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        cmake --install . --prefix "$INSTALL_PREFIX_PATH"

      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: install lz4 failed.\\033[39;49;0m"
        exit 1
      fi

      cd "$WORKING_DIR"
    fi
  fi
}

# install libiconv
function build_libiconv() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-static --disable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="--enable-static --enable-shared "
    STAGE_CFLAGS="-I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libiconv $BUILD_TARGET_COMPOMENTS) ]]; then
    LIBICONV_PKG=$(check_and_download "libiconv" "libiconv-$COMPOMENTS_LIBICONV_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/libiconv/libiconv-$COMPOMENTS_LIBICONV_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$LIBICONV_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      tar -axvf $LIBICONV_PKG
      LIBICONV=$(ls -d libiconv-$COMPOMENTS_LIBICONV_VERSION* | grep -v \.tar\.gz)
      cd $LIBICONV
      cleanup_configure_cache

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH --with-pic=yes --enable-relocatable $STAGE_CONFIGURE_OPTIONS
      make $BUILD_THREAD_OPT O='$$$$O' && make install O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build libiconv failed.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# binutils 2.39+ requires bison 3.0.4+
function build_bison() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-static --disable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="--enable-static --enable-shared "
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list bison $BUILD_TARGET_COMPOMENTS) ]]; then
    BISON_PKG=$(check_and_download "bison" "bison-$COMPOMENTS_BISON_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/bison/bison-$COMPOMENTS_BISON_VERSION.tar.xz")
    if [[ $? -ne 0 ]]; then
      echo -e "$BISON_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      find . -name "bison-$COMPOMENTS_BISON_VERSION*" -type d | xargs -r rm -rf
      tar -axvf $BISON_PKG
      BISON_DIR=$(ls -d bison-$COMPOMENTS_BISON_VERSION* | grep -v \.tar\.xz)
      cd $BISON_DIR
      cleanup_configure_cache
      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure \
        --prefix=$INSTALL_PREFIX_PATH $STAGE_CONFIGURE_OPTIONS
      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make $BUILD_THREAD_OPT $STAGE_CONFIGURE_OPTIONS O='$$$$O' \
        || env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" make
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: Build bison failed - make.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$}" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make install O='$$$$O'

      if [[ $? -ne 0 ]] || [[ ! -e "$INSTALL_PREFIX_PATH/bin/bison" ]]; then
        echo -e "\\033[31;1mError: Build bison failed - install.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# Build new version of binutils to support new version of dwarf
function build_bintuils() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-static --disable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
    COMPOMENTS_USE_VERSION=$COMPOMENTS_BINUTILS_STAGE1_VERSION
  else
    STAGE_CONFIGURE_OPTIONS="--enable-gprofng "
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
    COMPOMENTS_USE_VERSION=$COMPOMENTS_BINUTILS_VERSION
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ $# -gt 1 ]]; then
    COMPOMENTS_USE_VERSION=$2
  fi

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list binutils $BUILD_TARGET_COMPOMENTS) ]]; then
    BINUTILS_PKG=$(check_and_download "binutils" "binutils-$COMPOMENTS_USE_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/binutils/binutils-$COMPOMENTS_USE_VERSION.tar.xz")
    if [[ $? -ne 0 ]]; then
      echo -e "$BINUTILS_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      find . -name "binutils-$COMPOMENTS_USE_VERSION*" -type d | xargs -r rm -rf
      tar -axvf $BINUTILS_PKG
      BINUTILS_DIR=$(ls -d binutils-$COMPOMENTS_USE_VERSION* | grep -v \.tar\.xz)
      cd $BINUTILS_DIR
      cleanup_configure_cache

      BUILD_BINUTILS_OPTIONS="$STAGE_CONFIGURE_OPTIONS --with-bugurl=$REPOSITORY_MIRROR_URL_GITHUB/owent-utils/bash-shell/issues"
      BUILD_BINUTILS_OPTIONS="$BUILD_BINUTILS_OPTIONS --enable-build-with-cxx --enable-gold --enable-ld"
      BUILD_BINUTILS_OPTIONS="$BUILD_BINUTILS_OPTIONS --enable-libada --enable-lto --enable-objc-gc --enable-vtable-verify --enable-plugins --enable-host-pie"
      BUILD_BINUTILS_OPTIONS="$BUILD_BINUTILS_OPTIONS --enable-relro --enable-threads --enable-install-libiberty --disable-werror --enable-rpath"
      if [[ $COMPOMENTS_LIBSSP_ENABLE -ne 0 ]]; then
        BUILD_BINUTILS_OPTIONS="$BUILD_BINUTILS_OPTIONS --enable-libssp"
      fi
      # Patch for binutils 2.39(gprofng's documents have some error when building)
      sed -i.bak 's/[[:space:]]doc$//g' gprofng/Makefile.in

      BINUTILS_LDFLAGS="$LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../../lib64:\$ORIGIN/../../lib"
      if [[ $SYS_LONG_BIT -ne 32 ]] && [[ -e "$INSTALL_PREFIX_PATH/multilib/$SYS_LONG_BIT" ]] && [[ -e "$INSTALL_PREFIX_PATH/multilib/32" ]]; then
        BDWGC_PREBIUILT="--with-target-bdw-gc=$INSTALL_PREFIX_PATH/multilib/$SYS_LONG_BIT,32=$INSTALL_PREFIX_PATH/multilib/32"
      else
        BDWGC_PREBIUILT="--with-target-bdw-gc=$INSTALL_PREFIX_PATH/multilib/$SYS_LONG_BIT"
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${BINUTILS_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure --prefix=$INSTALL_PREFIX_PATH \
        --with-gmp=$INSTALL_PREFIX_PATH --with-mpc=$INSTALL_PREFIX_PATH --with-mpfr=$INSTALL_PREFIX_PATH --with-isl=$INSTALL_PREFIX_PATH $BDWGC_PREBIUILT \
        $BUILD_BINUTILS_OPTIONS $BUILD_TARGET_CONF_OPTION

      env LDFLAGS="${STAGE_LDFLAGS}${BINUTILS_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make $BUILD_THREAD_OPT O='$$$$O' \
        || env LDFLAGS="${STAGE_LDFLAGS}${BINUTILS_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: Build binutils failed - make.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${BINUTILS_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make install O='$$$$O'

      if [[ $? -ne 0 ]] || [[ ! -e "$INSTALL_PREFIX_PATH/bin/ld" ]]; then
        echo -e "\\033[31;1mError: Build binutils failed - install.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

function build_make() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-static --disable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS=""
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list make $BUILD_TARGET_COMPOMENTS) ]]; then
    MAKE_PKG=$(check_and_download "make" "make-$COMPOMENTS_MAKE_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/make/make-$COMPOMENTS_MAKE_VERSION.tar.gz")
    if [[ $? -ne 0 ]]; then
      echo -e "$MAKE_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      find . -name "make-$COMPOMENTS_MAKE_VERSION*" -type d | xargs -r rm -rf
      tar -axvf $MAKE_PKG
      MAKE_DIR=$(ls -d make-$COMPOMENTS_MAKE_VERSION* | grep -v \.tar\.gz)
      mkdir -p $MAKE_DIR/build
      cd $MAKE_DIR/build
      cleanup_configure_cache

      MAKE_LDFLAGS="$LDFLAGS -Wl,-rpath=\$ORIGIN/../../lib64:\$ORIGIN/../../lib"

      env LDFLAGS="${STAGE_LDFLAGS}${MAKE_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" ../configure --prefix=$INSTALL_PREFIX_PATH \
        --with-libiconv-prefix=$INSTALL_PREFIX_PATH --with-guile --enable-year2038 \
        $BUILD_TARGET_CONF_OPTION $STAGE_CONFIGURE_OPTIONS

      env LDFLAGS="${STAGE_LDFLAGS}${MAKE_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" make $BUILD_THREAD_OPT O='\$$O' \
        || env LDFLAGS="${STAGE_LDFLAGS}${MAKE_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" make O='\$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: Build make failed - make.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="${STAGE_LDFLAGS}${MAKE_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" make install O='\$$O'

      if [[ $? -ne 0 ]] || [[ ! -e "$INSTALL_PREFIX_PATH/bin/make" ]]; then
        echo -e "\\033[31;1mError: Install make failed - install.\\033[39;49;0m"
        exit 1
      fi
      cd "$WORKING_DIR"
    fi
  fi
}

# ======================= build internal glibc =======================
function build_glibc() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""
  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-static --enable-shared "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC -I$BUILD_STAGE1_LIBRARY_PREFIX/include "
    STAGE_LDFLAGS="-L$BUILD_STAGE1_LIBRARY_PREFIX/lib64 -L$BUILD_STAGE1_LIBRARY_PREFIX/lib "
  else
    STAGE_CONFIGURE_OPTIONS="--enable-static --enable-shared "
    STAGE_CFLAGS="-fPIC -I$INSTALL_PREFIX_PATH/include "
    STAGE_LDFLAGS="-L$INSTALL_PREFIX_PATH/lib64 -L$INSTALL_PREFIX_PATH/lib "
  fi

  echo "$LDFLAGS" | grep -F '$ORIGIN/../lib64' || STAGE_LDFLAGS="$STAGE_LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib"

  GLIBC_PKG=$(check_and_download "glibc" "glibc-$COMPOMENTS_INTERNAL_GLIBC_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/glibc/glibc-$COMPOMENTS_INTERNAL_GLIBC_VERSION.tar.xz")
  if [[ $? -ne 0 ]]; then
    echo -e "$GLIBC_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    find . -name "glibc-$COMPOMENTS_INTERNAL_GLIBC_VERSION*" -type d | xargs -r rm -rf
    tar -axvf $GLIBC_PKG
    GLIBC_DIR=$(ls -d glibc-$COMPOMENTS_INTERNAL_GLIBC_VERSION* | grep -v \.tar\.xz)
    mkdir -p glibc_build_dir
    cd glibc_build_dir
    cleanup_configure_cache

    BUILD_GLIBC_OPTIONS="$STAGE_CONFIGURE_OPTIONS --with-bugurl=$REPOSITORY_MIRROR_URL_GITHUB/owent-utils/bash-shell/issues"

    GLIBC_LDFLAGS="$LDFLAGS -Wl,-rpath=\$ORIGIN:\$ORIGIN/../../lib64:\$ORIGIN/../../lib"

    env LDFLAGS="${STAGE_LDFLAGS}${GLIBC_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" ./configure --prefix=$INSTALL_PREFIX_PATH/internal-runtime \
      $BUILD_GLIBC_OPTIONS $BUILD_TARGET_CONF_OPTION

    env LDFLAGS="${STAGE_LDFLAGS}${GLIBC_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make $BUILD_THREAD_OPT O='$$$$O' \
      || env LDFLAGS="${STAGE_LDFLAGS}${GLIBC_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make O='$$$$O'
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build glibc failed - make.\\033[39;49;0m"
      exit 1
    fi

    env LDFLAGS="${STAGE_LDFLAGS}${GLIBC_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make install $BUILD_THREAD_OPT O='$$$$O' \
      || env LDFLAGS="${STAGE_LDFLAGS}${GLIBC_LDFLAGS//\$/\$\$}" PATH="$INSTALL_PREFIX_PATH/bin:$PATH" CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" make install O='$$$$O'
    if [[ $? -ne 0 ]] || [[ ! -e "$INSTALL_PREFIX_PATH/bin/ld" ]]; then
      echo -e "\\033[31;1mError: Install glibc failed - install.\\033[39;49;0m"
      exit 1
    fi
    cd "$WORKING_DIR"
  fi
}

# ======================= build gcc =======================
function build_gcc() {
  INSTALL_PREFIX_PATH="$1"
  STAGE_CFLAGS=""
  STAGE_LDFLAGS=""

  if [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_LIBRARY_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_TOOLS_PREFIX" ]] || [[ "$INSTALL_PREFIX_PATH" == "$BUILD_STAGE1_GCC_PREFIX" ]]; then
    STAGE_CONFIGURE_OPTIONS="--enable-shared --enable-static "
    BUILD_BACKUP_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"
    if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig"
    else
      export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
    fi
    STAGE_CFLAGS="-fPIC"
    STAGE_LDFLAGS=""
    STAGE_LIBRARY_PREFIX="$BUILD_STAGE1_LIBRARY_PREFIX"
  else
    STAGE_CONFIGURE_OPTIONS="--enable-bootstrap --enable-shared --enable-static"
    STAGE_CFLAGS="-fPIC "
    STAGE_LDFLAGS=""
    STAGE_LIBRARY_PREFIX="$INSTALL_PREFIX_PATH"
  fi

  if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gcc $BUILD_TARGET_COMPOMENTS) ]]; then
    # ======================= gcc包 =======================
    GCC_PKG=$(check_and_download "gcc" "gcc-$COMPOMENTS_GCC_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/gcc/gcc-$COMPOMENTS_GCC_VERSION/gcc-$COMPOMENTS_GCC_VERSION.tar.xz")
    if [[ $? -ne 0 ]]; then
      echo -e "$GCC_PKG"
      exit 1
    fi
    if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
      GCC_DIR=$(ls -d gcc-$COMPOMENTS_GCC_VERSION* | grep -v \.tar\.xz)
      if [[ -z "$GCC_DIR" ]]; then
        tar -axvf $GCC_PKG
        GCC_DIR=$(ls -d gcc-$COMPOMENTS_GCC_VERSION* | grep -v \.tar\.xz)
      fi
      if [[ -e gcc_build_dir ]]; then
        rm -rf gcc_build_dir
      fi
      mkdir -p gcc_build_dir
      cd gcc_build_dir
      # ======================= 这一行的最后一个参数请注意，如果要支持其他语言要安装依赖库并打开对该语言的支持 =======================
      if [[ $SYS_LONG_BIT -ne 32 ]] && [[ -e "$STAGE_LIBRARY_PREFIX/multilib/$SYS_LONG_BIT" ]] && [[ -e "$STAGE_LIBRARY_PREFIX/multilib/32" ]]; then
        BDWGC_PREBIUILT="--with-target-bdw-gc=$STAGE_LIBRARY_PREFIX/multilib/$SYS_LONG_BIT,32=$STAGE_LIBRARY_PREFIX/multilib/32"
      else
        BDWGC_PREBIUILT="--with-target-bdw-gc=$STAGE_LIBRARY_PREFIX/multilib/$SYS_LONG_BIT"
      fi

      GCC_CONF_OPTION_ALL="--prefix=$INSTALL_PREFIX_PATH --with-gmp=$STAGE_LIBRARY_PREFIX --with-mpc=$STAGE_LIBRARY_PREFIX --with-mpfr=$STAGE_LIBRARY_PREFIX"
      GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL --with-isl=$STAGE_LIBRARY_PREFIX --with-zstd=$STAGE_LIBRARY_PREFIX $BDWGC_PREBIUILT "
      GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL --enable-gnu-unique-object --enable-build-with-cxx --disable-libjava-multilib --enable-checking=release"
      GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL --enable-gold --enable-ld --enable-libada --enable-lto --enable-objc-gc --enable-gprofng --enable-vtable-verify"
      if [[ $COMPOMENTS_LIBSSP_ENABLE -ne 0 ]]; then
        GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL --enable-libssp"
      fi
      GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL --enable-linker-build-id --enable-rpath"
      GCC_CONF_OPTION_ALL="$GCC_CONF_OPTION_ALL $GCC_OPT_DISABLE_MULTILIB $BUILD_TARGET_CONF_OPTION"
      # See https://stackoverflow.com/questions/13334300/how-to-build-and-install-gcc-with-built-in-rpath
      GCC_CONF_LDFLAGS="${STAGE_LDFLAGS}${LDFLAGS//\$/\$\$} -Wl,-rpath,\$\$ORIGIN:\$\$ORIGIN/../../../../lib64:\$\$ORIGIN/../../../../lib"
      if [[ "x$LD_RUN_PATH" == "x" ]]; then
        GCC_CONF_LD_RUN_PATH="\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib:\$ORIGIN/../../../../lib64:\$ORIGIN/../../../../lib"
      else
        GCC_CONF_LD_RUN_PATH="$LD_RUN_PATH \$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib:\$ORIGIN/../../../../lib:\$ORIGIN/../../../../lib"
      fi
      # env CFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" CXXFLAGS="--ggc-min-expand=0 --ggc-min-heapsize=6291456" 老版本的gcc没有这个选项
      env LDFLAGS="$GCC_CONF_LDFLAGS" LD_RUN_PATH="$GCC_CONF_LD_RUN_PATH" \
        LDFLAGS_FOR_TARGET="$GCC_CONF_LDFLAGS" LDFLAGS_FOR_BUILD="$GCC_CONF_LDFLAGS" BOOT_LDFLAGS="$GCC_CONF_LDFLAGS" \
        CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        ../$GCC_DIR/configure $GCC_CONF_OPTION_ALL $STAGE_CONFIGURE_OPTIONS
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: configure gcc failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="$GCC_CONF_LDFLAGS" LD_RUN_PATH="$GCC_CONF_LD_RUN_PATH" \
        LDFLAGS_FOR_TARGET="$GCC_CONF_LDFLAGS" LDFLAGS_FOR_BUILD="$GCC_CONF_LDFLAGS" BOOT_LDFLAGS="$GCC_CONF_LDFLAGS" \
        CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        make $BUILD_THREAD_OPT O='$$$$O'
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: build gcc failed.\\033[39;49;0m"
        exit 1
      fi

      env LDFLAGS="$GCC_CONF_LDFLAGS" LD_RUN_PATH="$GCC_CONF_LD_RUN_PATH" \
        LDFLAGS_FOR_TARGET="$GCC_CONF_LDFLAGS" LDFLAGS_FOR_BUILD="$GCC_CONF_LDFLAGS" BOOT_LDFLAGS="$GCC_CONF_LDFLAGS" \
        CFLAGS="${STAGE_CFLAGS}${CFLAGS}" CXXFLAGS="${STAGE_CFLAGS}${CXXFLAGS}" \
        make install O='$$$$O'
      cd "$WORKING_DIR"

      ls $INSTALL_PREFIX_PATH/bin/*gcc
      if [[ $? -ne 0 ]]; then
        echo -e "\\033[31;1mError: install gcc failed.\\033[39;49;0m"
        exit 1
      fi

      # ======================= 建立cc软链接 =======================
      ln -s $INSTALL_PREFIX_PATH/bin/gcc $INSTALL_PREFIX_PATH/bin/cc
    fi
  fi
}

# Build stage1 libraries and tools
if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
  export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_STAGE1_TOOLS_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_TOOLS_PREFIX/lib/pkgconfig"
else
  export PKG_CONFIG_PATH="$BUILD_STAGE1_LIBRARY_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_LIBRARY_PREFIX/lib/pkgconfig:$BUILD_STAGE1_TOOLS_PREFIX/lib64/pkgconfig:$BUILD_STAGE1_TOOLS_PREFIX/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
fi

# Prepare directories
mkdir -p "$BUILD_STAGE1_LIBRARY_PREFIX/include"
mkdir -p "$BUILD_STAGE1_LIBRARY_PREFIX/lib"
mkdir -p "$BUILD_STAGE1_LIBRARY_PREFIX/lib64"

build_m4 "$BUILD_STAGE1_TOOLS_PREFIX"
build_autoconf "$BUILD_STAGE1_TOOLS_PREFIX"
build_automake "$BUILD_STAGE1_TOOLS_PREFIX"
build_libtool "$BUILD_STAGE1_TOOLS_PREFIX"
build_pkgconfig "$BUILD_STAGE1_TOOLS_PREFIX"
build_gmp "$BUILD_STAGE1_LIBRARY_PREFIX"
build_mpfr "$BUILD_STAGE1_LIBRARY_PREFIX"
build_mpc "$BUILD_STAGE1_LIBRARY_PREFIX"
build_isl "$BUILD_STAGE1_LIBRARY_PREFIX"
build_libatomic_ops "$BUILD_STAGE1_LIBRARY_PREFIX"
build_bdw_gc "$BUILD_STAGE1_LIBRARY_PREFIX"
build_zlib "$BUILD_STAGE1_LIBRARY_PREFIX"
build_xz "$BUILD_STAGE1_LIBRARY_PREFIX"
build_zstd "$BUILD_STAGE1_LIBRARY_PREFIX"
build_lz4 "$BUILD_STAGE1_LIBRARY_PREFIX"
build_libiconv "$BUILD_STAGE1_LIBRARY_PREFIX"
build_bison "$BUILD_STAGE1_LIBRARY_PREFIX"
build_bintuils "$BUILD_STAGE1_TOOLS_PREFIX" "$COMPOMENTS_BINUTILS_STAGE1_VERSION"
build_make "$BUILD_STAGE1_TOOLS_PREFIX"
build_gcc "$BUILD_STAGE1_GCC_PREFIX"

if [[ "x$BUILD_BACKUP_LD_LIBRARY_PATH" == "x" ]]; then
  export LD_LIBRARY_PATH="$PREFIX_DIR/lib64:$PREFIX_DIR/lib:$BUILD_STAGE1_GCC_PREFIX/lib64:$BUILD_STAGE1_GCC_PREFIX/lib"
else
  export LD_LIBRARY_PATH="$PREFIX_DIR/lib64:$PREFIX_DIR/lib:$BUILD_STAGE1_GCC_PREFIX/lib64:$BUILD_STAGE1_GCC_PREFIX/lib:$BUILD_BACKUP_LD_LIBRARY_PATH"
fi
export PATH=$PREFIX_DIR/bin:$PATH

echo -e "\\033[32;1mNotice: reset env LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m"
echo -e "\\033[32;1mNotice: reset env PATH=$PATH\\033[39;49;0m"

export CC=$BUILD_STAGE1_GCC_PREFIX/bin/gcc
export CXX=$BUILD_STAGE1_GCC_PREFIX/bin/g++
if [[ "x$BUILD_BACKUP_PKG_CONFIG_PATH" == "x" ]]; then
  export PKG_CONFIG_PATH="$PREFIX_DIR/lib64/pkgconfig:$PREFIX_DIR/lib/pkgconfig:$PREFIX_DIR/internal-packages/lib/pkgconfig"
else
  export PKG_CONFIG_PATH="$PREFIX_DIR/lib64/pkgconfig:$PREFIX_DIR/lib/pkgconfig:$PREFIX_DIR/internal-packages/lib/pkgconfig:$BUILD_BACKUP_PKG_CONFIG_PATH"
fi
for ADDITIONAL_PKGCONFIG_PATH in $(find $PREFIX_DIR -name pkgconfig); do
  export PKG_CONFIG_PATH="$ADDITIONAL_PKGCONFIG_PATH:$PKG_CONFIG_PATH"
done

if [[ -z "$CFLAGS" ]]; then
  export CFLAGS="-fPIC"
else
  export CFLAGS="$CFLAGS -fPIC"
fi
if [[ -z "$CXXFLAGS" ]]; then
  export CXXFLAGS="-fPIC"
else
  export CXXFLAGS="$CXXFLAGS -fPIC"
fi
if [[ -z "$LDFLAGS" ]]; then
  export LDFLAGS="-L$PREFIX_DIR/lib64 -L$PREFIX_DIR/lib"
else
  export LDFLAGS="-L$PREFIX_DIR/lib64 -L$PREFIX_DIR/lib $LDFLAGS"
fi

# bootstrap
mkdir -p "$PREFIX_DIR/include"
mkdir -p "$PREFIX_DIR/lib"
mkdir -p "$PREFIX_DIR/lib64"

build_m4 "$PREFIX_DIR"
build_autoconf "$PREFIX_DIR"
build_automake "$PREFIX_DIR"
build_libtool "$PREFIX_DIR"
build_pkgconfig "$PREFIX_DIR"
build_gmp "$PREFIX_DIR"
build_mpfr "$PREFIX_DIR"
build_mpc "$PREFIX_DIR"
build_isl "$PREFIX_DIR"
build_libatomic_ops "$PREFIX_DIR"
build_bdw_gc "$PREFIX_DIR"
build_zlib "$PREFIX_DIR"
build_xz "$PREFIX_DIR"
build_zstd "$PREFIX_DIR"
build_lz4 "$PREFIX_DIR"
build_libiconv "$PREFIX_DIR"
build_make "$PREFIX_DIR"
build_bison "$PREFIX_DIR"
build_bintuils "$PREFIX_DIR"
build_gcc "$PREFIX_DIR"

if [[ "x$BUILD_BACKUP_LD_LIBRARY_PATH" == "x" ]]; then
  export LD_LIBRARY_PATH="$PREFIX_DIR/lib64:$PREFIX_DIR/lib"
else
  export LD_LIBRARY_PATH="$PREFIX_DIR/lib64:$PREFIX_DIR/lib:$BUILD_BACKUP_LD_LIBRARY_PATH"
fi
export CC=$PREFIX_DIR/bin/gcc
export CXX=$PREFIX_DIR/bin/g++

# ======================= install openssl [后面有些组件依赖] =======================
# openssl的依赖太广泛了，所以不放进默认的查找目录，以防外部使用者会使用到这里的版本。如果需要使用，可以手动导入这里的openssl
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list openssl $BUILD_TARGET_COMPOMENTS) ]]; then
  # OPENSSL_PKG=$(check_and_download "openssl" "openssl-$COMPOMENTS_OPENSSL_VERSION*.tar.gz" "https://www.openssl.org/source/openssl-$COMPOMENTS_OPENSSL_VERSION.tar.gz")
  OPENSSL_PKG=$(check_and_download "openssl" "openssl-$COMPOMENTS_OPENSSL_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/quictls/openssl/archive/refs/tags/openssl-$COMPOMENTS_OPENSSL_VERSION-quic1.tar.gz" "openssl-$COMPOMENTS_OPENSSL_VERSION-quic1.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$OPENSSL_PKG"
    exit 1
  fi
  mkdir -p $PREFIX_DIR/internal-packages
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf $OPENSSL_PKG
    OPENSSL_SRC_DIR=$(ls -d openssl-$COMPOMENTS_OPENSSL_VERSION* | grep -v \.tar\.gz)
    cd $OPENSSL_SRC_DIR
    cleanup_configure_cache
    # @see https://wiki.openssl.org/index.php/Compilation_and_Installation
    env LDFLAGS="${LDFLAGS//\$/\$\$}" ./config "--prefix=$PREFIX_DIR/internal-packages" "--openssldir=$PREFIX_DIR/internal-packages/ssl" "--release" \
      "no-dso" "no-tests" "no-external-tests" "no-shared" "no-idea" "no-md4" "no-mdc2" "no-rc2" \
      "no-ssl3" "no-weak-ssl-ciphers" "enable-ec_nistp_64_gcc_128" "enable-static-engine" # "--api=1.1.1"
    make $BUILD_THREAD_OPT || make
    make install_sw install_ssldirs
    if [[ $? -eq 0 ]]; then
      OPENSSL_INSTALL_DIR=$PREFIX_DIR/internal-packages
      mkdir -p "$OPENSSL_INSTALL_DIR/ssl"
      for COPY_SSL_DIR in "/etc/pki/tls/" "/usr/lib/ssl" "/etc/ssl/"; do
        if [[ -e "$COPY_SSL_DIR/cert.pem" ]]; then
          rsync -rL "$COPY_SSL_DIR/cert.pem" "$OPENSSL_INSTALL_DIR/ssl/"
        fi

        if [[ -e "$COPY_SSL_DIR/certs" ]]; then
          mkdir -p "$OPENSSL_INSTALL_DIR/ssl/certs/"
          rsync -rL "$COPY_SSL_DIR/certs/"* "$OPENSSL_INSTALL_DIR/ssl/certs/"
        fi
      done

      # Some build system use <PREFIX>/lib to link openssl, but openssl 3.0 install files to <PREFIX>/lib64
      # We need patch these files to support legacy tools(Such as cmake and Python)
      if [[ -e "$PREFIX_DIR/internal-packages/lib64" ]]; then
        mkdir -p "$PREFIX_DIR/internal-packages/lib/pkgconfig"
        if [[ -e "$PREFIX_DIR/internal-packages/lib64/ossl-modules" ]] && [[ ! -e "$PREFIX_DIR/internal-packages/lib/ossl-modules" ]]; then
          ln -s "$PREFIX_DIR/internal-packages/lib64/ossl-modules" "$PREFIX_DIR/internal-packages/lib/ossl-modules"
        fi
        for OPENSSL_ALIAS_PATH in "$PREFIX_DIR/internal-packages/lib64/engines-"*; do
          OPENSSL_ALIAS_BASENAME="$(basename "$OPENSSL_ALIAS_PATH")"
          if [[ -e "$PREFIX_DIR/internal-packages/lib64/$OPENSSL_ALIAS_BASENAME" ]] && [[ ! -e "$PREFIX_DIR/internal-packages/lib/$OPENSSL_ALIAS_BASENAME" ]]; then
            ln -s "$PREFIX_DIR/internal-packages/lib64/$OPENSSL_ALIAS_BASENAME" "$PREFIX_DIR/internal-packages/lib/$OPENSSL_ALIAS_BASENAME"
          fi
        done
        for OPENSSL_ALIAS_PATH in "$PREFIX_DIR/internal-packages/lib64/"*crypto.* \
          "$PREFIX_DIR/internal-packages/lib64/"*ssl.* \
          "$PREFIX_DIR/internal-packages/lib64/"*openssl.*; do
          OPENSSL_ALIAS_BASENAME="$(basename "$OPENSSL_ALIAS_PATH")"
          if [[ -e "$PREFIX_DIR/internal-packages/lib64/$OPENSSL_ALIAS_BASENAME" ]] && [[ ! -e "$PREFIX_DIR/internal-packages/lib/$OPENSSL_ALIAS_BASENAME" ]]; then
            ln "$PREFIX_DIR/internal-packages/lib64/$OPENSSL_ALIAS_BASENAME" "$PREFIX_DIR/internal-packages/lib/$OPENSSL_ALIAS_BASENAME"
          fi
        done
        for OPENSSL_ALIAS_PATH in "$PREFIX_DIR/internal-packages/lib64/pkgconfig/"*crypto.* \
          "$PREFIX_DIR/internal-packages/lib64/pkgconfig/"*ssl.* \
          "$PREFIX_DIR/internal-packages/lib64/pkgconfig/"*openssl.*; do
          OPENSSL_ALIAS_BASENAME="$(basename "$OPENSSL_ALIAS_PATH")"
          if [[ -e "$PREFIX_DIR/internal-packages/lib64/pkgconfig/$OPENSSL_ALIAS_BASENAME" ]] && [[ ! -e "$PREFIX_DIR/internal-packages/lib/pkgconfig/$OPENSSL_ALIAS_BASENAME" ]]; then
            ln "$PREFIX_DIR/internal-packages/lib64/pkgconfig/$OPENSSL_ALIAS_BASENAME" "$PREFIX_DIR/internal-packages/lib/pkgconfig/$OPENSSL_ALIAS_BASENAME"
          fi
        done
      fi
    fi
    cd "$WORKING_DIR"
  fi
fi

# ======================= install libffi [后面有些组件依赖] =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libffi $BUILD_TARGET_COMPOMENTS) ]]; then
  LIBFFI_PKG=$(check_and_download "libffi" "libffi-$COMPOMENTS_LIBFFI_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$LIBFFI_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf $LIBFFI_PKG
    LIBFFI_DIR=$(ls -d libffi-$COMPOMENTS_LIBFFI_VERSION* | grep -v \.tar\.gz)
    cd "$LIBFFI_DIR"
    cleanup_configure_cache

    env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure --prefix=$PREFIX_DIR --with-pic=yes
    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build libffi failed.\\033[39;49;0m"
      exit 1
    fi
    make install
    cd "$WORKING_DIR"
  fi
fi

# ======================= install ncurses =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list ncurses $BUILD_TARGET_COMPOMENTS) ]]; then
  NCURSES_PKG=$(check_and_download "ncurses" "ncurses-$COMPOMENTS_NCURSES_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/ncurses/ncurses-$COMPOMENTS_NCURSES_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$NCURSES_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf "$NCURSES_PKG"
    NCURSES_DIR=$(ls -d ncurses-$COMPOMENTS_NCURSES_VERSION* | grep -v \.tar\.gz)
    cd $NCURSES_DIR
    cleanup_configure_cache

    # Pyhton require shared libraries
    # expected --with-xterm-kbs=DEL for linux-gnu
    env LDFLAGS="${LDFLAGS//\$/\$\$}" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" ./configure "--prefix=$PREFIX_DIR" "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig" \
      --with-normal --without-debug --without-ada --with-termlib --enable-termcap \
      --disable-widec --enable-pc-files --with-cxx-binding --with-shared --with-cxx-shared \
      --enable-ext-colors --enable-ext-mouse --enable-bsdpad --enable-opaque-curses \
      --with-xterm-kbs=DEL \
      --with-terminfo-dirs=/etc/terminfo:/usr/share/terminfo:/lib/terminfo \
      --with-termpath=/etc/termcap:/usr/share/misc/termcap

    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build ncurse failed.\\033[39;49;0m"
      exit 1
    fi
    make install

    cleanup_configure_cache
    # Pyhton require shared libraries
    # expected --with-xterm-kbs=DEL for linux-gnu
    env LDFLAGS="${LDFLAGS//\$/\$\$}" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" ./configure "--prefix=$PREFIX_DIR" "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig" \
      --with-normal --without-debug --without-ada --with-termlib --enable-termcap \
      --enable-widec --enable-pc-files --with-cxx-binding --with-shared --with-cxx-shared \
      --enable-ext-colors --enable-ext-mouse --enable-bsdpad --enable-opaque-curses \
      --with-xterm-kbs=DEL \
      --with-terminfo-dirs=/etc/terminfo:/usr/share/terminfo:/lib/terminfo \
      --with-termpath=/etc/termcap:/usr/share/misc/termcap

    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build ncursew failed.\\033[39;49;0m"
      exit 1
    fi
    make install
    cd "$WORKING_DIR"
  fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libexpat $BUILD_TARGET_COMPOMENTS) ]]; then
  LIBEXPAT_PKG=$(check_and_download "expat" "expat-$COMPOMENTS_LIBEXPAT_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/libexpat/libexpat/releases/download/R_${COMPOMENTS_LIBEXPAT_VERSION//./_}/expat-$COMPOMENTS_LIBEXPAT_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$LIBEXPAT_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf "$LIBEXPAT_PKG"
    LIBEXPAT_DIR=$(ls -d expat-$COMPOMENTS_LIBEXPAT_VERSION* | grep -v \.tar\.gz)
    if [[ -e "$LIBEXPAT_DIR/build_jobs_dir" ]]; then
      rm -rf "$LIBEXPAT_DIR/build_jobs_dir"
    fi
    mkdir -p "$LIBEXPAT_DIR/build_jobs_dir"
    cd "$LIBEXPAT_DIR/build_jobs_dir"

    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=YES "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR" -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_BUILD_FUZZERS=OFF -DEXPAT_LARGE_SIZE=ON
    cmake --build . $BUILD_THREAD_OPT || cmake --build .
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build libexpat failed.\\033[39;49;0m"
      exit 1
    fi
    cmake --build . -- install

    cd "$WORKING_DIR"
  fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list libxcrypt $BUILD_TARGET_COMPOMENTS) ]]; then
  LIBXCRYPT_PKG=$(check_and_download "libxcrypt" "libxcrypt-$COMPOMENTS_LIBXCRYPT_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/besser82/libxcrypt/archive/v$COMPOMENTS_LIBXCRYPT_VERSION.tar.gz" "libxcrypt-$COMPOMENTS_LIBXCRYPT_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$LIBXCRYPT_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf "$LIBXCRYPT_PKG"
    LIBXCRYPT_DIR=$(ls -d libxcrypt-$COMPOMENTS_LIBXCRYPT_VERSION* | grep -v \.tar\.gz)
    cd "$LIBXCRYPT_DIR"
    cleanup_configure_cache

    ./autogen.sh
    env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes
    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build libxcrypt failed.\\033[39;49;0m"
      exit 1
    fi
    make install

    cd "$WORKING_DIR"
  fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gdbm $BUILD_TARGET_COMPOMENTS) ]]; then
  GDBM_PKG=$(check_and_download "gdbm" "gdbm-*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/gdbm/gdbm-$COMPOMENTS_GDBM_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$GDBM_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf "$GDBM_PKG"
    GDBM_DIR=$(ls -d gdbm-* | grep -v \.tar\.gz)
    cd "$GDBM_DIR"
    cleanup_configure_cache

    # add -fcommon to solve multiple definition of `parseopt_program_args'
    env CFLAGS="$CFLAGS -fcommon" LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes
    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build gdbm failed.\\033[39;49;0m"
      exit 1
    fi
    make install

    cd "$WORKING_DIR"
  fi
fi

if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list readline $BUILD_TARGET_COMPOMENTS) ]]; then
  READLINE_PKG=$(check_and_download "readline" "readline-$COMPOMENTS_READLINE_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/readline/readline-$COMPOMENTS_READLINE_VERSION.tar.gz")
  if [[ $? -ne 0 ]]; then
    echo -e "$READLINE_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf "$READLINE_PKG"
    READLINE_DIR=$(ls -d readline-$COMPOMENTS_READLINE_VERSION* | grep -v \.tar\.gz)
    cd "$READLINE_DIR"
    cleanup_configure_cache

    env LDFLAGS="${LDFLAGS//\$/\$\$} -static" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes --enable-static=yes --enable-shared=no \
      --enable-multibyte --with-curses
    env LDFLAGS="${LDFLAGS//\$/\$\$} -static" make $BUILD_THREAD_OPT || env LDFLAGS="${LDFLAGS//\$/\$\$} -static" make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build readline failed.\\033[39;49;0m"
      exit 1
    fi
    env LDFLAGS="${LDFLAGS//\$/\$\$} -static" make install

    cd "$WORKING_DIR"
  fi
fi

# bootstrap bison, because it may depend on readline and libiconv
build_bison "$PREFIX_DIR"

# ------------------------ patch for global 6.6.5/Python linking error ------------------------
echo "int main() { return 0; }" | gcc -x c -ltinfow -o /dev/null - 2>/dev/null
if [[ $? -eq 0 ]]; then
  BUILD_TARGET_COMPOMENTS_PATCH_TINFO="-ltinfo -ltinfow"
else
  echo "int main() { return 0; }" | gcc -x c -ltinfo -o /dev/null - 2>/dev/null
  if [[ $? -eq 0 ]]; then
    BUILD_TARGET_COMPOMENTS_PATCH_TINFO="-ltinfo"
  else
    BUILD_TARGET_COMPOMENTS_PATCH_TINFO=0
  fi
fi

# ======================= install gdb =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list gdb $BUILD_TARGET_COMPOMENTS) ]]; then
  # =======================  尝试编译安装python  =======================
  PYTHON_PKG=$(check_and_download "python" "Python-$COMPOMENTS_PYTHON_VERSION*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz")
  if [[ $? -ne 0 ]]; then
    echo -e "$PYTHON_PKG"
    exit 1
  fi

  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf $PYTHON_PKG
    PYTHON_DIR=$(ls -d Python-$COMPOMENTS_PYTHON_VERSION* | grep -v \.tar\.xz)
    cd $PYTHON_DIR
    # --enable-optimizations require gcc 8.1.0 or later
    PYTHON_CONFIGURE_OPTIONS=("--prefix=$PREFIX_DIR" "--enable-optimizations" "--with-ensurepip=install" "--enable-shared" "--with-system-expat" "--with-dbmliborder=gdbm:ndbm:bdb")
    if [[ ! -z "$OPENSSL_INSTALL_DIR" ]]; then
      PYTHON_CONFIGURE_OPTIONS=(${PYTHON_CONFIGURE_OPTIONS[@]} "--with-openssl=$OPENSSL_INSTALL_DIR")
    fi
    cleanup_configure_cache

    if [[ "$BUILD_TARGET_COMPOMENTS_PATCH_TINFO" != "0" ]]; then
      env "LIBS=$LIBS $BUILD_TARGET_COMPOMENTS_PATCH_TINFO" LDFLAGS="${LDFLAGS//\$/\$\$}" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" ./configure ${PYTHON_CONFIGURE_OPTIONS[@]}
    else
      env LDFLAGS="${LDFLAGS//\$/\$\$}" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" ./configure ${PYTHON_CONFIGURE_OPTIONS[@]}
    fi
    make $BUILD_THREAD_OPT || make
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build python failed.\\033[39;49;0m"
      exit 1
    fi
    make install && GDB_DEPS_OPT=(${GDB_DEPS_OPT[@]} "--with-python=$PREFIX_DIR/bin/python3")

    cd "$WORKING_DIR"
  fi

  # ======================= 正式安装GDB =======================
  GDB_PKG=$(check_and_download "gdb" "gdb-$COMPOMENTS_GDB_VERSION*.tar.xz" "$REPOSITORY_MIRROR_URL_GNU/gdb/gdb-$COMPOMENTS_GDB_VERSION.tar.xz")
  if [[ $? -ne 0 ]]; then
    echo -e "$GDB_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf $GDB_PKG
    GDB_DIR=$(ls -d gdb-$COMPOMENTS_GDB_VERSION* | grep -v \.tar\.xz)
    cd $GDB_DIR

    if [[ $COMPOMENTS_GDB_STATIC_BUILD -ne 0 ]]; then
      COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS="-static ${LDFLAGS//\$/\$\$}"
    else
      COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS="${LDFLAGS//\$/\$\$}"
    fi
    if [[ -e build_jobs_dir ]]; then
      rm -rf build_jobs_dir
    fi
    mkdir -p build_jobs_dir
    cd build_jobs_dir
    cleanup_configure_cache

    if [[ $COMPOMENTS_LIBSSP_ENABLE -ne 0 ]]; then
      GDB_DEPS_OPT=(${GDB_DEPS_OPT[@]} --enable-libssp)
    fi

    if [[ $SYS_LONG_BIT -ne 32 ]] && [[ -e "$PREFIX_DIR/multilib/$SYS_LONG_BIT" ]] && [[ -e "$PREFIX_DIR/multilib/32" ]]; then
      BDWGC_PREBIUILT="--with-target-bdw-gc=$PREFIX_DIR/multilib/$SYS_LONG_BIT,32=$PREFIX_DIR/multilib/32"
    else
      BDWGC_PREBIUILT="--with-target-bdw-gc=$PREFIX_DIR/multilib/$SYS_LONG_BIT"
    fi

    env LDFLAGS="$COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" ../configure \
      --prefix=$PREFIX_DIR --with-gmp=$PREFIX_DIR --with-mpc=$PREFIX_DIR --with-mpfr=$PREFIX_DIR \
      --with-isl=$PREFIX_DIR $BDWGC_PREBIUILT --enable-build-with-cxx --enable-gold --enable-libada \
      --enable-objc-gc --enable-lto --enable-vtable-verify --with-curses=$PREFIX_DIR $BDWGC_PREBIUILT \
      --with-liblzma-prefix=$PREFIX_DIR --with-libexpat-prefix=$PREFIX_DIR --with-libiconv-prefix=$PREFIX_DIR \
      ${GDB_DEPS_OPT[@]} $BUILD_TARGET_CONF_OPTION
    env LDFLAGS="$COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" make $BUILD_THREAD_OPT O='$$$$O' \
      || env LDFLAGS="$COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" make O='$$$$O'
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mError: Build gdb failed.\\033[39;49;0m"
      exit 1
    fi
    env LDFLAGS="$COMPOMENTS_GDB_STATIC_BUILD_LDFLAGS" CFLAGS="-fPIC ${CFLAGS}" CXXFLAGS="-fPIC ${CXXFLAGS}" make install O='$$$$O'
    cd "$WORKING_DIR"

    if [[ ! -e "$PREFIX_DIR/bin/gdb" ]]; then
      echo -e "\\033[31;1mError: Build gdb failed.\\033[39;49;0m"
    fi
  fi
fi

# ======================= install global tool =======================
if [[ -z "$BUILD_TARGET_COMPOMENTS" ]] || [[ "0" == $(is_in_list global $BUILD_TARGET_COMPOMENTS) ]]; then
  GLOBAL_PKG=$(check_and_download "global" "global-$COMPOMENTS_GLOBAL_VERSION*.tar.gz" "$REPOSITORY_MIRROR_URL_GNU/global/global-$COMPOMENTS_GLOBAL_VERSION.tar.gz")
  if [ $? -ne 0 ]; then
    echo -e "$GLOBAL_PKG"
    exit 1
  fi
  if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
    tar -axvf $GLOBAL_PKG
    GLOBAL_DIR=$(ls -d global-$COMPOMENTS_GLOBAL_VERSION* | grep -v \.tar\.gz)
    cd $GLOBAL_DIR
    cleanup_configure_cache

    # patch for global 6.6.5 linking error
    if [[ "$BUILD_TARGET_COMPOMENTS_PATCH_TINFO" != "0" ]]; then
      env "LIBS=$LIBS $BUILD_TARGET_COMPOMENTS_PATCH_TINFO" LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure --prefix=$PREFIX_DIR --with-pic=yes
    else
      env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure --prefix=$PREFIX_DIR --with-pic=yes
    fi
    make $BUILD_THREAD_OPT && make install
    cd "$WORKING_DIR"
  fi
fi

# 应该就编译完啦
# 64位系统内，如果编译java支持的话可能在gmp上会有问题，可以用这个选项关闭java支持 --enable-languages=c,c++,objc,obj-c++,fortran,ada
# 再把$PREFIX_DIR/bin放到PATH
# $PREFIX_DIR/lib （如果是64位机器还有$PREFIX_DIR/lib64）[另外还有$PREFIX_DIR/libexec我也不知道要不要加，反正我加了]放到LD_LIBRARY_PATH或者/etc/ld.so.conf里
# 再执行ldconfig就可以用新的gcc啦
echo '#!/bin/bash
' >"$PREFIX_DIR/load-gcc-envs.sh"
echo "GCC_HOME_DIR=\"$PREFIX_DIR\"" >>"$PREFIX_DIR/load-gcc-envs.sh"
echo '
if [[ "x$LD_LIBRARY_PATH" == "x" ]]; then
    export LD_LIBRARY_PATH="$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
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
' >>"$PREFIX_DIR/load-gcc-envs.sh"
chmod +x "$PREFIX_DIR/load-gcc-envs.sh"

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
" >"$PREFIX_DIR/load-libstdc++-gdb-printers.py"
chmod +x "$PREFIX_DIR/load-libstdc++-gdb-printers.py"

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m"
  echo -e "\\033[31;1mexport PATH=$PATH\\033[39;49;0m"
  echo -e "\\033[31;1mexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH\\033[39;49;0m"
  echo -e "\tor you can add $PREFIX_DIR/lib, $PREFIX_DIR/lib64 (if in x86_64) and $PREFIX_DIR/libexec to file [/etc/ld.so.conf] and then run [ldconfig]"
  echo -e "\\033[33;1mBuild Gnu Compile Collection done.\\033[39;49;0m"
  echo -e "If you want to use openssl $COMPOMENTS_OPENSSL_VERSION built by this toolchain, just add \\033[33;1m$PREFIX_DIR/internal-packages\\033[0m to search path."

  PAKCAGE_NAME="$(dirname "$PREFIX_DIR")"
  PAKCAGE_NAME="${PAKCAGE_NAME//\//-}-gcc"
  if [[ "x${PAKCAGE_NAME:0:1}" == "x-" ]]; then
    PAKCAGE_NAME="${PAKCAGE_NAME:1}"
  fi
  mkdir -p "$PREFIX_DIR/SPECS"
  echo "Name:           $PAKCAGE_NAME
Version:        $COMPOMENTS_GCC_VERSION
Release:        1%{?dist}
Summary:        gcc $COMPOMENTS_GCC_VERSION

Group:          Development Tools
License:        BSD
URL:            $REPOSITORY_MIRROR_URL_GITHUB/owent-utils/bash-shell/tree/master/GCC%20Installer
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

" >"$PREFIX_DIR/SPECS/rpm.spec"

  echo "Using:"
  echo "    mkdir -pv \$HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}"
  echo "    cd $PREFIX_DIR && rpmbuild -bb --target=x86_64 SPECS/rpm.spec"
  echo "to build rpm package."

else
  echo -e "\\033[35;1mAll packages downloaded.\\033[39;49;0m"
fi
