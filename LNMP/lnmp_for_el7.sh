#!/bin/sh
 
# 注意: CentOS 7这个脚本默认使用了MySQL的开源替代品mariadb
# 如果要切换会MySQL请自行安装并去除下面脚本内的安装的mariadb-server mariadb软件包

WORKING_DIR="$PWD";
 
ARCH_FLAG=$(getconf LONG_BIT);
PHP_CONF_FILE_PATH=/etc/php.ini
PHP_CONF_DIR_PATH=/etc/php.d
PHP_FPM_CONF_FILE_PATH=/etc/php-fpm.d/www.conf
PHP_CACHE_DIR_PATH=/tmp/php/cache
PHP_EXT_LOG_DIR_PATH=/var/log/php
PHP_OPT_COMP_INSTALL="";
DB_DATA_DIR=/home/db


while getopts "a:c:d:f:hl:m:o:" arg; do
        case $arg in
             a)
                PHP_CACHE_DIR_PATH="$OPTARG";
                ;;
             c)
                PHP_CONF_FILE_PATH="$OPTARG";
                ;;
             d)
                PHP_CONF_DIR_PATH="$OPTARG";
                ;;
             l)
                PHP_EXT_LOG_DIR_PATH="$OPTARG";
                ;;
             f)
                PHP_FPM_CONF_FILE_PATH="$OPTARG";
                ;;
             o)
                PHP_OPT_COMP_INSTALL="$PHP_OPT_COMP_INSTALL $OPTARG";
                ;;
             m)
                DB_DATA_DIR="$OPTARG";
                ;;
             h)
                echo "usage: $0 [options]
options:
-a  <dir path>                  ext cache dir path
-c  <php.ini path>              path of php.ini(Notice: must match rpm packages)
-d  <php conf dir>              dir path of php.d(Notice: must match rpm packages)
-f  <php-fpm.d/www.conf path>   path of php-fpm.d/www.conf path(Notice: must match rpm packages)
-h                              help message
-l  <php conf dir>              dir path of php ext logs
-m  <db data dir>               db data directory
-o  <php opt compoments>        can be one or some of [xcache, zendopcache, apcu, none]
                ";
                exit 0;
                ;;
             o)
                 PHP_OPT_COMP_INSTALL="$OPTARG";
                ;;
             ?)  #当有不认识的选项的时候arg为?
                echo "unkonw argument $arg";
                ;;
        esac
done

# 安装扩展软件源
rpm -ivh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
 
yum install -y nginx
yum install -y autoconf zlib zlib-devel libpng libpng-devel freetype freetype-devel sendmail mariadb-server mariadb memcached procmail php php-adodb php-bcmath php-cli php-common php-devel php-enchant php-fpm php-gd php-imap php-intl php-ldap php-markdown php-mbstring php-mcrypt php-mssql php-mysql php-odbc php-pdo php-pear php-pear-DB php-pear-File php-pear-File-Util php-pear-HTTP php-pear-HTTP-* php-pear-Mail php-pear-XML-* php-pecl-mailparse php-pecl-memcache php-pecl-memprof php-pecl-mongo php-pecl-oauth php-pecl-redis php-pecl-uuid php-pgsql php-process php-pspell php-recode php-soap php-tidy php-xml php-xmlrpc php-zipstream
systemctl disable httpd.service

cp $PHP_CONF_FILE_PATH $PHP_CONF_FILE_PATH.bak

