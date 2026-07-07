:: 1.2.0
:: Claude Code Client

@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
echo Claude Code Client - v1.2.0
echo.

set "CLAUDE_DIR=%~dp0claude"
set "RESOURCES_DIR=%~dp0resources"
set "NODE_DIR=%~dp0node" & REM temporarily not in use

if not exist "!RESOURCES_DIR!" mkdir "!RESOURCES_DIR!"
if exist "updater.cmd" del "updater.cmd"

call :main %*
if "!EXIT_IMMEDIATELY!"=="1" goto :eof
echo.
echo Thank you for using Claude Code Client ~
echo.
pause
goto :eof

:main
    call :env
    if "%~1"=="--update-script" (call :update %2 & goto :eof)
    if "%~1"=="-u" (call :update %2 & goto :eof)
    set "PROFILE="
    set "CLAUDE_ARGS="
    call :parse_args %*
    if defined PROFILE (
        call :load_ini "!PROFILE!"
        if "!SECTION_FOUND!"=="0" (
            echo Error: Profile "!PROFILE!" not found in settings.ini
            goto :eof
        )
    )
    call :install
    call :claude
    call :exit
    goto :eof

:env
    set "PATH=!CLAUDE_DIR!\.local\bin;!NODE_DIR!;!PATH!"
    set "USERPROFILE=!CLAUDE_DIR!"
    set "EXE=!CLAUDE_DIR!\.local\bin\claude.exe"

    set "CONFIG_FILE=!RESOURCES_DIR!\settings.ini"
    if exist "!CONFIG_FILE!" (
        call :load_ini ""
    ) else (
        call :create_ini
    )
    if "!ANTHROPIC_BASE_URL!"=="" set "ANTHROPIC_BASE_URL=https://api.anthropic.com"
    if "!MODEL_NAME!"=="" set "MODEL_NAME=claude-opus-4-6"
    if "!UPDATE_MASK!"=="" set "UPDATE_MASK=raw/refs/heads/{BRANCH}/claude.cmd"
    goto :eof

:load_ini
    set "SECTION_FOUND=0"
    set "TARGET_SECTION=%~1"
    set "IN_SECTION=0"
    for /f "usebackq delims=" %%A in ("!CONFIG_FILE!") do (
        set "line=%%A"
        if "!line:~0,1!"=="[" (
            if "!TARGET_SECTION!"=="" (
                goto :load_ini_done
            ) else (
                if "!line!"=="[!TARGET_SECTION!]" (set "IN_SECTION=1" & set "SECTION_FOUND=1") else (set "IN_SECTION=0")
            )
        )
        if not "!line:~0,1!"=="#" if not "!line:~0,1!"=="[" (
            if "!TARGET_SECTION!"=="" (
                for /f "tokens=1* delims==" %%B in ("%%A") do set "%%B=%%C"
            ) else (
                if "!IN_SECTION!"=="1" (
                    for /f "tokens=1* delims==" %%B in ("%%A") do set "%%B=%%C"
                )
            )
        )
    )
    :load_ini_done
    goto :eof

