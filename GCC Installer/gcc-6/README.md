Linux 编译安装 GCC 6
======

详情及变更请参照: [Linux 编译安装 GCC 6](https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-6)

GCC 6发布啦，本脚本在之前GCC 5的基础上做了稍许改进

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

另外由于GNU官方已经不建议使用bzip2，所以依赖包会尽量使用xz压缩包

GCC 6的大致内容如下：

1.   **默认C++标准使用c++14(gnu++14)，原先是c++98(gnu++98)**
2.  增加了严格数组越界行为检测(-fsanitize=bounds-strict)
3.  区分类型别名的指针访问分析。这会影响类型双关的代码，可以加-fno-strict-aliasing移除
4.  类型别名支持weakref和alias属性，有助于链接时优化。
5.  移除值范围传播时的this指针有效性检查，
6.  链接时优化 - 链接声明时warning和error属性
7.  链接时优化 - C和Fortan的类型合并规则修订并支持Fortan 2008标准
8.  链接时优化 - 不开启链接优化时保留更多的类型信息
9.  链接时优化 - 非法的全局变量和声明检测（-Wodr-type-mismatch）
10. 链接时优化 - 链接中间文件大小减小了约11%
11. 链接时优化 - 通过减小数据流分区的大小提升并行链接性能，Firefox的IL流减少了66%
12. 链接时优化 - 插件拓展，支持增量链接和全局程序优化（-r选项）
13. 跨程序优化
14. OpenACC 2.0a
15. OpenMP 4.5
16. 支持枚举类型的属性声明
17. 错误代码现在显示一个表达式范围，之前只提供出错点
18. 诊断提示附加到错误处
19. 一些新的细节控制选项，不一一列出了
20. 对SCM附加的merge标记做特殊提示
21. 支持[C++ Concepts](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4377.pdf)
22. 支持C++17的折叠表达式，*u8*字符修饰，扩展static_assert和嵌套命名空间的功能
23. 允许非类型模板参数的常量评估
24. 支持内存事物（-fgnu-tm）
25. C++17的一些实验性支持

编译安装 GCC 6.X.X
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
16. isl 版本 0.14,0.15或0.16 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 中gcc目录中的infrastructure目录下载 ）

### 我编译的环境
#### 系统：
CentOS 6 & CentOS 7

#### 系统库：
+ gzip 1.3.12 and gzip 1.5
+ zip/unzip 3.0/6.0
+ GNU make 3.81 and GNU make 3.82
+ tar 1.23 and tar 1.26
+ perl 5.10.1 and perl 5.16.3
+ bzip2 1.0.5 and bzip2 1.0.6
+ gcc 4.4.7 and gcc 4.8.5

#### 编译的依赖库：
+ gmp 6.1.2
+ mpfr 3.1.5
+ mpc 1.0.3
+ isl 0.16.1

#### 编译目标：
+ gcc 6.3.0
+ binutils 2.27
+ python 3.6.0 *[按需]*
+ gdb 7.12 (如果存在ncurses-devel包)

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
+ 2016-04-28    Created
+ 2016-09-01    更新gcc到6.2.0,gmp到6.1.1,binutils到2.27,python到3.5.2
+ 2016-12-26    更新gcc到6.3.0,gmp到6.1.2,mpfr到3.1.5,python到3.6.0,gdb到7.12