# 替换PHP配置
sed -i 's#output_buffering = Off#output_buffering = On#' $PHP_CONF_FILE_PATH
sed -i 's/memory_limit = 128M/memory_limit = 300M/g' $PHP_CONF_FILE_PATH
sed -i 's/post_max_size = 8M/post_max_size = 50M/g' $PHP_CONF_FILE_PATH
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' $PHP_CONF_FILE_PATH
sed -i 's/;date.timezone =/date.timezone = PRC/g' $PHP_CONF_FILE_PATH
sed -i 's/short_open_tag = Off/short_open_tag = On/g' $PHP_CONF_FILE_PATH
sed -i 's/; cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' $PHP_CONF_FILE_PATH
sed -i 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/g' $PHP_CONF_FILE_PATH
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $PHP_CONF_FILE_PATH
sed -i 's/disable_functions =.*/disable_functions = proc_open,proc_get_status,ini_alter,ini_alter,ini_restore,pfsockopen,popepassthru,stream_socket_server,fsocket/g' $PHP_CONF_FILE_PATH
 
# 替换PHP-FPM配置
groupadd users
useradd -s /sbin/nologin -g nginx users
usermod -g users nginx
cp $PHP_FPM_CONF_FILE_PATH $PHP_FPM_CONF_FILE_PATH.bak
sed -i 's/user = apache/user = nginx/g' $PHP_FPM_CONF_FILE_PATH
sed -i 's/group = apache/group = users/g' $PHP_FPM_CONF_FILE_PATH
sed -i 's/;php_admin_value\[memory_limit\] = 128M/php_admin_value\[memory_limit\] = 300M/g' $PHP_FPM_CONF_FILE_PATH
 

# 安装加速器 Zend Guard Loader
ZEND_GUARD_LOADER="http://downloads.zend.com/guard/6.0.0/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz";
wget -c "$ZEND_GUARD_LOADER"
ZEND_GUARD_NAME=$(ls ZendGuardLoader-*-PHP-5.4-linux-glibc23-*.tar.gz);
tar -axvf $ZEND_GUARD_NAME
mv -f ZendGuardLoader-*-PHP-5.4-linux-glibc23-*/php-5.4.x/ZendGuardLoader.so $(php-config --extension-dir)
rm -rf $ZEND_GUARD_NAME
 
echo "
[Zend.loader]
zend_loader.enable=1
zend_loader.disable_licensing=1
zend_loader.obfuscation_level_support=3
zend_loader.license_path=
zend_extension=$(php-config --extension-dir)/ZendGuardLoader.so
" > $PHP_CONF_DIR_PATH/zendloader.ini

# 复制通用配置文件
NGINX_CONF_PATH="/etc/nginx"
echo '
location / {
if (-f $request_filename/index.html){
                rewrite (.*) $1/index.html break;
        }
if (-f $request_filename/index.php){
                rewrite (.*) $1/index.php;
        }
if (!-f $request_filename){
                rewrite (.*) /index.php;
        }
}
' > "$NGINX_CONF_PATH/wordpress.conf";
 
echo '
location / {
            rewrite ^(.*)-htm-(.*)$ $1.php?$2 last;
            rewrite ^(.*)/simple/([a-z0-9\_]+\.html)$ $1/simple/index.php?$2 last;
        }
'  > "$NGINX_CONF_PATH/phpwind.conf";
 
echo '
location / {
            rewrite ^/archiver/((fid|tid)-[\w\-]+\.html)$ /archiver/index.php?$1 last;
            rewrite ^/forum-([0-9]+)-([0-9]+)\.html$ /forumdisplay.php?fid=$1&page=$2 last;
            rewrite ^/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ /viewthread.php?tid=$1&extra=page%3D$3&page=$2 last;
            rewrite ^/space-(username|uid)-(.+)\.html$ /space.php?$1=$2 last;
            rewrite ^/tag-(.+)\.html$ /tag.php?name=$1 last;
        }
'  > "$NGINX_CONF_PATH/discuz.conf";
 