:create_ini
    set "INPUT_ANTHROPIC_BASE_URL="
    set /p "INPUT_ANTHROPIC_BASE_URL=Enter ANTHROPIC_BASE_URL [https://api.anthropic.com]: "
    if "!INPUT_ANTHROPIC_BASE_URL!"=="" (
        set "ANTHROPIC_BASE_URL=https://api.anthropic.com"
    ) else (
        set "ANTHROPIC_BASE_URL=!INPUT_ANTHROPIC_BASE_URL!"
    )

    set "INPUT_ANTHROPIC_AUTH_TOKEN="
    set /p "INPUT_ANTHROPIC_AUTH_TOKEN=Enter ANTHROPIC_AUTH_TOKEN [None]: "
    if "!INPUT_ANTHROPIC_AUTH_TOKEN!"=="" (
        set "ANTHROPIC_AUTH_TOKEN="
    ) else (
        set "ANTHROPIC_AUTH_TOKEN=!INPUT_ANTHROPIC_AUTH_TOKEN!"
    )

    set "INPUT_MODEL_NAME="
    set /p "INPUT_MODEL_NAME=Enter MODEL_NAME [claude-opus-4-6]: "
    if "!INPUT_MODEL_NAME!"=="" (
        set "MODEL_NAME=claude-opus-4-6"
    ) else (
        set "MODEL_NAME=!INPUT_MODEL_NAME!"
    )

    set "INPUT_BRANCH="
    set /p "INPUT_BRANCH=Enter UPDATE_BRANCH (main/dev) [main]: "
    if "!INPUT_BRANCH!"=="" (
        set "UPDATE_BRANCH=main"
    ) else (
        set "UPDATE_BRANCH=!INPUT_BRANCH!"
    )
    echo.
    (
        echo ANTHROPIC_BASE_URL=!ANTHROPIC_BASE_URL!
        echo ANTHROPIC_AUTH_TOKEN=!ANTHROPIC_AUTH_TOKEN!
        echo MODEL_NAME=!MODEL_NAME!
        echo UPDATE_BRANCH=!UPDATE_BRANCH!
        echo UPDATE_REPOSITORY=https://github.com/retopology/Claude-Code-Client
        echo UPDATE_MASK=raw/refs/heads/{BRANCH}/claude.cmd
    ) > "!CONFIG_FILE!"
    goto :eof

:update
    set "BRANCH=%~1"
    if "!BRANCH!"=="" set "BRANCH=!UPDATE_BRANCH!"
    if "!BRANCH!"=="" set "BRANCH=main"
    if "!UPDATE_REPOSITORY!"=="" set "UPDATE_REPOSITORY=https://github.com/retopology/Claude-Code-Client"

    echo Checking for updates from branch: !BRANCH!

    set "LATEST_FILE=!RESOURCES_DIR!\latest.cmd"
    if exist "!LATEST_FILE!" del "!LATEST_FILE!"

    curl -sLfk -o "!LATEST_FILE!" "!UPDATE_REPOSITORY!/!UPDATE_MASK:{BRANCH}=%BRANCH%!"
    if errorlevel 1 (
        echo Error: Failed to download update from branch "!BRANCH!".
        echo Please check your internet connection or the branch name.
        goto :eof
    )

    if not exist "!LATEST_FILE!" (
        echo Error: Downloaded file was not found.
        goto :eof
    )

    set "CURRENT_VERSION=unknown"
    for /f "usebackq tokens=2" %%A in ("%~f0") do (
        set "CURRENT_VERSION=%%A"
        goto :read_current_version_done
    )

    :read_current_version_done
    if "!CURRENT_VERSION!"=="unknown" (
        echo Error: Could not determine current version.
        if exist "!LATEST_FILE!" del "!LATEST_FILE!"
        goto :eof
    )
    set "LATEST_VERSION=unknown"
    for /f "usebackq tokens=2" %%A in ("!LATEST_FILE!") do (
        set "LATEST_VERSION=%%A"
        goto :read_latest_version_done
    )

    :read_latest_version_done
    if "!LATEST_VERSION!"=="unknown" (
        echo Error: Could not determine version of downloaded update.
        if exist "!LATEST_FILE!" del "!LATEST_FILE!"
        goto :eof
    )

    echo Current version: !CURRENT_VERSION!
    echo Latest version: !LATEST_VERSION!

    if "!CURRENT_VERSION!" NEQ "!LATEST_VERSION!" (
        set "READY_UPDATE=Y"
        set /p "READY_UPDATE=Do you want to update Claude Code Client? [Y/n]: "
        if /i "!READY_UPDATE!" NEQ "Y" (
            if exist "!LATEST_FILE!" del "!LATEST_FILE!"
            goto :eof
        )
        if not exist "!RESOURCES_DIR!\old versions\" mkdir "!RESOURCES_DIR!\old versions"
        set "TMPFILE=%~dp0updater.tmp"
        set "OUTFILE=%~dp0updater.cmd"
        if exist "!TMPFILE!" del "!TMPFILE!"
        <NUL set /p "=QGVjaG8gb2ZmCmVjaG8gSW5zdGFsbGluZyBDbGF1ZGUgQ29kZSBDbGllbnQgdXBkYXRlLi4uCnRpbWVvdXQgL3QgMyAvbm9icmVhayA+bnVsCm1vdmUgL3kgIiV+MSIgIiV+M1xvbGQgdmVyc2lvbnNcY2xhdWRlLXYlfjQuY21kIiA+bnVsCm1vdmUgL3kgIiV+MiIgIiV+MSIgPm51bAp0aW1lb3V0IC90IDIgL25vYnJlYWsgPm51bA==">"!TMPFILE!"
        powershell -NoProfile -Command "[System.IO.File]::WriteAllBytes($env:OUTFILE, [Convert]::FromBase64String((Get-Content -LiteralPath $env:TMPFILE -Raw)))"
        if exist "!TMPFILE!" del "!TMPFILE!"
        start cmd /c "call "%~dp0updater.cmd" "%~f0" "!LATEST_FILE!" "!RESOURCES_DIR!" "!CURRENT_VERSION!""
        set "EXIT_IMMEDIATELY=1"
    ) else (
        echo You already have the latest version: !LATEST_VERSION!
        if exist "!LATEST_FILE!" del "!LATEST_FILE!"
    )
    goto :eof

