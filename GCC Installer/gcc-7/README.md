Linux 编译安装 GCC 7
======

**GCC 30周年纪念**

详情及变更请参照: [Linux 编译安装 GCC 7](https://github.com/owent-utils/bash-shell/tree/master/GCC%20Installer/gcc-7)

GCC 7发布啦，本脚本在之前GCC 6的基础上做了稍许更新

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 7的大致(C/C++)内容如下：

1. 默认使用新的寄存器分配策略(LRA)
2. 移除一些非标准的type traits
3. 不推荐使用libstdc++性能分析模式
4. 不推荐使用Cilk+插件
5. 修复ARM目标的一处[BUG](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=77728)
6. GCC 7 可以检测某些情况下sprintf族函数的返回值范围并加以优化。（ -fprintf-return-value，默认-O1或更高）
7. 增加了一种新的常量合并策略。（-fstore-merging，默认-O2或更高和-Os启用）
8. 增加了一种新的代码优化策略，可以加快表达式结束判定，能够减少代码段大小并提升代码生成速度。（-fcode-hoisting，默认-O2或更高和-Os启用）
9. 替换了新的位操作常量优化。（-fipa-bit-cp和-fipa-cp，默认-O2或更高和-Os启用）
10. 新的值范围判定优化。（-fipa-vrp，默认-O2或更高和-Os启用）
11. 循环分割优化。（-fsplit-loops，默认-O3或更高启用）
12. 某些平台的包装器压缩优化（-fshrink-wrap-separate ，默认启用）
13. 新的地址范围安全性检测（-fsanitize-address-use-after-scope）
14. 有符号整数溢出检测（-fsanitize=signed-integer-overflow）
15. 支持[DWARF调试信息V5](http://www.dwarfstd.org/Download.php)
16. C语言-新的Warning
> + -Wimplicit-fallthrough : 隐式失败
> + -Wpointer-compare : 指针和0字符常量比较
> + -Wduplicated-branches : if-else有相同分支
> + -Wrestrict : 带约束参数的别名
> + -Wmemset-elt-size : memset时第三个参数是数组的大小而不是字节数
> + -Wint-in-bool-context : 在应该用bool类型的地方可能不正确地使用了整型
> + -Wswitch-unreachable : 不可达的switch分支
> + -Wexpansion-to-defined : 在#if外部的defined宏
> + -Wregister : 在C++17之后***register***关键字被废弃
> + -Wvla-larger-than=N : 变长长度数组越界
> + -Wduplicate-decl-specifier : 重复的const, volatile, restrict 或 _Atomic 标识符

17. GCC前端可以建议拼写错误（成员、预处理）
18. 字符串格式化会有下划线提示
19. 变量名覆盖提示（-Wshadow=compatible-local/local/global）
20. 内存分配溢出和误用检测
21. 一些数值限制的宏，*INT_WIDTH*、*CR_DECIMAL_DIG*等等
22. 一些用于检测移除的内建API，*__builtin_add_overflow_p*、*__builtin_sub_overflow_p*、*__builtin_mul_overflow_p*
23. 允许自定义使用的浮点数标准
24. 原子关键字***_Atomic***兼容*-fopenmp*
25. *-std=c++1z*和*-std=gnu++1z*的实验性支持，包含if constexpr、模板参数推断、auto模板参数和结构化绑定。详见： https://gcc.gnu.org/projects/cxx-status.html#cxx1z
26. C++17 new操作符的对齐支持
27. 允许指定C++17的结算顺序(*-fstrong-eval-order*)。比如指定函数参数的结算顺序。
28. 默认的继承的结构（内存布局）变化（使用*-fno-new-inheriting-ctors*或者*-fabi-version*低于11时可以强制使用老的内存布局）
29. 可以提示丢失分号
30. iostream的异常使用新的[cxx11 ABI](https://gcc.gnu.org/onlinedocs/gcc-7.1.0/libstdc++/manual/using_dual_abi.html)
31. 一些C++17的实验性STL支持
32. 新的rehashing策略

## 编译安装 GCC 7.X.X
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
12. tar或zip和unzip工具 （此处可下载 http://www.info-zip.org)
13. gmp库 版本4.3.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
14. mpfr库 版本2.4.2及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
15. mpc库 版本0.8.1及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 下载 ）
16. isl 版本 0.15及以上 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org 中gcc目录中的infrastructure目录下载 ）
17. awk

### 我编译的环境
#### 系统
CentOS 7

#### 系统库
+ gzip 1.5
+ zip/unzip 3.0/6.0
+ GNU make 3.82
+ tar 1.26
+ perl 5.16.3
+ bzip2 1.0.6
+ gcc 4.8.5

#### 编译的依赖库
+ gmp 6.1.2
+ mpfr 3.1.5
+ mpc 1.0.3
+ isl 0.16.1
+ libatomic_ops 7.4.4
+ bdw-gc 7.6.0

#### 编译目标
+ gcc 7.1.0
+ binutils 2.28
+ python 2.7.13 *[按需]*
+ gdb 7.12.1 (如果存在ncurses-devel包)

#### 注
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议
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

#### History
+ 2017-05-05    Created