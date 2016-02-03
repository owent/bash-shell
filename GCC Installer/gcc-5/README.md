Linux 编译安装 GCC 5
======

** 重要信息： 这个版本的release包有一些问题，顺带计划剥离cloog依赖，所以暂缓更新。**
** 新版本的gcc文档里不再官方支持isl-0.12，所以计划更新isl到最新版，但是binutils只支持isl-0.12（预计快要放出2.26，应该就支持了），另外目前最新版本的gdb 7.10.1 编译也存在问题（头文件包含有点问题）**

** 所以请先使用 https://github.com/owent-utils/bash-shell/tree/gcc-5.2/GCC%20Installer/gcc-5 。可用于编译gcc 5.2.0 **

详情及变更请参照: [Linux 编译安装 GCC 5](https://github.com/owt5008137/OWenT-s-Utils/tree/master/Bash%26Shell/GCC%20Installer/gcc-5)

GCC 5发布啦，本脚本在之前4.9的基础上做了稍许改进

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

另外由于GNU官方已经不建议使用bzip2，所以依赖包会尽量使用xz压缩包

GCC 5的大致内容如下：

1.   **默认C标准使用c11，原先是c98**
2.  移除对cloog的依赖*(虽然gcc 5可以用新版的isl从而不依赖cloog，但是目前的gdb和binutils仍然依赖老版本的isl和cloog，所以编译脚本里用了老板的isl并会编译cloog)*
3.  移除了一些实验性的编译器命令，转而使用标准里的
4.  优化跨模块编译优化功能和性能
5.  优化链接时优化功能、性能和内存消耗
6.  寄存器分配优化
7.  指针边界检查
8.  **全面支持c++14**
9.  **不再支持[http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2013/n3639.html](N3639)里定义的变长数组声明**
10. **std::string默认情况下使用小字符串优化策略代替写时复制**（关于这个《More Exceptional C++》里有说明）
11. **默认情况下使用新的std::list策略，std::list::size函数复杂度变为O(1)**
12. libstdc++完全c++11（STL库完全支持）
13. 初步的libgccjit功能
14. 其他的不列举啦，可以参见 https://gcc.gnu.org/gcc-5/changes.html

编译安装 GCC 5.X.X
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
11. perl 版本5.6.1及以上      （此处可下载 http://www.perl.org/）
12. jar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
13. gmp库 版本4.3.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpfr库 版本2.4.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. mpc库 版本0.8.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
16. isl 版本 0.14 或0.12.2 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org  中gcc目录中的infrastructure目录下载 ）

### 我编译的环境
#### 系统：
CentOS 6.5 & CentOS 7

#### 系统库：
+ gzip 1.3.12 and gzip 1.5
+ zip/unzip 3.0/6.0
+ GNU make 3.81 and GNU make 3.82
+ tar 1.23 and tar 1.26
+ perl 5.10.1 and perl 5.16.3
+ bzip2 1.0.5 and bzip2 1.0.6
+ gcc 4.4.7 and gcc 4.8.3

#### 编译的依赖库：
+ gmp 6.1.0
+ mpfr 3.1.3
+ mpc 1.0.3
+ isl 0.15

#### 编译目标：
+ gcc 5.3.0
+ binutils 2.26
+ python 2.7.11 *[按需]*
+ gdb 7.10.1 (如果存在ncurses-devel包)

#### 注：
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议：
给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. 安装完成后，把[GCC源码目录]/libstdc++-v3/python 复制到[用户目录]/.gdb
3. 编辑[用户目录]/.gdbinit,添加
```python
import sys
import os
p = os.path.expanduser('~/.gdb/python')
print p
if os.path.exists(p):
    sys.path.insert(0, p)
    from libstdcxx.v6.printers import register_libstdcxx_printers
    register_libstdcxx_printers(None)
end
```
5. 编译安装gdb

#### History:
+ 2015-04-13     Created
+ 2015-07-20     更新GCC版本到5.2.0，Python到2.7.10，mpfr到3.1.3, gdb到7.9.1
+ 2016-02-03     更新GCC版本到5.3.0，Python到2.7.11，binutils到2.26, gdb到7.10.1，移除**cloog**