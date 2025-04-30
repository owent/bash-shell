#!/bin/bash

# Dependency: libedit-devel libxml2-devel ncurses-devel python-devel swig
set -x

# ======================================= 配置 =======================================
LLVM_VERSION=20.1.3
LLVM_INSTALLER_VERSION=${LLVM_VERSION%.*}
LLVM_PATCH_FILES=(
  "https://raw.githubusercontent.com/owent-utils/bash-shell/main/LLVM%26Clang%20Installer/$LLVM_INSTALLER_VERSION/bolt-disable-emit-relocs.patch"
)
COMPOMENTS_LIBEDIT_VERSION=20240808-3.1
# distcc 3.4 use distutils which is removed from python 3.12.2, we use python 3.11 by now
COMPOMENTS_PYTHON_VERSION=3.13.3
COMPOMENTS_SWIG_VERSION=v4.3.0
COMPOMENTS_ZLIB_VERSION=1.3.1
COMPOMENTS_LIBFFI_VERSION=3.4.8
COMPOMENTS_LIBXML2_VERSION=2.14.1
COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION=0.24
PREFIX_DIR=/usr/local/llvm-$LLVM_VERSION

# ======================= 非交叉编译 =======================
CHECK_TOTAL_MEMORY=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
CHECK_AVAILABLE_MEMORY=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
BUILD_DOWNLOAD_ONLY=0
BUILD_USE_SHM=0
BUILD_USE_LD=""
BUILD_USE_GCC_TOOLCHAIN=""
BUILD_TYPE="Release"
BUILD_STAGE_CACHE_FILE="$PWD/distribution-stage1.cmake"
BUILD_INSTALL_TARGETS="stage2-install-distribution"
LINK_JOBS_MAX_NUMBER=0

BUILD_JOBS_MAX_NUMBER=$(nproc)
if [[ "x$LLVM_PARALLEL_BUILD_MAX_JOBS" != "x" ]]; then
  if [[ $BUILD_JOBS_MAX_NUMBER -gt $LLVM_PARALLEL_BUILD_MAX_JOBS ]]; then
    BUILD_JOBS_MAX_NUMBER=$LLVM_PARALLEL_BUILD_MAX_JOBS
  fi
fi
BUILD_JOBS_OPTION="-j$BUILD_JOBS_MAX_NUMBER"

if [[ "x$LLVM_PARALLEL_LINK_JOBS" != "x" ]]; then
  LINK_JOBS_MAX_NUMBER=$LLVM_PARALLEL_LINK_JOBS
elif [[ "x$CHECK_AVAILABLE_MEMORY" != "x" ]]; then
  # 4GB for each linker
  let LINK_JOBS_MAX_NUMBER=$CHECK_AVAILABLE_MEMORY/4194303
  if [[ "x$LLVM_PARALLEL_LINK_MAX_JOBS" != "x" ]]; then
    if [[ $LINK_JOBS_MAX_NUMBER -gt $LLVM_PARALLEL_LINK_MAX_JOBS ]]; then
      LINK_JOBS_MAX_NUMBER=$LLVM_PARALLEL_LINK_MAX_JOBS
    fi
  fi
elif [[ "x$CHECK_TOTAL_MEMORY" != "x" ]]; then
  # 4GB for each linker
  let LINK_JOBS_MAX_NUMBER=$CHECK_TOTAL_MEMORY/4194303
  if [[ "x$LLVM_PARALLEL_LINK_MAX_JOBS" != "x" ]]; then
    if [[ $LINK_JOBS_MAX_NUMBER -gt $LLVM_PARALLEL_LINK_MAX_JOBS ]]; then
      LINK_JOBS_MAX_NUMBER=$LLVM_PARALLEL_LINK_MAX_JOBS
    fi
  fi
fi

# ======================= 内存大于13GB，使用动态链接库（linking libLLVM-XXX.so的时候会消耗巨量内存） =======================
if [[ -z "$CHECK_AVAILABLE_MEMORY" ]]; then
  CHECK_AVAILABLE_MEMORY=0
fi

if [[ -z "$CHECK_TOTAL_MEMORY" ]]; then
  CHECK_TOTAL_MEMORY=0
fi

BUILD_LDFLAGS="-Wl,-rpath=\$ORIGIN:\$ORIGIN/../lib64:\$ORIGIN/../lib:$PREFIX_DIR/lib64:$PREFIX_DIR/lib"
# See https://stackoverflow.com/questions/42344932/how-to-include-correctly-wl-rpath-origin-linker-argument-in-a-makefile
if [[ "owent$LDFLAGS" == "owent" ]]; then
  export LDFLAGS="$BUILD_LDFLAGS"
else
  export LDFLAGS="$LDFLAGS $BUILD_LDFLAGS"
fi
export ORIGIN='$ORIGIN'
if [[ ! -z "$BUILD_LLVM_LLVM_OPTION" ]]; then
  if [[ -z "$BUILD_LLVM_PATCHED_OPTION" ]]; then
    BUILD_LLVM_PATCHED_OPTION="$BUILD_LLVM_PATCHED_OPTION $BUILD_LLVM_LLVM_OPTION"
  else
    BUILD_LLVM_PATCHED_OPTION="$BUILD_LLVM_LLVM_OPTION"
  fi
fi
export BUILD_LLVM_PATCHED_OPTION="$BUILD_LLVM_PATCHED_OPTION"

if [[ -z "$CC" ]]; then
  CC=$(which gcc)
  if [[ $? -eq 0 ]]; then
    CXX="$(dirname $CC)/g++"
  else
    CC=$(which clang)
    if [[ $? -eq 0 ]]; then
      CXX="$(dirname $CC)/clang++"
    else
      echo -e "\\033[32;1mCan not find gcc or clang.\\033[39;49;0m"
      exit 1
    fi
  fi
fi

TEST_SYSTEM_LIBRARIES=(rt pthread dl m)
for TEST_LIB in ${TEST_SYSTEM_LIBRARIES[@]}; do
  echo "#include <cstdio>
int main() { return 0; }" | "$CXX" -o /dev/null -x c++ -l$TEST_LIB -pipe -
  if [[ $? -eq 0 ]]; then
    if [[ -z "$LDFLAGS" ]]; then
      export LDFLAGS="-l$TEST_LIB"
    else
      export LDFLAGS="$LDFLAGS -l$TEST_LIB"
    fi
  fi
done
export LDFLAGS="$LDFLAGS"

ORIGIN_COMPILER_CC="$(readlink -f "$CC")"
ORIGIN_COMPILER_CXX="$(readlink -f "$CXX")"

