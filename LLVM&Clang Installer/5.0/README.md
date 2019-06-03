Linux 编译安装 LLVM + Clang 5.0
======

LLVM + Clang 5.0 发布啦，本脚本在之前LLVM + Clang 4.0 的基础上做了稍许更新并增加了仅下载模式

如果在一些比较老的系统上，自带的gcc版本过低（比如CentOS 6）.可以先用 https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-7 编译出新版gcc，再用这个gcc来编译llvm+clang工具链。

### NOTICE

1. 第二次自举编译完成后，不再依赖libstdc++，转而依赖编译出来的libc++和libc++abi,但是仍然会依赖libgcc_s.so
2. llvm内部分组件没有使用LIBCXX_LIBCXXABI_INCLUDE_PATHS来查找c++abi的头文件，故而编译的时候直接把这个目录加到了C_INCLUDE_PATH里
3. 使用动态库，原先使用静态库会导致编译出来的二进制非常大，现在全部使用动态库
4. CentOS 7下测试默认包+lld通过, 本地测试过的编译命令如下
> clang -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ -lstdc++ *[源文件...]*
> 
> clang++ -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ *[源文件...]*
> 
> clang -O0 -g -ggdb -std=c++11 -stdlib=libc++ -lc++ -lc++abi *[源文件...]*
> 
> clang -O0 -g -ggdb -std=c++14 -stdlib=libc++ -lc++ -lc++abi *[源文件...]*
> 
> clang++ -O0 -g -ggdb -std=c++11 -stdlib=libc++ -lc++abi *[源文件...]*
> 
> clang++ -O0 -g -ggdb -std=c++14 -stdlib=libc++ -lc++abi *[源文件...]*
> 
> 其他选项参见: llvm-config --cflags ; llvm-config --cxxflags ; llvm-config --ldflags


* 如果使用***clang -stdlib=libc++***则需要加上***-lc++ -lc++abi***的链接选项,或者使用***clang++ -stdlib=libc++ -lc++abi***。（无论如何-lc++abi都要手动加链接符号）
* 如果使用***clang -stdlib=libstdc++***则需要加上***-lstdc++***的链接选项,或者使用***clang++ -stdlib=libstdc++***
* 建议使用**llvm-config --cflags**,**llvm-config --cxxflags**和**llvm-config --ldflags**来查看需要附加的编译选项

### 发行注记
+ llvm : http://llvm.org/releases/5.0.1/docs/ReleaseNotes.html
+ clang : http://llvm.org/releases/5.0.1/tools/clang/docs/ReleaseNotes.html
+ clang Extra : http://llvm.org/releases/5.0.1/tools/clang/tools/extra/docs/ReleaseNotes.html
+ lld: http://llvm.org/releases/5.0.1/tools/lld/docs/ReleaseNotes.html

## 编译安装 LLVM + Clang 5.0
### 准备环境及依赖项

1. cmake
2. Python 2.7 or higher
3. **python-devel/python-dev(lldb依赖项)**
4. **swig(lldb依赖项)**
5. **libedit/libedit-devel/libedit-dev(lldb依赖项)**
6. **libxml2-devel(lldb依赖项)**
7. **ncurses-devel(lldb依赖项)**
8. GCC 4.7 or higher

### 我编译的环境
#### 系统：
CentOS 7.3 & CentOS 6.2

#### 系统库：
详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖库：
+ libc++ 5.0.1
+ libc++abi 5.0.1
+ libunwind 5.0.1(这个库不会install)

#### 默认编译目标：
+ llvm 5.0.1
+ clang 5.0.1
+ compiler_rt 5.0.1
+ clang_tools_extra 5.0.1
+ lldb 5.0.1
+ lld 5.0.1

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令***./install.sh -t +openmp*** 

#### History:
+ 2017-09-13     Created
+ 2017-10-14     增加一些低版本环境的适配支持，支持通过CC和CXX指定编译器
+ 2018-02-01     升级到5.0.1，使用HTTPS下载，修复cmake失败流程没有正确提示的问题


#### 参考文献
1. [llvm官网](http://llvm.org/)