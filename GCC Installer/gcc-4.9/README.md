Linux 编译安装 GCC 4.9
======
详情及变更请参照: [Linux 编译安装 GCC 4.9](https://github.com/owt5008137/OWenT-s-Utils/tree/master/Bash%26Shell/GCC%20Installer/gcc-4.9)

GCC4.9发布啦，本脚本在之前4.8的基础上做了稍许改进，更新
PS：4.9.0 开始支持C++1y特性
GCC 4.9 的大致变更如下，因为我只用C/C++所以更关注**通用性高的C和C++**的部分啦： 

1. 标记过时系统
2. 移除mudflag功能
3. 在ARM架构中引入内存错误检查器AddressSanitizer
4. 增加运行时错误检测器UndefinedBehaviorSanitizer
5. 多项链接优化（包含对类型合并功能重写、函数体按需加载等）[Debug模式的Firefox内存消耗从15GB降到3.5GB,链接时间从1700秒降到350秒]
6. Inter-procedural优化改进（包含新的继承类型分析模型、直接调用转为非直接调用和本地符号别名等）
7. Feedback优化（包含对c++内联函数性能分析的改进、函数排序等）
8. 支持OpenMP 4.0[并行计算]
9. C、C++、Fortran增加date-time警告
10. GNAT切换到Ada2012
11. **C/C++ 增加编译信息带颜色输出(-fdiagnostics-color=auto)**
12. 单指令多数据（SIMD）指令的无循环依赖断言
13. 支持Cilk Plus(C和C++的数据与任务并行处理插件)
14. **C11原子操作、线程本地存储**
15. **C++1y 返回类型检测、lambda函数默认参数支持、可变长度数组、[[deprecated]]属性支持、数字分隔符支持、多态lambda表达式**
16. **支持正则表达式、部分C++14实验性内容**
17. Fortran更新的内容我就无情地忽略啦
18. Go语言1.2.1版本的接口
19. 还有一系列针对特定编译目标架构的优化


编译安装 GCC 4.9.X 
### 准备环境及依赖项

1. 支持 ISO C++ 98 的编译器（GCC 4.7.2 的中期一个patch导致的整个项目开始转为由C++编译）
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
16. isl 版本 0.10, 0.11 或0.12 （可由GNU镜像列表 http://www.gnu.org/prep/ftp.html 或自动选择最佳镜像 http://ftpmirror.gnu.org  中gcc目录中的infrastructure目录下载 ）
17. cloog 版本0.18.1（此处可下载 ftp://gcc.gnu.org/pub/gcc/infrastructure/ ）

### 我编译的环境
#### 系统：
CentOS 6.2 & CentOS 6.5 & Fedora 20 & Ubuntu 14.04 LTS

#### 系统库：
+ gzip 1.3.12
+ zip/unzip 3.0
+ GNU make 3.81
+ tar 1.23
+ perl 5.10.1
+ bzip2 1.0.5
+ gcc 4.4.7 or gcc 4.4.5 or gcc 4.8.2 

#### 编译的依赖库：
+ gmp 6.0.0a
+ mpfr 3.1.2
+ mpc 1.0.2
+ isl 0.11.1
+ cloog 0.18.1

#### 编译目标：
+ gcc 4.9.X
+ binutils 2.24
+ python 2.7.8 *[按需]*
+ gdb 7.7.1 (如果存在ncurses-devel包)

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
+ 2014-04-23     Created
+ 2014-04-28     增加一些控制选项
+ 2014-05-23     更新gdb到7.7.1
+ 2014-07-18     更新gcc到4.9.1,更新python到2.7.8
+ 2014-11-12     更新gcc到4.9.2,更新gdb到7.8.1
