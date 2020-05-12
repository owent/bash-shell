Linux 编译安装 LLVM + Clang 10.0
======

LLVM + Clang 10.0 发布啦，本脚本保持之前LLVM + Clang 9.0 的大部分选项参数，但是几乎全部重写了。

如果在一些比较老的系统上，自带的gcc版本过低（比如CentOS 7）.可以先用 https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-9 编译出新版gcc，再用这个gcc来编译llvm+clang工具链。

### 编译脚本使用示例

```bash
sudo -b env CC=/usr/local/gcc-9.3.0/gcc CXX=/usr/local/gcc-9.3.0/g++ nohup ./installer.sh
sudo chmod 777 nohup.out && tail -f nohup.out;

# 或者不需要root权限
env CC=/usr/local/gcc-9.3.0/gcc CXX=/usr/local/gcc-9.3.0/g++ nohup ./installer.sh -p $HOME/prebuilt/llvm-10.0 &
tail -f nohup.out;
```

### NOTICE

1. 第二次自举编译完成后，不再依赖libstdc++，转而依赖编译出来的libc++和libc++abi,但是仍然会依赖libgcc_s.so
2. 现在采用了git拉取[llvm-project][1]仓库，额外编译[libedit][2]时使用wger下载
3. CentOS 7下测试通过, 本地测试过的编译命令如下

> ```bash
> clang -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ -lstdc++ [源文件...]
> clang++ -O0 -g -ggdb -std=c++11 -stdlib=libstdc++ [源文件...]
> clang -O0 -g -ggdb -std=c++11 -stdlib=libc++ -lc++ -lc++abi [源文件...]
> clang -O0 -g -ggdb -std=c++14 -stdlib=libc++ -lc++ -lc++abi [源文件...]
> clang++ -O0 -g -ggdb -std=c++11 -stdlib=libc++ -lc++abi [源文件...]
> clang++ -O0 -g -ggdb -std=c++14 -stdlib=libc++ -lc++abi [源文件...]
> 其他选项参见: llvm-config --cflags ; llvm-config --cxxflags ; llvm-config --ldflags
> ```

* 如果使用***clang -stdlib=libc++***则需要加上***-lc++ -lc++abi***的链接选项,或者使用***clang++ -stdlib=libc++ -lc++abi***。（无论如何-lc++abi都要手动加链接符号）
* 如果使用***clang -stdlib=libstdc++***则需要加上***-lstdc++***的链接选项,或者使用***clang++ -stdlib=libstdc++***
* 建议使用**llvm-config --cflags**,**llvm-config --cxxflags**和**llvm-config --ldflags**来查看需要附加的编译选项

### 发行注记

+ llvm : http://llvm.org/releases/10.0.0/docs/ReleaseNotes.html
+ clang : http://llvm.org/releases/10.0.0/tools/clang/docs/ReleaseNotes.html
+ clang Extra : http://llvm.org/releases/10.0.0/tools/clang/tools/extra/docs/ReleaseNotes.html
+ lld: http://llvm.org/releases/10.0.0/tools/lld/docs/ReleaseNotes.html

## 编译安装 LLVM + Clang 10.0

### 准备环境及依赖项

1. cmake
2. Python 2.7 or higher
3. **python-devel/python-dev(lldb依赖项)**
4. **swig(lldb依赖项)**
5. **libxml2-devel(lldb依赖项)**
6. **ncurses-devel(lldb依赖项)**
7. GCC 4.7 or higher

### 我编译的环境

#### 系统：

CentOS 7

#### 系统库：

详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖库：

+ libc++ 10.0.0
+ libc++abi 10.0.0
+ libunwind 10.0.0
+ [libedit][2] 20191231-3.1

#### 默认编译目标：

+ llvm 10.0.0
+ clang 10.0.0
+ compiler-rt 10.0.0
+ clang-tools-extra 10.0.0
+ lldb 10.0.0
+ lld 10.0.0
+ libc
+ libclc
+ openmp
+ parallel-libs
+ polly
+ pstl

#### 注：

+ (所有的库都会被安装在 ```$PREFEX_DIR``` 里)

#### 额外建议：

+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令 ```./installer.sh -t +debuginfo-tests```

#### History:

+ 2020-04-22     Created
+ 2020-05-12     更新优化环境变量加载脚本
+ 
#### 参考文献

1. [llvm官网](http://llvm.org/)

[1]: https://github.com/llvm/llvm-project.git
[2]: http://thrysoee.dk/editline/
