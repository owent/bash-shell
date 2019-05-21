新建同步仓库
============

git clone --mirror https://github.com/atframework/atframe_utils.git atframe_utils
cd UnrealEngine
git push --mirror https://gitlab.com/atframework/atframe_utils.git

更新同步仓库
============
cd UnrealEngine
git remote update
git push --mirror https://gitlab.com/atframework/atframe_utils.git
