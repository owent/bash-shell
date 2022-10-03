# Linux 编译安装 GCC 12

GCC 12发布啦，本脚本在之前GCC 11的基础上做了稍许更新 。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 12的大致(C/C++)内容如下：

1. 修订C和C++之间传递对象中包含位域时的ABI兼容性问题
2. 两个非标准 `std::pair` 开启 deprecated 标记
3. 移除了一些老的目标平台
4. `-O2` 默认开启向量化，等于原先的 `-O2 -ftree-vectorize -fvect-cost-model=very-cheap`
5. 增加 ` -fsanitize=shadow-call-stack` 支持
6. 更多的C2X和C++2X的支持
7. 一些和常量表达式相关的内存优化、推断优化和 `thread_local` 优化
8. 恢复了 `<stdatomic.h>` , 之前由于BUG移除了这个头文件。

详见: https://gcc.gnu.org/gcc-12/changes.html

## 编译安装 GCC 12.X.X

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
12. tar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
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
+ automake 1.16.5
+ libtool 2.4.7
+ pkgconfig 0.29.2
+ gmp 6.2.1
+ mpfr 4.1.0
+ mpc 1.2.1
+ isl 0.24
+ libatomic_ops 7.6.14
+ bdw-gc 8.2.2
+ zstd 1.5.2
+ openssl 3.0.5
+ libexpat 2.4.9
+ libxcrypt 4.4.28
+ gdbm latest
+ readline 8.2

### 编译目标

+ gcc 12.2.0
+ bison 3.8.2
+ binutils 2.39
+ python 3.10.7 *[按需]*
+ gdb 12.1
+ global 6.6.8
+ lz4 1.9.4 *[非必须]*
+ zlib 1.2.12 *[非必须]*
+ libffi 3.4.3 *[非必须]*
+ ncurses 6.3 *[非必须]*
+ xz 5.2.7 *[非必须]*

### 注

+ (所有的库都会被安装在**$PREFEX_DIR**里)

### 额外建议

给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. gdb载入后可使用 ```so [安装目录]/load-libstdc++-gdb-printers.py``` 手动加载gdb的pretty printers

### History

+ 2021-05-06    Created
+ 2022-08-02    Update
  + python -> 3.9.13
  + openssl -> 3.0.5
+ 2022-10-03    Update
  + gcc -> 12.2.0
  + libatomic_ops -> 7.6.14
  + bdw-gc -> 8.2.2
  + binutils -> 2.39
    + Patch: 移除 gprofng 组件的文档,有资源错误
  + libffi -> 3.4.3
  + libexpat -> 2.4.9
  + python -> 3.10.7
  + xz -> 5.2.7
  + lz4 -> 1.9.4
