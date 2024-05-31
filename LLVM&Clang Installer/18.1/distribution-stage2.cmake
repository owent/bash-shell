# This file sets up a CMakeCache for the second stage of a Fuchsia toolchain build.

set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "") # X86;ARM;AArch64;RISCV

set(PACKAGE_VENDOR OWenT CACHE STRING "")

set(LLVM_ENABLE_PROJECTS "bolt;clang;clang-tools-extra;lld;llvm;lldb;libclc;mlir;polly;pstl" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

set(LLVM_ENABLE_BACKTRACES OFF CACHE BOOL "")
set(LLVM_ENABLE_DIA_SDK OFF CACHE BOOL "")
set(LLVM_ENABLE_LIBCXX ON CACHE BOOL "")
# set(LLVM_ENABLE_LIBEDIT OFF CACHE BOOL "")
set(LLVM_ENABLE_LLD ON CACHE BOOL "")
set(LLVM_ENABLE_LTO ON CACHE BOOL "")
set(LLVM_ENABLE_PER_TARGET_RUNTIME_DIR ON CACHE BOOL "")
set(LLVM_ENABLE_TERMINFO OFF CACHE BOOL "")
set(LLVM_ENABLE_UNWIND_TABLES OFF CACHE BOOL "")
set(LLVM_ENABLE_Z3_SOLVER OFF CACHE BOOL "")
set(LLVM_ENABLE_ZLIB ON CACHE BOOL "")
set(LLVM_INCLUDE_DOCS OFF CACHE BOOL "")
set(LLVM_INCLUDE_EXAMPLES OFF CACHE BOOL "")
set(LLVM_INCLUDE_GO_TESTS OFF CACHE BOOL "")
set(LLVM_STATIC_LINK_CXX_STDLIB ON CACHE BOOL "")
set(LLVM_USE_RELATIVE_PATHS_IN_FILES ON CACHE BOOL "")

if(WIN32)
  set(LLVM_USE_CRT_RELEASE "MT" CACHE STRING "")
endif()

set(CLANG_DEFAULT_CXX_STDLIB libc++ CACHE STRING "")
set(CLANG_DEFAULT_LINKER lld CACHE STRING "")
set(CLANG_DEFAULT_OBJCOPY llvm-objcopy CACHE STRING "")
set(CLANG_DEFAULT_RTLIB compiler-rt CACHE STRING "")
set(CLANG_DEFAULT_UNWINDLIB libunwind CACHE STRING "")
set(CLANG_ENABLE_ARCMT OFF CACHE BOOL "")
set(CLANG_ENABLE_STATIC_ANALYZER ON CACHE BOOL "")
set(CLANG_PLUGIN_SUPPORT OFF CACHE BOOL "")

set(ENABLE_LINKER_BUILD_ID ON CACHE BOOL "")
set(ENABLE_X86_RELAX_RELOCATIONS ON CACHE BOOL "")

set(CMAKE_BUILD_TYPE Release CACHE STRING "")
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "")
elseif(WIN32)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE STRING "")
endif()

function(stage2_patch_install_rpath VAR_NAME)
  if(UNIX)
    if(CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN)
      set(STAGE2_APPEND_RPATHS)
      set(STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN)
      if(NOT APPLE)
        set(STAGE2_RPATH_ORIGIN "\$ORIGIN")
      else()
        set(STAGE2_RPATH_ORIGIN "@loader_path")
      endif()
      if(CMAKE_INSTALL_PREFIX)
        file(RELATIVE_PATH STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN "${CMAKE_INSTALL_PREFIX}/bin"
             "${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}")
      endif()
      if(CMAKE_INSTALL_RPATH)
        set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_RPATH})
      else()
        # Just like in llvm/cmake/modules/AddLLVM.cmake : llvm_setup_rpath
        set(${VAR_NAME} "${STAGE2_RPATH_ORIGIN}/../lib${LLVM_LIBDIR_SUFFIX}")
        if(LLVM_INSTALL_PREFIX AND NOT (LLVM_INSTALL_PREFIX STREQUAL CMAKE_INSTALL_PREFIX))
          list(APPEND ${VAR_NAME} "${LLVM_LIBRARY_DIR}")
        elseif(LLVM_BUILD_LIBRARY_DIR)
          list(APPEND ${VAR_NAME} "${LLVM_LIBRARY_DIR}")
        endif()
      endif()
      if(EXISTS "${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}/lib64")
        list(APPEND ${VAR_NAME} "${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}/lib64")
        if(STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN)
          list(APPEND ${VAR_NAME} "${STAGE2_RPATH_ORIGIN}/${STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN}/lib64")
        endif()
      endif()
      if(EXISTS "${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}/lib")
        list(APPEND ${VAR_NAME} "${CMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN}/lib")
        if(STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN)
          list(APPEND ${VAR_NAME} "${STAGE2_RPATH_ORIGIN}/${STAGE2_RPATH_ORIGIN_EXTERNAL_TOOLCHAIN}/lib")
        endif()
      endif()
      message("Stage2: Reset ${VAR_NAME}=${${VAR_NAME}}")
      set(${VAR_NAME} ${${VAR_NAME}} CACHE STRING "" FORCE)
      set(${VAR_NAME} ${${VAR_NAME}} PARENT_SCOPE)
    endif()
  endif()
