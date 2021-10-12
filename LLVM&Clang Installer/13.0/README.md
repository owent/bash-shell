Linux 编译安装 LLVM + Clang 13.0
======

LLVM + Clang 13.0 发布啦，本脚本在之前LLVM + Clang 12.0 的构建脚本的基础上修改而来，增加了rpmbuild的配置，修订在stage 2阶段的 ```--gcc-toolchain <gcc install prefix>``` 选项。

> 因为自举编译阶段会失败，临时关闭 ```polly``` 的编译。

如果在一些比较老的系统上，自带的gcc版本过低（比如CentOS 7）.可以先用 https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-11 编译出新版gcc，再用这个gcc来编译llvm+clang工具链。

### 编译脚本使用示例

```bash
sudo -b env CC=/usr/local/gcc-11.1.0/gcc CXX=/usr/local/gcc-11.1.0/g++ nohup ./installer.sh
sudo chmod 777 nohup.out && tail -f nohup.out;

# 或者不需要root权限
env CC=/usr/local/gcc-11.1.0/gcc CXX=/usr/local/gcc-11.1.0/g++ nohup ./installer.sh -p $HOME/prebuilt/llvm-13.0 &
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

+ llvm : http://llvm.org/releases/13.0.0/docs/ReleaseNotes.html
+ clang : http://llvm.org/releases/13.0.0/tools/clang/docs/ReleaseNotes.html
+ clang Extra : http://llvm.org/releases/13.0.0/tools/clang/tools/extra/docs/ReleaseNotes.html
+ lld: http://llvm.org/releases/13.0.0/tools/lld/docs/ReleaseNotes.html

## 编译安装 LLVM + Clang 13.0

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

### 我编译的环境

#### 系统：

CentOS 7

#### 系统库：

详情参见 [llvm官网](http://llvm.org/)

#### 编译的依赖项：

+ [x] libc++ 13.0.0
+ [x] libc++abi 13.0.0
+ [x] libunwind 13.0.0
+ [x] [libedit][2] 20210910-3.1
+ [x] [Python][3] 3.9.7
+ [x] [swig][4] v4.0.2
+ [x] [zlib][5] 1.2.11
+ [x] [libffi][6] 3.3

#### 默认编译目标：

+ [x] llvm 13.0.0
+ [x] clang 13.0.0
+ [x] compiler-rt 13.0.0
+ [x] clang-tools-extra 13.0.0
+ [x] lldb 13.0.0
+ [x] lld 13.0.0
+ [ ] libc (这个版本还是无法编译过，故而排除)
+ [x] libclc
+ [x] openmp
+ [x] parallel-libs
+ [ ] polly (这个版本自举编译 polly 会失败，故而本版本临时关闭之)
+ [x] pstl

#### 注：

+ (所有的库都会被安装在 ```$PREFEX_DIR``` 里)

#### 额外建议：

+ 如果增加编译组件，比如已装有gtest要编译lld，使用命令 ```./installer.sh -t +debuginfo-tests```

#### History:

+ 2021-05-06     Created

#### 参考文献

1. [llvm官网](http://llvm.org/)

[1]: https://github.com/llvm/llvm-project.git
[2]: http://thrysoee.dk/editline/
[3]: https://www.python.org/
[4]: https://github.com/swig/swig.git
[5]: https://www.zlib.net/
[6]: https://sourceware.org/libffi/
