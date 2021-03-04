<#
.SYNOPSIS
Dieses Skript kann alle aktiven Benutzern eine Nachricht schicken bzw. abmelden

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER Message
An alle angemeldeten Benutzer wird eine Nachricht verschickt.

.PARAMETER Logoff
Alle angemeldete Benutzer werden auf dem Server abgemeldet.

 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           windows-server_rds-role_logoff-all-connected-users.ps1
Version:        1.2
Author:         Daniel Wydler
Creation Date:  10.03.2019, 12:45 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 12:45 Uhr  Initial community release
15.09.2019, 15:43 Uhr  Code base revised
04.02.2021, 21:09 Uhr  Fixed query problem with getrennte sessions

.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/WindowsServer/windows-server_rds-role_logoff-all-connected-users.ps1

.EXAMPLE
.\windows-server_rds-role_logoff-all-connected-users.ps1
.\windows-server_rds-role_logoff-all-connected-users.ps1 -Message
.\windows-server_rds-role_logoff-all-connected-users.ps1 -Logoff
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$false
    )]
   [Switch] $Message,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$false
    )]
   [switch] $Logoff
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log
[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


###
[string] $strMessageText = "Wartungsarbeiten beginnen in 5 Minuten.`nBitte melden Sie sich rechtzeitig ab. Vielen Dank."

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

if( ($Message -eq $false) -and ($Logoff -eq $false) ) {
    Write-Log -LogText "Das Skript wurde ohne Parameter aufgerufen. Keine Interaktion!" -LogStatus Warning -Absatz
}

Write-Log -LogText "Abfrage der Sitzungen auf dem Server." -LogStatus Info
$queryResults = qwinsta.exe | foreach { ($_.trim() -replace "\s+",",") } | ConvertFrom-Csv

ForEach($QueryResult in $QueryResults) {

    If( ($QueryResult.SITZUNGSNAME -ne "services") -and ($QueryResult.SITZUNGSNAME -ne "console") -and ($QueryResult.SITZUNGSNAME -ne "rdp-tcp") -and ($QueryResult.BENUTZERNAME -ne $env:USERNAME) ) {

        Write-Log -LogText "Benutzer: $($QueryResult.BENUTZERNAME), ID: $($QueryResult.ID), Status: $($QueryResult.STATUS) gefunden." -LogStatus Info

        if ($Message) {
            Write-Log -LogText "Nachricht an $($QueryResult.BENUTZERNAME) geschickt." -LogStatus Success
            msg.exe $QueryResult.BENUTZERNAME $strMessageText
        }

        if ($Logoff) {
            Write-Log -LogText "$($QueryResult.BENUTZERNAME) wurde abgemeldet." -LogStatus Success
            
            if($QueryResult.ID -eq "Getr.") {
                logoff.exe $QueryResult.BENUTZERNAME
            }
            else {
                logoff.exe $QueryResult.ID
            }
        }
    }
}

Write-Log -LogText "Vorgang erfolgreich angeschlossen." -LogStatus Info
