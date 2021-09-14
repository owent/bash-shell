#!/bin/bash

# Dependency: libedit-devel libxml2-devel ncurses-devel python-devel swig
set -x

# ======================================= 配置 =======================================
LLVM_VERSION=12.0.1
COMPOMENTS_LIBEDIT_VERSION=20210714-3.1
COMPOMENTS_PYTHON_VERSION=3.9.6
COMPOMENTS_SWIG_VERSION=v4.0.2
COMPOMENTS_ZLIB_VERSION=1.2.11
COMPOMENTS_LIBFFI_VERSION=3.4.2
PREFIX_DIR=/usr/local/llvm-$LLVM_VERSION

# ======================= 非交叉编译 =======================
CHECK_TOTAL_MEMORY=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
CHECK_AVAILABLE_MEMORY=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
BUILD_DOWNLOAD_ONLY=0
BUILD_USE_SHM=0
BUILD_USE_LD=""
BUILD_USE_GCC_TOOLCHAIN=""
BUILD_TYPE="Release"
BUILD_JOBS_OPTION="-j$(cat /proc/cpuinfo | grep processor | awk 'BEGIN{MAX_CORE_NUM=1}{if($3>MAX_CORE_NUM){MAX_CORE_NUM=$3;}}END{print MAX_CORE_NUM;}')"
BUILD_STAGE_CACHE_FILE="$PWD/distribution-stage1.cmake"
BUILD_INSTALL_TARGETS="stage2-install-distribution"
LINK_JOBS_MAX_NUMBER=0
if [[ "x$CHECK_AVAILABLE_MEMORY" != "x" ]]; then
  # 4GB for each linker
  let LINK_JOBS_MAX_NUMBER=$CHECK_AVAILABLE_MEMORY/4194303
elif [[ "x$CHECK_TOTAL_MEMORY" != "x" ]]; then
  # 4GB for each linker
  let LINK_JOBS_MAX_NUMBER=$CHECK_TOTAL_MEMORY/4194303
fi
if [[ $LINK_JOBS_MAX_NUMBER -gt 0 ]]; then
  export BUILD_LLVM_PATCHED_OPTION="-DLLVM_PARALLEL_LINK_JOBS=$LINK_JOBS_MAX_NUMBER"
else
  export BUILD_LLVM_PATCHED_OPTION=""
fi

# ======================= 内存大于13GB，使用动态链接库（linking libLLVM-XXX.so的时候会消耗巨量内存） =======================
if [[ -z "$CHECK_AVAILABLE_MEMORY" ]]; then
  CHECK_AVAILABLE_MEMORY=0
fi

if [[ -z "$CHECK_TOTAL_MEMORY" ]]; then
  CHECK_TOTAL_MEMORY=0
fi

export ORIGIN='$ORIGIN'
export BUILD_LLVM_PATCHED_OPTION="$BUILD_LLVM_LLVM_OPTION"

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

ORIGIN_COMPILER_CC="$(readlink -f "$CC")"
ORIGIN_COMPILER_CXX="$(readlink -f "$CXX")"

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
rm -f contest.tmp.exe contest.tmp.c

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

if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  mkdir -p "$PREFIX_DIR"
  PREFIX_DIR="$(cd "$PREFIX_DIR" && pwd)"
fi

# ======================= 转到脚本目录 =======================
WORKING_DIR="$PWD"
BUILD_STAGE_CACHE_FILE="$(readlink -f "$BUILD_STAGE_CACHE_FILE")"

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
echo "WORKING_DIR               = $WORKING_DIR"
echo "PREFIX_DIR                = $PREFIX_DIR"
echo "BUILD_STAGE_CACHE_FILE    = $BUILD_STAGE_CACHE_FILE"
echo "CHECK_INFO_SLEEP          = $CHECK_INFO_SLEEP"
echo "SYS_LONG_BIT              = $SYS_LONG_BIT"
echo "CC                        = $CC"
echo "CXX                       = $CXX"
echo "BUILD_USE_LD              = $BUILD_USE_LD"

echo -e "\\033[32;1mnotice: now, sleep for $CHECK_INFO_SLEEP seconds.\\033[39;49;0m"
sleep $CHECK_INFO_SLEEP

