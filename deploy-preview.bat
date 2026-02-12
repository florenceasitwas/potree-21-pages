@echo off
echo ================================================
echo PREVIEW MODE - No files will be changed
echo ================================================
echo.

REM Set source and destination paths
set SOURCE=%~dp0
set DEST=\\lpotree2\sambashare\v21\pages

REM Remove trailing backslash from SOURCE
if "%SOURCE:~-1%"=="\" set SOURCE=%SOURCE:~0,-1%

echo Source: %SOURCE%
echo Destination: %DEST%
echo.
echo Checking what would be copied/deleted...
echo.

REM Use robocopy in LIST ONLY mode (/L) to preview changes
robocopy "%SOURCE%" "%DEST%" /MIR /XD .git .vs node_modules .vscode /XF .gitignore deploy.bat deploy-preview.bat deploy.ps1 *.md /L

echo.
echo ================================================
echo PREVIEW COMPLETE - No files were changed
echo ================================================
echo.
echo Review the list above to see what would happen.
echo.
echo Files marked with:
echo   New File       - Will be copied to destination
echo   Newer          - Will update existing file
echo   *EXTRA File    - Will be DELETED from destination
echo.
echo If this looks good, run deploy.bat to actually deploy.
echo.
pause
