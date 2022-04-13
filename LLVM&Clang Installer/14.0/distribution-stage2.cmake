# This file sets up a CMakeCache for the second stage of a simple distribution
# bootstrap build.
# See https://github.com/llvm/llvm-project/blob/release/14.x/clang/cmake/caches/Fuchsia-stage2.cmake

# See LLVM_ALL_RUNTIMES in https://github.com/llvm/llvm-project/blob/main/runtimes/CMakeLists.txt See LLVM_ALL_PROJECTS
# in https://github.com/llvm/llvm-project/blob/main/llvm/CMakeLists.txt

# 未来版本测试polly, 12.0 版本编译不过

# 这个版本的libc适配有点问题，这个版本增加了thread模块，对 ```stdatomic.h``` 的适配有问题，故而排除

# set(LLVM_ENABLE_PROJECTS
# "clang;clang-tools-extra;compiler-rt;libc;libclc;libcxx;libcxxabi;libunwind;lld;lldb;mlir;openmp;parallel-libs;polly;pstl"
# CACHE STRING "")

set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld;llvm;lldb;libclc;parallel-libs;pstl" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "") # X86;ARM;AArch64;RISCV

# Setup vendor-specific settings.
set(PACKAGE_VENDOR OWenT CACHE STRING "")

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH OFF CACHE BOOL "")
set(CMAKE_BUILD_WITH_INSTALL_RPATH ON CACHE BOOL "")
set(CMAKE_BUILD_RPATH_USE_ORIGIN ON CACHE BOOL "")
set(LLVM_BUILD_EXAMPLES OFF CACHE BOOL "")
set(LLVM_BUILD_TESTS OFF CACHE BOOL "")
set(LLVM_ENABLE_EH ON CACHE BOOL "")
set(LLVM_ENABLE_RTTI ON CACHE BOOL "")
set(LLVM_ENABLE_PIC ON CACHE BOOL "")
set(LLVM_USE_INTEL_JITEVENTS ON CACHE BOOL "")
set(CLANG_LINK_CLANG_DYLIB ON CACHE BOOL "")
set(LLVM_BUILD_LLVM_DYLIB ON CACHE BOOL "")
set(LLVM_LINK_LLVM_DYLIB ON CACHE BOOL "")
set(LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
set(LLVM_ENABLE_LIBCXX ON CACHE BOOL "")
if(NOT APPLE)
  # TODO: Remove this once we switch to ld64.lld.
  set(LLVM_ENABLE_LLD ON CACHE BOOL "")
endif()
set(LLVM_ENABLE_LTO ON CACHE BOOL "")
set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")
set(LLVM_USE_RELATIVE_PATHS_IN_FILES ON CACHE BOOL "")
if(WIN32)
  set(LLVM_USE_CRT_RELEASE "MT" CACHE STRING "")
endif()
set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
if(NOT APPLE)
  # TODO: Remove this once we switch to ld64.lld.
  set(CLANG_DEFAULT_LINKER lld CACHE STRING "")
  set(CLANG_DEFAULT_OBJCOPY llvm-objcopy CACHE STRING "")
endif()
set(CLANG_DEFAULT_RTLIB compiler-rt CACHE STRING "")
set(CLANG_ENABLE_STATIC_ANALYZER ON CACHE BOOL "")

set(ENABLE_EXPERIMENTAL_NEW_PASS_MANAGER ON CACHE BOOL "")
set(ENABLE_LINKER_BUILD_ID ON CACHE BOOL "")
set(ENABLE_X86_RELAX_RELOCATIONS ON CACHE BOOL "")

set(CMAKE_BUILD_TYPE Release CACHE STRING "")
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "")
elseif(WIN32)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE STRING "")
endif()

