@echo off
REM ================================================================
REM  Upload code to GitHub
REM  Pure ASCII batch - safe against code page issues.
REM  The PowerShell script is UTF-8 with BOM, so it reads Chinese
REM  correctly and outputs using the console's native code page.
REM ================================================================
title Upload to GitHub
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0upload.ps1"

if errorlevel 1 (
    echo.
    echo Script returned an error. See messages above.
    pause
)