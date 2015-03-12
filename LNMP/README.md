Lnmp yum 安装脚本 (for CentOS)
======
详情见: [Lnmp yum 安装脚本 (for CentOS)](http://www.owent.net/?p=740)
脚本执行完后**有几个需要注意的地方**

文件列表
------
1. **lnmp.sh** 可用于CentOS 6及Redhat 6
2. **lnmp_for_el7.sh** 可用于CentOS 7及Redhat 7(m替换成了MySQL开分支:mariadb)

## 脚本选项
```shell
-a <加速器缓存目录路径> ext cache dir path
-c <php.ini 文件路径> path of php.ini(Notice: must match rpm packages)
-d <php.d 路径> dir path of php.d(Notice: must match rpm packages)
-l <php部分扩展的日志路径> dir path of php ext logs
-f <php-fpm.d/www.conf路径> path of php-fpm.d/www.conf path(Notice: must match rpm packages)
-m <数据库数据目录> (仅限lnmp_for_el7.sh)
-o <要安装的 php 加速器> 可以是这几个 [xcache, zendopcache, eaccelerator, apcu, none]
其中apcu和其他的不冲突，另外几个互相冲突的只会安装第一个指定的加速器
-h 帮助信息

# apcu会导致Centos 7下php-fpm 5.4崩溃，故已禁用
# eaccelerator 在Centos 7下无软件源，故已禁用

```

## php加速器UI组件
php加速组件安装以后只有加速核心，没有UI部分，各个组件的UI安装不一样。可以安如下方式安装

1. **eaccelerator**

	> 从 http://eaccelerator.net/ 下载 对应版本
	>
	> 把源码包内的所有php文件放置到网站目录即可
	> 
	> **注意设置admin用户名和密码**

2. **xcache**

	> 从 http://xcache.lighttpd.net/ 下载 对应版本源码包
	> 
	> 把htdoc目录内所有文件放置到网站目录即可
	> 
	> **注意设置admin用户名和密码**
	
3. **zendopcache**

	> zendopcache官方没有提供UI管理器，可以使用第三方管理器
	> + 方案一： https://github.com/amnuts/opcache-gui
	> + 方案二： https://github.com/rlerdorf/opcache-status/
	> + 方案三： https://github.com/PeeHaa/OpCacheGUI
	> + 方案四： https://github.com/carlosbuenosvinos/opcache-dashboard
	>
	> **注意设置admin用户名和密码**
	
4. **apcu**

	> 从 http://pecl.php.net/package/APCU 下载 对应版本源码包
	> 
	> 把源码包内的所有php文件放置到网站目录即可
	>
	> **注意设置admin用户名和密码**

## 配置建议

脚本执行完后，有几个配置建议

1. 建议**php-fpm运行方式改为类似 unix:/var/run/php-fpm.sock** 这样，而不是绑定IP和端口，据说可以减少内存消耗和网络开销。修改方法为，*php-fpm.conf*或*php-fpm.d/www.conf* 内的**listen**设置改成 */var/run/php-fpm.sock* 然后 nginx内网站的server内*fastcgi_pass*节点改为*fastcgi_pass unix:/var/run/php-fpm.sock;*(其他sock路劲类似)
	
2. 建议**nginx.conf**内的**event**节点增加*use epoll;*选项，即为
	```nginx
	events {
	    use epoll;
	    worker_connections 51200;
	}
	```
3. 建议 server include的cgi通用配置（默认是*fastcgi_params*）中添加以下选项
	```nginx
	fastcgi_connect_timeout 300;
	fastcgi_send_timeout 300;
	fastcgi_read_timeout 300;
	fastcgi_buffer_size 128k;
	fastcgi_buffers 4 256k;
	fastcgi_busy_buffers_size 256k;
	fastcgi_temp_file_write_size 256k;
	fastcgi_intercept_errors on;
	fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
	# 并且server节点内的 fastcgi_param SCRIPT_FILENAME使用上诉文件的配置
	
	```
4. 建议**nginx.conf**内的http节点增加以下配置，开启*gzip*压缩
	```nginx
	gzip on;
	gzip_min_length  1k;
	gzip_buffers     16 64k;
	gzip_http_version 1.0;
	gzip_comp_level 5;
	gzip_types       text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;
	gzip_vary on; 
	
	```
5. 建议**/etc/php-fpm.conf**内配置*sendmail*选项
	```ini

	php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f admin@owent.net
	```
6. 根据服务器具体情况配置**/etc/php-fpm.d/*.conf**的的参数
	```ini
	pm.max_children = 10
	pm.start_servers = 2
	pm.min_spare_servers = 3
	pm.max_spare_servers = 5
	;pm.max_requests = 500
	php_admin_value[memory_limit] = 300M

	;以上是我的配置
	```
7. 建议修改php,nginx,php-fpm,nginx 内 server所有***日志***文件位置
