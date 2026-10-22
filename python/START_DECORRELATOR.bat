@echo off
cd /d "%~dp0"
python decorrelator.py %*
if errorlevel 1 pause
