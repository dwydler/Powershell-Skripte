<#
.SYNOPSIS
Dieses Skript ruft die Garantieinformationen eines Geräts vom Hersteller Fujitsu ab

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER SerialNumber
Angabe der Seriennummer des Geräts, welches abgefragt werden soll

 
.INPUTS
Die Seriennummer des Geräts
 
.OUTPUTS
Ausgabe der Garantieinformationen des Geräts
 
.NOTES
File:           fujtisu-support_check-warranty-status
Version:        0.4
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:32 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 10:32 Uhr  Initial community release
10.03.2019, 10:34 Uhr  Fujtisu change the query function
10.03.2019, 10:35 Uhr  remove serial from demo pc
15.09.2019, 15:35 Uhr  Fujtisu change the query function


.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Fujitsu/fujtisu-support_check-warranty-status.ps1

.EXAMPLE
.\fujtisu-support_check-warranty-status -SerialNumber "YLLC001597"
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

param(
    [Parameter(
        Position=0,
        Mandatory=$true
    )] 
    [ValidateNotNullOrEmpty()]
    [string] $SerialNumber = ""
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

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WorkingDir {
    param (
         [parameter(
            Mandatory=$false,
            Position=0
          )]
        [switch] $Debugging
    )

    # Splittet aus dem vollstÃ¤ndigen Dateipfad den Verzeichnispfad heraus
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

Function ValidSerialNumber ([string] $strLocSerialNumber) {
    
    if($strLocSerialNumber -match "^[a-zA-Z]{2}[\da-zA-Z][a-zA-Z]\d{6}$") {
        return $true
    }
    else {
        return $false

    }
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        Fujitsu Garantie / Service Status ueberpruefen
                                                        Version: 0.4

------------------------------------------------------------------------------------------------------------------------
"@

Write-Log -LogText "Überprüfen des Muster/Länger der Seriennummer." -LogStatus Info
if (ValidSerialNumber $SerialNumber ) {
    Write-Log -LogText "Gültige Seriennummer '$SerialNumber' erkannt." -LogStatus Success -Absatz
}
else {
    Write-Log -LogText "Die Seriennummer '$SerialNumber' ist ungültig!" -LogStatus Error
    exit
}


Write-Log -LogText "Abfrage der Daten des Geräts bei Fujitsu." -LogStatus Info -Absatz
$wroSearchHtml= Invoke-WebRequest "https://support.ts.fujitsu.com/Adler/Default.aspx?Lng=de&GotoDiv=Warranty/WarrantyStatus&DivID=indexwarranty&GotoUrl=IndexWarranty&Ident=$SerialNumber"

#$wroSearchHtml.InputFields | Where-Object { ($_.name -like "*") } | Select-Object Name, Value
[array] $arrFujitsuDeviceWarrentyInfos = $wroSearchHtml.InputFields | Where-Object { ($_.name -eq "Ident") -or ($_.name -eq "Produkt") -or ($_.name -eq "Firstuse") -or ($_.name -eq "WarrantyEndDate")  -or ($_.name -eq "WCode") `
      -or ($_.name -eq "WCodeDesc") -or ($_.name -eq "PartNumber") -or ($_.name -eq "WGR") -or ($_.name -eq "SOG") } | Select-Object Name, Value
 
Write-Log -LogText "Produktname:`t`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[1].value)" -LogStatus Info 
Write-Log -LogText "Bestellnummer:`t`t`t$($arrFujitsuDeviceWarrentyInfos[8].value)" -LogStatus Info
Write-Log -LogText "Garantie Gruppe:`t`t$($arrFujitsuDeviceWarrentyInfos[6].value)" -LogStatus Info
Write-Log -LogText "Service Offer Gruppe:`t$($arrFujitsuDeviceWarrentyInfos[7].value)" -LogStatus Info
Write-Log -LogText "Service Code:`t`t`t$($arrFujitsuDeviceWarrentyInfos[2].value)" -LogStatus Info
Write-Log -LogText "Service Start:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[3].value -Format "dd.MM.yyyy")" -LogStatus Info

if( (Get-Date $arrFujitsuDeviceWarrentyInfos[4].value) -gt (Get-Date)) {
    Write-Log -LogText "Service Ende:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[4].value -Format "dd.MM.yyyy")" -LogStatus Success
    Write-Log -LogText "Service Status:`t`tDas Produkt ist unter Service." -LogStatus Success
}
else {
    Write-Log -LogText "Service Ende:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[4].value -Format "dd.MM.yyyy")" -LogStatus Error
    Write-Log -LogText "Service Status:`t`tDas Produkt hat keinen Service mehr!" -LogStatus Error
}
Write-Log -LogText "Garantie Typ:`t`t`t$($arrFujitsuDeviceWarrentyInfos[5].value)" -LogStatus Info