BOOTSTRAP_BUILD_USE_LD=lld
echo '
#include <stdio.h>
int main() {
    puts("test mold");
    return 0;
}
' >contest.tmp.c
$CC -o contest.tmp.exe -O2 -fuse-ld=mold contest.tmp.c
if [[ $? -eq 0 ]]; then
  BUILD_USE_LD="mold"
fi

if [[ -z "$BUILD_USE_LD" ]]; then
  echo '
#include <stdio.h>
int main() {
    puts("test ld.gold");
    return 0;
}
' >contest.tmp.c
  $CC -o contest.tmp.exe -O2 -fuse-ld=gold contest.tmp.c
  if [[ $? -eq 0 ]]; then
    BUILD_USE_LD="gold"
  fi
fi
rm -f contest.tmp.exe contest.tmp.c

BUILD_USE_LD_SEARCH_LDFLAGS=""
if [[ ! -z "$BUILD_USE_LD" ]]; then
  if [[ "$BUILD_USE_LD" == "mold" ]]; then
    MOLD_DIR="$(dirname "$(which mold)")"
    MOLD_PREFIX_DIR="$(dirname "$MOLD_DIR")"
    if [[ -e "$MOLD_PREFIX_DIR/libexec/mold" ]]; then
      BUILD_USE_LD_SEARCH_LDFLAGS=" -B$MOLD_PREFIX_DIR/libexec/mold"
    fi
    BUILD_USE_LD_SEARCH_LDFLAGS="$BUILD_USE_LD_SEARCH_LDFLAGS -B$MOLD_DIR"
    BUILD_USE_LD_ALL_LDFLAGS="${BUILD_USE_LD_SEARCH_LDFLAGS} -fuse-ld=mold"
  elif [[ "$BUILD_USE_LD" == "gold" ]]; then
    LD_GOLD_DIR="$(dirname "$(which ld.gold)")"
    BUILD_USE_LD_SEARCH_LDFLAGS=" -B$LD_GOLD_DIR"
    BUILD_USE_LD_ALL_LDFLAGS="${BUILD_USE_LD_SEARCH_LDFLAGS} -fuse-ld=gold"
  fi
fi

# ======================= 检测完后等待时间 =======================
CHECK_INFO_SLEEP=3

# ======================= 安装目录初始化/工作目录清理 =======================
while getopts "b:cde:g:hi:j:np:s-" OPTION; do
  case $OPTION in
  p)
    PREFIX_DIR="$OPTARG"
    ;;
  b)
    BUILD_TYPE="$OPTARG"
    ;;
  c)
    for CLEANUP_DIR in $(find . -maxdepth 1 -mindepth 1 -type d -name "*"); do
      if [[ -e "$CLEANUP_DIR/.git" ]]; then
        cd "$CLEANUP_DIR"
        git reset --hard
        git clean -dfx
        cd -
      else
        rm -rf "$CLEANUP_DIR"
      fi
    done
    echo -e "\\033[32;1mnotice: clear work dir(s) done.\\033[39;49;0m"
    exit 0
    ;;
  d)
    BUILD_DOWNLOAD_ONLY=1
    echo -e "\\033[32;1mDownload mode.\\033[39;49;0m"
    ;;
  e)
    BUILD_STAGE_CACHE_FILE="$OPTARG"
    ;;
  h)
    echo "usage: $0 [options] -p=prefix_dir -c -h"
    echo "options:"
    echo "-b [build type]             Release (default), RelWithDebInfo, MinSizeRel, Debug"
    echo "-c                          clean build cache."
    echo "-d                          download only."
    echo "-e                          set cmake cache file for stage 1."
    echo "-h                          help message."
    echo "-j [parallel jobs]          build in parallel using the given number of jobs."
    echo "-i [install targets]        set install targets(stage2-install,stage2-install-distribution,install,install-distribution or other targets)."
    echo "-g [gcc toolchain]          set gcc toolchain."
    echo "-n                          print toolchain version and exit."
    echo "-p [prefix_dir]             set prefix directory."
    echo "-s                          use shared memory to build targets when support."
    exit 0
    ;;
  i)
    BUILD_INSTALL_TARGETS="$OPTARG"
    ;;
  j)
    BUILD_JOBS_OPTION="-j$OPTARG"
    ;;
  n)
    echo $LLVM_VERSION
    exit 0
    ;;
  s)
    BUILD_USE_SHM=1
    ;;
  g)
    BUILD_USE_GCC_TOOLCHAIN="$OPTARG"
    ;;
  -)
    break
    ;;
  ?) #当有不认识的选项的时候arg为?
    echo "unkonw argument detected"
    exit 1
    ;;
  esac
done

shift $(($OPTIND - 1))

if [[ -z "$REPOSITORY_MIRROR_URL_GITHUB" ]]; then
  REPOSITORY_MIRROR_URL_GITHUB="https://github.com"
  # REPOSITORY_MIRROR_URL_GITHUB=https://mirrors.tencent.com/github.com
fi

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  mkdir -p "$PREFIX_DIR"
  PREFIX_DIR="$(cd "$PREFIX_DIR" && pwd)"
fi

# ======================= 转到脚本目录 =======================
WORKING_DIR="$PWD"
BUILD_STAGE_CACHE_FILE="$(readlink -f "$BUILD_STAGE_CACHE_FILE")"

which ninja >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  CMAKE_BUILD_WITH_NINJA="-G Ninja"
else
  which ninja-build >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    CMAKE_BUILD_WITH_NINJA="-G Ninja"
  else
    CMAKE_BUILD_WITH_NINJA=""
  fi
fi

if [[ -z "$CMAKE_BUILD_WITH_NINJA" ]] && [[ $LLVM_PARALLEL_BUILD_MAX_JOBS -gt $LLVM_PARALLEL_LINK_JOBS ]]; then
  LLVM_PARALLEL_BUILD_MAX_JOBS=$LLVM_PARALLEL_LINK_JOBS
fi

