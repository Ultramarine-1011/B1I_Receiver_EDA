@echo off
powershell.exe -NoProfile -File "%~dp0demo_acceptance.ps1"
if errorlevel 1 pause
