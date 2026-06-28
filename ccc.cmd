@echo off
chcp 65001 >nul

set "PATH=%~dp0claude\.local\bin;%~dp0node;%PATH%"

if not exist "%~dp0claude\.local\bin\claude.exe" (
    for /f "tokens=1" %%i in ('""%~dp0resources\claude.exe" -v"') do (
        mkdir "%~dp0claude\.local\bin"
        copy "%~dp0resources\claude.exe" "%~dp0claude\.local\bin"
        mkdir "%~dp0claude\.local\share\claude\versions\"
        copy "%~dp0resources\claude.exe" "%~dp0claude\.local\share\claude\versions\%%i"
    )
)

set "MODEL=claude-opus-4-6"

set "USERPROFILE=%~dp0claude"
set "EXE=%~dp0claude\.local\bin\claude.exe"

set "ANTHROPIC_BASE_URL=https://api.anthropic.com"
set "ANTHROPIC_AUTH_TOKEN="

"%EXE%" --model "%MODEL%" %*

pause