@echo off
rem Copy civetweb.hdll and sqlite.hdll from SideWinder prebuilt to Export folder

set PREBUILT_DIR=.haxelib\SideWinder\git\native\civetweb\prebuilt\windows

if not exist "%PREBUILT_DIR%" (
    echo [copy-server-hdlls.bat] Path not found: %PREBUILT_DIR%
    exit /b 0
)

rem HL Target
if exist "Export\hl\bin" (
    echo [copy-server-hdlls.bat] Copying dlls to Export\hl\bin
    copy /Y "%PREBUILT_DIR%\civetweb.hdll" "Export\hl\bin\" >nul
    copy /Y "%PREBUILT_DIR%\sqlite.hdll" "Export\hl\bin\" >nul
)

rem HLC Target
if exist "Export\hlc\bin" (
    echo [copy-server-hdlls.bat] Copying dlls to Export\hlc\bin
    copy /Y "%PREBUILT_DIR%\civetweb.hdll" "Export\hlc\bin\" >nul
    copy /Y "%PREBUILT_DIR%\sqlite.hdll" "Export\hlc\bin\" >nul
)
