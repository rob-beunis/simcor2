@echo off
cd /d "%~dp0"
python rawa_counts.py %*
if errorlevel 1 pause
