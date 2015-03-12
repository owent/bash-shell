Linux 编译安装 GCC 4.8
======

详见: [Linux 编译安装 GCC 4.8](http://www.owent.net/?p=730)

GCC4.8发布啦，这个脚本在之前4.7的基础上做了点改进，移除一些过时的组件,增加了检测不到时自动下载源码包

PS：4.8.1开始全面支持C++11特性，并且脱离了ppl库，gdb也开始脱离ppl库了

编译安装 GCC 4.8.X
<h4><span style="color:#4B0082;">准备环境及依赖项</span></h4>
1. 支持 ISO C++ 98 的编译器（GCC 4.7.2 的中期一个patch导致的整个项目开始转为由C++编译）
2. 用于创建Ada编译器的GNAT
3. 支持POSIX的shell或GNU bash
4. POSIX或SVR4的 awk工具
5. GNU binutils
6. gzip 版本1.2.4及以上     （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
7. bzip2 版本 1.0.2及以上    （此处可下载 http://www.bzip.org/）
8. GNU make 工具 版本3.80及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
9. GNU tar工具 版本1.14及以上   （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
10. perl 版本5.6.1及以上      （此处可下载 http://www.perl.org/）
11. jar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
12. gmp库 版本5.0.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
13. mpfr库 版本2.4.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpc库 版本0.8.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. isl 版本 0.11.1 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org  中gcc目录中的infrastructure目录下载 ）
16. cloog 版本0.18.1（此处可下载 ftp://gcc.gnu.org/pub/gcc/infrastructure/ ）

<h3><span style="color:#008080;">我编译的环境</span></h3>
<h4><span style="color:#4B0082;">系统：</span></h4>
CentOS 6.2 & CentOS 6.5 & Suse 的不知道哪个很老的版本

<h4><span style="color:#4B0082;">系统库：</span></h4>
+ gzip 1.3.12
+ zip/unzip 3.0
+ GNU make 3.81
+ tar 1.23
+ perl 5.10.1
+ bzip2 1.0.5
+ gcc 4.4.7 or gcc 4.1.2 or gcc 4.4.5

<h4><span style="color:#4B0082;">编译的依赖库：</span></h4>
+ gmp 6.0.0a
+ mpfr 3.1.2
+ mpc 1.0.2
+ isl 0.11.1
+ cloog 0.18.1

<h4><span style="color:#4B0082;">编译目标：</span></h4>
+ gcc 4.8.X
+ binutils 2.24
+ gdb 7.7.1

<h4><span style="color:#4B0082;">注：</span></h4>
+ (所有的库都会被安装在**$PREFEX_DIR**里)

<h4><span style="color:#4B0082;">额外建议：</span></h4>
给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. 安装完成后，把[GCC源码目录]/libstdc++-v3/python 复制到[用户目录]/.gdb
3. 编辑[用户目录]/.gdbinit,添加
<pre>
python
import sys
import os
p = os.path.expanduser('~/.gdb/python')
print p
if os.path.exists(p):
    sys.path.insert(0, p)
    from libstdcxx.v6.printers import register_libstdcxx_printers
    register_libstdcxx_printers(None)
end
</pre>
5. 编译安装gdb

#### History:
+ 2013-03-26     Created
+ 2013-04-11     改进脚本，增加统一编译选项，增加对binutils和gdb可选包的编译，增加自动把PREFIX_DIR变为绝对路径的问题，统一目录组织，修复环境变量的一些小问题
+ 2013-05-24     增加安装pretty-printer的方法
+ 2013-06-03     更新gcc到4.8.1，更新基础库，更新gdb到7.6，添加clean功能，gdb添加python支持(用于pretty-printer)
+ 2013-10-29     更新gcc到4.8.2，更新gdb到7.6.1，更新GMP到5.1.3
+ 2013-12-13     更新binutils到2.24，更新gdb到7.6.2，移除对ppl的依赖，显式开启gold等一些选项，显式开启链接时优化选项
+ 2014-05-23     更新gcc到4.8.3，更新gdb到7.7.1，完全移除对ppl的依赖，同步gcc4.9编译脚本中修复的一些问题，增加编译选项等
+ 2015-02-09     更新gcc到4.8.4（未测试，貌似这个版本加入了[jit](https://gcc.gnu.org/wiki/JIT)）
