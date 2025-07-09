# Linux 编译安装 GCC 15

**注意: 使用 `./installer.sh` 前请先将文件Copy到外层，确保路径上没有特殊字符和空格。**
> 某些第三方组件的构建脚本适配不是很好，特殊字符和空格会导致编译不过。

GCC 15发布啦，本脚本在之前GCC 14的基础上做了稍许更新 。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 15的大致(C/C++)内容如下：

1. Union类型不再保证零值初始化，可通过 `-fzero-init-padding-bits=unions` 切换到老行为
2. 改进向量化优化
3. 改进增量链接优化
4. 改进大源文件编译
5. 增加更多的诊断信息格式
6. 一些代码风格提示
7. C语言默认切到C23，补全部分C2Y的功能
8. 部分C++23和C++26的功能
9. Concepts TS被移除(废弃 `-fconcepts-ts`)
10. C++ Modules的进一步支持
11. 优化编译性能，优化模板特化Hash
12. STL默认开启Debug模式assert


详见: https://gcc.gnu.org/gcc-13/changes.html

## 编译安装 GCC 15.X.X

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

+ gcc 15.2.0
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

+ 2025-04-27    Created
+ 2025-07-09    Update
  + openssl -> 3.5.1
  + python -> 3.13.5
  + gdb -> 16.3
  + mold -> 2.40.1
