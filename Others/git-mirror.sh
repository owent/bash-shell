新建同步仓库
============

git clone --mirror https://github.com/atframework/atframe_utils.git atframe_utils
cd UnrealEngine
git push --mirror https://gitlab.com/atframework/atframe_utils.git

更新同步仓库
============
cd atframe_utils
git remote update
git push --mirror https://gitlab.com/atframework/atframe_utils.git

手动指定更新的引用
============
cd atframe_utils
git remote update
# git show-ref --head
git push --force https://gitlab.com/atframework/atframe_utils.git "+refs/heads/*:refs/heads/*" "+refs/tags/*:refs/tags/*"
