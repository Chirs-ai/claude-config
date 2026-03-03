@echo off
REM Claude Code 配置一键部署 - Windows 双击入口
REM 自动调用 PowerShell 执行 deploy.ps1

powershell -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
pause
