Linux 编译安装 GCC 11
======

GCC 11发布啦，本脚本在之前GCC 10的基础上做了稍许更新 。增加了用于rpmbuild的打包文件。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 11的大致(C/C++)内容如下：

1. 编译GCC时需要工具链支持 C++11（之前是C++98），即如果使用GCC，至少要GCC 4.8以上
2. 一些调试信息相关的位置变化和选项变化(```-gsplit-dwarf``` 等)
3. 移除一些老平台支持
4. 覆盖率工具， ```gov``` 的一些选项变化
5. ```ThreadSanitizer``` 支持多种运行时
6. 提示源代码中的“列”时，支持多字节字符集
7. 引入 ```Hardware-assisted AddressSanitizer``` 支持
8. DWARF调试信息版本升级到 [DWARF version 5](http://dwarfstd.org/doc/DWARF5.pdf)
9. 一些编译优化的提升（向量化、条件语句转switch，跨过程调用）
10. 一些链接优化，优化速度和内存占用
11. Profile优化
12. \[C\] 增加一些新的属性和warning
13. \[C\] C2X的一些新功能
14. \[C++\] 默认使用 C++17
15. \[C++\] 优化 ```--enable-cheaders=c_std``` 标记为不推荐使用，转而使用 ```--enable-cheaders=c_global``` 。（行为一样）
16. \[C++\] 继续增加C++20功能的实现
17. \[C++\] 部分C++23的功能

详见: https://gcc.gnu.org/gcc-11/changes.html

## 编译安装 GCC 11.X.X

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

### 我编译的环境

#### 系统

CentOS 7

#### 编译的依赖库和工具

+ m4 latest
+ autoconf latest
+ automake 1.16.3
+ libtool 2.4.6
+ pkgconfig 0.29.2
+ gmp 6.2.1
+ mpfr 4.1.0
+ mpc 1.2.1
+ isl 0.18
+ libatomic_ops 7.6.10
+ bdw-gc 8.0.4
+ zstd 1.5.0
+ openssl 1.1.1k
+ libexpat 2.4.1
+ libxcrypt 4.4.23
+ gdbm latest

#### 编译目标

+ gcc 11.2.0
+ binutils 2.36.1
+ python 3.9.12 *[按需]*
+ gdb 10.2 (如果存在ncurses-devel包)
+ global 6.6.6
+ lz4 1.9.3 *[非必须]*
+ zlib 1.2.11 *[非必须]*
+ libffi 3.3 *[非必须]*
+ ncurses 6.2 *[非必须]*

#### 注

+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议

给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. gdb载入后可使用 ```so [安装目录]/load-libstdc++-gdb-printers.py``` 手动加载gdb的pretty printers

#### History

+ 2021-05-06    Created
+ 2021-06-23    Update
  + m4: latest, optional
  + libexpat: 2.4.1
  + libxcrypt: 4.4.23
  + zstd: 1.5.0
+ 2021-07-28     Update
  >
  > + gcc: 11.2.0
  > + python: 3.9.6
  > + global: 6.6.7
  > + libffi: 3.4.2
  > + binutils: 2.37
  > + automake: 1.16.4
  >
+ 2021-01-21     Update
  >
  > + automake: 1.16.5
  > + isl: 0.24
  > + libatomic_ops: 7.6.12
  > + bdwgc: 8.0.6
  > + openssl: 3.0.1
  > + ncurses: 6.3
  > + libexpat: 2.4.3
  > + libxcrypt: 4.4.27
  > + python: 3.10.2
  > + gdb: 11.2
  > + global: 6.6.8
  > + zstd: 1.5.2
  >
+ 2022-04-13     Update
  >
  > + libtool: 2.4.7
  > + binutils: 2.38
  > + openssl: 3.0.2
  > + libexpat: 2.4.8
  > + libxcrypt: 4.4.28
  > + python: 3.9.12(distcc不支持3.10，回滚到3.9)
  >
+ 2022-04-17     软链接 openssl 库的输出目录。
  > 某些工具写死了用 `<PREFIX>/lib` 来查找库。但是openssl 3.0 开始输出目录为 `<PREFIX>/lib64` 。
