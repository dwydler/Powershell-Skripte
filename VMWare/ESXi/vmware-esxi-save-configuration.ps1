<#
.SYNOPSIS
Backup configuration of ESXi Host 
.DESCRIPTION
Connect to one or more vCenter Server and list all connected ESXi Host to backup the configuration to a cifs share
.PARAMETER <Parameter_Name>
<Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
None
.OUTPUTS
Status Text on Console of the different steps; Generate a Logfile of all steps.
.NOTES
File:           vmware-esxi-save-configuration.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  20.07.2019, 22:31 Uhr
Purpose/Change:

Date                   Comment
-----------------------------------------------
01.07.2019, 10:00 Uhr  Initial the script
09.07.2019, 08:40 Uhr  Added section for each topic
20.07.2019, 20:00 Uhr  Added various sections for new structure in the script
20.07.2019, 21:15 Uhr  Added function for console and log output
20.07.2018, 22:00 Uhr  Added try/catch to important commands
20.07.2019, 22:34 Uhr  Added the new debug flag SUCCESS to function
   
.COMPONENT
VMWare PowerCLI must be installed
  
.LINK
https://blog.wydler.eu/ 
   
.EXAMPLE
.\vmware-esxi-save-configuration.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
Clear-Host

#Arbeitsverzeichnis
cd "C:\Temp"


#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm"
[string] $strLogfileName = ("Log_" + $strLogfileDate + "_"+ $env:USERDOMAIN + "_" + $env:USERNAME + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName

[array] $aVMWareVcenterHost = @("")
[string] $strVMWareVcenterProtocol = "https"

[string] $strVmWareBackupPath = "\\fqdn\sicherungen\vmware-esxi"
[string] $strVmWareBackupFolder = Get-Date -Format yyyy-MM-dd_HH-mm-ss

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $LogText = "",

        [Parameter(Mandatory=$true)]
        [ValidateRange(0,3)]
        [int] $LogLevel=0
    )

	[string] $strLogdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    [array] $aDebugLevel = @("INFO   ", "WARNING", "ERROR  ", "SUCCESS")
    [array] $aDebugTextColor = @("White", "Yellow", "Red", "Green")

    $LogText = "$strLogdate - $($aDebugLevel[$LogLevel]) - $LogText"

    Write-Host $LogText -ForegroundColor $aDebugTextColor[$LogLevel]
    "$LogText" | Out-File -FilePath $strLogfile -Append

}

#-------------------------------------------------------------[Modules]------------------------------------------------------------

Write-Log -LogText "VMWare PowerCLI wird eingebunden..." -LogLevel 0
try {
    & 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1'
    Write-Log -LogText "VMWare PowerCLI erfolgreich einbebunden." -LogLevel 3
    Write-Log -LogText " " -LogLevel 0
}
catch {
    Write-Log -LogText "VMWare PowerCLI  konnte nicht eingebunden werden." -LogLevel 2
    exit
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder wird angelegt..." -LogLevel 0

try {
    New-Item "$strVmWareBackupPath\$strVmWareBackupFolder" -ItemType directory
    Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder wurde erstellt." -LogLevel 3
    Write-Log -LogText " " -LogLevel 0
}
catch {
    Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder konnte nicht erstellt werden. " -LogLevel 2
    exit
}


foreach ($strVMWareVcenterHost in $aVmWareVcenterHost) {
    
    Write-Log -LogText "Verbindung zum vCenter $strVMWareVcenterHost wird aufgebaut" -LogLevel 0
    try {
        Connect-VIServer -Server $strVMWareVcenterHost -Protocol $strVMWareVcenterProtocol
        Write-Log -LogText "Die Verbindung zum vCenter $strVMWareVcenterHost ist aufgebaut." -LogLevel 3
        Write-Log -LogText " " -LogLevel 0
    }
    catch {
        Write-Log -LogText "Die Verbindungaufbau zum vCenter strVMWareVcenterHost ist fehlgeschlagen. " -LogLevel 2
        Remove-Item "$strVmWareBackupPath\$strVmWareBackupFolder" -Recurse -Force -Confirm:$false
        exit
    }


    Write-Log -LogText "Alle ESXi-Server im vCenter Server auslesen" -LogLevel 0
    Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath "$strVmWareBackupPath\$strVmWareBackupFolder"


    Write-Log -LogText "Verbindung zum vCenter $strVMWareVcenterHost wird beendet" -LogLevel 0
    Disconnect-VIServer -Server $strVMWareVcenterHost -Confirm:$false
    Write-Log -LogText " " -LogLevel 0
}

Write-Log -LogText "Das Skript wurde beendet." -LogLevel 3