# ======================= 关闭交换分区，否则就爽死了 =======================
if [[ $BUILD_DOWNLOAD_ONLY -eq 0 ]]; then
  swapoff -a
fi

# ======================= 统一的包检查和下载函数 =======================
if [[ ! -e "llvm-project-$LLVM_VERSION" ]]; then
  git clone -b "llvmorg-$LLVM_VERSION" --depth 1 "https://github.com/llvm/llvm-project.git" "llvm-project-$LLVM_VERSION"
fi

if [[ ! -e "llvm-project-$LLVM_VERSION/.git" ]]; then
  echo -e "\\033[31;1mgit clone https://github.com/llvm/llvm-project.git failed.\\033[39;49;0m"
  exit 1
fi

check_and_download "libedit" "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz" "http://thrysoee.dk/editline/libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz" "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
if [[ $? -ne 0 ]]; then
  rm -f "libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz"
  echo -e "\\033[31;1mDownload from http://thrysoee.dk/editline/libedit-$COMPOMENTS_LIBEDIT_VERSION.tar.gz failed.\\033[39;49;0m"
  exit 1
fi

check_and_download "libffi" "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" "https://github.com/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz" "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz"
if [[ $? -ne 0 ]]; then
  rm -f "libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz"
  echo -e "\\033[31;1mDownload from https://github.com/libffi/libffi/releases/download/v$COMPOMENTS_LIBFFI_VERSION/libffi-$COMPOMENTS_LIBFFI_VERSION.tar.gz failed.\\033[39;49;0m"
  exit 1
fi

if [[ ! -e "zlib-$COMPOMENTS_ZLIB_VERSION" ]]; then
  git clone -b "v$COMPOMENTS_ZLIB_VERSION" --depth 1 "https://github.com/madler/zlib.git" "zlib-$COMPOMENTS_ZLIB_VERSION"
fi

PYTHON_PKG=$(check_and_download "python" "Python-*.tar.xz" "https://www.python.org/ftp/python/$COMPOMENTS_PYTHON_VERSION/Python-$COMPOMENTS_PYTHON_VERSION.tar.xz")
if [[ $? -ne 0 ]]; then
  return
fi

if [[ ! -e "swig-$COMPOMENTS_SWIG_VERSION" ]]; then
  git clone -b "$COMPOMENTS_SWIG_VERSION" --depth 1 "https://github.com/swig/swig.git" "swig-$COMPOMENTS_SWIG_VERSION"
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
fi

check_and_download "distribution-stage1.cmake" "distribution-stage1.cmake" "https://raw.githubusercontent.com/owent-utils/bash-shell/main/LLVM%26Clang%20Installer/12.0/distribution-stage1.cmake" "distribution-stage1.cmake"
if [[ $? -ne 0 ]]; then
  exit 1
fi

check_and_download "distribution-stage2.cmake" "distribution-stage2.cmake" "https://raw.githubusercontent.com/owent-utils/bash-shell/main/LLVM%26Clang%20Installer/12.0/distribution-stage2.cmake" "distribution-stage2.cmake"
if [[ $? -ne 0 ]]; then
  exit 1
fi

if [[ $BUILD_DOWNLOAD_ONLY -ne 0 ]]; then
  exit 0
fi

export LLVM_DIR="$PWD/llvm-project-$LLVM_VERSION"

