@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM CONFIGURATION
REM ============================================================

set "CONFIG_FILE=%~1"
if not defined CONFIG_FILE set "CONFIG_FILE=%~dp0update_ssl_certificates.conf"
set "NOTIFY_SCRIPT=%~dp0notify_discord.bat"
set "DISCORD_WEBHOOK_FILE=%~dp0discord_webhooks\ssl_alerts.txt"

if not "%~2"=="" (
    echo Usage: %~nx0 [CONFIG_FILE]
    exit /b 2
)

if not exist "%CONFIG_FILE%" (
    echo ERROR: Configuration file was not found: "%CONFIG_FILE%"
    call :send_notification error "SSL updater configuration error" "Configuration file was not found: %CONFIG_FILE%"
    exit /b 1
)

set "CERT_SERVER="
set "CERT="
set "TARGET_BASE="
set "TOMCAT_SERVICE="
set "SERVICE_POLL_SECONDS="
set "STOP_TIMEOUT_SECONDS="
set "FORCE_KILL_WAIT_SECONDS="
set "CONFIG_ERROR=0"

REM The config format is KEY=VALUE, without quotes or spaces around the equals
REM sign. Only the known keys below are accepted; the file is not executed.
for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    set "CONFIG_KNOWN=0"

    if /I "%%A"=="CERT_SERVER" (
        set "CERT_SERVER=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="CERT" (
        set "CERT=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="TARGET_BASE" (
        set "TARGET_BASE=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="TOMCAT_SERVICE" (
        set "TOMCAT_SERVICE=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="SERVICE_POLL_SECONDS" (
        set "SERVICE_POLL_SECONDS=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="STOP_TIMEOUT_SECONDS" (
        set "STOP_TIMEOUT_SECONDS=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="FORCE_KILL_WAIT_SECONDS" (
        set "FORCE_KILL_WAIT_SECONDS=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="NOTIFY_SCRIPT" (
        set "NOTIFY_SCRIPT=%%B"
        set "CONFIG_KNOWN=1"
    )
    if /I "%%A"=="DISCORD_WEBHOOK_FILE" (
        set "DISCORD_WEBHOOK_FILE=%%B"
        set "CONFIG_KNOWN=1"
    )

    if "!CONFIG_KNOWN!"=="0" (
        echo ERROR: Unknown configuration key: %%A
        set "CONFIG_ERROR=1"
    )
)

for %%V in (CERT_SERVER CERT TARGET_BASE TOMCAT_SERVICE SERVICE_POLL_SECONDS STOP_TIMEOUT_SECONDS FORCE_KILL_WAIT_SECONDS NOTIFY_SCRIPT DISCORD_WEBHOOK_FILE) do (
    if not defined %%V (
        echo ERROR: Required configuration value is missing: %%V
        set "CONFIG_ERROR=1"
    )
)

if "%CONFIG_ERROR%"=="1" (
    call :send_notification error "SSL updater configuration error" "The configuration file contains unknown keys or is missing required values: %CONFIG_FILE%"
    exit /b 1
)

REM ============================================================
REM SCRIPT
REM ============================================================

set "TARGET_DIR=%TARGET_BASE%\%CERT%"
set "CHANGED=0"
set "FAILED=0"
set "INSTALL_STARTED=0"

if not exist "%TARGET_BASE%" (
    mkdir "%TARGET_BASE%"
    if errorlevel 1 (
        echo ERROR: Could not create %TARGET_BASE%
        call :send_notification error "SSL certificate update failed" "Could not create the certificate directory: %TARGET_BASE%"
        exit /b 1
    )
)

:create_work_dir
set "WORK_DIR=%TARGET_BASE%\.ssl-update-%RANDOM%-%RANDOM%"
if exist "%WORK_DIR%" goto create_work_dir

set "STAGE_DIR=%WORK_DIR%\downloads"
set "BACKUP_DIR=%WORK_DIR%\backups"