# ======================= 统一的包检查和下载函数 =======================
function check_and_download() {
  PKG_NAME="$1"
  PKG_MATCH_EXPR="$2"
  PKG_URL="$3"

  PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"))
  if [[ ${#PKG_VAR_VAL} -gt 0 ]]; then
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
    return 1
  fi

  PKG_VAR_VAL=($(find . -maxdepth 1 -name "$PKG_MATCH_EXPR"))

  if [[ ${#PKG_VAR_VAL} -eq 0 ]]; then
    echo -e "\\033[31;1m$PKG_NAME not found.\\033[39;49;0m"
    return 1
  fi

  echo "${PKG_VAR_VAL[0]}"
}

# ======================= 如果是64位系统且没安装32位的开发包，则编译要gcc加上 --disable-multilib 参数, 不生成32位库 =======================
SYS_LONG_BIT=$(getconf LONG_BIT)

# ======================================= 搞起 =======================================
echo -e "\\033[31;1mcheck complete.\\033[39;49;0m"

# ======================= 准备环境, 把库和二进制目录导入，否则编译会找不到库或文件 =======================
echo "WORKING_DIR                 = $WORKING_DIR"
echo "PREFIX_DIR                  = $PREFIX_DIR"
echo "BUILD_STAGE_CACHE_FILE      = $BUILD_STAGE_CACHE_FILE"
echo "CHECK_INFO_SLEEP            = $CHECK_INFO_SLEEP"
echo "SYS_LONG_BIT                = $SYS_LONG_BIT"
echo "CC                          = $CC"
echo "CXX                         = $CXX"
echo "BUILD_USE_LD                = $BUILD_USE_LD"
echo "BOOTSTRAP_BUILD_USE_LD      = $BOOTSTRAP_BUILD_USE_LD"
echo "BUILD_USE_LD_SEARCH_LDFLAGS = $BUILD_USE_LD_SEARCH_LDFLAGS"
echo "BUILD_USE_LD_ALL_LDFLAGS    = $BUILD_USE_LD_ALL_LDFLAGS"

echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m"
sleep $CHECK_INFO_SLEEP

# ======================= 关闭交换分区，否则就爽死了 =======================
if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  swapoff -a || true
fi

# ======================= 统一的包检查和下载函数 =======================
if [[ ! -e "llvm-project-$LLVM_VERSION" ]]; then
  git clone -b "llvmorg-$LLVM_VERSION" --depth 1 "$REPOSITORY_MIRROR_URL_GITHUB/llvm/llvm-project.git" "llvm-project-$LLVM_VERSION"
  for PATCH_FILE in "${LLVM_PATCH_FILES[@]}"; do
    PATCH_FILE_BASENAME="$(basename "$PATCH_FILE")"
    check_and_download "$PATCH_FILE_BASENAME" "$PATCH_FILE_BASENAME" "$PATCH_FILE" "$PATCH_FILE_BASENAME"
    if [[ $? -ne 0 ]]; then
      rm -f "$PATCH_FILE_BASENAME"
      echo -e "\\033[31;1mDownload from $PATCH_FILE failed.\\033[39;49;0m"
      exit 1
    fi
  done
  cd "llvm-project-$LLVM_VERSION"
  git reset --hard
  for PATCH_FILE in "${LLVM_PATCH_FILES[@]}"; do
    PATCH_FILE_BASENAME="$(basename "$PATCH_FILE")"
    git -c "advice.detachedHead=false" -c "init.defaultBranch=main" -c "core.autocrlf=true" apply "../$PATCH_FILE_BASENAME"
  done
  cd ..
fi

if [[ ! -e "llvm-project-$LLVM_VERSION/.git" ]]; then
  echo -e "\\033[31;1mgit clone $REPOSITORY_MIRROR_URL_GITHUB/llvm/llvm-project.git failed.\\033[39;49;0m"
  exit 1
fi

if [[ ! -e "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION/.git" ]]; then
  if [[ -e "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION" ]]; then
    rm -rf "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION"
  fi
  git clone -b "$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION" --depth 1 "$REPOSITORY_MIRROR_URL_GITHUB/include-what-you-use/include-what-you-use.git" "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION"
  for PATCH_FILE in "${LLVM_PATCH_FILES[@]}"; do
    PATCH_FILE_BASENAME="$(basename "$PATCH_FILE")"
    check_and_download "$PATCH_FILE_BASENAME" "$PATCH_FILE_BASENAME" "$PATCH_FILE" "$PATCH_FILE_BASENAME"
    if [[ $? -ne 0 ]]; then
      rm -f "$PATCH_FILE_BASENAME"
      echo -e "\\033[31;1mDownload from $PATCH_FILE failed.\\033[39;49;0m"
      exit 1
    fi
  done
fi

if [[ ! -e "llvm-project-$LLVM_VERSION/.git" ]]; then
  echo -e "\\033[31;1mgit clone $REPOSITORY_MIRROR_URL_GITHUB/llvm/llvm-project.git failed.\\033[39;49;0m"
  exit 1
fi

check_and_download "libedit" "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz" "http://thrysoee.dk/editline/libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz" "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
if [[ $? -ne 0 ]]; then
  rm -f "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
  echo -e "\\033[31;1mDownload from http://thrysoee.dk/editline/libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz failed.\\033[39;49;0m"
  exit 1
fi

check_and_download "libffi" "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" "$REPOSITORY_MIRROR_URL_GITHUB/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz"
if [[ $? -ne 0 ]]; then
  rm -f "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz"
  echo -e "\\033[31;1mDownload from $REPOSITORY_MIRROR_URL_GITHUB/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz failed.\\033[39;49;0m"
  exit 1
fi

check_and_download "libxml2" "libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz" "https://gitlab.gnome.org/GNOME/libxml2/-/archive/v$COMPOMENTS_LIBXML2_VERSION/libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz" "libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz"
if [[ $? -ne 0 ]]; then
  rm -f "libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz"
  echo -e "\\033[31;1mDownload from https://gitlab.gnome.org/GNOME/libxml2/-/archive/v$COMPOMENTS_LIBXML2_VERSION/libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz failed.\\033[39;49;0m"
  exit 1
fi

if [[ ! -e "zlib-$COMPOMENTS_ZLIB_VERSION" ]]; then
  git clone -b "v$COMPOMENTS_ZLIB_VERSION" --depth 1 "$REPOSITORY_MIRROR_URL_GITHUB/madler/zlib.git" "zlib-$COMPOMENTS_ZLIB_VERSION"
fi

PYTHON_PKG=$(check_and_download "python" "Python-*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz")
if [[ $? -ne 0 ]]; then
  return
fi

if [[ ! -e "swig-$COMPOMENTS_SWIG_VERSION" ]]; then
  git clone -b "$COMPOMENTS_SWIG_VERSION" --depth 1 "$REPOSITORY_MIRROR_URL_GITHUB/swig/swig.git" "swig-$COMPOMENTS_SWIG_VERSION"
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
fi

check_and_download "distribution-stage1.cmake" "distribution-stage1.cmake" "https://raw.githubusercontent.com/owent-utils/bash-shell/main/LLVM%26Clang%20Installer/$LLVM_INSTALLER_VERSION/distribution-stage1.cmake" "distribution-stage1.cmake"
if [[ $? -ne 0 ]]; then
  exit 1
fi

check_and_download "distribution-stage2.cmake" "distribution-stage2.cmake" "https://raw.githubusercontent.com/owent-utils/bash-shell/main/LLVM%26Clang%20Installer/$LLVM_INSTALLER_VERSION/distribution-stage2.cmake" "distribution-stage2.cmake"
if [[ $? -ne 0 ]]; then
  exit 1
fi

if [[ $BUILD_DOWNLOAD_ONLY -ne 0 ]]; then
  echo "Download sources for building LLVM complete."
  exit 0
fi

export LLVM_DIR="$PWD/llvm-project-$LLVM_VERSION"

function cleanup_build_dir() {
  if [[ -e "/dev/shm/build-install-llvm/build_jobs_dir" ]]; then
    rm -rf "/dev/shm/build-install-llvm/build_jobs_dir"
    rm -rf "$LLVM_DIR/build_jobs_dir"
  fi
}

trap cleanup_build_dir EXIT

if [[ ! -z "$BUILD_USE_GCC_TOOLCHAIN" ]]; then
  BUILD_USE_GCC_INSTALL_DIR="$(dirname "$(find "$BUILD_USE_GCC_TOOLCHAIN/lib/gcc" -name crtbegin.o | head -n 1)")"
  BUILD_USE_GCC_TRIPLE="$(basename "$(dirname "$BUILD_USE_GCC_INSTALL_DIR")")"
fi

function build_llvm_toolchain() {
  STAGE_BUILD_EXT_COMPILER_FLAGS=("-DCMAKE_FIND_ROOT_PATH=$PREFIX_DIR"
    "-DCMAKE_PREFIX_PATH=$PREFIX_DIR"
    "-DLLVM_USE_SPLIT_DWARF=ON" "-DBOOTSTRAP_LLVM_USE_SPLIT_DWARF=ON"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DBOOTSTRAP_CMAKE_POSITION_INDEPENDENT_CODE=ON")

  if [[ "x$CFLAGS" == "x" ]]; then
    export CFLAGS="-I$PREFIX_DIR/include"
  else
    export CFLAGS="$CFLAGS -I$PREFIX_DIR/include"
  fi
  if [[ "x$CXXFLAGS" == "x" ]]; then
    export CXXFLAGS="-I$PREFIX_DIR/include"
  else
    export CXXFLAGS="$CXXFLAGS -I$PREFIX_DIR/include"
  fi
  # See https://stackoverflow.com/questions/42344932/how-to-include-correctly-wl-rpath-origin-linker-argument-in-a-makefile
  if [[ "x$LDFLAGS" == "x" ]]; then
    LDFLAGS="-L$PREFIX_DIR/lib -B$PREFIX_DIR/bin"
  else
    LDFLAGS="$LDFLAGS -L$PREFIX_DIR/lib -B$PREFIX_DIR/bin"
  fi
  export LDFLAGS="$LDFLAGS${BUILD_USE_LD_SEARCH_LDFLAGS}"

  echo "======================== Build LLVM with environment ========================"
  echo "PATH                     = $PATH"
  echo "CFLAGS                   = $CFLAGS"
  echo "CXXFLAGS                 = $CXXFLAGS"
  echo "LDFLAGS                  = $LDFLAGS"

  # Try to use the same triple as gcc, so we can find the correct libgcc
  BUILD_TARGET_TRIPLE=$(env LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 "$CC" -v 2>&1 | grep -i 'Target:' | awk '{print $NF}')
  if [[ ! -z "$BUILD_TARGET_TRIPLE" ]]; then
    STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}"
      "-DLLVM_DEFAULT_TARGET_TRIPLE=$BUILD_TARGET_TRIPLE" "-DBOOTSTRAP_LLVM_DEFAULT_TARGET_TRIPLE=$BUILD_TARGET_TRIPLE"
      "-DLLVM_HOST_TRIPLE=$BUILD_TARGET_TRIPLE" "-DBOOTSTRAP_LLVM_HOST_TRIPLE=$BUILD_TARGET_TRIPLE")
  fi

  if [[ ! -z "$BUILD_USE_GCC_TOOLCHAIN" ]]; then
    export CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN=$BUILD_USE_GCC_TOOLCHAIN
    STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}"
      "-DBOOTSTRAP_CMAKE_CXX_FLAGS=--gcc-install-dir=$BUILD_USE_GCC_INSTALL_DIR --gcc-triple=$BUILD_USE_GCC_TRIPLE -Wno-unused-command-line-argument"
      "-DBOOTSTRAP_CMAKE_C_FLAGS=--gcc-install-dir=$BUILD_USE_GCC_INSTALL_DIR --gcc-triple=$BUILD_USE_GCC_TRIPLE -Wno-unused-command-line-argument"
      "-DCMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN=$BUILD_USE_GCC_TOOLCHAIN"
      "-DBOOTSTRAP_CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN=$BUILD_USE_GCC_TOOLCHAIN"
    )
    # 替换默认的gcc查找路径，直接改 clang/include/clang/Config/config.h.cmake 文件
    # @see getGCCToolchainDir in <llvm-projects>/clang/lib/Driver/ToolChains/Gnu.cpp
    sed -i.bak -E "s;define[[:space:]]+GCC_INSTALL_PREFIX[[:space:]]+\".*\";define GCC_INSTALL_PREFIX \"$BUILD_USE_GCC_TOOLCHAIN\";g" "$LLVM_DIR/clang/include/clang/Config/config.h.cmake"

    echo "============ Patched GCC_INSTALL_PREFIX in $LLVM_DIR/clang/include/clang/Config/config.h.cmake ============"
    cat "$LLVM_DIR/clang/include/clang/Config/config.h.cmake"
  fi

  if [[ ! -z "$BUILD_USE_LD" ]]; then
    STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}"
      "-DLLVM_USE_LINKER=$BUILD_USE_LD" "-DBOOTSTRAP_LLVM_USE_LINKER=$BOOTSTRAP_BUILD_USE_LD")
  fi

  STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}"
    "-DLLVM_PARALLEL_LINK_JOBS=$LINK_JOBS_MAX_NUMBER" "-DBOOTSTRAP_LLVM_PARALLEL_LINK_JOBS=$LINK_JOBS_MAX_NUMBER"
    "-DLLVM_PARALLEL_COMPILE_JOBS=$LLVM_PARALLEL_BUILD_MAX_JOBS" "-DBOOTSTRAP_LLVM_PARALLEL_COMPILE_JOBS=$LLVM_PARALLEL_BUILD_MAX_JOBS"
  )

  # Ready to build
  cd "$LLVM_DIR"
  if [[ -e "/dev/shm/build-install-llvm/build_jobs_dir" ]]; then
    rm -rf "/dev/shm/build-install-llvm/build_jobs_dir"
  fi
  if [[ -e "$LLVM_DIR/build_jobs_dir" ]]; then
    rm -rf "$LLVM_DIR/build_jobs_dir"
  fi
  CHECK_AVAILABLE_MEMORY=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
  # Use memory disk to build if we have enough memory(16GB)
  if [[ $BUILD_USE_SHM -ne 0 ]] && [[ ! -z "$CHECK_AVAILABLE_MEMORY" ]]; then
    if [[ $CHECK_AVAILABLE_MEMORY -gt 16777216 ]]; then
      mkdir -p "/dev/shm/build-install-llvm/build_jobs_dir"
      ln -s "/dev/shm/build-install-llvm/build_jobs_dir" "$LLVM_DIR/build_jobs_dir"
    fi
  fi
  if [[ ! -e "$LLVM_DIR/build_jobs_dir" ]]; then
    mkdir -p "$LLVM_DIR/build_jobs_dir"
  fi
  cd "$LLVM_DIR/build_jobs_dir"

  PASSTHROUGH_CMAKE_OPTIONS="CMAKE_INSTALL_PREFIX;CMAKE_FIND_ROOT_PATH;CMAKE_PREFIX_PATH;LLVM_PARALLEL_LINK_JOBS;LLVM_PARALLEL_COMPILE_JOBS"
  PASSTHROUGH_CMAKE_OPTIONS="$PASSTHROUGH_CMAKE_OPTIONS;PYTHON_HOME;LLDB_PYTHON_VERSION;LLDB_ENABLE_PYTHON;LLDB_RELOCATABLE_PYTHON"
  cmake "$LLVM_DIR/llvm" $CMAKE_BUILD_WITH_NINJA "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR" \
    -C "$BUILD_STAGE_CACHE_FILE" "-DCLANG_BOOTSTRAP_PASSTHROUGH=$PASSTHROUGH_CMAKE_OPTIONS" \
    $BUILD_LLVM_PATCHED_OPTION "${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}" "$@"
  if [[ 0 -ne $? ]]; then
    echo -e "\\033[31;1mError: build llvm failed when run cmake.\\033[39;49;0m"
    return 1
  fi

  # 这里会消耗茫茫多内存，所以尝试先开启多进程编译，失败之后降级到单进程
  cmake --build . $BUILD_JOBS_OPTION --config $BUILD_TYPE --target stage2 stage2-distribution ||
    cmake --build . -j2 --config $BUILD_TYPE --target stage2 stage2-distribution ||
    cmake --build . --config $BUILD_TYPE --target stage2 stage2-distribution

  if [[ 0 -ne $? ]]; then
    echo -e "\\033[31;1mError: build llvm failed when run cmake --build .\\033[39;49;0m"
    return 1
  fi

  HAS_SUCCESS_INSTALL=0
  for BUILD_INSTALL_TARGET in $(echo "$BUILD_INSTALL_TARGETS" | tr ',' ' '); do
    cmake --build . --target "$BUILD_INSTALL_TARGET" && HAS_SUCCESS_INSTALL=1
  done
  if [[ 0 -eq $HAS_SUCCESS_INSTALL ]]; then
    echo -e "\\033[31;1mError: build llvm failed when install.\\033[39;49;0m"
    return 1
  fi

  return 0
}

