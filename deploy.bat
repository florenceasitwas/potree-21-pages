@echo off
setlocal enabledelayedexpansion
echo ================================================
echo Deploying to live web server...
echo ================================================
echo.

REM Set source and destination paths
set SOURCE=%~dp0
set DEST=\\lpotree2\sambashare\v21\pages

REM Remove trailing backslash from SOURCE
if "%SOURCE:~-1%"=="\" set SOURCE=%SOURCE:~0,-1%

cd /d "%SOURCE%"

echo Checking Git status...
echo.

REM Check for uncommitted changes
git diff --quiet
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: You have uncommitted changes
    echo Please commit your changes before deploying.
    echo.
    git status --short
    echo.
    pause
    exit /b 1
)

REM Check for unpushed commits
for /f %%i in ('git rev-list @{u}..HEAD 2^>nul ^| C:\Windows\System32\find.exe /c /v ""') do set UNPUSHED=%%i
if %UNPUSHED% GTR 0 (
    echo ERROR: You have %UNPUSHED% unpushed commit(s^)
    echo Please push to GitHub before deploying.
    echo.
    git log @{u}..HEAD --oneline
    echo.
    pause
    exit /b 1
)

echo ✓ Git working tree is clean
echo ✓ All commits are pushed to GitHub
echo.

REM Pull latest from GitHub to ensure sync
echo Pulling latest from GitHub...
git pull origin main
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to pull from GitHub
    pause
    exit /b 1
)
echo ✓ Synced with GitHub
echo.

REM Get current commit hash
for /f %%i in ('git rev-parse HEAD') do set CURRENT_COMMIT=%%i

REM Check for last deployed commit marker
set MARKER_FILE=%DEST%\.last-deploy
set LAST_COMMIT=
if exist "%MARKER_FILE%" (
    for /f %%i in ('type "%MARKER_FILE%"') do set LAST_COMMIT=%%i
    echo Last deployment: !LAST_COMMIT!
    echo Current commit:  %CURRENT_COMMIT%
    echo.
)

if "!LAST_COMMIT!"=="" (
    echo WARNING: No deployment marker found.
    echo This appears to be the first deployment with this system.
    echo.
    echo Choose deployment mode:
    echo 1. Smart deploy - Only copy files changed in last commit
    echo 2. Full sync - Mirror all files (slower, updates all timestamps)
    echo.
    choice /C 12 /N /M "Enter choice (1 or 2): "
    set CHOICE_RESULT=!ERRORLEVEL!
    if !CHOICE_RESULT!==2 (
        echo.
        echo Performing FULL SYNC...
        echo.
        robocopy "%SOURCE%" "%DEST%" /MIR /XD .git .vs node_modules .vscode /XF .gitignore deploy.bat deploy-preview.bat deploy.ps1 *.md
        goto :mark_deployed
    )
    REM For smart deploy on first run, use last commit only
    set LAST_COMMIT=HEAD~1
)

echo Analyzing changed files since last deployment...
echo.

REM Get list of changed files
set CHANGED_COUNT=0
for /f "delims=" %%f in ('git diff --name-only !LAST_COMMIT! %CURRENT_COMMIT%') do (
    set "FILE=%%f"
    REM Skip excluded files
    echo !FILE! | findstr /i "\.gitignore deploy.bat deploy-preview.bat deploy.ps1 \.md$" >nul
    if !ERRORLEVEL! NEQ 0 (
        echo Copying: !FILE!
        REM Create directory structure if needed
        for %%d in ("!FILE!") do set "DIR=%%~dpd"
        if not "!DIR!"=="." (
            if not exist "%DEST%\!DIR!" mkdir "%DEST%\!DIR!"
        )
        REM Copy the file
        copy /Y "%SOURCE%\!FILE!" "%DEST%\!FILE!" >nul
        set /a CHANGED_COUNT+=1
    )
)

:mark_deployed
echo.
if %CHANGED_COUNT% GTR 0 (
    echo Deployed %CHANGED_COUNT% changed file(s^)
) else (
    echo No files needed to be updated
)

REM Update deployment marker
echo %CURRENT_COMMIT%> "%MARKER_FILE%"
echo ✓ Updated deployment marker

echo.
echo ================================================
echo Deployment completed successfully!
echo Deployed commit: %CURRENT_COMMIT%
echo ================================================

pause
