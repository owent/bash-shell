# Let's Encrypt 使用说明和常用配置

Let's Encrypt 官方网站 https://letsencrypt.org/


# certbot
现在Let's Encrypt正式开始使用[**certbot**](https://certbot.eff.org)来生成证书

官网： https://certbot.eff.org

GitHub： https://github.com/certbot/certbot

## 初始化

参考 [init.sh](init.sh) 脚本，这是CentOS 7的脚本，其他系统类似，查看[官网](https://certbot.eff.org)可以获取安装[**certbot**](https://certbot.eff.org)的方法

## 续期脚本

参考 [renew.sh](renew.sh) 脚本，这是CentOS 7+nginx的脚本，其他系统类似。

请修改网站目录和证书拷贝脚本以适应自己的环境

# 关于续期
默认情况下renew命令只在证书快过期的时候（现在是剩余有效期30天内）允许续期，其他情况跳过，所以最好定时执行续期脚本。建议是一周或每天一次

1. crontab -e
2. 17 3 * * 1,4 /home/website/letsencrypt/renew.sh
3. 注意权限问题

# 限制
对每天每个域名，每3小时每台机器，一个域名最多签证的子域名数量等都有限制

详情见： https://letsencrypt.org/docs/rate-limits/

截止至目前，限制如下:

       限制项目            | 限制量 | 计量周期  
---------------------     |-------|--------
每个证书的域名数量           | 100   | 永久
每个注册域名每周处理证书数量   | 20    | 一周
每个完整域名每周处理证书数量   | 5     | 一周
每个周每账户(ACME)自动认证数  | 300   | 一周