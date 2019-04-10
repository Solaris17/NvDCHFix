@echo off
SET build=.2
title Nvidia DCH fixer v%BUILD%

:checkPrivileges
:: Check for Admin by accessing protected stuff. This calls net(#).exe and can stall if we don't kill it later.
NET FILE 1>nul 2>&1 2>nul 2>&1
if '%errorlevel%' == '0' ( goto start) else ( goto getPrivileges ) 

:getPrivileges
:: Write vbs in temp to call batch as admin.
if '%1'=='ELEV' (shift & goto start)                               
for /f "delims=: tokens=*" %%A in ('findstr /b ::- "%~f0"') do @Echo(%%A
setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
Echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs" 
Echo UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs" 
"%temp%\OEgetPrivileges.vbs" 
exit /B

:start
cls
Echo.
Echo TPU Nvidia DCH driver fix https://bit.ly/2EnMLWo
Echo.
Echo Written by: Solaris17 (TPU)
Echo.
Echo If you do not want to auto clean exit the script now.
Echo.
pause
Echo.
cls
Echo.
Echo Going to see if the registry key exists...
:: Find out of the entry exists.
REG Query HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm /V "DCHUVen" /S >nul 2>&1
IF NOT ERRORLEVEL 1 goto oeminf
IF ERRORLEVEL 1 goto notfound


:: find the infname
:oeminf
Echo.
Echo I found the registry entry, deleting value.
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /V DCHUVen /f >nul 2>&1
Echo Lets get the .inf name.
powershell -Command "gwmi Win32_PnPSignedDriver | ? DeviceClass -eq "Display" | Select Infname"
Echo Enter the inf name exactly as shown. IE: oem19.inf
Echo.
SET /P infname=""
Echo.
Echo Deleting the inf. The display(s) may go blank and flicker.
Echo.
pnputil /delete-driver %infname% /uninstall >nul 2>&1
Echo inf deleted.
Echo.

:: delete the service.
Echo Please wait, now deleting the service. The display(s) may go blank and flicker.
timeout 30 >nul 2>&1
sc delete nvlddmkm >nul 2>&1
Echo.
Echo Service deleted.
goto end


:notfound
Echo I didn't find, it you should be good.
goto end

:end
Echo.
Echo All done!
Echo.
Echo You should be able to install normally. If driver install fails reboot.
Echo.
pause
exit