function build_llvm_toolchain() {
  STAGE_BUILD_EXT_COMPILER_FLAGS=("-DCMAKE_FIND_ROOT_PATH=$PREFIX_DIR"
    "-DCMAKE_PREFIX_PATH=$PREFIX_DIR")

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
    export LDFLAGS="-L$PREFIX_DIR/lib"
  else
    export LDFLAGS="$LDFLAGS -L$PREFIX_DIR/lib"
  fi

  if [[ ! -z "$BUILD_USE_GCC_TOOLCHAIN" ]]; then
    export LIBCXXABI_GCC_TOOLCHAIN=$BUILD_USE_GCC_TOOLCHAIN
    STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}"
      "-DBOOTSTRAP_CMAKE_CXX_FLAGS=--gcc-toolchain=$BUILD_USE_GCC_TOOLCHAIN"
      "-DBOOTSTRAP_CMAKE_C_FLAGS=--gcc-toolchain=$BUILD_USE_GCC_TOOLCHAIN")
  fi

  if [[ ! -z "$BUILD_USE_LD" ]]; then
    STAGE_BUILD_EXT_COMPILER_FLAGS=("${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}" "-DLLVM_USE_LINKER=$BUILD_USE_LD")
  fi

  which ninja >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    BUILD_WITH_NINJA="-G Ninja"
  else
    which ninja-build >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      BUILD_WITH_NINJA="-G Ninja"
    else
      BUILD_WITH_NINJA=""
    fi
  fi

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

  PASSTHROUGH_CMAKE_OPTIONS="CMAKE_INSTALL_PREFIX;CMAKE_FIND_ROOT_PATH;CMAKE_PREFIX_PATH;LLVM_PARALLEL_LINK_JOBS"
  PASSTHROUGH_CMAKE_OPTIONS="$PASSTHROUGH_CMAKE_OPTIONS;PYTHON_HOME;LLDB_PYTHON_VERSION;LLDB_ENABLE_PYTHON;LLDB_RELOCATABLE_PYTHON"
  cmake "$LLVM_DIR/llvm" $BUILD_WITH_NINJA "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR" \
    -C "$BUILD_STAGE_CACHE_FILE" "-DCLANG_BOOTSTRAP_PASSTHROUGH=$PASSTHROUGH_CMAKE_OPTIONS" \
    $BUILD_LLVM_PATCHED_OPTION "${STAGE_BUILD_EXT_COMPILER_FLAGS[@]}" "$@"
  if [[ 0 -ne $? ]]; then
    echo -e "\\033[31;1mError: build llvm failed when run cmake.\\033[39;49;0m"
    return 1
  fi

  # 这里会消耗茫茫多内存，所以尝试先开启多进程编译，失败之后降级到单进程
  cmake --build . $BUILD_JOBS_OPTION --config $BUILD_TYPE --target stage2 stage2-distribution \
    || cmake --build . -j2 --config $BUILD_TYPE --target stage2 stage2-distribution \
    || cmake --build . --config $BUILD_TYPE --target stage2 stage2-distribution

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

  if [[ -e "/dev/shm/build-install-llvm/build_jobs_dir" ]]; then
    cd ..
    rm -rf "/dev/shm/build-install-llvm/build_jobs_dir"
    rm -rf "$LLVM_DIR/build_jobs_dir"
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
  env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure --prefix=$PREFIX_DIR --with-pic=yes
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
  cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=YES -DBUILD_SHARED_LIBS=OFF "-DCMAKE_INSTALL_PREFIX=$PREFIX_DIR"
  cmake --build . -j $BUILD_JOBS_OPTION || cmake --build .
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
  env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure "--prefix=$PREFIX_DIR" --with-pic=yes
  make $BUILD_JOBS_OPTION || make
  if [[ $? -ne 0 ]]; then
    echo -e "\\033[31;1mBuild libffi failed.\\033[39;49;0m"
    exit 1
  fi
  make install
  cd "$WORKING_DIR"
fi

if [[ -z "$(find $PREFIX_DIR -name swig)" ]]; then
  cd "swig-$COMPOMENTS_SWIG_VERSION"
  ./autogen.sh
  make clean || true
  env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure "--prefix=$PREFIX_DIR"
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
  fi
  # --enable-optimizations require gcc 8.1.0 or later
  PYTHON_CONFIGURE_OPTIONS=("--prefix=$PREFIX_DIR" "--enable-optimizations" "--with-normal" "--with-cxx-binding"
    "--without-debug" "--with-ensurepip=install" "--enable-shared" "--enable-pc-files" "--with-system-ffi"
    "--with-pkg-config-libdir=$PREFIX_DIR/lib/pkgconfig")
  if [[ ! -z "$OPENSSL_INSTALL_DIR" ]]; then
    PYTHON_CONFIGURE_OPTIONS=(${PYTHON_CONFIGURE_OPTIONS[@]} "--with-openssl=$OPENSSL_INSTALL_DIR")
  fi
  make clean || true
  env LDFLAGS="${LDFLAGS//\$/\$\$}" ./configure ${PYTHON_CONFIGURE_OPTIONS[@]}
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

  DEP_COMPILER_HOME="$(dirname "$(dirname "$ORIGIN_COMPILER_CXX")")"
  echo "#!/bin/bash

