#!/bin/sh
 
# 注意: CentOS 7这个脚本默认使用了MySQL的开源替代品mariadb
# 如果要切换会MySQL请自行安装并去除下面脚本内的安装的mariadb-server mariadb软件包

WORKING_DIR="$PWD";
 
ADMIN_EMAIL="admin@owent.net";
NGINX_CONF=/etc/nginx/nginx.conf
PHP_CONF_FILE_PATH=/etc/php.ini
PHP_CONF_DIR_PATH=/etc/php.d
PHP_FPM_CONF_DIR_PATH=/etc/php-fpm.d
PHP_FPM_CONF_FILE_PATH=/etc/php-fpm.conf
WEBSITE_DIR_PATH=/home/website
DB_CONF_FILE_PATH=/etc/my.cnf
PHP_OPT_COMP_INSTALL="";
USER=nginx
GROUP=users

while getopts "c:d:f:hw:m:n:u:g:s:" arg; do
        case $arg in
             c)
                PHP_CONF_FILE_PATH="$OPTARG";
                ;;
             d)
                PHP_CONF_DIR_PATH="$OPTARG";
                ;;
             l)
                LOG_DIR_PATH="$OPTARG";
                ;;
             f)
                PHP_FPM_CONF_FILE_PATH="$OPTARG";
                ;;
             p)
                PHP_FPM_CONF_DIR_PATH="$OPTARG";
                ;;
             m)
                ADMIN_EMAIL="$OPTARG";
                ;;
             n)
                NGINX_CONF="$OPTARG";
                ;;
             w)
                WEBSITE_DIR_PATH="$OPTARG";
                ;;
             u)
                USER="$OPTARG";
                ;;
             g)
                GROUP="$OPTARG";
                ;;
             s)
                DB_CONF_FILE_PATH="$OPTARG";
                ;;
             h)
                echo "usage: $0 [options]
options:
-c  <php.ini path>              path of php.ini(default: $PHP_CONF_FILE_PATH)
-d  <php conf dir>              dir path of php.d(default: $PHP_CONF_DIR_PATH)
-f  <php-fpm.conf path>         path of php-fpm.conf(default: $PHP_FPM_CONF_FILE_PATH)
-p  <php-fpm.d path>            path of php-fpm.d(default: $PHP_FPM_CONF_DIR_PATH)
-h                              help message
-w  <website dir>               dir path of website(default: $WEBSITE_DIR_PATH)
-m  <default admin email>       admin email(default: $ADMIN_EMAIL)
-n  <nginx.conf path>           path of nginx.conf(default: $NGINX_CONF)
-u  <user name>                 owner user name(default: $USER)
-g  <user group>                owner group name (default: $GROUP)
-s  <mysql/mariadb conf path>   path of my.cnf (default: $DB_CONF_FILE_PATH)
                ";
                exit 0;
                ;;
             ?)  #当有不认识的选项的时候arg为?
                echo "unkonw argument $arg";
                ;;
        esac
done

if [ ! -e "$WEBSITE_DIR_PATH" ]; then
    mkdir -p ""$WEBSITE_DIR_PATH;
fi
cd "$WEBSITE_DIR_PATH";
WEBSITE_DIR_PATH="$PWD";
NGINX_LOG_DIR="$WEBSITE_DIR_PATH/log/nginx";
PHP_LOG_DIR="$WEBSITE_DIR_PATH/log/php";
DB_LOG_DIR="$WEBSITE_DIR_PATH/log/db";
PHP_SESSION_DIR="$WEBSITE_DIR_PATH/session";
SSL_CERT_DIR="$WEBSITE_DIR_PATH/ssl";
mkdir -p "$NGINX_LOG_DIR";
mkdir -p "$PHP_LOG_DIR";
mkdir -p "$DB_LOG_DIR";
mkdir -p "$PHP_SESSION_DIR";
mkdir -p "$SSL_CERT_DIR";
chown $USER:$GROUP -R "$NGINX_LOG_DIR";
chown $USER:$GROUP -R "$PHP_LOG_DIR";
chown $USER:$GROUP -R "$WEBSITE_DIR_PATH";
chown $USER:$GROUP -R "$PHP_SESSION_DIR";
chown $USER:$GROUP -R "$SSL_CERT_DIR";
chown $USER:$GROUP -R "$DB_LOG_DIR";
chmod 777 -R "$WEBSITE_DIR_PATH/log";

