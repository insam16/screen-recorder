@echo off
chcp 65001 >nul
REM 더블클릭하면 녹화가 시작됩니다. 이 창에서 q 를 누르면 저장 후 종료됩니다.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0record.ps1" %*
pause
