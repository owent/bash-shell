# Linux 编译安装 LLVM + Clang 14.0

LLVM + Clang 14.0 发布啦，本脚本在之前LLVM + Clang 13.0 的构建脚本的基础上修改而来。

如果在一些比较老的系统上，自带的gcc版本过低（比如CentOS 7）.可以先用 https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-11 编译出新版gcc，再用这个gcc来编译llvm+clang工具链。

## 编译脚本使用示例

```bash
sudo -b env CC=/usr/local/gcc-11.2.0/gcc CXX=/usr/local/gcc-11.2.0/g++ nohup ./installer.sh
sudo chmod 777 nohup.out && tail -f nohup.out;

# 或者不需要root权限
env CC=/usr/local/gcc-11.2.0/gcc CXX=/usr/local/gcc-11.2.0/g++ nohup ./installer.sh -p $HOME/prebuilt/llvm-14.0 &
tail -f nohup.out;
```

## NOTICE

1. 现在采用了git拉取[llvm-project][1]仓库，额外编译[libedit][2]时使用 `curl` 下载
2. CentOS 7下测试通过, 本地测试过的编译命令如下

> ```bash
> clang -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ -lstdc++ [源文件...]
> clang++ -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ [源文件...]
> clang -O0 -g -ggdb -std=c++11 -stdlib=libc++ -lc++ -lc++abi -lunwind [源文件...]
> clang -O0 -g -ggdb -std=c++14 -stdlib=libc++ -lc++ -lc++abi -lunwind [源文件...]
> clang++ -O0 -g -ggdb -std=c++11 -lunwind [源文件...]
> clang++ -O0 -g -ggdb -std=c++14 -lunwind [源文件...]
> 其他选项参见: llvm-config --cflags ; llvm-config --cxxflags ; llvm-config --ldflags
> ```

+ 如果使用 `clang -stdlib=libc++` 则需要加上 `-lc++ -lc++abi -lunwind` 的链接选项，或者使用 `clang++  -stdlib=libc++ -lunwind`。我们剥离了对 `libgcc_s` 的依赖，但是需要使用 `libunwind` 代替相关功能。
+ 如果使用 `clang -stdlib=libstdc++` 则需要加上 `-lstdc++` 的链接选项，或使用 `clang++ -stdlib=libstdc++` 。
+ 建议使用 `llvm-config --cflags` , `llvm-config --cxxflags` 和 `llvm-config --ldflags` 来查看需要附加的编译选项。

## 发行注记

+ llvm : http://llvm.org/releases/14.0.1/docs/ReleaseNotes.html
+ clang : http://llvm.org/releases/14.0.1/tools/clang/docs/ReleaseNotes.html
+ clang Extra : http://llvm.org/releases/14.0.1/tools/clang/tools/extra/docs/ReleaseNotes.html
+ lld: http://llvm.org/releases/14.0.1/tools/lld/docs/ReleaseNotes.html

## 编译安装 LLVM + Clang 14.0

### 准备环境及依赖项

1. cmake
2. Python 3 or higher
3. **python-devel/python-dev(lldb依赖项)**
4. **swig(lldb依赖项)**
5. **libxml2-devel(lldb依赖项)**
6. **ncurses-devel(lldb依赖项)**
7. GCC 5.1 or higher
8. binutils 2.20.1 or higher
9. openssl

### 测试环境

#### 系统

CentOS 7&CentOS 8

#### 系统库

详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖项

+ [x] libc++ 14.0.1
+ [x] libc++abi 14.0.1
+ [x] libunwind 14.0.1
+ [x] [libedit][2] 20210910-3.1
+ [x] [Python][3] 3.9.12
+ [x] [swig][4] v4.0.2
+ [x] [zlib][5] 1.2.11
+ [x] [libffi][6] 3.4.2

#### 默认编译目标

+ [x] llvm 14.0.1
+ [x] clang 14.0.1
+ [x] compiler-rt 14.0.1
+ [x] clang-tools-extra 14.0.1
+ [x] lldb 14.0.1
+ [x] lld 14.0.1
+ [ ] libc: 提示不支持
+ [x] libclc
+ [x] openmp
+ [ ] polly (这个版本自举编译 polly 会失败，故而本版本临时关闭之)
+ [x] pstl

> 注: 所有的库都会被安装在 ```$PREFEX_DIR``` 里

#### 额外建议

