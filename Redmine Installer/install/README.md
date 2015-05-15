
软件源
======
1. using https://ruby.taobao.org/ as gem source(@see https://ruby.taobao.org/)

```bash
gem sources --remove https://rubygems.org/
gem sources -a https://ruby.taobao.org/
gem sources -l
```

2. edit Gemfile and change https://rubygems.org/ to https://ruby.taobao.org/ or http://rubygems.org/

其他
======
```bash

# 初始化命令
bundle exec rake generate_secret_token

RAILS_ENV=production bundle exec rake db:migrate

RAILS_ENV=production REDMINE_LANG=zh bundle exec rake redmine:load_default_data

# 权限设置
mkdir -p tmp tmp/pdf public/plugin_assets
sudo chown -R redmine:redmine files log tmp public/plugin_assets
sudo chmod -R 755 files log tmp public/plugin_assets

```

测试
======
```bash
bundle exec rails server webrick -e production
```


配置Web服务
======

thin
------

``bash
gem install thin;
thin install;
thin config -C /etc/thin/redmine.yml -c /usr/local/redmine -e production --server 4;
cp -f etc/thin/redmine.yml /etc/thin/redmine.yml

mkdir -p /var/run/thin;
chown nginx:users /var/run/thin -R

# 在redmine目录的Gemfile中添加
gem "thin"

# 启动脚本 
thin start -C /etc/thin/redmine.yml

# 自启动systemd配置见 usr/lib/systemd/system
```

备份
======
```bash
# Database
/usr/bin/mysqldump -u <username> -p<password> <redmine_database> | gzip > /path/to/backup/db/redmine_`date +%y_%m_%d`.gz

# Attachments
rsync -a /path/to/redmine/files /path/to/backup/files
```
