#!/bin/bash

###########################################################################
#  Change values here
#
SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version);
#
###########################################################################
#
# Don't change anything here
WORKING_DIR="$PWD";

ARCHS="i386 x86_64 armv7 armv7s arm64";
DEVELOPER_ROOT=$(xcode-select -print-path);
PROTOBUF_SRC_DIR="$PWD";
BUILD_TYPE="Release" ;
OTHER_CFLAGS="-fPIC" ;
LIB_CMAKE_FLAGS="-Dprotobuf_BUILD_TESTS=NO -Dprotobuf_BUILD_EXAMPLES=NO -DBUILD_SHARED_LIBS=NO";

# ======================= options ======================= 
while getopts "a:b:d:hi:r:s:-" OPTION; do
    case $OPTION in
        a)
            ARCHS="$OPTARG";
        ;;
        b)
            BUILD_TYPE="$OPTARG";
        ;;
        d)
            DEVELOPER_ROOT="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options] -r SOURCE_DIR [-- [cmake options]]";
            echo "options:";
            echo "-a [archs]                    which arch need to built, multiple values must be split by space(default: $ARCHS)";
            echo "-b [build type]               build type(default: $BUILD_TYPE, available: Debug, Release, RelWithDebInfo, MinSizeRel)";
            echo "-d [developer root directory] developer root directory, we use xcode-select -print-path to find default value.(default: $DEVELOPER_ROOT)";
            echo "-h                            help message.";
            echo "-i [option]                   enable bitcode support(available: off, all, bitcode, marker)";
            echo "-s [sdk version]              sdk version, we use xcrun -sdk iphoneos --show-sdk-version to find default value.(default: $SDKVERSION)";
            echo "-r [source dir]               root directory of this library";
            exit 0;
        ;;
        i)
            if [ ! -z "$OPTARG" ]; then
                OTHER_CFLAGS="$OTHER_CFLAGS -fembed-bitcode=$OPTARG";
            else
                OTHER_CFLAGS="$OTHER_CFLAGS -fembed-bitcode";
            fi
        ;;
        r)
            PROTOBUF_SRC_DIR="$OPTARG";
        ;;
        s)
            SDKVERSION="$OPTARG";
        ;;
        -) 
            break;
            break;
        ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

shift $(($OPTIND-1));

echo "Ready to build for ios";
echo "WORKING_DIR=${WORKING_DIR}";
echo "ARCHS=${ARCHS}";
echo "DEVELOPER_ROOT=${DEVELOPER_ROOT}";
echo "SDKVERSION=${SDKVERSION}";
echo "make options=$@";

##########
if [ ! -e "$PROTOBUF_SRC_DIR/cmake/CMakeLists.txt" ]; then
    echo "$PROTOBUF_SRC_DIR/cmake/CMakeLists.txt not found";
    exit -2;
fi
PROTOBUF_SRC_DIR="$(cd "$PROTOBUF_SRC_DIR/cmake" && pwd)";

mkdir -p "$WORKING_DIR/bin";
mkdir -p "$WORKING_DIR/lib";

# 交叉编译前需要先编译一个本地的protoc和js_embed出来
if [ ! -e "$WORKING_DIR/build_job_dir/host" ]; then
    mkdir -p "$WORKING_DIR/build_job_dir/host-build";
    mkdir -p "$WORKING_DIR/build_job_dir/host";
    cd "$WORKING_DIR/build_job_dir/host-build";
    cmake "$PROTOBUF_SRC_DIR" "-DCMAKE_INSTALL_PREFIX=$WORKING_DIR/build_job_dir/host" -Dprotobuf_BUILD_TESTS=NO -Dprotobuf_BUILD_EXAMPLES=NO -DBUILD_SHARED_LIBS=NO;
    cmake --build . --target install;
    cd - ;
fi
export PATH=$WORKING_DIR/build_job_dir/host/bin:$WORKING_DIR/build_job_dir/host-build:$PATH;

for ARCH in ${ARCHS}; do
    echo "================== Compling $ARCH ==================";
    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    echo "Building protobuf for ${PLATFORM} ${SDKVERSION} ${ARCH}"
    
    echo "Patching Makefile...";
    if [ -e "Makefile.bak" ]; then
        mv -f Makefile.bak Makefile;
    fi
    
    # sed -i.bak '4d' Makefile;
    echo "Please stand by..."
    
    export DEVROOT="${DEVELOPER_ROOT}/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
    export BUILD_TOOLS="${DEVELOPER_ROOT}"
    #export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
    #export CC=${BUILD_TOOLS}/usr/bin/gcc
    #export LD=${BUILD_TOOLS}/usr/bin/ld
    #export CPP=${BUILD_TOOLS}/usr/bin/cpp
    #export CXX=${BUILD_TOOLS}/usr/bin/g++
    #export AR=${DEVROOT}/usr/bin/ar
    #export AS=${DEVROOT}/usr/bin/as
    #export NM=${DEVROOT}/usr/bin/nm
    #export CXXCPP=${BUILD_TOOLS}/usr/bin/cpp
    #export RANLIB=${BUILD_TOOLS}/usr/bin/ranlib
    #export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT}"
    #export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I$PROTOBUF_SRC_DIR/include"
   
    if [ -e "$WORKING_DIR/build_job_dir/$ARCH" ]; then
        rm -rf "$WORKING_DIR/build_job_dir/$ARCH";
    fi
    mkdir -p "$WORKING_DIR/build_job_dir/$ARCH";
    cd "$WORKING_DIR/build_job_dir/$ARCH";
    
    # add -DCMAKE_OSX_DEPLOYMENT_TARGET=7.1 to specify the min SDK version
    mkdir -p "$WORKING_DIR/install/$ARCH";
    cmake "$PROTOBUF_SRC_DIR" -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX="$WORKING_DIR/install/$ARCH" \
          -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_SYSROOT=$SDKROOT -DCMAKE_OSX_ARCHITECTURES=$ARCH \
          -DCMAKE_C_FLAGS="$OTHER_CFLAGS" -DCMAKE_CXX_FLAGS="$OTHER_CFLAGS" $LIB_CMAKE_FLAGS "$@";
    cmake --build . --target install ;
done

cd "$WORKING_DIR";
echo "Linking and packaging library...";

for LIB_NAME in "libprotobuf" "libprotobuf-lite" "libprotoc"; do
    lipo -create $(find "$WORKING_DIR/install" -name $LIB_NAME.a) -output "$WORKING_DIR/lib/$LIB_NAME.a";
done

if [ -e "$WORKING_DIR/include" ] && [ "$WORKING_DIR" != "$PROTOBUF_SRC_DIR" ] ; then
    rm -rf "$WORKING_DIR/include";
fi

for INC_DIR in $(find "$WORKING_DIR/install" -name include); do
    cp -rf "$INC_DIR" "$WORKING_DIR/include";
    break;
done

echo "Building done.";
