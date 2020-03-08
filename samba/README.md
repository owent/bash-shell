# Samba

服务启动:

```bash
# smb服务
sudo systemctl enable smb.service
sudo systemctl restart smb.service

# 网络发现(NetBIOS name server to provide NetBIOS over IP naming services to clients)
sudo systemctl enable nmb.service
sudo systemctl restart nmb.service

# 添加用户
sudo smbpasswd -a root
sudo smbpasswd -a admin
sudo smbpasswd -a owent
```

## Samba 服务器配置

文件: **/etc/samba/smb.conf**

```
[global]
   workgroup = WORKGROUP
   dns proxy = no
   log file = /data/logs/samba/%m.log   # LOG 目录
   max log size = 1000
   client min protocol = SMB2
   server role = standalone server
   server services = +smb                # LOG 目录
   passdb backend = tdbsam
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *New*UNIX*password* %n\n *ReType*new*UNIX*password* %n\n *passwd:*all*authentication*tokens*updated*successfully*
   pam password change = yes
   map to guest = Bad User               # 默认的 Bad Password 会让游客也必须输入正确的用户名才能打开
   usershare allow guests = yes
   name resolve order = lmhosts bcast host wins
   security = user
   guest account = nobody
   guest ok = yes
   usershare path = /data/samba          # 数据共享目录
   usershare max shares = 256
   usershare owner only = yes
   force create mode = 0777
   force directory mode = 0777
   # socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=2097152 SO_SNDBUF=2097152 # 连接优化
   socket options = TCP_NODELAY SO_RCVBUF=2097152 SO_SNDBUF=2097152 # 连接优化

[share]
   comment = Shared Directories(Guest account: nobody)
   path = /data/samba
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   guest ok = yes

[download]
   comment = Download Directory(Guest account: nobody)
   path = /data/aria2/download
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   guest ok = yes

[data]
   comment = Data Directories(require login)
   path = /data
   browseable = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   security = user
   guest ok = no
   valid users = admin,owent,root

[printers]
   comment = All Printers
   browseable = no
   path = /var/spool/samba
   printable = yes
   guest ok = yes
   read only = yes
   create mask = 0700

[print$]
   comment = Printer Drivers
   path = /var/lib/samba/printers
   browseable = yes
   read only = yes
   guest ok = yes
```



## Windows关闭老连接

连接提示: **不允许一个用户使用一个以上用户名与一个服务器或共享资源的多重连接**

执行:

```bash
net use * /del /y
```