echo '
rewrite ^([^\.]*)/topic-(.+)\.html$ $1/portal.php?mod=topic&topic=$2 last;
rewrite ^([^\.]*)/article-([0-9]+)-([0-9]+)\.html$ $1/portal.php?mod=view&aid=$2&page=$3 last;
rewrite ^([^\.]*)/forum-(\w+)-([0-9]+)\.html$ $1/forum.php?mod=forumdisplay&fid=$2&page=$3 last;
rewrite ^([^\.]*)/thread-([0-9]+)-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=viewthread&tid=$2&extra=page%3D$4&page=$3 last;
rewrite ^([^\.]*)/group-([0-9]+)-([0-9]+)\.html$ $1/forum.php?mod=group&fid=$2&page=$3 last;
rewrite ^([^\.]*)/space-(username|uid)-(.+)\.html$ $1/home.php?mod=space&$2=$3 last;
rewrite ^([^\.]*)/([a-z]+)-(.+)\.html$ $1/$2.php?rewrite=$3 last;
if (!-e $request_filename) {
        return 404;
}
'  > "$NGINX_CONF_PATH/discuzx.conf";
 
# 防火墙 管理
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
 
# 自启动
systemctl enable php-fpm.service
systemctl enable nginx.service
systemctl enable mariadb.service

# 加速器 php-xcache php-pecl-zendopcache php-eaccelerator php-pecl-apcu

# 安装加速器 eaccelerator
function install_eaccelerator()
{
    mkdir -p "$PHP_CACHE_DIR_PATH";
    mkdir -p "$PHP_EXT_LOG_DIR_PATH";
    yum install -y php-eaccelerator;
    PHP_EACC_CONF_FILE="$PHP_CONF_DIR_PATH/eaccelerator.ini";
    cp $PHP_EACC_CONF_FILE $PHP_EACC_CONF_FILE.bak;
    sed -i "s#eaccelerator\\.cache_dir\\s*=.*#eaccelerator\\.cache_dir = \"$PHP_CACHE_DIR_PATH\"#g" $PHP_EACC_CONF_FILE;
    sed -i "s#eaccelerator\\.log_file\\s*=.*#eaccelerator\\.log_file = \"$PHP_EXT_LOG_DIR_PATH/eaccelerator.log\"#g" $PHP_EACC_CONF_FILE;
    sed -i '/accelerator.compress\s*=.*/d' $PHP_EACC_CONF_FILE;
    sed -i "/accelerator.compress_level\s*=.*/d" $PHP_EACC_CONF_FILE;
    echo '
	eaccelerator.compress="1"
	eaccelerator.compress_level="9"
' >> $PHP_EACC_CONF_FILE;
    echo "eaccelerator admin can be download from http://eaccelerator.net/";
    # 需要手动配置eaccelerator服务控制台 http://eaccelerator.net/ (源码包内所有php文件)
}

function install_pecl_apcu()
{
    mkdir -p "$PHP_CACHE_DIR_PATH";
    mkdir -p "$PHP_EXT_LOG_DIR_PATH";
    yum install -y php-pecl-apcu;
    PHP_PECL_APCU_CONF_FILE="$PHP_CONF_DIR_PATH/apcu.ini";
    cp $PHP_PECL_APCU_CONF_FILE $PHP_PECL_APCU_CONF_FILE.bak;
    sed -i "s#apc\\.mmap_file_mask\\s*=.*#apc\\.mmap_file_mask=\"$PHP_CACHE_DIR_PATH/apc.XXXXXXX\"#g" $PHP_PECL_APCU_CONF_FILE;
    echo "apcu admin can be download http://pecl.php.net/package/APCU";
    # 需要手动配置apcu服务控制台 http://pecl.php.net/package/APCU (源码包内所有php文件)
}

function install_xcache()
{
    mkdir -p "$PHP_CACHE_DIR_PATH";
    mkdir -p "$PHP_EXT_LOG_DIR_PATH";
    yum install -y php-xcache;
    PHP_XCACHE_CONF_FILE="$PHP_CONF_DIR_PATH/xcache.ini";
    cp $PHP_XCACHE_CONF_FILE $PHP_XCACHE_CONF_FILE.bak;
    sed -i "s#xcache\\.optimizer\\s*=.*#xcache\\.optimizer=            On#g" $PHP_XCACHE_CONF_FILE;
    echo "xcache admin can be downloaded from http://xcache.lighttpd.net/";

    # xcache 管理端需要从 http://xcache.lighttpd.net/ 手动下载对应版本安装
    # 如果要给xcache的管理端设置密码，请修改 $PHP_CONF_DIR_PATH/xcache.ini( 即 /etc/php.d/xcache.ini ) 文件
}

