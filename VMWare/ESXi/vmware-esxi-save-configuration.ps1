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
21.07.2019, 13:24 Uhr  Replace function write-log with new version

.COMPONENT
VMWare PowerCLI must be installed
  
.LINK
https://blog.wydler.eu/ 
   
.EXAMPLE
.\vmware-esxi-save-configuration.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileName = ("Log_" + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName

[array] $aVMWareVcenterHost = @("server01", "server02")
[string] $strVMWareVcenterProtocol = "https"

[string] $strVmWareBackupPath = "\\fqdn\sicherungen\vmware-esxi"
[string] $strVmWareBackupFolder = Get-Date -Format yyyy-MM-dd_HH-mm-ss

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $LogText = "",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Info','Success','Warning','Error')]
        [string] $LogStatus= "Info",

        [Parameter(Mandatory=$false)]
        [switch] $Absatz,

        [Parameter(Mandatory=$false)]
        [switch] $EventLog
    )

	[string] $strLogdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    [string] $strTextColor = "White"
    [string] $strLogFileAbsatz = ""
    [string] $strLogFileHeader = ""

    # Add a header to logfile, if the logfile not exist
    If ( -not (Test-Path $strLogfile) ) {
        $strLogFileHeader = "$("#" * 75)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Skript:", "$($MyInvocation.ScriptName)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Ausführendes Konto:", "$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Computername:", "$env:COMPUTERNAME`n"
        $strLogFileHeader += "$("#" * 75)`n"

        Write-Host $strLogFileHeader
        Add-Content -Path $strLogfile -Value $strLogFileHeader -Encoding UTF8
    }
   

    switch($LogStatus) {
        Info {
            $strTextColor = "White"
        }
        Success {
            $strTextColor = "Green"
        }
        Warning {
            $strTextColor = "Yellow"
        }
        Error {
            $strTextColor = "Red"
        }
    }

    # Add an Absatz if the parameter is True
    if($Absatz) {
        [string] $strLogFileAbsatz = "`r`n"
    }

    #Format the text output
    $LogText = "{0,-20} - {1,-7} - {2,0}" -f "$strLogdate", "$LogStatus", "$LogText $strLogFileAbsatz"

    # Write output to powershell console
    Write-Host $LogText -ForegroundColor $strTextColor

    # Write output to logfile
    Add-Content -Path $strLogfile -Value $LogText -Encoding UTF8

    # Add Logfile to local Eventlog of the operating system 
    if($EventLog) {
        Write-EventLog -LogName 'Windows PowerShell' -Source "Powershell" -EventId 0 -Category 0 -EntryType $LogStatus -Message $LogText
    }

}

#-------------------------------------------------------------[Modules]------------------------------------------------------------

Write-Log -LogText "VMWare PowerCLI wird eingebunden..." -LogStatus Info
try {
    . "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
    Write-Log -LogText "VMWare PowerCLI erfolgreich einbebunden." -LogStatus Success -Absatz
}
catch {
    Write-Log -LogText "VMWare PowerCLI  konnte nicht eingebunden werden." -LogStatus Error
    exit
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder wird angelegt..." -LogStatus Info

try {
    New-Item "$strVmWareBackupPath\$strVmWareBackupFolder" -ItemType directory
    Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder wurde erstellt." -LogStatus Success -Absatz
}
catch {
    Write-Log -LogText "Das Verzeichnis $strVmWareBackupPath\$strVmWareBackupFolder konnte nicht erstellt werden. " -LogStatus Error
    exit
}


foreach ($strVMWareVcenterHost in $aVmWareVcenterHost) {
    
    Write-Log -LogText "Verbindung zum vCenter $strVMWareVcenterHost wird aufgebaut" -LogStatus Info
    try {
        Connect-VIServer -Server $strVMWareVcenterHost -Protocol $strVMWareVcenterProtocol
        Write-Log -LogText "Die Verbindung zum vCenter $strVMWareVcenterHost ist aufgebaut." -LogStatus Success -Absatz
    }
    catch {
        Write-Log -LogText "Die Verbindungaufbau zum vCenter strVMWareVcenterHost ist fehlgeschlagen. " -LogStatus Error
        Remove-Item "$strVmWareBackupPath\$strVmWareBackupFolder" -Recurse -Force -Confirm:$false
        exit
    }


    Write-Log -LogText "Alle ESXi-Server im vCenter Server auslesen" -LogStatus Info
    Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath "$strVmWareBackupPath\$strVmWareBackupFolder"


    Write-Log -LogText "Verbindung zum vCenter $strVMWareVcenterHost wird beendet" -LogStatus Info -Absatz
    Disconnect-VIServer -Server $strVMWareVcenterHost -Confirm:$false
}

Write-Log -LogText "Das Skript wurde beendet." -LogStatus Success
