# Linux 编译安装 GCC 14

**注意: 使用 `./installer.sh` 前请先将文件Copy到外层，确保路径上没有特殊字符和空格。**
> 某些第三方组件的构建脚本适配不是很好，特殊字符和空格会导致编译不过。

GCC 14发布啦，本脚本在之前GCC 13的基础上做了稍许更新 。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 14的大致(C/C++)内容如下：

1. 开始支持 `__has_feature` 和 `__has_extension` 。
2. 一些C23的功能。
3. 一些C++26的功能特性。
4. C++模板诊断信息增强。
5. NRVO支持子代码块。
6. 常量表达式会跟踪生命周期。
7. 优化 `#include` 提示。
8. 优化显示类型转换的诊断信息输出。
9. 优化修订 `static/thread_local` 符号名。
10. 支持 `hot` 和 `cold` 可以应用在类上。
11. 大量 `decltype` 的修订。
12. 向量化相关的增强和 `#pragma`。

详见: https://gcc.gnu.org/gcc-13/changes.html

## 编译安装 GCC 14.X.X

### 准备环境及依赖项

1. 支持 ISO C++ 11 的编译器（GCC 4.8及以上）
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
12. tar或zip和unzip工具 （此处可下载 http://www.info-zip.org）
13. gmp库 版本4.3.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpfr库 版本3.1.0及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. mpc库 版本1.0.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
16. isl 版本 0.15及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 中gcc目录中的infrastructure目录下载 ）
17. zstd
18. awk
19. m4
20. automake
21. autoconf
22. gettext
23. gperf
24. cmake

## 我编译的环境

### 系统

CentOS 7 & CentOS 8

### 编译的依赖库和工具

+ m4 latest
+ autoconf latest
+ automake 1.17
+ libtool 2.5.4
+ pkgconfig 0.29.2
+ gmp 6.3.0
+ mpfr 4.2.2
+ mpc 1.3.1
+ isl 0.24
+ libatomic_ops 7.8.2
+ bdw-gc 8.2.8
+ zstd 1.5.7
+ openssl 3.3.0
+ libexpat 2.7.1
+ libxcrypt 4.4.38
+ gdbm latest
+ readline 8.2

### 编译目标

+ gcc 14.2.0
+ bison 3.8.2
+ binutils 2.44
+ python 3.13.3 *[按需]*
+ gdb 16.2
+ global 6.6.14
+ lz4 1.10.0 *[非必须]*
+ zlib 1.3.1 *[非必须]*
+ libffi 3.4.8 *[非必须]*
+ ncurses 6.5 *[非必须]*
+ xz 5.8.1 *[非必须]*
+ libiconv 1.18 *[非必须]*

### 注

+ (所有的库都会被安装在**$PREFEX_DIR**里)

### 额外建议

给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. gdb载入后可使用 ```so [安装目录]/load-libstdc++-gdb-printers.py``` 手动加载gdb的pretty printers

### History

+ 2024-05-23    Created
+ 2024-08-03    Update
  + GCC -> 14.2.0
  + automake -> 1.17
  + gdb -> 15.1
  + global -> 6.6.13
  + xz -> 5.6.2
  + lz4 -> 1.10.0
+ 2024-08-08    Restore GDB->14.2(15.1 always crash), Update binutils to 2.43
+ 2024-12-16    Update
  + libtool -> 2.5.3
  + bdw-gc -> 8.2.8
  + openssl -> 3.3.0 with quictls
  + python -> 3.11.11
  + gdb -> 15.2
  + global -> 6.6.14
  + xz -> 5.6.3
  + libiconv -> 1.18
+ 2025-04-14    Update
  + libtool -> 2.5.4
  + mpfr -> 4.2.2
  + binutils -> 2.44
  + libffi 3.4.8
  + libexpat -> 2.7.1
  + libxcrypt -> 4.4.38
  + Python -> 3.13.3
  + gdb -> 16.2
  + xz -> 5.8.1
  + zstd -> l.5.7