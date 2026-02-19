@echo off
echo Building Client HTML5...
cd Client
call lime build html5
if %ERRORLEVEL% NEQ 0 (
    echo Client build failed!
    exit /b %ERRORLEVEL%
)

echo Building Server HL...
cd ..\Server
call lime build hl
if %ERRORLEVEL% NEQ 0 (
    echo Server build failed!
    exit /b %ERRORLEVEL%
)

echo Running Server...
call run-server.bat
