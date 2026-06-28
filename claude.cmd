:: 1.0.0
:: Claude Code Client

@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
echo Claude Code Client - v1.0.0
echo.

set "CLAUDE_DIR=%~dp0claude"
set "RESOURCES_DIR=%~dp0resources"
set "NODE_DIR=%~dp0node" & REM temporarily not in use

if not exist "%RESOURCES_DIR%" mkdir "%RESOURCES_DIR%"

call :main %*
echo.
echo Thank you for using Claude Code Client ~
echo.
pause
goto :eof

:main
    call :env
    call :install
    call :claude %*
    call :exit
    goto :eof

:env
    set "PATH=%CLAUDE_DIR%\.local\bin;%NODE_DIR%;%PATH%"
    set "USERPROFILE=%CLAUDE_DIR%"
    set "EXE=%CLAUDE_DIR%\.local\bin\claude.exe"

    set "CONFIG_FILE=%RESOURCES_DIR%\.env"
    if exist "%CONFIG_FILE%" (
        for /f "usebackq delims=" %%A in ("%CONFIG_FILE%") do (
            set "key="
            set "val="
            for /f "tokens=1* delims==" %%B in ("%%A") do (
                set "key=%%B"
                set "val=%%C"
            )
            if "!key!"=="ANTHROPIC_BASE_URL" set "ANTHROPIC_BASE_URL=!val!"
            if "!key!"=="ANTHROPIC_AUTH_TOKEN" set "ANTHROPIC_AUTH_TOKEN=!val!"
            if "!key!"=="MODEL" set "MODEL=!val!"
        )
    ) else (
        call :create_env
    )
    goto :eof

:create_env
    set "INPUT_URL="
    set /p "INPUT_URL=Enter ANTHROPIC_BASE_URL [https://api.anthropic.com]: "
    if "!INPUT_URL!"=="" (
        set "ANTHROPIC_BASE_URL=https://api.anthropic.com"
    ) else (
        set "ANTHROPIC_BASE_URL=!INPUT_URL!"
    )

    set "INPUT_TOKEN="
    set /p "INPUT_TOKEN=Enter ANTHROPIC_AUTH_TOKEN [None]: "
    if "!INPUT_TOKEN!"=="" (
        set "ANTHROPIC_AUTH_TOKEN="
    ) else (
        set "ANTHROPIC_AUTH_TOKEN=!INPUT_TOKEN!"
    )

    set "INPUT_MODEL="
    set /p "INPUT_MODEL=Enter MODEL [claude-opus-4-6]: "
    if "!INPUT_MODEL!"=="" (
        set "MODEL=claude-opus-4-6"
    ) else (
        set "MODEL=!INPUT_MODEL!"
    )
    echo.
    (
        echo ANTHROPIC_BASE_URL=!ANTHROPIC_BASE_URL!
        echo ANTHROPIC_AUTH_TOKEN=!ANTHROPIC_AUTH_TOKEN!
        echo MODEL=!MODEL!
    ) > "%CONFIG_FILE%"
    goto :eof

:install
    if not exist "%EXE%" (
        if not exist "%RESOURCES_DIR%\claude.exe" (
            call :download
        )
        if exist "%RESOURCES_DIR%\claude.exe" (
            for /f "tokens=1" %%i in ('""%RESOURCES_DIR%\claude.exe" -v"') do (
                if not exist "%CLAUDE_DIR%\.local\bin" mkdir "%CLAUDE_DIR%\.local\bin"
                copy "%RESOURCES_DIR%\claude.exe" "%CLAUDE_DIR%\.local\bin" >nul
                if not exist "%CLAUDE_DIR%\.local\share\claude\versions\" mkdir "%CLAUDE_DIR%\.local\share\claude\versions\"
                copy "%RESOURCES_DIR%\claude.exe" "%CLAUDE_DIR%\.local\share\claude\versions\%%i" >nul
            )
            call :add_to_path
        )
    ) else (
        set "LATEST_LOCAL="
        for /f "delims=" %%v in ('dir /b /a-d /o-d "%CLAUDE_DIR%\.local\share\claude\versions" 2^>nul') do (
            if not defined LATEST_LOCAL (
                set "LATEST_LOCAL=%%v"
            )
        )
        if defined LATEST_LOCAL (
            set "RES_VERSION="
            if exist "%RESOURCES_DIR%\claude.exe" (
                for /f "tokens=1" %%v in ('""%RESOURCES_DIR%\claude.exe" -v" 2^>nul') do (
                    set "RES_VERSION=%%v"
                )
            )
            if "!LATEST_LOCAL!" NEQ "!RES_VERSION!" (
                copy "%CLAUDE_DIR%\.local\share\claude\versions\!LATEST_LOCAL!" "%RESOURCES_DIR%\claude.exe" >nul
            )
        )
    )
    goto :eof

:add_to_path
    set "SCRIPT_DIR=%~dp0"
    set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
    set "IN_PATH=0"
    set "REG_PATH="

    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
        set "REG_PATH=%%B"
    )

    if defined REG_PATH (
        echo "!REG_PATH!" | findstr /I /C:"!SCRIPT_DIR!" >nul && set "IN_PATH=1"
    )

    if "!IN_PATH!"=="0" (
        echo !SCRIPT_DIR!
        set /p "ADD_TO_PATH=Do you want to add it to the user's system PATH environment variable? [y/N]: "
        if /i "!ADD_TO_PATH!"=="Y" (
            reg export "HKCU\Environment" "%RESOURCES_DIR%\env_backup.reg" /y >nul
            if not exist "%RESOURCES_DIR%\env_backup.reg" (
                echo Error: Failed to create environment backup. Path modification aborted.
                goto :eof
            )
            if defined REG_PATH (
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SCRIPT_DIR!;!REG_PATH!" /f >nul
            ) else (
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SCRIPT_DIR!" /f >nul
            )
            echo.
        )
    )
    goto :eof

:download
    for /f "usebackq tokens=*" %%i in (`curl -s -L https://downloads.claude.ai/claude-code-releases/latest`) do set "VERSION=%%i"
    if "!VERSION!"=="" (
        echo Error: Failed to fetch the latest version information.
        goto :eof
    )
    curl -L -o "%RESOURCES_DIR%\claude_downloading.exe" "https://downloads.claude.ai/claude-code-releases/!VERSION!/win32-x64/claude.exe"
    if %errorlevel% neq 0 (
        echo Error: Download failed with exit code %errorlevel%.
        if exist "%RESOURCES_DIR%\claude_downloading.exe" del "%RESOURCES_DIR%\claude_downloading.exe" >nul
        goto :eof
    )
    if not exist "%RESOURCES_DIR%\claude_downloading.exe" (
        echo Error: Downloaded file not found.
        goto :eof
    )
    ren "%RESOURCES_DIR%\claude_downloading.exe" "claude.exe"
    "%RESOURCES_DIR%\claude.exe" -v
    if errorlevel 1 (
        echo Error: Downloaded file is not a valid Claude Code executable.
        del "%RESOURCES_DIR%\claude.exe" 2>nul
        goto :eof
    )
    echo.
    goto :eof

:claude
    "%EXE%" --model "%MODEL%" %*
    goto :eof

:exit
    endlocal
    goto :eof