mkdir "%STAGE_DIR%"
if errorlevel 1 (
    echo ERROR: Could not create temporary download directory.
    call :send_notification error "SSL certificate update failed" "Could not create the temporary certificate download directory."
    call :cleanup
    exit /b 1
)

mkdir "%BACKUP_DIR%"
if errorlevel 1 (
    echo ERROR: Could not create temporary backup directory.
    call :send_notification error "SSL certificate update failed" "Could not create the temporary certificate backup directory."
    call :cleanup
    exit /b 1
)

echo Checking certificate: %CERT%

REM Download both files before changing the installed certificate.
REM If no curl.exe on the server then download from https://curl.se/windows/ then extract to C:\dev\curl and add C:\dev\curl\bin to PATH
for %%F in (server.crt chain.crt) do (
    set "URL=%CERT_SERVER%/%CERT%/%%F"
    set "STAGED=!STAGE_DIR!\%%F"

    echo   Downloading !URL!

    curl.exe ^
        --fail ^
        --silent ^
        --show-error ^
        --location ^
        --connect-timeout 15 ^
        --max-time 60 ^
        "!URL!" ^
        --output "!STAGED!"

    if errorlevel 1 (
        echo ERROR: Failed to download !URL!
        set "FAILED=1"
    ) else (
        for %%S in ("!STAGED!") do set "SIZE=%%~zS"

        if "!SIZE!"=="0" (
            echo ERROR: Downloaded file is empty: !URL!
            set "FAILED=1"
        )
    )
)

if "%FAILED%"=="1" (
    echo.
    echo One or more certificate downloads failed.
    echo Existing certificates were not changed.
    echo Tomcat will NOT be restarted.
    call :send_notification error "SSL certificate update failed" "One or more files for %CERT% could not be downloaded or were empty. Existing certificates were not changed and Tomcat was not restarted."
    call :cleanup
    exit /b 1
)

REM Compare the complete staged update with the installed files.
for %%F in (server.crt chain.crt) do (
    set "STAGED=%STAGE_DIR%\%%F"
    set "TARGET=%TARGET_DIR%\%%F"

    if exist "!TARGET!" (
        fc /b "!STAGED!" "!TARGET!" >nul 2>&1

        if errorlevel 1 (
            echo   %%F changed
            set "CHANGED=1"
        ) else (
            echo   %%F unchanged
        )
    ) else (
        echo   %%F is new
        set "CHANGED=1"
    )
)

if "%CHANGED%"=="0" (
    echo.
    echo No certificate changes detected.
    call :cleanup
    exit /b 0
)

if not exist "%TARGET_DIR%" (
    mkdir "%TARGET_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create %TARGET_DIR%
        call :send_notification error "SSL certificate update failed" "Could not create the certificate directory: %TARGET_DIR%"
        call :cleanup
        exit /b 1
    )
)

echo.
echo Certificate changes detected. Installing staged files...
set "INSTALL_STARTED=1"

REM Back up and replace only changed files.
for %%F in (server.crt chain.crt) do (
    set "STAGED=%STAGE_DIR%\%%F"
    set "TARGET=%TARGET_DIR%\%%F"
    set "BACKUP=%BACKUP_DIR%\%%F"
    set "MARKER=%BACKUP_DIR%\%%F.changed"
    set "FILE_CHANGED=1"

    if exist "!TARGET!" (
        fc /b "!STAGED!" "!TARGET!" >nul 2>&1
        if not errorlevel 1 set "FILE_CHANGED=0"
    )

    if "!FILE_CHANGED!"=="1" (
        if exist "!TARGET!" (
            copy /y "!TARGET!" "!BACKUP!" >nul
            if errorlevel 1 goto install_failed
        )

        copy /y NUL "!MARKER!" >nul
        if errorlevel 1 goto install_failed

        move /y "!STAGED!" "!TARGET!" >nul
        if errorlevel 1 goto install_failed
    )
)

