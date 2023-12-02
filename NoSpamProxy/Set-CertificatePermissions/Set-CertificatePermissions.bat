@echo off

rem Aktuelles Verzeichnis des Skripts in Variable schreiben
SET CURRENTDIR="%~dp0"

rem In das Verzeichnis wechseln
cd "%CURRENTDIR%"

rem PowerShell Skript starten
"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -File "Set-CertificatePermissions.ps1"

pause