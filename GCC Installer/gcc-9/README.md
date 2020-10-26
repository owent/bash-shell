Linux 编译安装 GCC 9
======

GCC 9发布啦，本脚本在之前GCC 8的基础上做了稍许更新。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 9的大致(C/C++)内容如下：

1. 修复arm的64位位域的传参对齐问题
2. 错误和警告提示的代码输出会输出行号
3. 一系列编译优化相关的提升
4. 某些条件下的switch语句的复杂度优化
5. 优化代码优化的性能
6. 更精确的profile
7. 增强链接的并发能力
8. \[C\] -std=c2x/-std=gnu2x
9. \[C\] 一堆新的warning
10. \[C++\] 也是一堆新的warning，deprecated掉自动生成拷贝构造函数
11. \[C++\] 部分-std=c++2a/-std=gnu++2a 的功能
12. \[C++\] 错误和warning提示会有额外的位置指向提示，format的warning提示会精确到位置，自动生成的return代码会有生成内容的提示
13. \[C++\] 文件系统支持（需要-lstdc++fs）
14. \[C++\] 支持Windows下文件系统的宽字符集
15. \[C++\] 支持部分TS的网络库

## 编译安装 GCC 9.X.X

### 准备环境及依赖项

1. 支持 ISO C++ 98 的编译器（GCC 3.4及以上）
2. C标准库及头文件
3. 用于创建Ada编译器的GNAT
4. 支持POSIX的shell或GNU bash
5. POSIX或SVR4的 awk工具
6. GNU binutils
7. gzip 版本1.2.4及以上     （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
8. bzip2 版本 1.0.2及以上    （此处可下载 http://www.bzip.org/）
9. GNU make 工具 版本3.80及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
10. GNU tar工具 版本1.14及以上   （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
11. perl 版本5.6.1-5.6.24      （此处可下载 http://www.perl.org/）
12. tar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
13. gmp库 版本4.3.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpfr库 版本2.4.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. mpc库 版本0.8.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
16. isl 版本 0.15及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 中gcc目录中的infrastructure目录下载 ）
17. awk
18. m4
19. automake
20. gettext
21. gperf

### 我编译的环境

#### 系统

CentOS 7

#### 编译的依赖库

+ gmp 6.2.0
+ mpfr 4.1.0
+ mpc 1.2.1
+ isl 0.18
+ libatomic_ops 7.6.10
+ bdw-gc 8.0.4
+ openssl 1.1.1h

#### 编译目标

+ gcc 9.3.0
+ binutils 2.35.1
+ python 3.9.0 *[按需]*
+ gdb 10.1 (如果存在ncurses-devel包)
+ global 6.6.5

#### 注

+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议

给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. gdb载入后可使用 ```so [安装目录]/load-libstdc++-gdb-printers.py``` 手动加载gdb的pretty printers

#### History

+ 2019-06-03    Created
+ 2019-08-23    Update gcc to 9.2.0
+ 2020-03-23    Update gmp to 6.2.0, gcc to 9.3.0, binutils to 2.34, Python to 2.7.17, gdb to 9.1, global to 6.6.4
+ 2020-10-26    更新组件,增加工具脚本 ```load-libstdc++-gdb-printers.py```,增加内部使用的openssl
  + mpfr          -> 4.1.0
  + mpc           -> 1.2.1
  + binutils      -> 2.35.1
  + openssl       -> 1.1.1h
  + python        -> 3.9.0
  + gdb           -> 10.1
  + global        -> 6.6.5
