@echo off
 
:AQUIRE_ADMINISTRATOR_PRIVILEGE
rem 获取管理员权限
rem 首先在%windir%尝试新建文件夹，查看是否有管理员权限
rem 如果新建文件夹成功则删除文件夹，继续操作
rem 如果失败文件夹则新建vbs脚本，通过UAC窗口，获取管理员权限
rem 运行脚本后，删除vbs脚本
md "%windir%\TestAdminPrivilege" > nul
cls
if '%errorlevel%' == '0' ( 
  rmdir "%windir%\TestAdminPrivilege" & goto gotAdmin 
) else (goto UACPrompt)
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute %0, "", "", "runas", 1  >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" (del "%temp%\getadmin.vbs")
CD /D "%~dp0"

rem run your code here