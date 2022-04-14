# This file sets up a CMakeCache for a simple distribution bootstrap build.
# See https://github.com/llvm/llvm-project/blob/release/13.x/clang/cmake/caches/Fuchsia.cmake

# See LLVM_ALL_RUNTIMES in https://github.com/llvm/llvm-project/blob/main/runtimes/CMakeLists.txt LLVM_ALL_PROJECTS in
# https://github.com/llvm/llvm-project/blob/main/llvm/CMakeLists.txt

# Enable LLVM projects and runtimes
set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld;llvm;lldb;libclc;parallel-libs;pstl" CACHE STRING "")

# Only build the native target in stage1 since it is a throwaway build.
set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "") # X86;ARM;AArch64;RISCV

# Setup vendor-specific settings.
set(PACKAGE_VENDOR OWenT CACHE STRING "")

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON CACHE BOOL "")
set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF CACHE BOOL "")
set(CMAKE_BUILD_RPATH_USE_ORIGIN OFF CACHE BOOL "")
set(LLVM_BUILD_EXAMPLES OFF CACHE BOOL "")
set(LLVM_BUILD_TESTS OFF CACHE BOOL "")
set(LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN ON CACHE BOOL "")
set(LLVM_ENABLE_EH ON CACHE BOOL "")
set(LLVM_ENABLE_RTTI ON CACHE BOOL "")
set(LLVM_ENABLE_PIC ON CACHE BOOL "")
set(LLVM_USE_INTEL_JITEVENTS ON CACHE BOOL "")
set(CLANG_LINK_CLANG_DYLIB ON CACHE BOOL "")
set(LLVM_BUILD_LLVM_DYLIB ON CACHE BOOL "")
set(LLVM_LINK_LLVM_DYLIB ON CACHE BOOL "")

if(MSVC)
  set(LLVM_USE_CRT_RELEASE "MT" CACHE STRING "")
endif()

set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
if(NOT APPLE)
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
  set(MACOSX_DEPLOYMENT_TARGET 10.7 CACHE STRING "")
elseif(MSVC)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE STRING "")
endif()

if(APPLE)
  set(COMPILER_RT_ENABLE_IOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
endif()

set(LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
set(LIBUNWIND_INSTALL_LIBRARY OFF CACHE BOOL "")
set(LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
set(LIBCXXABI_ENABLE_STATIC_UNWINDER ON CACHE BOOL "")
set(LIBCXXABI_INSTALL_LIBRARY OFF CACHE BOOL "")
set(LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
set(LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
set(LIBCXX_ABI_VERSION 2 CACHE STRING "")
set(LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
if(WIN32)
  set(LIBCXX_HAS_WIN32_THREAD_API ON CACHE BOOL "")
  set(LIBCXX_ENABLE_EXPERIMENTAL_LIBRARY OFF CACHE BOOL "")
  set(LIBCXX_ENABLE_FILESYSTEM OFF CACHE BOOL "")
  set(LIBCXX_ENABLE_ABI_LINKER_SCRIPT OFF CACHE BOOL "")
  set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY OFF CACHE BOOL "")
  set(BUILTINS_CMAKE_ARGS -DCMAKE_SYSTEM_NAME=Windows CACHE STRING "")
  set(RUNTIMES_CMAKE_ARGS -DCMAKE_SYSTEM_NAME=Windows CACHE STRING "")
  set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx" CACHE STRING "")
else()
  set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
  set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")
endif()

if(BOOTSTRAP_CMAKE_SYSTEM_NAME)
  set(target "${BOOTSTRAP_CMAKE_CXX_COMPILER_TARGET}")
  if(STAGE2_LINUX_${target}_SYSROOT)
    set(LLVM_BUILTIN_TARGETS "${target}" CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SYSROOT ${STAGE2_LINUX_${target}_SYSROOT} CACHE STRING "")

    set(LLVM_RUNTIME_TARGETS "${target}" CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME Linux CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_BUILD_TYPE Release CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SYSROOT ${STAGE2_LINUX_${target}_SYSROOT} CACHE STRING "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    # if(NOT EXISTS "/usr/include/gnu/stubs-32.h") set(RUNTIMES_${target}_COMPILER_RT_DEFAULT_TARGET_ONLY ON CACHE BOOL
    # "") endif()
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS ON CACHE BOOL "")
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
    set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
  endif()
endif()
message(STATUS "Stage1: BOOTSTRAP_CMAKE_SYSTEM_NAME=${BOOTSTRAP_CMAKE_SYSTEM_NAME}")

if(UNIX)
  set(BOOTSTRAP_CMAKE_SHARED_LINKER_FLAGS "-ldl -lpthread" CACHE STRING "")
  set(BOOTSTRAP_CMAKE_MODULE_LINKER_FLAGS "-ldl -lpthread" CACHE STRING "")
  set(BOOTSTRAP_CMAKE_EXE_LINKER_FLAGS "-ldl -lpthread" CACHE STRING "")
endif()

set(BOOTSTRAP_LLVM_ENABLE_LTO ON CACHE BOOL "")
if(NOT APPLE)
  set(BOOTSTRAP_LLVM_ENABLE_LLD ON CACHE BOOL "")
endif()

# Expose stage2 targets through the stage1 build configuration.
set(CLANG_BOOTSTRAP_TARGETS
    check-all
    check-llvm
    check-clang
    check-lld
    llvm-config
    test-suite
    test-depends
    llvm-test-depends
    clang-test-depends
    lld-test-depends
    distribution
    install-distribution
    install-distribution-stripped
    # install-distribution-toolchain
    clang
    CACHE STRING "")

get_cmake_property(variableNames VARIABLES)
foreach(variableName ${variableNames})
  if(variableName MATCHES "^STAGE2_")
    string(REPLACE "STAGE2_" "" new_name ${variableName})
    list(APPEND EXTRA_ARGS "-D${new_name}=${${variableName}}")
  endif()
endforeach()

# Setup the bootstrap build.
set(CLANG_ENABLE_BOOTSTRAP ON CACHE BOOL "")
set(CLANG_BOOTSTRAP_EXTRA_DEPS builtins runtimes CACHE STRING "")

if(STAGE2_CACHE_FILE)
  set(CLANG_BOOTSTRAP_CMAKE_ARGS -C ${STAGE2_CACHE_FILE} CACHE STRING "")
else()
  set(CLANG_BOOTSTRAP_CMAKE_ARGS -C ${CMAKE_CURRENT_LIST_DIR}/distribution-stage2.cmake CACHE STRING "")
endif()
