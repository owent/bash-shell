@echo off

chcp 65001

where pwsh

if ERRORLEVEL 0 goto USE_POWERSHELL_CORE

exit %ERRORLEVEL%

:USE_POWERSHELL

@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Interactive -NoExit -File %~dp0\aria2-rpc.ps1

:USE_POWERSHELL_CORE

@pwsh.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Interactive -NoExit -File %~dp0\aria2-rpc.ps1