function install_pecl_zendopcache()
{
    mkdir -p "$PHP_CACHE_DIR_PATH";
    mkdir -p "$PHP_EXT_LOG_DIR_PATH";
    yum install -y php-pecl-zendopcache;
    PHP_PECL_ZENDOPCACHE_CONF_FILE="$PHP_CONF_DIR_PATH/opcache.ini";
    cp $PHP_PECL_ZENDOPCACHE_CONF_FILE $PHP_PECL_ZENDOPCACHE_CONF_FILE.bak;
    sed -i '/^opcache.error_log\s*=.*/d' $PHP_PECL_ZENDOPCACHE_CONF_FILE;
    sed -i "N;/;opcache\\.error_log\\s*=.*/a\\opcache\\.error_log=\"$PHP_EXT_LOG_DIR_PATH/opcache.error.log\"" $PHP_PECL_ZENDOPCACHE_CONF_FILE;
    # 需要手动安装opcache-gui，有很多解决方案，可以google一下
    # 方案一： https://github.com/amnuts/opcache-gui
    # 方案二： https://github.com/rlerdorf/opcache-status/
    # 方案三： https://github.com/PeeHaa/OpCacheGUI
    # 方案四： https://github.com/carlosbuenosvinos/opcache-dashboard
}


# ===========================  安装优化器  ===========================
if [ -z "$PHP_OPT_COMP_INSTALL" ]; then
    echo "do you want to install php cache tools?(optional: xcache, zendopcache, eaccelerator, apcu, none)";
    read PHP_OPT_COMP_INSTALL;
fi

for PHP_OPT_COMP_NAME in $PHP_OPT_COMP_INSTALL; do
    PHP_OPT_CONFILCTS_FLAG=0;
    if [ "0" == "$PHP_OPT_CONFILCTS_FLAG" ] && [ "$PHP_OPT_COMP_NAME" == "xcache" ]; then
        PHP_OPT_CONFILCTS_FLAG=1;
        install_xcache;
    elif  [ "0" == "$PHP_OPT_CONFILCTS_FLAG" ] && [ "$PHP_OPT_COMP_NAME" == "zendopcache" ]; then
        PHP_OPT_CONFILCTS_FLAG=1;
        install_pecl_zendopcache;
    elif  [ "0" == "$PHP_OPT_CONFILCTS_FLAG" ] && [ "$PHP_OPT_COMP_NAME" == "eaccelerator" ]; then
        PHP_OPT_CONFILCTS_FLAG=1;
        install_eaccelerator;
    elif [ "$PHP_OPT_COMP_NAME" == "apcu" ]; then
        # install_pecl_apcu;
	# 这货会导致php-fpm崩溃，网上说不如用zendopcache 
	echo "apcu disabled in php-fpm 5.4";
    fi
done

if [ ! -z "DB_DATA_DIR" ] && [ -e "/etc/my.cnf" ]; then
    mkdir -p "$DB_DATA_DIR/mariadb/datadir";
    chown mysql:users "$DB_DATA_DIR" -R "$DB_DATA_DIR";
    sed -i "s#datadir=.*#datadir=$DB_DATA_DIR/mariadb/datadir#g" /etc/my.cnf;
fi

# ===========================  配置 权限  ===========================
chown nginx:users $PHP_EXT_LOG_DIR_PATH* $PHP_CACHE_DIR_PATH /var/log/nginx -R;

# ===========================  重启 服务  ===========================
systemctl restart nginx.service
systemctl restart php-fpm.service
systemctl restart mariadb.service
