# 编译protobuf请注意

现在的交叉流程都是:

1. 在 [工作目录]/build_job_dir/host-build 下线编译出本地版本的protoc和js_embed可执行程序，
2. 安装到 [工作目录]/build_job_dir/host 里（js_embed不会被安装）。
3. PATH里加这两个目录
4. 枚举所有要编译的架构并用前面编好的本地架构的protoc和js_embed程序。

但是protobuf的cmake脚本里再交叉编译的时候并没有移除掉protoc和js_embed，也没有选项可以移除他们（至少目前的版本3.5.0为止还没有）。可能会导致编译出错。这时候需要手动编辑一下文件 [protobuf源码目录]/cmake/libprotoc.cmake 文件。然后注释掉 *add_executable(js_embed ...)* 这一行，关闭js_embed的编译。然后把下面 *add_custom_command* 里对js_embed的依赖移除掉（我们会在PATH目录里找所以不需要了）。这样就能编译出来了。
