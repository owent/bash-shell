Linux 编译安装 GCC 10
======

GCC 9发布啦，本脚本在之前GCC 9的基础上做了稍许更新，主要增加了新的链接优化依赖 [zstd](http://www.zstd.net) ， 增加了一个方便打包的工具 [lz4](https://github.com/lz4/lz4) 。

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 10的大致(C/C++)内容如下：

1. 增加了 ```__has_builtin``` 预处理，用于功能检测
2. 增加了一些分析相关的选项
3. 一系列跨过程优化和链接时优化相关的改进
4. 一些新的warning，支持UTF-8标识符和UCN语法的标识符
5. 支持u8字符标识```u8''```，支持属性
6. \[C\] 默认开启 ```-fno-common```
7.  \[C++\] 茫茫多C++20的功能
8.  \[C++\] 优化 ```constexpr``` 在编译期的内存消耗
9.  \[C++\] 支持 ```[[no_unique_address]]``` ， 允许空类0字节大小。（和 ```-std=c++17``` and ```-std=c++14``` ABI 不兼容 ）
10. \[C++\] 减少头文件依赖，加快编译速度

## 编译安装 GCC 10.X.X

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
14. mpfr库 版本3.1.0及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. mpc库 版本1.0.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
16. isl 版本 0.15及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 中gcc目录中的infrastructure目录下载 ）
17. zstd
18. awk
19. m4
20. automake
21. gettext
22. gperf
23. cmake

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
+ zstd 1.4.5
+ openssl 1.1.1h

#### 编译目标

+ gcc 10.2.0
+ binutils 2.35.1
+ python 3.9.0 *[按需]*
+ gdb 10.1 (如果存在ncurses-devel包)
+ global 6.6.5
+ lz4 1.9.2 *[非必须]*
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

+ 2020-05-09    Created
+ 2020-05-12    更新优化环境变量加载脚本
+ 2020-08-20    更新组件
  + GCC       -> 10.2.0
  + mpfr      -> 4.1.0
  + mpc       -> 1.2.0
  + binutils  -> 2.35
  + gdb       -> 9.2
  + zstd      -> 1.4.5
+ 2020-10-26    更新组件,增加工具脚本 ```load-libstdc++-gdb-printers.py```,增加内部使用的openssl
  + mpc       -> 1.2.1
  + binutils  -> 2.35.1
  + openssl   -> 1.1.1h
  + python    -> 2.7.18
  + gdb       -> 10.1
  + global    -> 6.6.5
+ 2020-11-10    增加部分Python和gdb的依赖链
  + zlib      -> 1.2.11
  + libffi    -> 3.3
  + ncurses   -> 6.2
