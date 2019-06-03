Linux编译安装GCC 4.7
======

详见: [Linux编译安装GCC 4.7](http://www.owent.net/?p=584)

#### 准备环境及依赖项
1.   支持 ISO C90 的编译器
2.   用于创建Ada编译器的GNAT
3.   支持POSIX的shell或GNU bash
4.   POSIX或SVR4的 awk工具
5.   GNU binutils
6.   gzip 版本1.2.4及以上     （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
7.   bzip2 版本 1.0.2及以上    （此处可下载 http://www.bzip.org/）
8.   GNU make 工具 版本3.80及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
9.   GNU tar工具 版本1.14及以上   （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
10. perl 版本5.6.1及以上      （此处可下载 http://www.perl.org/）
11. jar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
12. gmp库 版本4.3.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
13. mpfr库 版本2.4.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpc库 版本0.8.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. ppl库 版本0.11及以上 （此处可下载 http://www.cs.unipr.it/ppl/Download/）
16. isl 版本 0.10 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org  中gcc目录中的infrastructure目录下载 ）
17. cloog-ppl 版本0.15 或cloog 版本0.16(注意不能使用更高版本) （此处可下载 http://cloog.org/ ）

###### 我编译的环境
**系统**：

CentOS 6.2 & CentOS 6.3

**系统库**：

+ gzip 1.1.12
+ zip/unzip 3.0
+ GNU make 3.81
+ tar 1.23
+ perl 5.10.1
+ bzip2 1.0.5

**依赖库**：
+ gmp 5.0.4 or gmp 5.0.5
+ mpfr 3.1.0
+ mpc 0.8.2 or mpc 0.9
+ ppl 1.12 or ppl 1.12.1
+ isl 0.10
+ cloog 0.16.1 or cloog 0.16.2

#### 注：

+ 使用该脚本前保证脚本依赖的源码包文件处于当前目录下
+ (所有的库都会被安装在**$PREFEX_DIR**里)