# 替换nginx基础配置
ULIMIT_OPEN_FILES=$(ulimit -n);
if [ -z "$ULIMIT_OPEN_FILES" ] || [ "unlimited" == "$ULIMIT_OPEN_FILES" ]; then
    ULIMIT_OPEN_FILES=51200;
fi
sed -i "s/worker_processes\\s*[0-9]*\\s*;/worker_processes 4;/g" "$NGINX_CONF";
sed -i "s;error_log\\s*[^\\;]*\\;;error_log  $NGINX_LOG_DIR/nginx-error.log warn\\;;g" "$NGINX_CONF";
sed -i "/use\\s*epoll\\s*;/d" "$NGINX_CONF";
sed -i "s/worker_connections\\s*[0-9]*\\s*;/worker_connections $ULIMIT_OPEN_FILES;/g" "$NGINX_CONF";
sed -i "/worker_connections\\s*[0-9]*\\s*/i use epoll;" "$NGINX_CONF";

sed -i "s;access_log\\s*[^\\;]*\\;;access_log  $NGINX_LOG_DIR/nginx-access.log main\\;;g" "$NGINX_CONF";
sed -i "/gzip/d" "$NGINX_CONF";
sed -i "/server_tokens/d" "$NGINX_CONF";
sed -i "/fastcgi_hide_header/d" "$NGINX_CONF";
sed -i "/ssl_/d" "$NGINX_CONF";
sed -i "/add_header/d" "$NGINX_CONF";
NGINX_COMMON_CONFIGURES="\\
    gzip on; \\
    gzip_min_length  1k; \\
    gzip_buffers     16 64k;\\
    gzip_http_version 1.0;\\
    gzip_comp_level 5;\\
    gzip_types       text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;\\
    gzip_vary on; \\
\\
    # 去除 nginx 版本\\
    server_tokens off;\\
\\
    # 去除 Nginx 的 X-Powered-By header\\
    fastcgi_hide_header X-Powered-By;\\
\\
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # omit SSLv3 because of POODLE (CVE-2014-3566)\\
    ssl_session_cache   shared:SSL:10m;\\
    ssl_session_timeout 10m;\\
    ssl_session_tickets off;\\
    # add_header Strict-Transport-Security \"max-age=15768000; includeSubdomains; preload\"; # HSTS, 180days\\
    add_header X-Content-Type-Options nosniff;\\
\\
    ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';\\
    ssl_prefer_server_ciphers on;\\
    ssl_dhparam $SSL_CERT_DIR/dhparam.pem;\\
    ssl_stapling on;\\
    ssl_stapling_verify on;";
sed -i "/include\\s*[^\\*]*\\*[^;]*;/i\\ $NGINX_COMMON_CONFIGURES" "$NGINX_CONF";

if [ ! -e "$SSL_CERT_DIR/dhparam.pem" ]; then
    openssl dhparam -out "$SSL_CERT_DIR/dhparam.pem" 2048 ;
fi
# 替换nginx fastcgi_params配置
NGINX_CONF_FASTCGI_PARAMS="$(dirname $NGINX_CONF)/fastcgi_params";
sed -i "/fastcgi_connect_timeout/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_send_timeout/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_read_timeout/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_buffer_size/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_buffers/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_busy_buffers_size/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_temp_file_write_size/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_intercept_errors/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_param\\s*SCRIPT_FILENAME/d" "$NGINX_CONF_FASTCGI_PARAMS";
sed -i "/fastcgi_param\\s*SERVER_ADMIN/d" "$NGINX_CONF_FASTCGI_PARAMS";

