#!/bin/bash

#
###########################################################################
#
# Don't change anything here
WORKING_DIR="$PWD";

ARCHS="x86 x86_64 armeabi armeabi-v7a arm64-v8a";
NDK_ROOT=$NDK_ROOT;
MBEDTLS_DIR="$PWD";
ANDROID_NATIVE_API_LEVEL=16 ;
ANDROID_TOOLCHAIN=clang ;
ANDROID_STL= ; #
BUILD_TYPE="Release" ;

# ======================= options ======================= 
while getopts "a:b:c:n:hl:r:t:-" OPTION; do
    case $OPTION in
        a)
            ARCHS="$OPTARG";
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
            MBEDTLS_DIR="$OPTARG";
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

echo "Ready to build for ios";
echo "WORKING_DIR=${WORKING_DIR}";
echo "ARCHS=${ARCHS}";
echo "ANDROID_STL=${ANDROID_STL}";
echo "NDK_ROOT=${NDK_ROOT}";
echo "ANDROID_TOOLCHAIN=${ANDROID_TOOLCHAIN}";
echo "ANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}";
echo "cmake options=$@";
echo "SOURCE=$SRC_DIR";


##########
if [ ! -e "$MBEDTLS_DIR/CMakeLists.txt" ]; then
    echo "$MBEDTLS_DIR/CMakeLists.txt not found";
    exit -2;
fi
MBEDTLS_DIR="$(cd "$MBEDTLS_DIR" && pwd)";

mkdir -p "$WORKING_DIR/lib";

CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=$ANDROID_TOOLCHAIN;
if [ "${ANDROID_TOOLCHAIN:0:5}" != "clang" ]; then
    ANDROID_TOOLCHAIN="gcc";
fi

for ARCH in ${ARCHS}; do
    echo "================== Compling $ARCH ==================";
    echo "Building mbedtls for android-$ANDROID_NATIVE_API_LEVEL ${ARCH}"
    
    # sed -i.bak '4d' Makefile;
    echo "Please stand by..."
    if [ -e "$WORKING_DIR/build/$ARCH" ]; then
        rm -rf "$WORKING_DIR/build/$ARCH";
    fi
    mkdir -p "$WORKING_DIR/build/$ARCH";
    cd "$WORKING_DIR/build/$ARCH";
    
    mkdir -p "$WORKING_DIR/lib/$ARCH";

    # 64 bits must at least using android-21
    # @see $NDK_ROOT/build/cmake/android.toolchain.cmake
    echo $ARCH | grep -E '64(-v8a)?$' ;
    if [ $? -eq 0 ] && [ $ANDROID_NATIVE_API_LEVEL -lt 21 ]; then
        ANDROID_NATIVE_API_LEVEL=21 ;
    fi

    cmake "$MBEDTLS_DIR" -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX="$WORKING_DIR/$ARCH" \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="$WORKING_DIR/lib/$ARCH" -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="$WORKING_DIR/lib/$ARCH" \
        -DCMAKE_TOOLCHAIN_FILE="$NDK_ROOT/build/cmake/android.toolchain.cmake" \
        -DANDROID_NDK="$NDK_ROOT" -DCMAKE_ANDROID_NDK="$NDK_ROOT" \
        -DANDROID_NATIVE_API_LEVEL=$ANDROID_NATIVE_API_LEVEL -DCMAKE_ANDROID_API=$ANDROID_NATIVE_API_LEVEL \
        -DANDROID_TOOLCHAIN=$ANDROID_TOOLCHAIN -DCMAKE_ANDROID_NDK_TOOLCHAIN_VERSION=$CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION \
        -DANDROID_ABI=$ARCH -DCMAKE_ANDROID_ARCH_ABI=$ARCH \
        -DANDROID_STL=$ANDROID_STL -DCMAKE_ANDROID_STL_TYPE=$ANDROID_STL \
        -DANDROID_PIE=YES -DENABLE_TESTING=NO "$@";

    cmake --build . --target install ;
done

echo "Building done.";