if(APPLE)
  list(APPEND BUILTIN_TARGETS "default")
  list(APPEND RUNTIME_TARGETS "default")

  set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
  set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
  set(LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBUNWIND_INSTALL_LIBRARY ON CACHE BOOL "")
  set(LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
  set(LIBCXXABI_INSTALL_LIBRARY ON CACHE BOOL "")
  set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
  set(LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
  set(LIBCXX_ABI_VERSION 2 CACHE STRING "")
  set(DARWIN_ios_ARCHS armv7;armv7s;arm64 CACHE STRING "")
  set(DARWIN_iossim_ARCHS i386;x86_64 CACHE STRING "")
  set(DARWIN_osx_ARCHS arm64;x86_64 CACHE STRING "")
  set(SANITIZER_MIN_OSX_VERSION 10.7 CACHE STRING "")
endif()

if(WIN32)
  set(target "x86_64-pc-windows-msvc")

  list(APPEND BUILTIN_TARGETS "${target}")
  set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Windows CACHE STRING "")
  set(BUILTINS_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")

  list(APPEND RUNTIME_TARGETS "${target}")
  set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME Windows CACHE STRING "")
  set(RUNTIMES_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
  set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_EXPERIMENTAL_LIBRARY OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_FILESYSTEM OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_ABI_LINKER_SCRIPT OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx" CACHE STRING "")
endif()

# Cross compiling
if("${LLVM_TARGETS_TO_BUILD}" MATCHES "Native|X86")
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
      set(LINUX_NATIVE_TARGET x86_64-unknown-linux-gnu)
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i386|i686|x86")
      set(LINUX_NATIVE_TARGET i386-unknown-linux-gnu)
    endif()
  elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    cmake_host_system_information(RESULT LINUX_NATIVE_IS_64BIT QUERY IS_64BIT)
    if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64" OR ("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL ""
                                                        AND LINUX_NATIVE_IS_64BIT))
      set(LINUX_NATIVE_TARGET x86_64-unknown-linux-gnu)
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "i386|i686|x86" OR "${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "")
      set(LINUX_NATIVE_TARGET i386-unknown-linux-gnu)
    endif()
  endif()
endif()
message(STATUS "Stage2: CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")
message(STATUS "Stage2: CMAKE_SYSTEM_PROCESSOR=${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Stage2: CMAKE_SYSTEM_VERSION=${CMAKE_SYSTEM_VERSION}")
message(STATUS "Stage2: CMAKE_HOST_SYSTEM_NAME=${CMAKE_HOST_SYSTEM_NAME}")
message(STATUS "Stage2: CMAKE_HOST_SYSTEM_PROCESSOR=${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "Stage2: CMAKE_HOST_SYSTEM_VERSION=${CMAKE_HOST_SYSTEM_VERSION}")
message(STATUS "Stage2: LLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}")
message(STATUS "Stage2: LINUX_NATIVE_IS_64BIT=${LINUX_NATIVE_IS_64BIT}")
message(STATUS "Stage2: LINUX_NATIVE_TARGET=${LINUX_NATIVE_TARGET}")

foreach(target aarch64-unknown-linux-gnu;armv7-unknown-linux-gnueabihf;i386-unknown-linux-gnu;x86_64-unknown-linux-gnu)
  if(LINUX_${target}_SYSROOT OR target STREQUAL "${LINUX_NATIVE_TARGET}")
    # Set the per-target builtins options.
    list(APPEND BUILTIN_TARGETS "${target}")
    set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_C_FLAGS "--target=${target}" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_CXX_FLAGS "--target=${target}" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_ASM_FLAGS "--target=${target}" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SYSROOT ${LINUX_${target}_SYSROOT} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_EXE_LINKER_FLAG "-fuse-ld=lld" CACHE STRING "")

    # Set the per-target runtimes options.
    list(APPEND RUNTIME_TARGETS "${target}")
    set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_C_FLAGS "--target=${target}" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_CXX_FLAGS "--target=${target}" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_ASM_FLAGS "--target=${target}" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SYSROOT ${LINUX_${target}_SYSROOT} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_MODULE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    # if("x86_64-unknown-linux-gnu" STREQUAL "${target}" AND NOT EXISTS "/usr/include/gnu/stubs-32.h")
    # set(RUNTIMES_${target}_COMPILER_RT_DEFAULT_TARGET_ONLY ON CACHE BOOL "") # Do not build i386 on x86_64 endif()
    set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_INSTALL_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_SHARED ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_INSTALL_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
    set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

    # Use .build-id link.
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}")
  endif() # LLVM_TARGETS_TO_BUILD
  message(STATUS "Stage2: LINUX_${target}_SYSROOT=${LINUX_${target}_SYSROOT}")
endforeach()

