#!/bin/bash

#  Automatic build script for mbedtls
#  for iPhoneOS and iPhoneSimulator
#
#  Created by owent Schulze on 2016.12.08.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
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
DEVELOPER=$(xcode-select -print-path);

if [ $# -lt 1 ]; then
    echo "Usage: $0 <mbedtle-* dir name>";
    exit -1;  
fi

MBEDTLS_DIR="$(cd "$1" && pwd)";
shift;

##########
if [ ! -e "$MBEDTLS_DIR/CMakeLists.txt" ]; then
    echo "$MBEDTLS_DIR/CMakeLists.txt not found";
    exit -2;
fi

mkdir -p "$WORKING_DIR/bin";
mkdir -p "$WORKING_DIR/lib";

for ARCH in ${ARCHS}; do
    echo "================== Compling $ARCH ==================";
    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    echo "Building mbedtls for ${PLATFORM} ${SDKVERSION} ${ARCH}"
    
    echo "Patching Makefile...";
    if [ -e "Makefile.bak" ]; then
        mv -f Makefile.bak Makefile;
    fi
    
    # sed -i.bak '4d' Makefile;
    echo "Please stand by..."
    
    export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
    export BUILD_TOOLS="${DEVELOPER}"
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
    #export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I$MBEDTLS_DIR/include"
   
    if [ -e "$WORKING_DIR/build/$ARCH" ]; then
        rm -rf "$WORKING_DIR/build/$ARCH";
    fi
    mkdir -p "$WORKING_DIR/build/$ARCH";
    cd "$WORKING_DIR/build/$ARCH";
    
    # add -DCMAKE_OSX_DEPLOYMENT_TARGET=7.1 to specify the min SDK version
    cmake "$MBEDTLS_DIR" -DCMAKE_OSX_SYSROOT=$SDKROOT -DCMAKE_SYSROOT=$SDKROOT -DCMAKE_OSX_ARCHITECTURES=$ARCH -DCMAKE_C_FLAGS="-fPIC" "$@";
    make -j4;
done

cd "$WORKING_DIR";
echo "Linking and packaging library...";

for LIB_NAME in "libmbedtls" "libmbedcrypto" "libmbedx509"; do
    lipo -create $(find "$WORKING_DIR/build" -name $LIB_NAME.a) -output "$WORKING_DIR/lib/$LIB_NAME.a";
done

if [ -e "$WORKING_DIR/include" ] && [ "$WORKING_DIR" != "$MBEDTLS_DIR" ] ; then
    rm -rf "$WORKING_DIR/include";
fi

cp -rf "$MBEDTLS_DIR/include" "$WORKING_DIR/include";

echo "Building done.";