:parse_args
    if "%~1"=="" goto :eof
    if "%~1"=="--profile" (
        if "%~2"=="" (call :pick_profile & shift & goto :parse_args)
        set "_ARG=%~2"
        if "!_ARG:~0,1!"=="-" (call :pick_profile & shift & goto :parse_args)
        set "PROFILE=%~2" & shift & shift & goto :parse_args
    )
    if "%~1"=="-p" (
        if "%~2"=="" (call :pick_profile & shift & goto :parse_args)
        set "_ARG=%~2"
        if "!_ARG:~0,1!"=="-" (call :pick_profile & shift & goto :parse_args)
        set "PROFILE=%~2" & shift & shift & goto :parse_args
    )
    if defined CLAUDE_ARGS (set "CLAUDE_ARGS=!CLAUDE_ARGS! %1") else (set "CLAUDE_ARGS=%1")
    shift
    goto :parse_args

:pick_profile
    set "_N=0"
    echo   0. default
    for /f "usebackq delims=" %%A in ("!CONFIG_FILE!") do (
        set "_line=%%A"
        if "!_line:~0,1!"=="[" (
            set /a "_N+=1"
            set "_line=!_line:~1,-1!"
            set "_P!_N!=!_line!"
            echo   !_N!. !_line!
        )
    )
    if "!_N!"=="0" (
        echo No profiles found in settings.ini
        goto :eof
    )
    echo.
    set "_CHOICE="
    set /p "_CHOICE=Select profile [1-!_N!]: "
    echo.
    if "!_CHOICE!"=="" goto :eof
    if "!_CHOICE!"=="0" goto :eof
    if !_CHOICE! LSS 0 (echo Invalid selection. & goto :pick_profile)
    if !_CHOICE! GTR !_N! (echo Invalid selection. & goto :pick_profile)
    set "PROFILE=!_P%_CHOICE%!"
    goto :eof

