# This file sets up a CMakeCache for the second stage of a simple distribution
# bootstrap build.
# See https://github.com/llvm/llvm-project/blob/release/12.x/clang/cmake/caches/Fuchsia-stage2.cmake

# See LLVM_ALL_RUNTIMES in https://github.com/llvm/llvm-project/blob/main/runtimes/CMakeLists.txt See LLVM_ALL_PROJECTS
# in https://github.com/llvm/llvm-project/blob/main/llvm/CMakeLists.txt

# 未来版本测试polly, 12.0 版本编译不过

# 这个版本的libc适配有点问题，这个版本增加了thread模块，对 ```stdatomic.h``` 的适配有问题，故而排除

# set(LLVM_ENABLE_PROJECTS
# "clang;clang-tools-extra;compiler-rt;libc;libclc;libcxx;libcxxabi;libunwind;lld;lldb;mlir;openmp;parallel-libs;polly;pstl"
# CACHE STRING "")
set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld;lldb;libclc;parallel-libs;pstl" CACHE STRING "")
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
  set(LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
  set(LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
  set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
  set(LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
  set(LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
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
foreach(target aarch64-unknown-linux-gnu;armv7-unknown-linux-gnueabihf;i386-unknown-linux-gnu;x86_64-unknown-linux-gnu)
  if(LINUX_${target}_SYSROOT)
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
    set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
    set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind;openmp" CACHE STRING "")

    # Use .build-id link.
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}")
  endif()
endforeach()

# Ignore FUCHSIA

# Platform names
set(LLVM_BUILTIN_TARGETS "${BUILTIN_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_TARGETS "${RUNTIME_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_BUILD_ID_LINK_TARGETS "${RUNTIME_BUILD_ID_LINK}" CACHE STRING "")

# Setup toolchain.
set(LLVM_INSTALL_TOOLCHAIN_ONLY ON CACHE BOOL "")
set(LLVM_TOOLCHAIN_TOOLS
    dsymutil
    llvm-ar
    llvm-as
    llvm-addr2line
    llvm-bitcode-strip
    llvm-cxxdump
    llvm-config
    llvm-cxxmap
    llvm-cov
    llvm-cxxfilt
    llvm-dlltool
    llvm-dwarfdump
    llvm-dwp
    llvm-elfabi
    llvm-gsymutil
    llvm-lib
    llvm-link
    llvm-lipo
    llvm-lto
    llvm-ml
    llvm-mt
    llvm-nm
    llvm-objcopy
    llvm-objdump
    llvm-pdbutil
    llvm-profdata
    llvm-rc
    llvm-ranlib
    llvm-readelf
    llvm-readobj
    llvm-size
    llvm-strings
    llvm-strip
    llvm-symbolizer
    llvm-xray
    sancov
    CACHE STRING "")

set(LLVM_DISTRIBUTION_COMPONENTS
    clang
    lld
    lldb
    lldb-server
    lldb-python
    LTO
    clang-apply-replacements
    clang-doc
    clang-format
    clang-resource-headers
    clang-include-fixer
    clang-refactor
    clang-scan-deps
    clang-tidy
    # clangAnalysis
    clang-libraries
    clangd
    builtins
    runtimes
    ${LLVM_TOOLCHAIN_TOOLS}
    CACHE STRING "")
