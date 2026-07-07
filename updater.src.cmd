@echo off
echo Installing Claude Code Client update...
timeout /t 3 /nobreak >nul
move /y "%~1" "%~3\old versions\claude-v%~4.cmd" >nul
move /y "%~2" "%~1" >nul
timeout /t 2 /nobreak >nul