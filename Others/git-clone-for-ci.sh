#!/bin/bash

# ====== SSH Key方式鉴权（推荐） ======

CI_SSH_KEY=~/.ssh/id_rsa.ci;

# 清理意外情况导致的长期ssh-agent
for PENDING_TO_KILL in $(ps --sort start_time -u $USER -o pid,state,etimes,start_time,command | grep "ssh-agent" | grep -v grep | awk '{if($3 > 259200) { print $1;}}') ; do
    kill $PENDING_TO_KILL;
done

# 启用ssh-agent来控制鉴权
eval $(timeout 3h ssh-agent);

# 默认ssh会检查key的权限，所以设置权限600
chmod 600 "$CI_SSH_KEY";
ssh-add "$CI_SSH_KEY";

# 设置忽略未知Host
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" ;

# echo "Host github.com
#     HostName github.com
#     IdentityFile $CI_SSH_KEY
#     User owent
#     Port 22
#     AddKeysToAgent yes" > $HOME/.ssh/config;

if [ -e repo ]; then
    cd repo;
    git reset --hard;
    git clean -dfx;
    git fetch origin;
    if [ $? -ne 0 ]; then
        echo "Fetch from remote failed";
        exit $?;
    fi
        
    git reset --hard origin/master;
    if [ $? -ne 0 ]; then
        git reset --hard;
        git clean -dfx;
        git reset --hard origin/master;
    fi
	
    # 替换submodule里的http地址到ssh地址
    if [ -e .gitmodules ]; then
        sed -E -i.bak "s;https\\?://github.com/;git@github.com:;" .gitmodules ;
        sed -E -i.bak "s;https\\?://github.com/;git@github.com:;" .git/config ;
        git submodule foreach "git reset --hard && git clean -dfx";
        git submodule update --init -f;
    fi
else
    git clone --depth=1 -b master git@github.com:owent-utils/bash-shell.git repo;
    cd repo;
    
    git lfs install;

    # 替换submodule里的http地址到ssh地址
    if [ -e .gitmodules ]; then
        sed -E -i.bak "s;https\\?://github.com/;git@github.com:;" .gitmodules ;
        sed -E -i.bak "s;https\\?://github.com/;git@github.com:;" .git/config ;
        git submodule update --init -f;
    fi
fi

git lfs pull;

#if [ "x$GIT_SETUP_USE_SSH_AGENT" != "x" ] && [ "x$GIT_SETUP_REUSE_SSH_AGENT" == "x" ]; then
    ssh-agent -k;
#fi


# ====== 备份http/https方式用户名密码鉴权（明文存储，不推荐） ======
GIT_CREDENTIAL_FILE=~/.git-credentials       ; # [密码文件存储地址]
git config --global user.[域名].name [用户名] ; # 也可以不指定域名直接写 user.name ，但不建议写全局
git config --global user.[域名].email [邮箱]  ; # 也可以不指定域名直接写 user.email ，但不建议写全局
git config --global credential.[域名].helper "store --file $GIT_CREDENTIAL_FILE" # 也可以不指定域名直接写 credential.helper ，但不建议写全局

### protocol 注意区分http和https,注意不能有多余的空格
echo "protocol=http  
host=[域名]
username=[用户名]
password=[密码]" | git credential-store --file $GIT_CREDENTIAL_FILE store ;

chmod 600 [密码文件存储地址] ;

# ====== 地址别名（共享鉴权配置） ======
git config --global --unset-all url.[Git地址].insteadOf || true
git config --add --global url.[Git地址].insteadOf "[Git别名地址]"
# git config --global credential.git@github.com.helper "store --file $GIT_CREDENTIAL_FILE"
# git config --global --unset-all url.git@github.com:.insteadOf || true
# git config --add --global url.git@github.com:.insteadOf "https://github.com.com/"