:install
    if not exist "!EXE!" (
        if not exist "!RESOURCES_DIR!\claude.exe" (
            call :download
        )
        if exist "!RESOURCES_DIR!\claude.exe" (
            for /f "tokens=1" %%i in ('"!RESOURCES_DIR!\claude.exe" -v') do (
                if not exist "!CLAUDE_DIR!\.local\bin" mkdir "!CLAUDE_DIR!\.local\bin"
                copy "!RESOURCES_DIR!\claude.exe" "!CLAUDE_DIR!\.local\bin" >nul
                if not exist "!CLAUDE_DIR!\.local\share\claude\versions\" mkdir "!CLAUDE_DIR!\.local\share\claude\versions\"
                copy "!RESOURCES_DIR!\claude.exe" "!CLAUDE_DIR!\.local\share\claude\versions\%%i" >nul
            )
            call :add_to_path
        )
    ) else (
        set "LATEST_LOCAL="
        for /f "delims=" %%v in ('dir /b /a-d /o-d "!CLAUDE_DIR!\.local\share\claude\versions" 2^>nul') do (
            if not defined LATEST_LOCAL (
                set "LATEST_LOCAL=%%v"
            )
        )
        if defined LATEST_LOCAL (
            set "RES_VERSION="
            if exist "!RESOURCES_DIR!\claude.exe" (
                for /f "tokens=1" %%v in ('"!RESOURCES_DIR!\claude.exe" -v 2^>nul') do (
                    set "RES_VERSION=%%v"
                )
            )
            if "!LATEST_LOCAL!" NEQ "!RES_VERSION!" (
                copy "!CLAUDE_DIR!\.local\share\claude\versions\!LATEST_LOCAL!" "!RESOURCES_DIR!\claude.exe" >nul
            )
        )
    )
    goto :eof

:download
    for /f "usebackq tokens=*" %%i in (`curl -s -L https://downloads.claude.ai/claude-code-releases/latest`) do set "VERSION=%%i"
    if "!VERSION!"=="" (
        echo Error: Failed to fetch the latest version information.
        goto :eof
    )
    curl -Lf -o "!RESOURCES_DIR!\claude_downloading.exe" "https://downloads.claude.ai/claude-code-releases/!VERSION!/win32-x64/claude.exe"
    if !errorlevel! neq 0 (
        echo Error: Download failed with exit code !errorlevel!.
        if exist "!RESOURCES_DIR!\claude_downloading.exe" del "!RESOURCES_DIR!\claude_downloading.exe"
        goto :eof
    )
    if not exist "!RESOURCES_DIR!\claude_downloading.exe" (
        echo Error: Downloaded file not found.
        goto :eof
    )
    ren "!RESOURCES_DIR!\claude_downloading.exe" "claude.exe"
    echo.
    "!RESOURCES_DIR!\claude.exe" -v
    if errorlevel 1 (
        echo Error: Downloaded file is not a valid Claude Code executable.
        if exist "!RESOURCES_DIR!\claude.exe" del "!RESOURCES_DIR!\claude.exe"
        goto :eof
    )
    echo.
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
        echo "!REG_PATH!;" | findstr /I /C:"!SCRIPT_DIR!;" >nul && set "IN_PATH=1"
    )

    if "!IN_PATH!"=="0" (
        echo !SCRIPT_DIR!
        set /p "ADD_TO_PATH=Do you want to add it to the user's system PATH environment variable? [y/N]: "
        if /i "!ADD_TO_PATH!"=="Y" (
            reg export "HKCU\Environment" "!RESOURCES_DIR!\env_backup.reg" /y >nul
            if not exist "!RESOURCES_DIR!\env_backup.reg" (
                echo Error: Failed to create environment backup. Path modification aborted.
                goto :eof
            )
            if defined REG_PATH (
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SCRIPT_DIR!;!REG_PATH!" /f >nul
            ) else (
                reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SCRIPT_DIR!" /f >nul
            )
            echo Path added successfully.
            echo.
        )
    )
    goto :eof

:claude
    "!EXE!" --model "!MODEL_NAME!" !CLAUDE_ARGS!
    goto :eof

:exit
    endlocal
    goto :eof