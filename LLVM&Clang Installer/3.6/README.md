Linux 编译安装 LLVM + Clang 3.6
======

LLVM和Clang工具链的生成配置文件写得比较搓，所以略微麻烦，另外这个脚本没有经过多环境测试，不保证在其他Linux发行版里正常使用。

### CHANGE

#### 相对于上一个版本[Linux 编译安装 LLVM + Clang 3.5](../3.5)的变化：

1. 这个版本llvm的源码修复了一个会导致开启exception功能之后的编译bug，所以编译脚本不再会修改llvm的源代码
2. 编译过程改成了两次编译
3. 编译过程完全使用cmake。
4. **终于自举编译成功啦**，第二次自举编译完成后，不再依赖libstdc++，转而依赖编译出来的libc++和libc++abi,但是仍然会依赖libgcc_s.so
5. 多线程编译的时候时不时会出现奇怪的失败，所以默认改成单线程编译
6. 修复编译完成后的提示输出

### NOTICE

由于生成动态库会出现一些问题，所以目前都是采用llvm默认的静态链接的方式。但是静态链接生成的文件比较大，并且链接的东西很多，有可能会出现链接超时的错误。
这时候可以通过手动cd到编译目录，执行 make && make install 即可

编译安装 LLVM + Clang 3.6
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
CentOS 7

#### 系统库：
详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖库：
+ libc++ 3.6.2
+ libc++abi 3.6.2


#### 默认编译目标：
+ llvm 3.6.2
+ clang 3.6.2
+ compiler_rt 
+ clang_tools_extra

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令***./install.sh -t +lld*** 

#### History:
+ 2015-03-10     Created
+ 2015-04-08     修订，完成自举编译，优化编译流程
+ 2015-07-20     默认采用动态链接，默认关闭LLDB编译（各种链接问题，解决不了，反正已经支持gdb了就用gdb吧）


#### 参考文献
1. [llvm官网](http://llvm.org/)
2. [Linux下编译clang、libcxx及其相关库——C++11环境搭建](http://www.cnblogs.com/soaliap/archive/2012/07/23/2605278.html)
3. [linux下编译clang, libc++, libc++abi，以及第二遍自举编译 ](http://blog.csdn.net/heartszhang/article/details/17652461)
