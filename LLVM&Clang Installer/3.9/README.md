Linux 编译安装 LLVM + Clang 3.9
======

LLVM和Clang工具链的生成脚本全部重写了，因为原来的流程是从GCC那个脚本copy过来然后改的，使用的时候各种问题。

每次升级版本都要折腾下，一开始是编译的默认静态库巨大无比，后来改成动态库后一会儿好一会儿不好。
目测3.9.0版本的问题是开启动态库的编译模式以后有些子工程还是静态库，并且会漏掉加-fPIC，即便我在cmake的选项里加了也没用。
之前的版本有时候是用gcc编译正常，用clang自举编译的时候失败。
然后每次测试一次都要花费巨量的时间，巨慢无比。我只是编译出来玩+当某些工具使用啊喂。要不要这么折腾我啊喂。

所以索性重写了，然后这回干脆不适用原来的动态库命令了，llvm的文档里说那个命令仅供llvm的developer。然后有新的选项是把编译出来的各种.a都动态链接到一起（我试了下保留Debug信息的话这个libLLVM.so有900MB）。所以干脆不保留Debug信息了。
然而之前发现的make install的时候的python目录的bug依然存在，所以就还是保留了那个bug的处理。

也是醉，现在的脚本终于第一次编译个自举编译都又OK了，然后建议的额外的编译flags也改成了使用llvm-config来显示。希望不要下次版本有各种问题吧，唉。

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

编译安装 LLVM + Clang 3.9
### 准备环境及依赖项

1. cmake
2. Python
3. **python-devel/python-dev(lldb依赖项)**
4. **swig(lldb依赖项)**
5. **libedit/libedit-devel/libedit-dev(lldb依赖项)**
6. **libxml2-devel(lldb依赖项)**
7. **ncurses-devel(lldb依赖项)**
8. GCC 4.7 or higher

### 我编译的环境
#### 系统：
CentOS 7.1

#### 系统库：
详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖库：
+ libc++ 3.9.1
+ libc++abi 3.9.1
+ libunwind 3.9.1(这个库不会install)

#### 默认编译目标：
+ llvm 3.9.1
+ clang 3.9.1
+ compiler_rt 3.9.1
+ clang_tools_extra 3.9.1
+ lldb 3.9.1
+ lld 3.9.1

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令***./install.sh -t +openmp*** 

#### History:
+ 2016-11-14     Created
+ 2016-12-26     更新版本到3.9.1


#### 参考文献
1. [llvm官网](http://llvm.org/)