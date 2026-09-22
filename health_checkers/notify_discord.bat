@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Send a monitoring notification to a Discord channel.
rem
rem Usage:
rem   notify_discord.bat WEBHOOK_FILE LEVEL "TITLE" "MESSAGE"
rem
rem Levels:
rem   info, success, warning, error, critical
rem
rem WEBHOOK_FILE must contain a Discord webhook URL on its first line.

if "%~4"=="" goto :usage

set "DISCORD_WEBHOOK_FILE=%~1"
set "NOTIFY_LEVEL=%~2"
set "NOTIFY_TITLE=%~3"
set "NOTIFY_MESSAGE=%~4"
set "NOTIFY_COLOR="

if /I "%NOTIFY_LEVEL%"=="info"     set "NOTIFY_COLOR=3447003"
if /I "%NOTIFY_LEVEL%"=="success"  set "NOTIFY_COLOR=5763719"
if /I "%NOTIFY_LEVEL%"=="warning"  set "NOTIFY_COLOR=16776960"
if /I "%NOTIFY_LEVEL%"=="error"    set "NOTIFY_COLOR=15548997"
if /I "%NOTIFY_LEVEL%"=="critical" set "NOTIFY_COLOR=10038562"

if not defined NOTIFY_COLOR (
    echo Error: unsupported notification level: %NOTIFY_LEVEL% 1>&2
    goto :usage
)

if not exist "%DISCORD_WEBHOOK_FILE%" (
    echo Error: Discord webhook file was not found: "%DISCORD_WEBHOOK_FILE%" 1>&2
    exit /b 2
)

set "DISCORD_WEBHOOK_URL="
set /p "DISCORD_WEBHOOK_URL="<"%DISCORD_WEBHOOK_FILE%"

if not defined DISCORD_WEBHOOK_URL (
    echo Error: no Discord webhook URL is configured. 1>&2
    exit /b 2
)

set "NOTIFY_HOST=%COMPUTERNAME%"
set "NOTIFY_TEMP_JSON=%TEMP%\notify-discord-%RANDOM%-%RANDOM%.json"

rem PowerShell safely creates the JSON, including quotes and line breaks in the
rem message. curl.exe performs the actual request so this works like the Linux
rem version and is compatible with older Windows PowerShell releases.
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$url = $env:DISCORD_WEBHOOK_URL;" ^
  "if (-not ($url.StartsWith('https://discord.com/api/webhooks/') -or $url.StartsWith('https://discordapp.com/api/webhooks/'))) { [Console]::Error.WriteLine('Error: the configured value is not a valid Discord webhook URL.'); exit 2 };" ^
  "$title = $env:NOTIFY_TITLE; if ($title.Length -gt 256) { $title = $title.Substring(0, 253) + '...' };" ^
  "$message = $env:NOTIFY_MESSAGE; if ($message.Length -gt 4096) { $message = $message.Substring(0, 4093) + '...' };" ^
  "$payload = @{ username = 'Server Monitor'; embeds = @(@{ title = $title; description = $message; color = [int]$env:NOTIFY_COLOR; fields = @(@{ name = 'Severity'; value = $env:NOTIFY_LEVEL.ToUpperInvariant(); inline = $true }, @{ name = 'Host'; value = $env:NOTIFY_HOST; inline = $true }); timestamp = [DateTime]::UtcNow.ToString('o') }) };" ^
  "$json = $payload | ConvertTo-Json -Depth 6 -Compress;" ^
  "[System.IO.File]::WriteAllText($env:NOTIFY_TEMP_JSON, $json, (New-Object System.Text.UTF8Encoding($false)))"

if errorlevel 1 (
    if exist "%NOTIFY_TEMP_JSON%" del /q "%NOTIFY_TEMP_JSON%" >nul 2>&1
    echo Error: Discord notification data could not be prepared. 1>&2
    exit /b 2
)

curl.exe --fail --silent --show-error --connect-timeout 10 --max-time 30 --retry 3 --retry-delay 2 --header "Content-Type: application/json" --request POST --data-binary "@%NOTIFY_TEMP_JSON%" "%DISCORD_WEBHOOK_URL%"
set "NOTIFY_RESULT=%ERRORLEVEL%"

del /q "%NOTIFY_TEMP_JSON%" >nul 2>&1

if not "%NOTIFY_RESULT%"=="0" (
    echo Error: Discord notification could not be delivered. 1>&2
    exit /b %NOTIFY_RESULT%
)

echo Discord notification delivered successfully.
exit /b 0

:usage
echo Usage: %~nx0 WEBHOOK_FILE LEVEL "TITLE" "MESSAGE" 1>&2
echo Levels: info, success, warning, error, critical 1>&2
exit /b 2
