#!/bin/bash

#
###########################################################################
#
# Don't change anything here
WORKING_DIR="$PWD";

ARCHS="x86 x86_64 armeabi armeabi-v7a arm64-v8a";
NDK_ROOT=$NDK_ROOT;
PROTOBUF_SRC_DIR="$PWD";
ANDROID_NATIVE_API_LEVEL=16 ;
ANDROID_TOOLCHAIN=clang ;
ANDROID_STL=c++_static ; #
BUILD_TYPE="Release" ;   
# OTHER_CFLAGS="-fPIC" ; # Android使用-DANDROID_PIE=YES
OTHER_LD_FLAGS="-llog";  # protobuf依赖liblog.so
LIB_CMAKE_FLAGS="-Dprotobuf_BUILD_TESTS=NO -Dprotobuf_BUILD_EXAMPLES=NO -DBUILD_SHARED_LIBS=NO";

# ======================= options ======================= 
while getopts "a:b:c:n:hl:r:t:-" OPTION; do
    case $OPTION in
        a)
            ARCHS="$OPTARG";
        ;;
        b)
            BUILD_TYPE="$OPTARG";
        ;;
        c)
            ANDROID_STL="$OPTARG";
        ;;
        n)
            NDK_ROOT="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options] -n NDK_ROOT -r SOURCE_DIR [-- [cmake options]]";
            echo "options:";
            echo "-a [archs]                    which arch need to built, multiple values must be split by space(default: $ARCHS)";
            echo "-b [build type]               build type(default: $BUILD_TYPE, available: Debug, Release, RelWithDebInfo, MinSizeRel)";
            echo "-c [android stl]              stl used by ndk(default: $ANDROID_STL, available: system, stlport_static, stlport_shared, gnustl_static, gnustl_shared, c++_static, c++_shared, none)";
            echo "-n [ndk root directory]       ndk root directory.(default: $DEVELOPER_ROOT)";
            echo "-l [api level]                API level, see $NDK_ROOT/platforms for detail.(default: $ANDROID_NATIVE_API_LEVEL)";
            echo "-r [source dir]               root directory of this library";
            echo "-t [toolchain]                ANDROID_TOOLCHAIN.(gcc version/clang, default: $ANDROID_TOOLCHAIN, @see CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION in cmake)";
            echo "-h                            help message.";
            exit 0;
        ;;
        r)
            PROTOBUF_SRC_DIR="$OPTARG";
        ;;
        t)
            ANDROID_TOOLCHAIN="$OPTARG";
        ;;
        l)
            ANDROID_NATIVE_API_LEVEL=$OPTARG;
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

echo "Ready to build for android";
echo "WORKING_DIR=${WORKING_DIR}";
echo "ARCHS=${ARCHS}";
echo "ANDROID_STL=${ANDROID_STL}";
echo "NDK_ROOT=${NDK_ROOT}";
echo "ANDROID_TOOLCHAIN=${ANDROID_TOOLCHAIN}";
echo "ANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}";
echo "cmake options=$@";
echo "SOURCE=$SRC_DIR";


##########
if [ ! -e "$PROTOBUF_SRC_DIR/cmake/CMakeLists.txt" ]; then
    echo "$PROTOBUF_SRC_DIR/cmake/CMakeLists.txt not found";
    exit -2;
fi
PROTOBUF_SRC_DIR="$(cd "$PROTOBUF_SRC_DIR/cmake" && pwd)";

mkdir -p "$WORKING_DIR/lib";

CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=$ANDROID_TOOLCHAIN;
if [ "${ANDROID_TOOLCHAIN:0:5}" != "clang" ]; then
    ANDROID_TOOLCHAIN="gcc";
fi

# 交叉编译前需要先编译一个本地的protoc和js_embed出来
if [ ! -e "$WORKING_DIR/build_job_dir/host" ]; then
    mkdir -p "$WORKING_DIR/build_job_dir/host-build";
    mkdir -p "$WORKING_DIR/build_job_dir/host";
    cd "$WORKING_DIR/build_job_dir/host-build";
    cmake "$PROTOBUF_SRC_DIR" "-DCMAKE_INSTALL_PREFIX=$WORKING_DIR/build_job_dir/host" -Dprotobuf_BUILD_TESTS=NO -Dprotobuf_BUILD_EXAMPLES=NO -DBUILD_SHARED_LIBS=NO;
    cmake --build . --target install -- -j8 ;
    cd - ;
fi
export PATH=$WORKING_DIR/build_job_dir/host/bin:$WORKING_DIR/build_job_dir/host-build:$PATH;

for ARCH in ${ARCHS}; do
    echo "================== Compling $ARCH ==================";
    echo "Building protobuf for android-$ANDROID_NATIVE_API_LEVEL ${ARCH}"
    
    # sed -i.bak '4d' Makefile;
    echo "Please stand by..."
    if [ -e "$WORKING_DIR/build_job_dir/$ARCH" ]; then
        rm -rf "$WORKING_DIR/build_job_dir/$ARCH";
    fi
    mkdir -p "$WORKING_DIR/build_job_dir/$ARCH";
    cd "$WORKING_DIR/build_job_dir/$ARCH";
    
    mkdir -p "$WORKING_DIR/lib/$ARCH";

    # 64 bits must at least using android-21
    # @see $NDK_ROOT/build/cmake/android.toolchain.cmake
    echo $ARCH | grep -E '64(-v8a)?$' ;
    if [ $? -eq 0 ] && [ $ANDROID_NATIVE_API_LEVEL -lt 21 ]; then
        ANDROID_NATIVE_API_LEVEL=21 ;
    fi

    cmake "$PROTOBUF_SRC_DIR" -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX="$WORKING_DIR/$ARCH" \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="$WORKING_DIR/lib/$ARCH" -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="$WORKING_DIR/lib/$ARCH" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_ROOT/build/cmake/android.toolchain.cmake" \
        -DANDROID_NDK="$NDK_ROOT" -DCMAKE_ANDROID_NDK="$NDK_ROOT" \
        -DANDROID_NATIVE_API_LEVEL=$ANDROID_NATIVE_API_LEVEL -DCMAKE_ANDROID_API=$ANDROID_NATIVE_API_LEVEL \
        -DANDROID_TOOLCHAIN=$ANDROID_TOOLCHAIN -DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=$CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION \
        -DANDROID_ABI=$ARCH -DCMAKE_ANDROID_ARCH_ABI=$ARCH \
        -DANDROID_STL=$ANDROID_STL -DCMAKE_ANDROID_STL_TYPE=$ANDROID_STL \
        -DANDROID_PIE=YES -DCMAKE_SHARED_LINKER_FLAGS="$OTHER_LD_FLAGS" -DCMAKE_EXE_LINKER_FLAGS="$OTHER_LD_FLAGS" $LIB_CMAKE_FLAGS "$@";

    cmake --build . --target install -- -j8 ;

done

echo "Building done." ;
