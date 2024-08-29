@echo off
CLS

ECHO =============================
ECHO Running Fix and Clean
ECHO =============================
ECHO FNC v3
ECHO Big Changes, this version has a full menu system, debloat and much more


:init
setlocal DisableDelayedExpansion
set cmdInvoke=1
set winSysFolder=System32
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (goto gotPrivileges) else (goto getPrivileges)

:getPrivileges
if '%1'=='ELEV' (shift & goto gotPrivileges)

ECHO.
ECHO **************************************
ECHO Invoking UAC for Privilege Escalation
ECHO **************************************

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"

if '%cmdInvoke%'=='1' goto InvokeCmd 

ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
goto ExecElevation

:InvokeCmd
ECHO args = "/c ""!batchPath!"" " + args >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
"%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul & shift)

:Menu
Set RunAll=0
CLS
ECHO =============================
ECHO Fix and Clean
ECHO             _
ECHO            / / 
ECHO           /  \_/\
ECHO           \   _ /
ECHO           /  /
ECHO          /  /
ECHO         /  /
ECHO        /  /
ECHO       (__/
ECHO =============================
ECHO 1. Run All
ECHO 2. Create Restore Point
ECHO 3. Check Windows Image Health
ECHO 4. Scan System Files
ECHO 5. Windows Update
ECHO 6. Reset Windows Network Services
ECHO 7. Cleanup (Temp Files, Recycle Bin, Download Folder)
ECHO 8. Run Windows Defender
ECHO 9. Check Disk
ECHO 10. Defragment All Hard Drives
ECHO 11. Set Windows Power Settings
ECHO 12. Refresh Windows Store
ECHO 13. Update winget Software
ECHO 14. Force Windows Update
ECHO 15. Force Windows Store to Update All
ECHO 16. Debloat apps
ECHO 17. Exit
SET /P choice=Choose an option (1-16): 

REM Process the user's choice
IF %choice%==1 goto RunAll
IF %choice%==2 goto RestorePoint
IF %choice%==3 goto DISM
IF %choice%==4 goto SFC
IF %choice%==5 goto ResetWindowsUpdate
IF %choice%==6 goto NetworkServicesReset
IF %choice%==7 goto CleanUp
IF %choice%==8 goto Defender
IF %choice%==9 goto CheckDisk
IF %choice%==10 goto Defragmentation
IF %choice%==11 goto Power
IF %choice%==12 goto store
IF %choice%==13 goto winget
IF %choice%==14 goto WindowsUpdate
IF %choice%==15 goto WindowsStoreUpdate
IF %choice%==16 goto Debloat
IF %choice%==17 goto End

:RunAll
ECHO Running all tasks sequentially...
set RunAll=1
goto RestorePoint

:RestorePoint
ECHO =============================
ECHO Creating Restore Point
ECHO =============================
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "MyRestorePoint", 100, 7
ECHO Restore point done!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto DISM

:DISM
ECHO =============================
ECHO Checking Windows Image Health
ECHO =============================
dism.exe /online /cleanup-image /scanhealth
dism.exe /online /cleanup-image /restorehealth
dism.exe /online /cleanup-image /startcomponentcleanup
ECHO Windows Health check run!
IF %RunAll%==0 goto Menu
goto SFC

:SFC
ECHO =============================
ECHO Scanning System Files
ECHO =============================

SFC /scannow

ECHO System files scanned!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto ResetWindowsUpdate

:ResetWindowsUpdate
ECHO =============================
ECHO Resetting Windows Update Services
ECHO =============================
net stop wuauserv
net start wuauserv
ECHO Windows update service reset!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto NetworkServicesReset

:NetworkServicesReset
ECHO =============================
ECHO Resetting Windows Network Services
ECHO =============================
net stop bits
UsoClient ScanInstallWait
net stop wuauserv
net stop cryptsvc
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ren %systemroot%\softwaredistribution softwaredistribution.bak
ren %systemroot%\system32\catroot2 catroot2.bak
net start bits
net start wuauserv
net start cryptsvc
ECHO Network services reset!
IF %RunAll%==0 goto Menu
goto CleanUp

:CleanUp
ECHO =============================
ECHO Cleaning up (Temp Files, Recycle Bin, Download Folder)
ECHO =============================
ECHO Are you sure you want to perform cleanup?
ECHO This will permanently delete files from:
ECHO 	Downloads
ECHO 	Temp Files
ECHO 	Chrome Cache
ECHO 	Trash
SET /P cleanupChoice=(y/n): 
if /i "%cleanupChoice%"=="y" (
    cleanmgr.exe /AUTOCLEAN /verylowdisk
    del /q /s %SystemRoot%\Temp\*
    del /q /s %SystemRoot%\SoftwareDistribution\Download\*
    del /q /s %USERPROFILE%\Downloads\*
    del /q /s %USERPROFILE%\AppData\Local\Google\Chrome\User Data\default\cache\*
    del /q /s %USERPROFILE%\AppData\Local\Temp\*
    del /q /s %USERPROFILE%\AppData\Local\Microsoft\Windows\INetCache\*
    del /q /s %USERPROFILE%\AppData\Local\Microsoft\Windows\Temporary Internet Files\*
    del /q /s %USERPROFILE%\.Trash\*
    ECHO Cleanup complete!
) else (
    ECHO Cleanup canceled!
)
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto Defender

:Defender
ECHO =============================
ECHO Running Windows Defender
ECHO =============================

"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -1

ECHO Windows Defender has been run!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto CheckDisk

:CheckDisk
ECHO =============================
ECHO Checking Disk
ECHO =============================

chkdsk /scan /perf

ECHO CheckDisk run!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto Defragmentation

:Defragmentation
ECHO =============================
ECHO Defragmenting All Hard Drives
ECHO =============================

defrag /c /o /u

ECHO Defragmentation complete!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto Power

:Power
ECHO =============================
ECHO Setting Windows Power Settings
ECHO =============================
ECHO 1. Balanced Power
ECHO 2. Ultimate Performance
SET /P powerChoice=Choose a power setting (1-2): 
IF %powerChoice%==1 (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
) ELSE (
    powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61
)
ECHO Power settings applied!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto store

:store
ECHO =============================
ECHO Refresh Windows Store
ECHO =============================

wsreset

ECHO Windows Store refreshed!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto winget

:winget
ECHO =============================
ECHO Update winget software
ECHO =============================

winget upgrade --all

ECHO winget software updated!
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto ForceWindowsUpdate

:ForceWindowsUpdate
ECHO =============================
ECHO Windows Update
ECHO =============================

net stop wuauserv
net start wuauserv
UsoClient StartScan
UsoClient StartDownload
UsoClient StartInstall

ECHO
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto End

:End

:DeBloat
ECHO =============================
ECHO remove Bloatware
ECHO =============================

: Xbox Applications
winget uninstall Microsoft.GamingApp_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.XboxApp_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.Xbox.TCUI_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.XboxIdentityProvider_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.XboxGamingOverlay_8wekyb3d8bbwe --accept-source-agreements --silent
winget uninstall Microsoft.XboxGameOverlay_8wekyb3d8bbwe --accept-source-agreements --silent

: Groove Music
winget uninstall Microsoft.ZuneMusic_8wekyb3d8bbwe --accept-source-agreements --silent

: Feedback Hub
winget uninstall Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe --accept-source-agreements --silent

: Microsoft-Tips...
winget uninstall Microsoft.Getstarted_8wekyb3d8bbwe --accept-source-agreements --silent

: 3D Viewer
winget uninstall 9NBLGGH42THS --accept-source-agreements --silent

: MS Solitaire
winget uninstall Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe --accept-source-agreements --silent

: Paint-3D...
winget uninstall 9NBLGGH5FV99 --accept-source-agreements --silent

: Weather 
winget uninstall Microsoft.BingWeather_8wekyb3d8bbwe --accept-source-agreements --silent

: People
winget uninstall Microsoft.People_8wekyb3d8bbwe --accept-source-agreements --silent

: MS Pay 
winget uninstall Microsoft.Wallet_8wekyb3d8bbwe --accept-source-agreements --silent

: MS Maps
winget uninstall Microsoft.WindowsMaps_8wekyb3d8bbwe --accept-source-agreements --silent

: Voice Recorder
winget uninstall Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe --accept-source-agreements --silent

: Movies & TV
winget uninstall Microsoft.ZuneVideo_8wekyb3d8bbwe --accept-source-agreements --silent

: Mixed Reality-Portal
winget uninstall Microsoft.MixedReality.Portal_8wekyb3d8bbwe --accept-source-agreements --silent

: Sticky Notes...
winget uninstall Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe --accept-source-agreements --silent

: Get Help
winget uninstall Microsoft.GetHelp_8wekyb3d8bbwe --accept-source-agreements --silent


: Windows 11 Bloatware

: Microsoft TO Do
winget uninstall Microsoft.Todos_8wekyb3d8bbwe --accept-source-agreements --silent
: Power Automate
winget uninstall Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe --accept-source-agreements --silent
: Bing News
winget uninstall Microsoft.BingNews_8wekyb3d8bbwe --accept-source-agreements --silent
: Microsoft Family
winget uninstall MicrosoftCorporationII.MicrosoftFamily_8wekyb3d8bbwe --accept-source-agreements --silent
: Quick Assist
winget uninstall MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe --accept-source-agreements --silent
: Third-Party Preinstalled bloat
winget uninstall disney+ --accept-source-agreements --silent
winget uninstall Clipchamp.Clipchamp_yxz26nhyzhsrt --accept-source-agreements --silent


ECHO
IF %RunAll%==0 goto Menu
IF %RunAll%==1 goto End


ECHO System scan complete, please close this window and reboot.
pause
exit