if [[ \"x\$GCC_HOME_DIR\" == \"x\" ]]; then
    GCC_HOME_DIR=\"$DEP_COMPILER_HOME\";
fi" >"$PREFIX_DIR/load-llvm-envs.sh"

  echo '
GCC_HOME_DIR="$(readlink -f "$GCC_HOME_DIR")";
LLVM_HOME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )";
LLVM_HOME_DIR="$(readlink -f "$LLVM_HOME_DIR")";
' >>"$PREFIX_DIR/load-llvm-envs.sh"
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
  echo '
if [[ "x/" == "x$GCC_HOME_DIR" ]] || [[ "x/usr" == "x$GCC_HOME_DIR" ]] || [[ "x/usr/local" == "x$GCC_HOME_DIR" ]] || [[ "x$LLVM_HOME_DIR" == "x$GCC_HOME_DIR" ]]; then
    if [[ "x$LD_LIBRARY_PATH" == "x" ]]; then
        export LD_LIBRARY_PATH="$LLVM_LD_LIBRARY_PATH" ;
    else
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LLVM_LD_LIBRARY_PATH" ;
    fi
    
    export PATH="$LLVM_HOME_DIR/bin:$LLVM_HOME_DIR/libexec:$PATH" ;
else
    if [[ "x$LD_LIBRARY_PATH" == "x" ]]; then
        export LD_LIBRARY_PATH="$LLVM_LD_LIBRARY_PATH:$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
    else
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LLVM_LD_LIBRARY_PATH:$GCC_HOME_DIR/lib64:$GCC_HOME_DIR/lib" ;
    fi
    
    export PATH="$LLVM_HOME_DIR/bin:$LLVM_HOME_DIR/libexec:$GCC_HOME_DIR/bin:$PATH" ;
fi

function build_with_llvm_clang() {
  export CC="$LLVM_HOME_DIR/bin/clang" ;
  export CXX="$LLVM_HOME_DIR/bin/clang++" ;
  export AR="$LLVM_HOME_DIR/bin/llvm-ar" ;
  export AS="$LLVM_HOME_DIR/bin/llvm-as" ;
' >>"$PREFIX_DIR/load-llvm-envs.sh"
  echo "  $LD_LOADER_SCRIPT" >>"$PREFIX_DIR/load-llvm-envs.sh"
  echo '  export RANLIB="$LLVM_HOME_DIR/bin/llvm-ranlib" ;
  export NM="$LLVM_HOME_DIR/bin/llvm-nm" ;
  export STRIP="$LLVM_HOME_DIR/bin/llvm-strip" ;
  export OBJCOPY="$LLVM_HOME_DIR/bin/llvm-objcopy" ;
  export OBJDUMP="$LLVM_HOME_DIR/bin/llvm-objdump" ;
  export READELF="$LLVM_HOME_DIR/bin/llvm-readelf" ;

  # Maybe need add --gcc-toolchain=$GCC_HOME_DIR to compile options
  "$@"
}
if [[ $# -gt 0 ]]; then
  build_with_llvm_clang "$@"
fi
' >>"$PREFIX_DIR/load-llvm-envs.sh"
  chmod +x "$PREFIX_DIR/load-llvm-envs.sh"

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
  echo -e "\\033[35;1m\tMaybe need add --gcc-toolchain=$GCC_HOME_DIR to compile options\\033[39;49;0m"
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
URL:            https://github.com/owent-utils/bash-shell/tree/master/LLVM%26Clang%20Installer
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

echo "Using:"
echo "    mkdir -pv \$HOME/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}"
echo "    cd $PREFIX_DIR && rpmbuild -bb --target=x86_64 SPECS/rpm.spec"
echo "to build rpm package."
