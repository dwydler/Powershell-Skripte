<#
.SYNOPSIS
Dieses Skript kopiert (1:1) die Mitgliedschaften zwischen zwei Gruppen

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER $SourceGroup
Name der Gruppe, welche die Quelle für den Kopiervorgang ist.

.PARAMETER $TargetGroup
Name der Gruppe, welche das Ziel ist.

 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           copy-members-of-group-to-group.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  10.03.2019, 12:45 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 12:45 Uhr  Initial community release
14.09.2019, 15:43 Uhr  Reworked the script


.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/ActiveDirectory/copy-members-of-group-to-group.ps1

.EXAMPLE
.\copy-members-of-group-to-group.ps1
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$true
    )]
   [string] $SourceGroup,

   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=1,
        Mandatory=$true
    )]
   [string] $TargetGroup
)


Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log

[string] $strLogfilePath = "C:\Temp"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName

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

function LoadModule {
    Param (
        [Parameter(
            mandatory=$True,
            Position=0
        )]
        [string] $ModuleName
    )

    if (Get-Module -ListAvailable -Name $ModuleName ) {
    Write-Log -LogText "Das Modul '$ModuleName' existiert." -LogStatus Info

        if (Get-module $ModuleName) {
            Write-Log -LogText "Das Modul '$ModuleName' ist bereits geladen." -LogStatus Info -Absatz
        }
        else {
            Write-Log -LogText "Das Modul '$ModuleName' wurde eingebunden." -LogStatus Success -Absatz
            Import-Module $ModuleName
        }
    } 
    else {
        Write-Log -LogText "Das Modul '$ModuleName' existiert nicht!" -LogStatus Error
        exit
    }
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

LoadModule -ModuleName "ActiveDirectory"

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Check if source group exist
Write-Log "Überprüfe, ob die Gruppe '$SourceGroup' im Active Directory exstiert." -LogStatus Info
try {
    Get-ADGroup -Identity $SourceGroup | Out-Null
    Write-Log -LogText "Die Gruppe '$SourceGroup' wurde gefunden." -LogStatus Success
}
catch {
    Write-Log -LogText "Die Gruppe '$SourceGroup' wurde nicht gefunden!" -LogStatus Error
    exit
}

# Check if target group exist
Write-Log "Überprüfe, ob die Gruppe '$TargetGroup' im Active Directory exstiert." -LogStatus Info
try {
    Get-ADGroup -Identity $TargetGroup | Out-Null
    Write-Log -LogText "Die Gruppe '$TargetGroup' wurde gefunden." -LogStatus Success
}
catch {
    Write-Log -LogText "Die Gruppe '$TargetGroup' wurde nicht gefunden!" -LogStatus Error
    exit
}

Write-Log -LogText "Überprüfe ob Quell- und Zielgruppe identisch sind." -LogStatus Info
if ($SourceGroup -eq $TargetGroup) {
    Write-Log -LogText "Quell- und Zielgruppe ist identisch!" -LogStatus Error
    exit
}

Write-Log -LogText "Kopiere die Gruppenmitgliedschaften." -LogStatus Info
try {
    Get-ADGroupMember $SourceGroup | Select SAMAccountName | ForEach {
        Add-ADGroupMember $TargetGroup -Members $_.SAMAccountName
        Write-Log -LogText "Der Benutzer '$($_.SAMAccountName)' wurde hinzugefügt" -LogStatus Success

    }
    Write-Log -LogText "Kopieren der Gruppenmitgliedschaften abgeschlossen." -LogStatus Success
}
catch {
    Write-Log -LogText "Beim Kopieren der Mitgliedschaften ist ein Fehler aufgetreten!" -LogStatus Error
    exit
}
