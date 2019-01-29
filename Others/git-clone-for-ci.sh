#!/bin/bash

CI_SSH_KEY=~/.ssh/id_rsa.ci;

# 启用ssh-agent来控制鉴权
eval $(ssh-agent);

# 默认ssh会检查key的权限，所以设置权限600
chmod 600 "$CI_SSH_KEY";
ssh-add "$CI_SSH_KEY";

# 设置忽略未知Host
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" ;

if [ -e repo]; then
    cd repo;
    git reset --hard;
    git clean -dfx;
	git pull;
    # 替换submodule里的http地址到ssh地址
    sed -i "s;https\\?://github.com/;git@github.com:;" .gitmodules ;
    sed -i "s;https\\?://github.com/;git@github.com:;" .git/config ;
	git submodule foreach "git reset --hard && git clean -dfx";
    git submodule update --init -f;
else
    git clone --depth=1 -b master git@github.com:owent-utils/bash-shell.git repo;
    cd repo;
	
	git lfs install;

    # 替换submodule里的http地址到ssh地址
    sed -i "s;https\\?://github.com/;git@github.com:;" .gitmodules ;
    sed -i "s;https\\?://github.com/;git@github.com:;" .git/config ;
	git submodule update --init -f;
fi

git lfs pull;