# Build libedit
if [[ -e "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz" ]]; then
  if [[ ! -e "libedit-$COMPOMENTS_LIBEDIT_VERSION-stage-1" ]]; then
    tar -axvf "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
    mv -f "libedit-$COMPOMENTS_LIBEDIT_VERSION" "libedit-$COMPOMENTS_LIBEDIT_VERSION-stage-1"
  fi
  tar -axvf "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
  cd "libedit-$COMPOMENTS_LIBEDIT_VERSION-stage-1"
  env LDFLAGS="${LDFLAGS//\$/\$\$}${BUILD_USE_LD_ALL_LDFLAGS}" ./configure --prefix=$PREFIX_DIR --with-pic=yes
  make $BUILD_JOBS_OPTION || make
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild libedit failed.\\033[39;49;0m"
    exit 1
  fi
  make install
  cd "$WORKING_DIR"
fi

if [[ -e "zlib-$COMPOMENTS_ZLIB_VERSION" ]]; then
  mkdir -p "zlib-$COMPOMENTS_ZLIB_VERSION/build_jobs_dir"
  cd "zlib-$COMPOMENTS_ZLIB_VERSION/build_jobs_dir"
  if [[ -e "CMakeCache.txt" ]]; then
    cmake --build . -- clean || true
  fi
  env LDFLAGS="${LDFLAGS}${BUILD_USE_LD_ALL_LDFLAGS}" cmake .. $CMAKE_BUILD_WITH_NINJA -DCMAKE_POSITION_INDEPENDENT_CODE=YES "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR"
  cmake --build . $BUILD_JOBS_OPTION || cmake --build .
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild zlib failed.\\033[39;49;0m"
    exit 1
  fi
  cmake --build . -- install
  cd "$WORKING_DIR"
fi

if [[ -e "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" ]]; then
  if [[ ! -e "libffi-$COMPOMENTS_LIBFFI_VERSION" ]]; then
    tar -axvf "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz"
  fi
  cd "libffi-$COMPOMENTS_LIBFFI_VERSION"
  make clean || true
  env LDFLAGS="${LDFLAGS//\$/\$\$}${BUILD_USE_LD_ALL_LDFLAGS}" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes
  make $BUILD_JOBS_OPTION || make
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild libffi failed.\\033[39;49;0m"
    exit 1
  fi
  make install
  cd "$WORKING_DIR"
fi

if [[ -e "libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz" ]]; then
  if [[ ! -e "libxml2-v$COMPOMENTS_LIBXML2_VERSION" ]]; then
    tar -axvf "libxml2-v$COMPOMENTS_LIBXML2_VERSION.tar.gz"
  fi
  mkdir -p "libxml2-v$COMPOMENTS_LIBXML2_VERSION/build_jobs_dir"
  cd "libxml2-v$COMPOMENTS_LIBXML2_VERSION/build_jobs_dir"
  if [[ -e "CMakeCache.txt" ]]; then
    cmake --build . -- clean || true
  fi
  LIBXML2_CMAKE_OPTIONS=("-DCMAKE_POSITION_INDEPENDENT_CODE=YES" "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR")
  TRY_GCC_HOME="$(dirname "$(dirname "$(which gcc)")")"
  if [[ -e "$PREFIX_DIR/../gcc-latest/load-gcc-envs.sh" ]]; then
    LIBXML2_CMAKE_OPTIONS=(${LIBXML2_CMAKE_OPTIONS[@]} "-DCMAKE_FIND_ROOT_PATH=$PREFIX_DIR/../gcc-latest" "-DCMAKE_PREFIX_PATH=$PREFIX_DIR/../gcc-latest")
  elif [[ ! -z "$TRY_GCC_HOME" ]] && [[ -e "$TRY_GCC_HOME/load-gcc-envs.sh" ]]; then
    LIBXML2_CMAKE_OPTIONS=(${LIBXML2_CMAKE_OPTIONS[@]} "-DCMAKE_FIND_ROOT_PATH=$TRY_GCC_HOME" "-DCMAKE_PREFIX_PATH=$TRY_GCC_HOME")
  fi
  env LDFLAGS="${LDFLAGS}${BUILD_USE_LD_ALL_LDFLAGS}" cmake .. $CMAKE_BUILD_WITH_NINJA ${LIBXML2_CMAKE_OPTIONS[@]}
  cmake --build . $BUILD_JOBS_OPTION || cmake --build .
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild libxml2 failed.\\033[39;49;0m"
    exit 1
  fi
  cmake --build . -- install
  cd "$WORKING_DIR"
fi

if [[ -z "$(find $PREFIX_DIR -name swig)" ]]; then
  cd "swig-$COMPOMENTS_SWIG_VERSION"
  ./autogen.sh
  make clean || true
  env LDFLAGS="${LDFLAGS//\$/\$\$}${BUILD_USE_LD_ALL_LDFLAGS}" ./configure "--prefix=$PREFIX_DIR"
  make $BUILD_JOBS_OPTION || make
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild swig failed.\\033[39;49;0m"
    exit 1
  fi
  make install
  cd "$WORKING_DIR"
fi

ORIGIN_COMPILER_PREFIX_DIR="$(dirname "$ORIGIN_COMPILER_CC")"
ORIGIN_COMPILER_PREFIX_DIR="$(dirname "$ORIGIN_COMPILER_PREFIX_DIR")"

if [[ "x$ORIGIN_COMPILER_PREFIX_DIR" != "x/usr" ]] && [[ "x$ORIGIN_COMPILER_PREFIX_DIR" != "x/usr/local" ]] && [[ ! -z "$(find "$ORIGIN_COMPILER_PREFIX_DIR/include" -name Python.h)" ]]; then
  PYTHIN_INCLUDE_DIR="$(find "$ORIGIN_COMPILER_PREFIX_DIR/include" -name Python.h)"
  PYTHIN_INCLUDE_DIR="$(dirname "$PYTHIN_INCLUDE_DIR")"
  PYTHON_HOME="$ORIGIN_COMPILER_PREFIX_DIR"
elif [[ -z "$(find $PREFIX_DIR -name Python.h)" ]]; then
  # =======================  尝试编译安装python  =======================
  tar -axvf $PYTHON_PKG
  PYTHON_DIR=$(ls -d Python-* | grep -v \.tar.xz)
  cd $PYTHON_DIR
  # 尝试使用gcc构建脚本中构建的openssl
  OPENSSL_INSTALL_DIR=""
  if [[ -e "$(dirname "$ORIGIN_COMPILER_CC")/../internal-packages/lib/libssl.a" ]]; then
    OPENSSL_INSTALL_DIR="$(readlink -f "$(dirname "$ORIGIN_COMPILER_CC")"/../internal-packages)"
    # Add rpath of internal-packages
    export LDFLAGS="$LDFLAGS -Wl,-rpath=\$ORIGIN/../internal-packages/lib64:\$ORIGIN/../internal-packages/lib:$PREFIX_DIR/internal-packages/lib64:$PREFIX_DIR/internal-packages/lib"
  fi
  # --enable-optimizations require gcc 8.1.0 or later
  PYTHON_CONFIGURE_OPTIONS=("--prefix=$PREFIX_DIR" "--enable-optimizations" "--with-normal" "--with-cxx-binding"
    "--without-debug" "--with-ensurepip=install" "--enable-shared" "--enable-pc-files" "--with-system-ffi"
    "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig")
  if [[ ! -z "$OPENSSL_INSTALL_DIR" ]]; then
    PYTHON_CONFIGURE_OPTIONS=(${PYTHON_CONFIGURE_OPTIONS[@]} "--with-openssl=$OPENSSL_INSTALL_DIR")
  fi
  make clean || true
  env LDFLAGS="${LDFLAGS//\$/\$\$}${BUILD_USE_LD_ALL_LDFLAGS}" ./configure ${PYTHON_CONFIGURE_OPTIONS[@]}
  make $BUILD_JOBS_OPTION || make
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild python failed.\\033[39;49;0m"
    exit 1
  fi
  make install

  PYTHIN_INCLUDE_DIR="$(find "$PREFIX_DIR/include" -name Python.h)"
  PYTHIN_INCLUDE_DIR="$(dirname "$PYTHIN_INCLUDE_DIR")"
  PYTHON_HOME="$PREFIX_DIR"
  cd "$WORKING_DIR"
fi
if [[ ! -z "$PYTHIN_INCLUDE_DIR" ]]; then
  PYTHON_MAJOR_VERSION=$(grep -E 'PY_MAJOR_VERSION[[:space:]]*[0-9]+' "$PYTHIN_INCLUDE_DIR"/*.h | awk '{print $NF}')
  if [[ ! -z "$PYTHON_MAJOR_VERSION" ]]; then
    export BUILD_LLVM_PATCHED_OPTION="$BUILD_LLVM_LLVM_OPTION -DPYTHON_HOME=$PYTHON_HOME -DLLDB_PYTHON_VERSION=$PYTHON_MAJOR_VERSION -DLLDB_ENABLE_PYTHON=ON -DLLDB_RELOCATABLE_PYTHON=1"
  fi
fi

build_llvm_toolchain "$@"

if [[ 0 -ne $? ]]; then
  if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
    echo -e "\\033[31;1mError: build llvm failed.\\033[39;49;0m"
    exit 1
  fi
fi

if [[ ! -e "$PREFIX_DIR/bin/clang" ]]; then
  if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
    echo -e "\\033[31;1mError: build llvm failed($PREFIX_DIR/bin/clang not found).\\033[39;49;0m"
    exit 1
  fi
fi

echo -e "\\033[32;1mbuild llvm success.\\033[39;49;0m"

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then

  if [[ ! -z "$BUILD_USE_GCC_TOOLCHAIN" ]]; then
    echo "gcc-toolchain: $BUILD_USE_GCC_TOOLCHAIN
gcc-install-dir: $BUILD_USE_GCC_INSTALL_DIR
gcc-triple: $BUILD_USE_GCC_TRIPLE" >"$PREFIX_DIR/llvm.gcc-toolchain.conf"
  fi

  DEP_COMPILER_HOME="$(dirname "$(dirname "$ORIGIN_COMPILER_CXX")")"
  echo "#!/bin/bash

if [[ \"x\$GCC_HOME_DIR\" == \"x\" ]]; then
    GCC_HOME_DIR=\"$DEP_COMPILER_HOME\";
fi
LLVM_HOME_DIR=\"$PREFIX_DIR\"" >"$PREFIX_DIR/load-llvm-envs.sh"
  cd "$PREFIX_DIR"
  LLVM_LD_LIBRARY_PATH=""
  for DIR_PATH in $(find "." -name "*.so" | grep -v "cpython" | grep -v -E 'python[0-9\.]*/site-packages' | xargs -r dirname | sort -u -r); do
    if [[ -z "$LLVM_LD_LIBRARY_PATH" ]]; then
      LLVM_LD_LIBRARY_PATH="\$LLVM_HOME_DIR/$DIR_PATH"
    else
      LLVM_LD_LIBRARY_PATH="$LLVM_LD_LIBRARY_PATH:\$LLVM_HOME_DIR/$DIR_PATH"
    fi
  done

  echo "LLVM_LD_LIBRARY_PATH=\"$LLVM_LD_LIBRARY_PATH\" ;" >>"$PREFIX_DIR/load-llvm-envs.sh"
  cat "$PREFIX_DIR/load-llvm-envs.sh" >"$PREFIX_DIR/load-llvm-envs-no-default.sh"

  echo '

if [[ "/" != "$GCC_HOME_DIR" ]] && [[ "$LLVM_HOME_DIR" != "$GCC_HOME_DIR" ]]; then
  if [[ ! ( "$PATH" =~ (^|:)"$GCC_HOME_DIR/bin"(:|$) ) ]]; then
    export PATH="$GCC_HOME_DIR/bin:$PATH" ;
  fi

  if [[ ! ( "$LD_LIBRARY_PATH" =~ (^|:)"$GCC_HOME_DIR/lib"(:|$) ) ]]; then
    if [[ -z "$LD_LIBRARY_PATH" ]]; then
      export LD_LIBRARY_PATH="$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
    else
      export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
    fi
  fi
fi

if [[ ! ( "$PATH" =~ (^|:)"$LLVM_HOME_DIR/bin"(:|$) ) ]]; then
  export PATH="$LLVM_HOME_DIR/bin:$LLVM_HOME_DIR/libexec:$PATH" ;
fi

if [[ ! ( "$LD_LIBRARY_PATH" =~ (^|:)"$LLVM_LD_LIBRARY_PATH"(:|$) ) ]]; then
  if [[ -z "$LD_LIBRARY_PATH" ]]; then
    export LD_LIBRARY_PATH="$LLVM_LD_LIBRARY_PATH" ;
  else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LLVM_LD_LIBRARY_PATH" ;
  fi
fi

function build_with_llvm_clang() {
  BUILD_USE_GCC_INSTALL_DIR="$(dirname "$(find "$GCC_HOME_DIR/lib/gcc" -name crtbegin.o | head -n 1)")"
  BUILD_USE_GCC_TRIPLE="$(basename "$(dirname "$BUILD_USE_GCC_INSTALL_DIR")")"

  export CC="$LLVM_HOME_DIR/bin/clang" ;
  export CXX="$LLVM_HOME_DIR/bin/clang++" ;
  export AR="$LLVM_HOME_DIR/bin/llvm-ar" ;
  export AS="$LLVM_HOME_DIR/bin/llvm-as" ;
  export RANLIB="$LLVM_HOME_DIR/bin/llvm-ranlib" ;
  export NM="$LLVM_HOME_DIR/bin/llvm-nm" ;
  export STRIP="$LLVM_HOME_DIR/bin/llvm-strip" ;
  export OBJCOPY="$LLVM_HOME_DIR/bin/llvm-objcopy" ;
  export OBJDUMP="$LLVM_HOME_DIR/bin/llvm-objdump" ;
  export READELF="$LLVM_HOME_DIR/bin/llvm-readelf" ;

  # Maybe need add --gcc-install-dir=$BUILD_USE_GCC_INSTALL_DIR --gcc-triple=$BUILD_USE_GCC_TRIPLE to compile options
  "$@"
}
if [[ $# -gt 0 ]]; then
  build_with_llvm_clang "$@"
fi
' >>"$PREFIX_DIR/load-llvm-envs.sh"
  chmod +x "$PREFIX_DIR/load-llvm-envs.sh"

  echo '

if [[ "/" != "$GCC_HOME_DIR" ]] && [[ "$LLVM_HOME_DIR" != "$GCC_HOME_DIR" ]]; then
  if [[ ! ( "$PATH" =~ (^|:)"$GCC_HOME_DIR/bin"(:|$) ) ]]; then
    export PATH="$PATH:$GCC_HOME_DIR/bin" ;
  fi
fi

if [[ ! ( "$PATH" =~ (^|:)"$LLVM_HOME_DIR/bin"(:|$) ) ]]; then
  export PATH="$PATH:$LLVM_HOME_DIR/bin:$LLVM_HOME_DIR/libexec" ;
fi

function build_with_llvm_clang() {
  BUILD_USE_GCC_INSTALL_DIR="$(dirname "$(find "$GCC_HOME_DIR/lib/gcc" -name crtbegin.o | head -n 1)")"
  BUILD_USE_GCC_TRIPLE="$(basename "$(dirname "$BUILD_USE_GCC_INSTALL_DIR")")"

  export CC="$LLVM_HOME_DIR/bin/clang" ;
  export CXX="$LLVM_HOME_DIR/bin/clang++" ;
  export AR="$LLVM_HOME_DIR/bin/llvm-ar" ;
  export AS="$LLVM_HOME_DIR/bin/llvm-as" ;
  export RANLIB="$LLVM_HOME_DIR/bin/llvm-ranlib" ;
  export NM="$LLVM_HOME_DIR/bin/llvm-nm" ;
  export STRIP="$LLVM_HOME_DIR/bin/llvm-strip" ;
  export OBJCOPY="$LLVM_HOME_DIR/bin/llvm-objcopy" ;
  export OBJDUMP="$LLVM_HOME_DIR/bin/llvm-objdump" ;
  export READELF="$LLVM_HOME_DIR/bin/llvm-readelf" ;

  # Maybe need add --gcc-install-dir=$BUILD_USE_GCC_INSTALL_DIR --gcc-triple=$BUILD_USE_GCC_TRIPLE to compile options
  "$@"
}
if [[ $# -gt 0 ]]; then
  build_with_llvm_clang "$@"
fi
' >>"$PREFIX_DIR/load-llvm-envs-no-default.sh"
  chmod +x "$PREFIX_DIR/load-llvm-envs-no-default.sh"

else
  echo -e "\\033[35;1mDownloaded.\\033[39;49;0m"
fi

PAKCAGE_NAME="$(dirname "$PREFIX_DIR")"
PAKCAGE_NAME="${PAKCAGE_NAME//\//-}-llvm-clang-libc++"
if [[ "x${PAKCAGE_NAME:0:1}" == "x-" ]]; then
  PAKCAGE_NAME="${PAKCAGE_NAME:1}"
fi
mkdir -p "$PREFIX_DIR/SPECS"
echo "Name:           $PAKCAGE_NAME
Version:        $LLVM_VERSION
Release:        1%{?dist}
Summary:        llvm-clang-libc++ $LLVM_VERSION
Group:          Development Tools
License:        BSD
URL:            $REPOSITORY_MIRROR_URL_GITHUB/owent-utils/bash-shell/tree/master/LLVM%26Clang%20Installer
BuildRoot:      %_topdir/BUILDROOT
Prefix:         $PREFIX_DIR
# Source0:
# BuildRequires:
Requires:       gcc,make
%description
llvm-clang-libc++ $LLVM_VERSION
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

source "$PREFIX_DIR/load-llvm-envs.sh"
# Build include-what-you-use
if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
  cd "$WORKING_DIR"
  if [[ -e "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION" ]]; then
    mkdir -p "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION/build_jobs_dir"

    # GCC_LIBSTDCXX_LIB_PATH=$(find "$GCC_HOME_DIR" -name libstdc++.so | head -n 1)
    LIBCLANG_CPP_PATH=$(find "$PREFIX_DIR" -name libclang-cpp.so | head -n 1)
    SELECT_STDLIB="-stdlib=libstdc++"
    ldd "$LIBCLANG_CPP_PATH" | grep -F 'libstdc++' >/dev/null 2>&1 || SELECT_STDLIB="$(llvm-config --cxxflags)"
    cd "include-what-you-use-$COMPOMENTS_INCLUDE_WHAT_YOU_USE_VERSION/build_jobs_dir"
    env CXXFLAGS="$CXXFLAGS $SELECT_STDLIB" LDFLAGS="$LDFLAGS -L$GCC_HOME_DIR/lib64 -L$GCC_HOME_DIR/lib $(llvm-config --ldflags)" \
      cmake $CMAKE_BUILD_WITH_NINJA .. -DCMAKE_POSITION_INDEPENDENT_CODE=YES "-DCMAKE_FIND_ROOT_PATH=$PREFIX_DIR" \
      "-DCMAKE_PREFIX_PATH=$PREFIX_DIR" "-DCMAKE_C_COMPILER=$PREFIX_DIR/bin/clang" "-DCMAKE_CXX_COMPILER=$PREFIX_DIR/bin/clang++" \
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" "-DIWYU_LINK_CLANG_DYLIB=ON"

    cmake --build . $BUILD_JOBS_OPTION || cmake --build .
    if [[ $? -ne 0 ]]; then
      echo -e "\\033[31;1mBuild include-what-you-use failed.\\033[39;49;0m"
      exit 1
    fi
    cmake --install . --prefix "$PREFIX_DIR"

    cd "$WORKING_DIR"
  fi
fi

if [ $BUILD_DOWNLOAD_ONLY -eq 0 ]; then
  LLVM_CONFIG_PATH="$PREFIX_DIR/bin/llvm-config"
  echo -e "\\033[33;1mAddition, run the cmds below to add environment var(s).\\033[39;49;0m"
  echo -e "\\033[31;1mexport PATH=$($LLVM_CONFIG_PATH --bindir):$PATH\\033[39;49;0m"
  echo -e "\\033[33;1mBuild LLVM done.\\033[39;49;0m"
  echo ""
  echo -e "\\033[32;1mSample flags to build exectable file:.\\033[39;49;0m"
  echo -e "\\033[35;1m\tCC=$PREFIX_DIR/bin/clang\\033[39;49;0m"
  echo -e "\\033[35;1m\tCXX=$PREFIX_DIR/bin/clang++\\033[39;49;0m"
  echo -e "\\033[35;1m\tCFLAGS=$($LLVM_CONFIG_PATH --cflags) -std=libc++\\033[39;49;0m"
  if [ ! -z "$(find $($LLVM_CONFIG_PATH --libdir) -name libc++abi.so)" ]; then
    echo -e "\\033[35;1m\tCXXFLAGS=$($LLVM_CONFIG_PATH --cxxflags) -std=libc++\\033[39;49;0m"
    echo -e "\\033[35;1m\tLDFLAGS=$($LLVM_CONFIG_PATH --ldflags) -lc++ -lc++abi\\033[39;49;0m"
  else
    echo -e "\\033[35;1m\tCXXFLAGS=$($LLVM_CONFIG_PATH --cxxflags)\\033[39;49;0m"
    echo -e "\\033[35;1m\tLDFLAGS=$($LLVM_CONFIG_PATH --ldflags)\\033[39;49;0m"
  fi
  echo -e "\\033[35;1m\tMaybe need add --gcc-install-dir=$BUILD_USE_GCC_INSTALL_DIR --gcc-triple=$BUILD_USE_GCC_TRIPLE to compile options\\033[39;49;0m"

  echo "Using:"
  echo "    mkdir -pv \$HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}"
  echo "    cd $PREFIX_DIR && rpmbuild -bb --target=x86_64 SPECS/rpm.spec"
  echo "to build rpm package."

fi
