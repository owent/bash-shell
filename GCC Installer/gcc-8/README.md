Linux 编译安装 GCC 8
======

GCC 8发布啦，本脚本在之前GCC 7的基础上做了稍许更新

由于GCC从5开始[对版本号进行重新规范](https://gcc.gnu.org/develop.html#num_scheme)，所以这里的编译脚本以后以主版本号为准。

GCC 8的大致(C/C++)内容如下：

1. 移除一些老的调试符号支持和插件
2. 内联和克隆的启发式优化算法和基于Profile的优化机制的优化
3. 链接优化增加了ELF中DWARF格式的语言相关调试信息，用以支持libstdc++在开启编译优化之后的pretty-print
4. 增加了实验性的 ```-fcf-protection=[full|branch|return|none]```选项（目前只支持Linux下x86架构）。用以检查控制流跳转后的程序安全性
5. 默认启用 ```-gcolumn-info``` ，用以在DWARF格式的调试信息中提供文件名和行号
6. 重构循环嵌套模块优化和新的循环展开优化编译选项和pragma
7. 增加检测动态还是静态栈的探针
8. 增强了冲突属性的检测
9. 覆盖率检测工具gcov增强函数关系分析能力和终端的颜色输出支持
10. 地址安全性检测模块（AddressSanitizer）增加了一组新的检测机制（比较和相减）
11. 未定义行为检测模块也增加了两个选项
12. [C] 新的warning选项: 不安全的宏展开、字符串操作参数不匹配、对齐、缺失属性标记、不兼容的函数指针、指针大小、转换对齐、
13. [C] 用 ```-fsanitize=signed-integer-overflow``` 代替 ```-Wstrict-overflow```
14. [C] 数组溢出检测增强
14. [C] 重叠访问检测增强
15. [C] 参数类型检测、format检测、代码提示增强
16. [C++] C++11 ```alignof``` 对应 C ```_Alignof``` 而不是原来的 GNU ```__alignof__```
17. [C++] 有风险的成员变量访问和模板的代码提示增强
18. [C++] ```-std=c++2a``` 支持
19. [libstdc++] 继续增加C++17和C++2a的支持和接入

## 编译安装 GCC 8.X.X
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
CentOS 7 & CentOS 6.2

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
+ mpfr 4.0.1
+ mpc 1.1.0
+ isl 0.18
+ libatomic_ops 7.6.4
+ bdw-gc 7.6.6

#### 编译目标
+ gcc 8.1.0
+ binutils 2.30
+ python 2.7.15 *[按需]*
+ gdb 8.1 (如果存在ncurses-devel包)

#### 注
+ (所有的库都会被安装在**$PREFEX_DIR**里)

#### 额外建议
给特定用户安装 gdb的pretty-printer 用以友好打印stdc++的stl容器

1. 在执行 install.sh 脚本前安装 ncurses-devel 和 python-devel， 用于编译gdb和开启python功能
2. 添加libstdcxx加载脚本到 ```~/.gdb-load-libstdcxx.py```
  ```python
  import sys
  import os
  import glob
  
  for stdcxx_path in glob.glob('安装目录/share/gcc-*/python'):
    p = os.path.expanduser(stdcxx_path)
    print p
    if os.path.exists(p):
      sys.path.insert(0, p)
      from libstdcxx.v6.printers import register_libstdcxx_printers
      register_libstdcxx_printers(None)
  ```

3. 编辑[用户目录]/.gdbinit,添加
  ```bash
  so ~/.gdb-load-libstdcxx.py
  ```

#### History
+ 2018-05-01    Created
+ 2018-08-13    更新GCC到8.2.0,更新libatomic_ops到7.6.6,更新bdwgc到7.6.8,更新binutils到2.31