+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令 ```./installer.sh -t +debuginfo-tests```

#### History

+ 2022-04-17     Created

## [`distribution-stage1.cmake`][11] 和 [`distribution-stage2.cmake`][12] 编译选项

[`distribution-stage1.cmake`][11]  基于 [llvm-project][1] 的 [clang/cmake/caches/Fuchsia.cmake][8] 。
[`distribution-stage2.cmake`][12] 基于 [llvm-project][1] 的 [clang/cmake/caches/Fuchsia-stage2.cmake][9] 。

修改的内容如下:

+ All: `set(PACKAGE_VENDOR OWenT CACHE STRING "")`
+ All: `set(LLVM_TARGETS_TO_BUILD Native CACHE STRING "") # X86;ARM;AArch64;RISCV`
+ All: 注释掉所有的`set(*LIBCXX_ABI_VERSION 2*)` , ABI 2还未稳定
+ All: `LLVM_ENABLE_PROJECTS` 增加 `lldb;libclc;mlir;pstl`
  > 注意顺序要参考 [llvm/CMakeLists.txt][10] 内的 `LLVM_ALL_PROJECTS`
+ ~[`distribution-stage2.cmake`][12]: `set(LLVM_INSTALL_TOOLCHAIN_ONLY OFF CACHE BOOL "")` ，我们需要开发包~
+ [`distribution-stage1.cmake`][11] 的 `BOOTSTRAP_CMAKE_SYSTEM_NAME` 内和 [`distribution-stage2.cmake`][12]
  + `*LIBCXXABI_INSTALL_LIBRARY` 改为 `ON`
  + `*LIBUNWIND_INSTALL_LIBRARY` 改为 `ON`
+ [`distribution-stage1.cmake`][11]: `CLANG_BOOTSTRAP_CMAKE_ARGS` 改为
  >
  > ```cmake
  > if(STAGE2_CACHE_FILE)
  >   set(CLANG_BOOTSTRAP_CMAKE_ARGS -C ${STAGE2_CACHE_FILE} CACHE STRING "")
  > else()
  >   set(CLANG_BOOTSTRAP_CMAKE_ARGS -C ${CMAKE_CURRENT_LIST_DIR}/distribution-stage2.cmake CACHE STRING "")
  > endif()
  > ```
  >
+ [`distribution-stage2.cmake`][12]: `foreach(target *-linux-*)` 后的 `if(LINUX_${target}_SYSROOT)` 改为 `if(LINUX_${target}_SYSROOT OR target STREQUAL "${LINUX_NATIVE_TARGET}")` ，并在前面插入适配脚本
  >
  > ```cmake
  > # Intel JIT API support
  > if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|Windows")
  >   set(LLVM_USE_INTEL_JITEVENTS ON CACHE BOOL "")
  > endif()
  > # Cross compiling
  > if("${LLVM_TARGETS_TO_BUILD}" MATCHES "Native|X86")
  >   if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  >     cmake_host_system_information(RESULT LINUX_NATIVE_IS_64BIT QUERY IS_64BIT)
  >     if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64" OR ("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL ""
  >                                                         AND LINUX_NATIVE_IS_64BIT))
  >       set(LINUX_NATIVE_TARGET x86_64-unknown-linux-gnu)
  >     elseif(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "i386|i686|x86" OR "${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "")
  >       set(LINUX_NATIVE_TARGET i386-unknown-linux-gnu)
  >     endif()
  >   endif()
  > endif()
  > message(STATUS "Stage2: CMAKE_HOST_SYSTEM_NAME=${CMAKE_HOST_SYSTEM_NAME}")
  > message(STATUS "Stage2: CMAKE_HOST_SYSTEM_PROCESSOR=${CMAKE_HOST_SYSTEM_PROCESSOR}")
  > message(STATUS "Stage2: CMAKE_HOST_SYSTEM_VERSION=${CMAKE_HOST_SYSTEM_VERSION}")
  > message(STATUS "Stage2: LLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}")
  > message(STATUS "Stage2: LINUX_NATIVE_IS_64BIT=${LINUX_NATIVE_IS_64BIT}")
  > message(STATUS "Stage2: LINUX_NATIVE_TARGET=${LINUX_NATIVE_TARGET}")
  > ```
  >

