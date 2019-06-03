Linux 编译安装 LLVM + Clang 3.7
======

LLVM和Clang工具链的生成配置文件写得比较搓，所以略微麻烦，另外这个脚本没有经过多环境测试，不保证在其他Linux发行版里正常使用。

### CHANGE

#### 相对于上一个版本[Linux 编译安装 LLVM + Clang 3.6](../3.6)的变化：

1. 更新版本到3.7.1
2. 第二次自举编译完成后，不再依赖libstdc++，转而依赖编译出来的libc++和libc++abi,但是仍然会依赖libgcc_s.so
3. llvm内部分组件没有使用LIBCXX_LIBCXXABI_INCLUDE_PATHS来查找c++abi的头文件，故而编译的时候直接把这个目录加到了C_INCLUDE_PATH里
4. 使用动态库，原先使用静态库会导致编译出来的二进制非常大，现在全部使用动态库
5. CentOS 7下测试默认包+lld通过, 本地测试过的编译命令如下
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

### NOTICE

由于生成动态库会出现一些问题，所以目前都是采用llvm默认的静态链接的方式。但是静态链接生成的文件比较大，并且链接的东西很多，有可能会出现链接超时的错误。
这时候可以通过手动cd到编译目录，执行 make && make install 即可


* 如果使用***clang -stdlib=libc++***则需要加上***-lc++ -lc++abi***的链接选项,或者使用***clang++ -stdlib=libc++ -lc++abi***。（无论如何-lc++abi都要手动加链接符号）
* 如果使用***clang -stdlib=libstdc++***则需要加上***-lstdc++***的链接选项,或者使用***clang++ -stdlib=libstdc++***

编译安装 LLVM + Clang 3.7
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
+ libc++ 3.7.7
+ libc++abi 3.7.1

#### 默认编译目标：
+ llvm 3.7.1
+ clang 3.7.1
+ compiler_rt 
+ clang_tools_extra

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令***./install.sh -t +lld*** 

#### History:
+ 2016-02-26     Created


#### 参考文献
1. [llvm官网](http://llvm.org/)
2. [Linux下编译clang、libcxx及其相关库——C++11环境搭建](http://www.cnblogs.com/soaliap/archive/2012/07/23/2605278.html)
3. [linux下编译clang, libc++, libc++abi，以及第二遍自举编译 ](http://blog.csdn.net/heartszhang/article/details/17652461)
