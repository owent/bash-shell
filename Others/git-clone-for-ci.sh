#!/bin/bash

CI_SSH_KEY=~/.ssh/id_rsa.ci;

# 清理意外情况导致的长期ssh-agent
ps --sort start_time -u $USER -o pid,state,etimes,start_time,command | grep "ssh-agent" | grep -v grep | awk '{if($3 > 259200) { print $1;}}' | xargs kill ;

# 启用ssh-agent来控制鉴权
eval $(ssh-agent);

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
