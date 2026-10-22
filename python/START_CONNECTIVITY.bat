@echo off
cd /d "%~dp0"
python connectivity.py %*
if errorlevel 1 pause
