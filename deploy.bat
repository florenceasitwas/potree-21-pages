@echo off
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
    echo ERROR: You have uncommitted changes!
    echo Please commit your changes before deploying.
    echo.
    git status --short
    echo.
    pause
    exit /b 1
)

REM Check for unpushed commits
for /f %%i in ('git rev-list @{u}..HEAD 2^>nul ^| find /c /v ""') do set UNPUSHED=%%i
if %UNPUSHED% GTR 0 (
    echo ERROR: You have %UNPUSHED% unpushed commit(s)!
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

echo Source: %SOURCE%
echo Destination: %DEST%
echo.
echo Deploying files...
echo.

REM Use robocopy to mirror files, excluding .git and other dev files
robocopy "%SOURCE%" "%DEST%" /MIR /XD .git .vs node_modules .vscode /XF .gitignore deploy.bat deploy-preview.bat deploy.ps1 *.md /NFL /NDL /NJH /NJS

if %ERRORLEVEL% LEQ 3 (
    echo.
    echo ================================================
    echo Deployment completed successfully!
    echo Deployed files that are synced with GitHub
    echo ================================================
) else (
    echo.
    echo ================================================
    echo Deployment failed with error code: %ERRORLEVEL%
    echo ================================================
)

pause