+ [`distribution-stage2.cmake`][12]: `LLVM_TOOLCHAIN_TOOLS` 改名为非Cache的 `LLVM_TOOLCHAIN_TOOLS_SELECT`, 增加注释 `# See <llvm-project>/llvm/test/CMakeLists.txt`
  + 移除:
    + llvm-ifs
    + llvm-lipo
    + llvm-libtool-darwin
    + llvm-otool
  + 增加
    + scan-build
    + scan-view
    + llvm-addr2line
    + llvm-as
    + llvm-config
    + llvm-cxxdump
    + llvm-cxxmap
    + llvm-install-name-tool
    + llvm-jitlink
    + llvm-jitlistener
    + llvm-link
    + llvm-ml
    + llvm-strings
  + 最后添加
    >
    > ```cmake
    > if(APPLE)
    >   list(
    >     APPEND
    >     LLVM_TOOLCHAIN_TOOLS_SELECT
    >     llvm-bitcode-strip
    >     llvm-ifs
    >     llvm-lipo
    >     llvm-libtool-darwin
    >     llvm-otool)
    > endif()
    > if(CMAKE_HOST_SYSTEM_NAME MATCHES "Linux|Windows")
    >   list(APPEND LLVM_TOOLCHAIN_TOOLS_SELECT llvm-jitlink llvm-jitlistener)
    > endif()
    > set(LLVM_TOOLCHAIN_TOOLS ${LLVM_TOOLCHAIN_TOOLS_SELECT} CACHE STRING "")
    > ```
    >
+ [`distribution-stage2.cmake`][12]: `LLVM_DISTRIBUTION_COMPONENTS` 增加 `${LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS}`
  >
  > ```cmake
  > set(LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS
  >     # add_lldb_library(...) in <llvm-project>/lldb
  >     liblldb
  >     # add_lldb_tool(...) in <llvm-project>/lldb
  >     lldb
  >     lldb-server
  >     lldb-instr
  >     lldb-vscode
  >     # add_llvm_install_targets(xxx) in <llvm-project>/clang
  >     libclang-headers
  >     libclang-python-bindings
  >     libclang
  >     # add_clang_tool(xxx) in <llvm-project>/clang
  >     clang-change-namespace
  >     clang-check
  >     clang-extdef-mapping
  >     clang-rename
  >     clang-repl
  >     diagtool
  >     modularize
  >     pp-trace
  >     opt-viewer
  >     # unwind, cxx, cxxabi are already included in runtimes
  >     # From <llvm-project>/clang/cmake/caches/Apple-stage2.cmake
  >     Remarks
  >     #[[
  >     # From <llvm-project>/clang/cmake/caches/MultiDistributionExample.cmake . These targets are development targets, and
  >     # them will only available when LLVM_INSTALL_TOOLCHAIN_ONLY=OFF
  >     cmake-exports
  >     llvm-headers
  >     llvm-libraries
  >     clang-cmake-exports
  >     clang-headers
  >     clang-libraries
  >     ]]
  > )
  > #[[
  > # clang-cpp is a development library, and linking it will cost a lot memory.It will only available when
  > # LLVM_INSTALL_TOOLCHAIN_ONLY=OFF
  > if(UNIX OR (MINGW AND LLVM_LINK_LLVM_DYLIB))
  >   list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS clang-cpp)
  > endif()
  > ]]
  > if(NOT WIN32)
  >   list(APPEND LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS lldb-python-scripts)
  > endif()
  > 
  > set(LLVM_DISTRIBUTION_COMPONENTS
  >     # ============ Additional tools begin ============
  >     ${LLVM_DISTRIBUTION_ADDTIONAL_COMPONENTS}
  >     # ============ Additional tools end ============
  > )    
  > ```

## 参考文献

1. [llvm官网][7]
2. [llvm-project][1]

[1]: https://github.com/llvm/llvm-project.git
[2]: http://thrysoee.dk/editline/
[3]: https://www.python.org/
[4]: https://github.com/swig/swig.git
[5]: https://www.zlib.net/
[6]: https://sourceware.org/libffi/
[7]: http://llvm.org/
[8]: https://github.com/llvm/llvm-project/blob/main/clang/cmake/caches/Fuchsia.cmake
[9]: https://github.com/llvm/llvm-project/blob/main/clang/cmake/caches/Fuchsia-stage2.cmake
[10]: https://github.com/llvm/llvm-project/blob/main/llvm/CMakeLists.txt
[11]: distribution-stage1.cmake
[12]: distribution-stage2.cmake
