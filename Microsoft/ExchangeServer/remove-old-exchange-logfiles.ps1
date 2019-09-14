<#
.SYNOPSIS
This script deletes old log files from Exchange Servers

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER $TargetFolder
Übergabe des vollständigen Pfads, in dem Protokolldateien liegen

 
.INPUTS
None
 
.OUTPUTS
None
 
.NOTES
File:           remove-old-exchange-logfiles.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  16.03.2019, 12:39 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
16.03.2019, 12:39 Uhr  Initial community release
14.09.2019, 11:44 Uhr  Reworked the script


.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Microsoft/ExchangeServer/remove-old-exchange-logfiles.ps1

.EXAMPLE
.\remove-old-exchange-logfiles.ps1
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


### function ClearLogfiles

# Alter der Dateien, die nicht gelöscht werden sollen ( in Tage)
[int] $intDays = 14

# Verzeichnisse in denen Microsoft Exchange Servern diverse Protokolldateien abgelegt
[string] $strIISLogPath = "C:\inetpub\logs\LogFiles\"
[string] $strExchangeLoggingPath = "C:\Program Files\Microsoft\Exchange Server\V15\Logging\"
[string] $strETLTracesPath = "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
[string] $strLoggingPath = "C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs\"

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

function Exchange-ClearLogfiles {
    Param (
        [Parameter(
            ValueFromPipelineByPropertyName,
            Position=0,
            Mandatory=$true
        )]
        [string] $TargetFolder
    )

    if (Test-Path $TargetFolder) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$intDays)

        Write-Log -LogText "Dateien mit entsprechenden Dateityp werden gesucht..." -LogStatus Info
        $Files = Get-ChildItem $TargetFolder -Recurse | Where-Object {$_.Name -like "*.log" -or $_.Name -like "*.blg" -or $_.Name -like "*.etl"}  | where {$_.lastWriteTime -le "$lastwrite"} | Select-Object FullName  
        
        foreach ($File in $Files) {
            Write-Log -LogText "Die Datei $($File.FullName) wird gelöscht..." -LogStatus Info

            try {
                #Remove-Item $File.FullName | Out-Null
                Write-Log -LogText "Die Datei $($File.FullName) wurde gelöscht." -LogStatus Success
            }
            catch {
                Write-Log -LogText "Die Datei $($File.FullName) konnte nicht gelöscht werden." -LogStatus Error
            }
        }
    }
    else {
        Write-Log -LogText "Das Verzeichnis $TargetFolder existiert nicht!" -LogStatus Error
    }
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

WorkingDir

Exchange-ClearLogfiles -TargetFolder $strIISLogPath
Exchange-ClearLogfiles -TargetFolder $strExchangeLoggingPath
Exchange-ClearLogfiles -TargetFolder $strETLTracesPath
Exchange-ClearLogfiles -TargetFolder $strLoggingPath