echo Restarting Tomcat service: %TOMCAT_SERVICE%...

call :restart_tomcat
if errorlevel 1 goto restart_failed

echo Certificate update completed successfully.
call :send_notification success "SSL certificate updated" "Updated %CERT%. Tomcat service %TOMCAT_SERVICE% restarted successfully."
call :cleanup
exit /b 0

:install_failed
echo ERROR: Could not install the certificate files.
call :rollback
call :send_notification error "SSL certificate update failed" "Could not install the new files for %CERT%. Previous certificate files were restored."
call :cleanup
exit /b 1

:restart_failed
echo ERROR: Tomcat restart failed.
call :rollback
echo Attempting to start Tomcat with the previous certificate files...
call :ensure_tomcat_running
if errorlevel 1 (
    echo CRITICAL: Tomcat is not running and could not be recovered automatically.
    call :send_notification critical "SSL update left Tomcat stopped" "The update for %CERT% failed. Previous certificate files were restored, but Tomcat service %TOMCAT_SERVICE% could not be started. Manual intervention is required."
) else (
    echo Tomcat is running with the previous certificate files.
    call :send_notification error "SSL certificate update failed" "Tomcat restart failed after updating %CERT%. Previous certificate files were restored and Tomcat service %TOMCAT_SERVICE% is running again."
)
call :cleanup
exit /b 1

:restart_tomcat
call :get_service_state
if errorlevel 1 exit /b 1

if not "%SERVICE_STATE%"=="1" (
    echo Sending the stop request to Tomcat...
    sc.exe stop "%TOMCAT_SERVICE%" >nul

    if errorlevel 1 (
        call :get_service_state
        if errorlevel 1 exit /b 1
        if not "!SERVICE_STATE!"=="1" if not "!SERVICE_STATE!"=="3" exit /b 1
    )

    set "STOP_WAITED_SECONDS=0"
    call :wait_for_stopped
    set "STOP_RESULT=!ERRORLEVEL!"

    if "!STOP_RESULT!"=="2" (
        echo WARNING: Tomcat did not stop within %STOP_TIMEOUT_SECONDS% seconds.
        call :force_kill_tomcat
        if errorlevel 1 exit /b 1

        echo Waiting %FORCE_KILL_WAIT_SECONDS% seconds after forced termination...
        timeout.exe /t %FORCE_KILL_WAIT_SECONDS% /nobreak >nul
    ) else if not "!STOP_RESULT!"=="0" (
        exit /b 1
    )
)

call :start_and_wait
exit /b %ERRORLEVEL%

:start_and_wait
echo Sending the start request to Tomcat...
sc.exe start "%TOMCAT_SERVICE%" >nul

if errorlevel 1 (
    call :get_service_state
    if errorlevel 1 exit /b 1
    if not "!SERVICE_STATE!"=="2" if not "!SERVICE_STATE!"=="4" exit /b 1
)

call :wait_for_running
exit /b %ERRORLEVEL%

:ensure_tomcat_running
call :get_service_state
if errorlevel 1 exit /b 1

if "%SERVICE_STATE%"=="4" exit /b 0

if "%SERVICE_STATE%"=="3" (
    set "STOP_WAITED_SECONDS=0"
    call :wait_for_stopped
    if errorlevel 1 exit /b 1
)

if "%SERVICE_STATE%"=="2" (
    call :wait_for_running
    if not errorlevel 1 exit /b 0
)

call :start_and_wait
exit /b %ERRORLEVEL%

:wait_for_stopped
call :get_service_state
if errorlevel 1 exit /b 1

if "%SERVICE_STATE%"=="1" (
    echo Tomcat is stopped.
    exit /b 0
)

if %STOP_WAITED_SECONDS% GEQ %STOP_TIMEOUT_SECONDS% exit /b 2