echo "fastcgi_connect_timeout 300;
fastcgi_send_timeout 300;
fastcgi_read_timeout 300;
fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
fastcgi_temp_file_write_size 256k;
fastcgi_intercept_errors on;
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  SERVER_ADMIN       $ADMIN_EMAIL;" >> "$NGINX_CONF_FASTCGI_PARAMS";

# 替换PHP配置
if [ -e "$PHP_CONF_FILE_PATH" ]; then
    sed -i 's;date.timezone\s*=.*;date.timezone = "Asia/Shanghai";g' "$PHP_CONF_FILE_PATH";
    sed -i '/error_log\s*=\s*./d' "$PHP_CONF_FILE_PATH";
    sed -i "/php\\.net\\/error-log/a error_log = $PHP_LOG_DIR/php-error.log" "$PHP_CONF_FILE_PATH";

    sed -i '/sendmail_from\s*=\s*./d' "$PHP_CONF_FILE_PATH";
    sed -i "/sendmail_path\\s*=\\s*/a sendmail_from = $ADMIN_EMAIL" "$PHP_CONF_FILE_PATH";

    sed -i '/session\\.save_path\s*=\s*./d' "$PHP_CONF_FILE_PATH";
    sed -i "/php\\.net\\/session\\.save-path/a session.save_path = \"$PHP_SESSION_DIR\"" "$PHP_CONF_FILE_PATH";
else
    echo -e "\\033];mcan not find php.ini in $PHP_CONF_FILE_PATH\\033;0m";
fi

# 替换PHP-FPM配置
if [ -e "$PHP_FPM_CONF_FILE_PATH" ]; then
    sed -i "s#error_log\s*=.*#error_log = $PHP_LOG_DIR/php-fpm-error.log#g" "$PHP_FPM_CONF_FILE_PATH";
else
    echo -e "\\033];mcan not find php-fpm.conf in $PHP_FPM_CONF_FILE_PATH\\033;0m";
fi

for PHP_FPM_FILE in "$PHP_FPM_CONF_DIR_PATH/"*.conf ; do
    PHP_FPM_NAME="$(basename $PHP_FPM_FILE)";
    sed -i "s#slowlog\\s*=.*#slowlog = $PHP_LOG_DIR/php-fpm-$PHP_FPM_NAME-slow.log#g" "$PHP_FPM_FILE";
    sed -i "s#php_admin_value\\[error_log\\]\\s*=.*#php_admin_value\\[error_log\\] = $PHP_LOG_DIR/php-fpm-$PHP_FPM_NAME-error.log#g" "$PHP_FPM_FILE";
    sed -i "s#listen\\s*=.*#listen = /var/run/php-fpm.sock#g" "$PHP_FPM_FILE";

    sed -i "/php_value\\[session\\.save_path\\]\\s*=\\s*./d" "$PHP_FPM_FILE";
    sed -i "/php_admin_value\\[sendmail_path\\]\\s*=\\s*./d" "$PHP_FPM_FILE";

    echo "php_value[session.save_path] = $PHP_SESSION_DIR" >> "$PHP_FPM_FILE";
    echo "php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f $ADMIN_EMAIL" >> "$PHP_FPM_FILE";
done

# 替换mysql/mariadb配置
if [ -e "$DB_CONF_FILE_PATH" ]; then
    sed -i "s#log-error\s*=.*#log-error=$DB_LOG_DIR/mariadb.log#g" "$DB_CONF_FILE_PATH";
else
    echo -e "\\033];mcan not find my.cnf in $DB_CONF_FILE_PATH\\033;0m";
fi

# ===========================  重启 服务  ===========================
systemctl restart nginx.service
systemctl restart php-fpm.service
systemctl restart mariadb.service
