<#
.SYNOPSIS
This script reads AnyDesk IDs from all users in to a file

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER

 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           list-anydesk-id-rds-host.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  16.03.2019, 12:39 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 12:51 Uhr  Initial community release
14.09.2019, 12:26 Uhr  Reworked the script
14.09.2019, 12:35 Uhr  Adjustments for anydesk 5


.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/WindowsServer/list-anydesk-id-rds-host.ps1

.EXAMPLE
.\list-anydesk-id-rds-host.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log
[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


### Anydesk
[string] $strAnyDeskIdsFilePath = "C:\Temp"
[string] $strAnyDeskIdsFilename = $("$strAnyDeskIdsFilePath\Uebersicht AnyDeskIDs.txt")
[string] $strAnyDeskConf = "AppData\Roaming\AnyDesk\system.conf"
[string] $strAnyDeskIdFileInput = ""
[string] $strAnyDeskId = ""


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WorkingDir {
    param (
         [parameter(
            Mandatory=$false,
            Position=0
          )]
        [switch] $Debugging
    )

    # Splittet aus dem vollständigen Dateipfad den Verzeichnispfad heraus
    # Beispiel: D:\Daniel\Temp\Unbenannt2.ps1 -> D:\Daniel\Temp
    [string] $strWorkingdir = Split-Path $MyInvocation.PSCommandPath -Parent

    # Wenn Variable wahr ist, gebe Text aus.
    if ($Debugging) {
        Write-Host "[DEBUG] PS $strWorkingdir`>" -ForegroundColor Gray
    }

    # In das Verzeichnis wechseln
    cd $strWorkingdir
}

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

    if ( -not (Test-Path $strLogfilePath) ) {
        Write-Host "Der angegebene Pfad $strLogfilePath existiert nicht!" -ForegroundColor Red
        exit
    }

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

#------------------------------------------------------------[Modules]-------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log -LogText "Wechsele das Arbeitsverzeichnis..." -LogStatus Info
WorkingDir

$strAnyDeskIdFileInput = "{0,-25} {1,9}" -f "Benutzername"," AnyDeskID`n"
$strAnyDeskIdFileInput += "-------------------------------------`n"


Write-Log -LogText "Auslesen der Benutzerprofile..." -LogStatus Info
Get-ChildItem "$env:systemdrive\Users" | Select Name, FullName | foreach {

    Write-Log -LogText $_.FullName -LogStatus Info

    if( Test-Path ($_.FullName + "\" + $strAnyDeskConf) ) {
        Write-Log -LogText "`tAnyDesk Konfiguration gefunden." -LogStatus Info

        Write-Log -LogText "`tAnyDesk ID ausgelesen." -LogStatus Info
        $strAnyDeskId = (Get-Content $($_.FullName + "\" + $strAnyDeskConf) | Select-String -Pattern "ad.anynet.id").ToString().Trim() -replace "ad.anynet.id="
        $strAnyDeskIdFileInput += "{0,-25}  {1,9}" -f $_.Name,$strAnyDeskId + "`n"
    }

}

Write-Log -LogText "Schreibe AnyDesk IDs in die Datei." -LogStatus Info
Set-Content -Path $strAnyDeskIdsFilename -Value $strAnyDeskIdFileInput -Encoding UTF8
