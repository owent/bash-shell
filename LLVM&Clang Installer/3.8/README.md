Linux 编译安装 LLVM + Clang 3.8
======

LLVM和Clang工具链的生成配置文件写得比较搓，所以略微麻烦，另外这个脚本没有经过多环境测试，不保证在其他Linux发行版里正常使用。

### CHANGE

#### 相对于上一个版本[Linux 编译安装 LLVM + Clang 3.7(../3.7)的变化：
1. 更新版本到3.8.0
2. 源码列表里多了一个libunwind，但是没找到什么模块需要加这个，所以暂时没加
3. 开启LLVM_ENABLE_LTO

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
> 其他选项参加: http://clang.llvm.org/docs/UsersManual.html


* 如果使用***clang -stdlib=libc++***则需要加上***-lc++ -lc++abi***的链接选项,或者使用***clang++ -stdlib=libc++ -lc++abi***。（无论如何-lc++abi都要手动加链接符号）
* 如果使用***clang -stdlib=libstdc++***则需要加上***-lstdc++***的链接选项,或者使用***clang++ -stdlib=libstdc++***

编译安装 LLVM + Clang 3.8
### 准备环境及依赖项

1. cmake
2. Python
3. **python-devel/python-dev**
4. **swig**
5. **libedit/libedit-devel/libedit-dev(lldb依赖项)**
6. *gtest, gtest-devel/gtest-dev(lld依赖项)*
7. GCC 4.7 or higher

### 我编译的环境
#### 系统：
CentOS 7.1

#### 系统库：
详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖库：
+ libc++ 3.8.1
+ libc++abi 3.8.1

#### 默认编译目标：
+ llvm 3.8.1
+ clang 3.8.1
+ compiler_rt 3.8.1
+ clang_tools_extra 3.8.1

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令***./install.sh -t +openmp*** 

#### History:
+ 2016-07-20     Created


#### 参考文献
1. [llvm官网](http://llvm.org/)
2. [Linux下编译clang、libcxx及其相关库——C++11环境搭建](http://www.cnblogs.com/soaliap/archive/2012/07/23/2605278.html)
3. [linux下编译clang, libc++, libc++abi，以及第二遍自举编译 ](http://blog.csdn.net/heartszhang/article/details/17652461)