endfunction()
stage2_patch_install_rpath(CMAKE_INSTALL_RPATH)

if(APPLE)
  list(APPEND BUILTIN_TARGETS "default")
  list(APPEND RUNTIME_TARGETS "default")

  set(COMPILER_RT_ENABLE_TVOS OFF CACHE BOOL "")
  set(COMPILER_RT_ENABLE_WATCHOS OFF CACHE BOOL "")
  set(COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")

  set(LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
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
  set(RUNTIMES_CMAKE_ARGS "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.13;-DCMAKE_OSX_ARCHITECTURES=arm64|x86_64" CACHE STRING "")
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
  set(RUNTIMES_${target}_LIBCXX_ENABLE_FILESYSTEM OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_ABI_LINKER_SCRIPT OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
  set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx" CACHE STRING "")
endif()

# Intel JIT API support
if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|Windows")
  set(LLVM_USE_INTEL_JITEVENTS ON CACHE BOOL "")
endif()
# Cross compiling
if("${LLVM_TARGETS_TO_BUILD}" MATCHES "Native|X86")
  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    cmake_host_system_information(RESULT LINUX_NATIVE_IS_64BIT QUERY IS_64BIT)
    if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64" OR ("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL ""
                                                        AND LINUX_NATIVE_IS_64BIT))
      set(LINUX_NATIVE_TARGET x86_64-unknown-linux-gnu)
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "i386|i686|x86" OR "${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "")
      set(LINUX_NATIVE_TARGET i386-unknown-linux-gnu)
    endif()
  endif()
endif()
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
    set(BUILTINS_${target}_CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld" CACHE STRING "")
    stage2_patch_install_rpath(BUILTINS_${target}_CMAKE_INSTALL_RPATH)

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
    stage2_patch_install_rpath(RUNTIMES_${target}_CMAKE_INSTALL_RPATH)
    set(RUNTIMES_${target}_COMPILER_RT_CXX_LIBRARY "libcxx" CACHE STRING "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_CAN_EXECUTE_TESTS ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_INSTALL_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_SHARED OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_CXX_ABI_INTREE ON CACHE BOOL "")
    set(RUNTIMES_${target}_SANITIZER_TEST_CXX "libc++" CACHE STRING "")
    set(RUNTIMES_${target}_SANITIZER_TEST_CXX_INTREE ON CACHE BOOL "")
    set(RUNTIMES_${target}_LLVM_TOOLS_DIR "${CMAKE_BINARY_DIR}/bin" CACHE BOOL "")
    set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

    # Use .build-id link.
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}")
  endif()
endforeach()

if(FUCHSIA_SDK)
  set(FUCHSIA_aarch64-unknown-fuchsia_NAME arm64)
  set(FUCHSIA_i386-unknown-fuchsia_NAME x64)
  set(FUCHSIA_x86_64-unknown-fuchsia_NAME x64)
  set(FUCHSIA_riscv64-unknown-fuchsia_NAME riscv64)
  foreach(target i386-unknown-fuchsia;x86_64-unknown-fuchsia;aarch64-unknown-fuchsia;riscv64-unknown-fuchsia)
    set(FUCHSIA_${target}_COMPILER_FLAGS
        "--target=${target} -I${FUCHSIA_SDK}/pkg/sync/include -I${FUCHSIA_SDK}/pkg/fdio/include")
    set(FUCHSIA_${target}_LINKER_FLAGS "-L${FUCHSIA_SDK}/arch/${FUCHSIA_${target}_NAME}/lib")
    set(FUCHSIA_${target}_SYSROOT "${FUCHSIA_SDK}/arch/${FUCHSIA_${target}_NAME}/sysroot")
  endforeach()

  foreach(target i386-unknown-fuchsia;x86_64-unknown-fuchsia;aarch64-unknown-fuchsia;riscv64-unknown-fuchsia)
    # Set the per-target builtins options.
    list(APPEND BUILTIN_TARGETS "${target}")
    set(BUILTINS_${target}_CMAKE_SYSTEM_NAME Fuchsia CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_ASM_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_C_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_CXX_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SHARED_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_MODULE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_EXE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(BUILTINS_${target}_CMAKE_SYSROOT ${FUCHSIA_${target}_SYSROOT} CACHE PATH "")
    stage2_patch_install_rpath(BUILTINS_${target}_CMAKE_INSTALL_RPATH)
  endforeach()

  foreach(target x86_64-unknown-fuchsia;aarch64-unknown-fuchsia)
    # Set the per-target runtimes options.
    list(APPEND RUNTIME_TARGETS "${target}")
    set(RUNTIMES_${target}_CMAKE_SYSTEM_NAME Fuchsia CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_BUILD_WITH_INSTALL_RPATH ON CACHE BOOL "")
    set(RUNTIMES_${target}_CMAKE_ASM_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_C_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_CXX_FLAGS ${FUCHSIA_${target}_COMPILER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SHARED_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_MODULE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_EXE_LINKER_FLAGS ${FUCHSIA_${target}_LINKER_FLAGS} CACHE STRING "")
    set(RUNTIMES_${target}_CMAKE_SYSROOT ${FUCHSIA_${target}_SYSROOT} CACHE PATH "")
    stage2_patch_install_rpath(RUNTIMES_${target}_CMAKE_INSTALL_RPATH)
    set(RUNTIMES_${target}_COMPILER_RT_CXX_LIBRARY "libcxx" CACHE STRING "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_BUILTINS_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_COMPILER_RT_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBUNWIND_HIDE_SYMBOLS ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_USE_LLVM_UNWINDER ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_HERMETIC_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXXABI_INSTALL_STATIC_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_USE_COMPILER_RT ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_HERMETIC_STATIC_LIBRARY ON CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LIBCXX_ABI_VERSION 2 CACHE STRING "")
    set(RUNTIMES_${target}_LLVM_ENABLE_ASSERTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}_LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind" CACHE STRING "")

    # Compat multilibs.
    set(RUNTIMES_${target}+compat_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}+compat_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+compat_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+compat_CMAKE_CXX_FLAGS "${FUCHSIA_${target}_COMPILER_FLAGS} -fc++-abi=itanium" CACHE STRING
                                                                                                                "")

    set(RUNTIMES_${target}+asan_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}+asan_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")

    set(RUNTIMES_${target}+asan+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan+noexcept_LLVM_USE_SANITIZER "Address" CACHE STRING "")
    set(RUNTIMES_${target}+asan+noexcept_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan+noexcept_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
    set(RUNTIMES_${target}+asan+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")

    # Use .build-id link.
    list(APPEND RUNTIME_BUILD_ID_LINK "${target}")
  endforeach()

  # HWAsan
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan_LLVM_USE_SANITIZER "HWAddress" CACHE STRING "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan_CMAKE_CXX_FLAGS
      "${FUCHSIA_aarch64-unknown-fuchsia_COMPILER_FLAGS} -mllvm --hwasan-globals=0" CACHE STRING "")

  # HWASan+noexcept
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LLVM_BUILD_COMPILER_RT OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LLVM_USE_SANITIZER "HWAddress" CACHE STRING "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LIBCXX_ENABLE_NEW_DELETE_DEFINITIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LIBCXXABI_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_LIBCXX_ENABLE_EXCEPTIONS OFF CACHE BOOL "")
  set(RUNTIMES_aarch64-unknown-fuchsia+hwasan+noexcept_CMAKE_CXX_FLAGS
      "${FUCHSIA_aarch64-unknown-fuchsia_COMPILER_FLAGS} -mllvm --hwasan-globals=0" CACHE STRING "")

  set(LLVM_RUNTIME_MULTILIBS "asan;noexcept;compat;asan+noexcept;hwasan;hwasan+noexcept" CACHE STRING "")

  set(LLVM_RUNTIME_MULTILIB_asan_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_noexcept_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_compat_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_asan+noexcept_TARGETS "x86_64-unknown-fuchsia;aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_hwasan_TARGETS "aarch64-unknown-fuchsia" CACHE STRING "")
  set(LLVM_RUNTIME_MULTILIB_hwasan+noexcept_TARGETS "aarch64-unknown-fuchsia" CACHE STRING "")
endif()

set(LLVM_BUILTIN_TARGETS "${BUILTIN_TARGETS}" CACHE STRING "")
set(LLVM_RUNTIME_TARGETS "${RUNTIME_TARGETS}" CACHE STRING "")

# Setup toolchain.
set(LLVM_INSTALL_TOOLCHAIN_ONLY OFF CACHE BOOL "")
# See <llvm-project>/llvm/test/CMakeLists.txt
set(LLVM_TOOLCHAIN_TOOLS_SELECT
    dsymutil
    llvm-ar
    llvm-as
    llvm-bolt
    llvm-cov
    llvm-cxxdump
    llvm-cxxfilt
    llvm-cxxmap
    llvm-debuginfod-find
    llvm-diff
    llvm-dis
    llvm-dlltool
    llvm-dwarfdump
    llvm-dwarfutil
    llvm-dwp
    llvm-exegesis
    llvm-extract
    llvm-gsymutil
    llvm-lib
    llvm-mt
    llvm-nm
    llvm-objcopy
    llvm-objdump
    llvm-opt-report
    llvm-pdbutil
    llvm-profdata
    llvm-profgen
    llvm-rc
    llvm-ranlib
    llvm-readelf
    llvm-readobj
    llvm-reduce
    llvm-rtdyld
    llvm-sim
    llvm-size
    llvm-split
    llvm-stress
    llvm-strip
    llvm-symbolizer
    llvm-tli-checker
    llvm-undname
    llvm-windres
    llvm-xray
    opt
    sancov
    sanstats
    scan-build-py
    # Additional
    llc
    lli
    llvm-addr2line
    llvm-as
    llvm-config
    llvm-cxxdump
    llvm-cxxmap
    llvm-install-name-tool
    llvm-link
    llvm-lto
    llvm-lto2
    llvm-mc
    llvm-mca
    llvm-ml
    llvm-modextract
    llvm-strings
    llvm-bitcode-strip
    llvm-lipo
    llvm-libtool-darwin
    llvm-tblgen
    llvm-ifs
    bugpoint
    verify-uselistorder
    llvm-bcanalyzer
    llvm-otool
    scan-build
    scan-view
    llvm-cat
    llvm-cfi-verify
    llvm-debuginfod
    llvm-remarkutil
    llvm-cvtres
    llvm-readtapi
    llvm-debuginfo-analyzer
    reduce-chunk-list)
if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|Windows")
  list(APPEND LLVM_TOOLCHAIN_TOOLS_SELECT llvm-jitlink llvm-jitlistener)
endif()
if(polly IN LIST LLVM_ENABLE_PROJECTS)
  list(APPEND LLVM_TOOLCHAIN_TOOLS_SELECT LLVMPolly PollyISL)
endif()
set(LLVM_TOOLCHAIN_TOOLS ${LLVM_TOOLCHAIN_TOOLS_SELECT} CACHE STRING "")

set(LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS
    # add_lldb_library(...) in <llvm-project>/lldb
    liblldb
    # add_lldb_tool(...) in <llvm-project>/lldb
    lldb
    lldb-server
    lldb-instr
    libclang-headers
    libclang-python-bindings
    libclang
    # add_clang_tool(xxx) in <llvm-project>/clang and <llvm-project>/clang-tools-extra
    clang-change-namespace
    clang-check
    clang-extdef-mapping
    clang-rename
    find-all-symbols
    diagtool
    modularize
    pp-trace
    opt-viewer
    # unwind, cxx, cxxabi are already included in runtimes From <llvm-project>/clang/cmake/caches/Apple-stage2.cmake
    Remarks)
#[[
# From <llvm-project>/clang/cmake/caches/MultiDistributionExample.cmake . These targets are development targets, and
# them will only available when LLVM_INSTALL_TOOLCHAIN_ONLY=OFF
]]
if(NOT LLVM_INSTALL_TOOLCHAIN_ONLY)
  list(
    APPEND
    LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS
    # llvm
    cmake-exports
    llvm-headers
    llvm-libraries
    llvm-c-test
    # clang
    clang-cmake-exports
    clang-headers
    clang-libraries)
endif()

#[[
# clang-cpp is a development library, and linking it will cost a lot memory.It will only available when
# LLVM_INSTALL_TOOLCHAIN_ONLY=OFF
if(TARGET clang-cpp)
  list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS clang-cpp)
endif()
]]

if(NOT WIN32)
  list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS lldb-python-scripts)
endif()

if(TARGET LLVMgold)
  list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS LLVMgold)
endif()

if(TARGET llvm-go)
  list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS llvm-go)
endif()

if(TARGET LTO)
  list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS LTO)
endif()

set(LLVM_DISTRIBUTION_COMPONENTS
    clang
    lld
    amdgpu-arch
    nvptx-arch
    clang-apply-replacements
    clang-doc
    clang-format
    clang-tblgen
    clang-offload-packager
    clang-offload-bundler
    clang-repl
    clang-reorder-fields
    clang-move
    clang-query
    clang-include-cleaner
    clang-pseudo
    clang-linker-wrapper
    clang-resource-headers
    clang-include-fixer
    clang-refactor
    clang-scan-deps
    clang-tidy
    clangd
    # ============ Additional tools begin ============
    ${LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS}
    # ============ Additional tools end ============
    builtins
    runtimes
    ${LLVM_TOOLCHAIN_TOOLS}
    CACHE STRING "")