echo Waiting for Tomcat to stop. Current service state: %SERVICE_STATE_NAME% ^(%STOP_WAITED_SECONDS%/%STOP_TIMEOUT_SECONDS% seconds^)
timeout.exe /t %SERVICE_POLL_SECONDS% /nobreak >nul
set /a STOP_WAITED_SECONDS+=SERVICE_POLL_SECONDS >nul
goto wait_for_stopped

:wait_for_running
call :get_service_state
if errorlevel 1 exit /b 1

if "%SERVICE_STATE%"=="4" (
    echo Tomcat is running.
    exit /b 0
)

if "%SERVICE_STATE%"=="1" (
    echo ERROR: Tomcat returned to the STOPPED state while starting.
    exit /b 1
)

echo Waiting for Tomcat to start. Current service state: %SERVICE_STATE_NAME%
timeout.exe /t %SERVICE_POLL_SECONDS% /nobreak >nul
goto wait_for_running

:force_kill_tomcat
set "SERVICE_PID="

for /f "tokens=3" %%P in ('sc.exe queryex "%TOMCAT_SERVICE%" ^| findstr /R /C:"PID *:"') do (
    set "SERVICE_PID=%%P"
)

if not defined SERVICE_PID (
    call :get_service_state
    if errorlevel 1 exit /b 1
    if "!SERVICE_STATE!"=="1" exit /b 0
    echo ERROR: Could not determine the Tomcat service process ID.
    exit /b 1
)

if "%SERVICE_PID%"=="0" (
    call :get_service_state
    if errorlevel 1 exit /b 1
    if "!SERVICE_STATE!"=="1" exit /b 0
    echo ERROR: Tomcat does not have a process ID to terminate.
    exit /b 1
)

echo Forcefully terminating Tomcat process %SERVICE_PID%...
taskkill.exe /PID %SERVICE_PID% /T /F >nul

if errorlevel 1 (
    call :get_service_state
    if errorlevel 1 exit /b 1
    if not "!SERVICE_STATE!"=="1" (
        echo ERROR: Could not terminate Tomcat process %SERVICE_PID%.
        exit /b 1
    )
)

exit /b 0

:get_service_state
set "SERVICE_STATE="
set "SERVICE_STATE_NAME="

for /f "tokens=3,4" %%S in ('sc.exe query "%TOMCAT_SERVICE%" ^| findstr /R /C:"STATE *:"') do (
    set "SERVICE_STATE=%%S"
    set "SERVICE_STATE_NAME=%%T"
)

if not defined SERVICE_STATE (
    echo ERROR: Could not read the state of Tomcat service: %TOMCAT_SERVICE%
    exit /b 1
)

exit /b 0

:rollback
if "%INSTALL_STARTED%"=="0" exit /b 0

echo Restoring previous certificate files...

for %%F in (server.crt chain.crt) do (
    set "TARGET=%TARGET_DIR%\%%F"
    set "BACKUP=%BACKUP_DIR%\%%F"
    set "MARKER=%BACKUP_DIR%\%%F.changed"

    if exist "!MARKER!" (
        if exist "!BACKUP!" (
            copy /y "!BACKUP!" "!TARGET!" >nul
        ) else (
            if exist "!TARGET!" del /q "!TARGET!"
        )
    )
)

set "INSTALL_STARTED=0"
exit /b 0

:cleanup
if defined WORK_DIR if exist "%WORK_DIR%" rmdir /s /q "%WORK_DIR%"
exit /b 0

:send_notification
if not exist "%NOTIFY_SCRIPT%" (
    echo ERROR: Discord notifier was not found: %NOTIFY_SCRIPT%
    exit /b 1
)

call "%NOTIFY_SCRIPT%" "%DISCORD_WEBHOOK_FILE%" "%~1" "%~2" "%~3"
if errorlevel 1 (
    echo ERROR: Discord notification could not be sent.
    exit /b 1
)

exit /b 0