if(ANDROID)
  set(CLANG_VENDOR Android CACHE STRING "")
  set(LLVM_ENABLE_THREADS OFF CACHE BOOL "")
  set(LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
  set(LLVM_LIBDIR_SUFFIX 64 CACHE STRING "")

  set(ANDROID_RUNTIMES_ENABLE_ASSERTIONS ON CACHE BOOL "")
  set(ANDROID_RUNTIMES_BUILD_TYPE Release CACHE STRING "")
  set(ANDROID_BUILTINS_BUILD_TYPE Release CACHE STRING "")

  # set(BUILTIN_TARGETS "i686-linux-android;x86_64-linux-android;aarch64-linux-android;armv7-linux-android" CACHE STRING
  # "")

  # set(RUNTIME_TARGETS "i686-linux-android;x86_64-linux-android;aarch64-linux-android;armv7-linux-android" CACHE STRING
  # "")

  set(BUILTIN_TARGETS "x86_64-linux-android;aarch64-linux-android" CACHE STRING "")
  set(RUNTIME_TARGETS "x86_64-linux-android;aarch64-linux-android" CACHE STRING "")
  foreach(target i686;x86_64;aarch64;armv7)
    set(BUILTINS_${target}-linux-android_ANDROID 1 CACHE STRING "")
    set(BUILTINS_${target}-linux-android_CMAKE_BUILD_TYPE ${ANDROID_BUILTINS_BUILD_TYPE} CACHE STRING "")
    set(BUILTINS_${target}-linux-android_CMAKE_ASM_FLAGS ${ANDROID_${target}_C_FLAGS} CACHE PATH "")
    set(BUILTINS_${target}-linux-android_CMAKE_C_FLAGS ${ANDROID_${target}_C_FLAGS} CACHE PATH "")
    set(BUILTINS_${target}-linux-android_CMAKE_SYSROOT ${ANDROID_${target}_SYSROOT} CACHE PATH "")
    set(BUILTINS_${target}-linux-android_CMAKE_EXE_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
    set(BUILTINS_${target}-linux-android_CMAKE_SHARED_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
    set(BUILTINS_${target}-linux-android_CMAKE_MOUDLE_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
  endforeach()

  foreach(target i686;x86_64;aarch64;armv7)
    set(RUNTIMES_${target}-linux-android_ANDROID 1 CACHE STRING "")
    set(RUNTIMES_${target}-linux-android_CMAKE_ASM_FLAGS ${ANDROID_${target}_C_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_BUILD_TYPE ${ANDROID_RUNTIMES_BUILD_TYPE} CACHE STRING "")
    set(RUNTIMES_${target}-linux-android_CMAKE_C_FLAGS ${ANDROID_${target}_C_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_CXX_FLAGS ${ANDROID_${target}_CXX_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_SYSROOT ${ANDROID_${target}_SYSROOT} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_EXE_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_SHARED_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_CMAKE_MODULE_LINKER_FLAGS ${ANDROID_${target}_LINKER_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_COMPILER_RT_ENABLE_WERROR ON CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_COMPILER_RT_TEST_COMPILER_CFLAGS ${ANDROID_${target}_C_FLAGS} CACHE PATH "")
    set(RUNTIMES_${target}-linux-android_COMPILER_RT_INCLUDE_TESTS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LLVM_ENABLE_ASSERTIONS ${ANDROID_RUNTIMES_ENABLE_ASSERTIONS} CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LLVM_ENABLE_LIBCXX ON CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LLVM_ENABLE_THREADS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LLVM_INCLUDE_TESTS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LIBUNWIND_HAS_NO_EXCEPTIONS_FLAG ON CACHE BOOL "")
    set(RUNTIMES_${target}-linux-android_LIBUNWIND_HAS_FUNWIND_TABLES ON CACHE BOOL "")
  endforeach()

  set(RUNTIMES_armv7-linux-android_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
endif()

# FUCHSIA
if(FUCHSIA_SDK)
  set(FUCHSIA_aarch64_NAME arm64)
  set(FUCHSIA_i386_NAME x64)
  set(FUCHSIA_x86_64_NAME x64)
  set(FUCHSIA_riscv64_NAME riscv64)
  foreach(target i386;x86_64;aarch64;riscv64)
    set(FUCHSIA_${target}_COMPILER_FLAGS "--target=${target}-unknown-fuchsia -I${FUCHSIA_SDK}/pkg/fdio/include")
    set(FUCHSIA_${target}_LINKER_FLAGS "-L${FUCHSIA_SDK}/arch/${FUCHSIA_${target}_NAME}/lib")
    set(FUCHSIA_${target}_SYSROOT "${FUCHSIA_SDK}/arch/${FUCHSIA_${target}_NAME}/sysroot")
  endforeach()

  foreach(target i386;x86_64;aarch64;riscv64)
    # Set the per-target builtins options.
    list(APPEND BUILTIN_TARGETS "${target}-unknown-fuchsia")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_SYSTEM_NAME Fuchsia CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_ASM_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_C_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_CXX_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_SHARED_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_MODULE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_EXE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}-unknown-fuchsia_CMAKE_SYSROOT ${FUCHSIA_${target}_SYSROOT} CACHE PATH "")
  endforeach()

  foreach(target x86_64;aarch64)
    # Set the per-target runtimes options.
    list(APPEND RUNTIME_TARGETS "${target}-unknown-fuchsia")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_SYSTEM_NAME Fuchsia CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_BUILD_WITH_INSTALL_RPATH ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_ASM_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_C_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_CXX_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_SHARED_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_MODULE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_EXE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_CMAKE_SYSROOT ${FUCHSIA_${target}_SYSROOT} CACHE PATH "")
    set(RUNTIMES_${target}-unknown-fuchsia_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBUNWIND_HERMETIC_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBUNWIND_INSTALL_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_HERMETIC_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_INSTALL_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXXABI_STATICALLY_LINK_UNWINDER_IN_SHARED_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXX_HERMETIC_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING
                                                                                                               "")

    set(RUNTIMES_${target}-unknown-fuchsia+asan_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}-unknown-fuchsia+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+asan+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables_CMAKE_CXX_FLAGS
        "${RUNTIMES_${target}-unknown-fuchsia+relative-vtables_CMAKE_CXX_FLAGS} -Xclang -fexperimental-relative-c++-abi-vtables"
        CACHE STRING "")

    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL
                                                                                                                   "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_CMAKE_CXX_FLAGS
        "${RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan_CMAKE_CXX_FLAGS} -Xclang -fexperimental-relative-c++-abi-vtables"
        CACHE STRING "")

    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+noexcept_CMAKE_CXX_FLAGS
        "${RUNTIMES_${target}-unknown-fuchsia+relative-vtables+noexcept_CMAKE_CXX_FLAGS} -Xclang -fexperimental-relative-c++-abi-vtables"
        CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF
        CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF
        CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_CMAKE_CXX_FLAGS
        "${RUNTIMES_${target}-unknown-fuchsia+relative-vtables+asan+noexcept_CMAKE_CXX_FLAGS} -Xclang -fexperimental-relative-c++-abi-vtables"
        CACHE STRING "")

    # Use .build-id link.
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}-unknown-fuchsia")
  endforeach()

  set(LLVM_RUNTIME_MULTILIBS "asan;noexcept;compat;asan+noexcept" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_asan_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_noexcept_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_compat_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_asan+noexcept_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
endif()

# Platform names
set(LLVM_BUILTIN_TARGETS "${BUILTIN_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_TARGETS "${RUNTIME_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_BUILD_ID_LINK_TARGETS "${RUNTIME_BUILD_ID_LINK}" CACHE STRING "")
# LLVM_TOOL_COMPILER_RT_BUILD

# Setup toolchain.
set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
# See <llvm-project>/llvm/test/CMakeLists.txt
set(LLVM_TOOLCHAIN_TOOLS_SELECT
    llvm-addr2line
    llvm-ar
    llvm-as
    llvm-config
    llvm-cov
    llvm-cxxdump
    llvm-cxxfilt
    llvm-cxxmap
    llvm-dlltool
    dsymutil
    llvm-dwarfdump
    llvm-dwp
    llvm-gsymutil
    llvm-install-name-tool
    llvm-jitlink
    llvm-jitlistener
    llvm-lib
    llvm-link
    llvm-lto
    llvm-lto2
    llvm-ml
    llvm-mt
    llvm-nm
    llvm-objcopy
    llvm-objdump
    llvm-pdbutil
    llvm-profdata
    llvm-ranlib
    llvm-rc
    llvm-readelf
    llvm-readobj
    llvm-size
    llvm-strings
    llvm-strip
    llvm-symbolizer
    llvm-xray
    LLVM
    LTO
    sancov
    sanstats
    Remarks)

if(APPLE)
  list(APPEND LLVM_TOOLCHAIN_TOOLS_SELECT llvm-bitcode-strip llvm-ifs llvm-lipo llvm-libtool-darwin)
endif()
set(LLVM_TOOLCHAIN_TOOLS ${LLVM_TOOLCHAIN_TOOLS_SELECT} CACHE STRING "")

set(LLVM_DISTRIBUTION_COMPONENTS
    # add_lld_tool(...) in <llvm-project>/lld
    lld
    # add_lldb_library(...) in <llvm-project>/lldb
    liblldb
    # add_lldb_tool(...) in <llvm-project>/lldb
    lldb
    lldb-server
    lldb-python-scripts
    lldb-vscode
    # clang
    libclang-headers
    libclang-python-bindings
    libclang
    # add_clang_tool(xxx) in <llvm-project>/clang
    clang
    clang-apply-replacements
    clang-change-namespace
    clang-check
    clang-cpp
    clang-doc
    clang-format
    clang-include-fixer
    clang-refactor
    clang-scan-deps
    clang-tidy
    clangd
    modularize
    pp-trace
    clang-libraries
    clang-resource-headers
    scan-build
    scan-view
    # Others
    builtins
    runtimes
    opt-viewer
    ${LLVM_TOOLCHAIN_TOOLS}
    CACHE STRING "")
