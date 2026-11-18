@echo off
chcp 65001 >nul
title 一键上传到 GitHub
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0一键上传.ps1"
if errorlevel 1 pause