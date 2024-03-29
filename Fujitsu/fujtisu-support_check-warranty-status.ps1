<#
.SYNOPSIS
Dieses Skript ruft die Garantieinformationen eines Geräts vom Hersteller Fujitsu ab

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER SerialNumber
Angabe der Seriennummer des Geräts, welches abgefragt werden soll

.PARAMETER csv
Ausgabe der Gerätedaten in eine CSV Datei

.PARAMETER Interactive
Skript wird am Ende nicht automatisch beendet

 
.INPUTS
Die Seriennummer des Geräts
 
.OUTPUTS
Ausgabe der Garantieinformationen des Geräts
 
.NOTES
File:           fujtisu-support_check-warranty-status
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:32 Uhr

.COMPONENT
None

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Fujitsu/fujtisu-support_check-warranty-status.ps1

.EXAMPLE
.\fujtisu-support_check-warranty-status -SerialNumber "YM5G017837"
.\fujtisu-support_check-warranty-status -SerialNumber "YM5G017837" -Interactive
.\fujtisu-support_check-warranty-status -SerialNumber "YM5G017837;YLPW019174" -csv
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

param(
    [Parameter(Position=0)] 
    [ValidateNotNullOrEmpty()]
    [string] $SerialNumber = "",

    [Parameter()] 
    [ValidateNotNullOrEmpty()]
    [switch] $csv,

    [Parameter()] 
    [ValidateNotNullOrEmpty()]
    [switch] $Interactive
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log
[string] $strLogfilePath = $(pwd).Path
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


### Variables for this script 
[array] $aSerialNumbers = @()

[string] $strCsvFilePath = $(pwd).Path
[string] $strCsvFileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strCsvFileNamePrefix = "Export_"
[string] $strCsvFileName = $($strCsvFileNamePrefix + $strCsvFileDate + ".csv")
[string] $strCsvFile = $strCsvFilePath + "\" + $strCsvFileName

[hashtable] $htFtsHeaders = @{
    Origin = 'https://support.ts.fujitsu.com'
    Referer = 'https://support.ts.fujitsu.com/IndexWarranty.asp?lng=de'
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function WorkingDir {
    param (
        [parameter(Position=0)]
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
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $LogText = "",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Info','Success','Warning','Error')]
        [string] $LogStatus= "Info",

        [Parameter()]
        [switch] $Absatz,

        [Parameter()]
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
        $strLogFileHeader = "$("#" * 120)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Skript:", "$($MyInvocation.ScriptName)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Startzeit:", "$(Get-Date -Format "dd.MM.yyyy HH:mm:ss")`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Ausführendes Konto:", "$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`n"
        $strLogFileHeader += "{0,-21} {1,0}" -f "# Computername:", "$env:COMPUTERNAME`n"
        $strLogFileHeader += "$("#" * 120)`n"

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

# Wechselt in das Verzeichnis, in dem das PowerShell Skript liegt
WorkingDir


Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        Fujitsu Garantie / Service Status ueberpruefen

------------------------------------------------------------------------------------------------------------------------
"@

Write-Log -LogText "Überprüfen ob Seriennummern(n) als Parameter übergeben worden sind." -LogStatus Info
if ($SerialNumber -eq "") {
    Write-Log -LogText "Keine Seriennummern gefünden." -LogStatus Info -Absatz

    do {
        $SerialNumber = Read-Host "Bitte Seriennummer(n) eingebenn (z.B. YLPW019174;DSET073915)"
    } while ($SerialNumber -eq "")    
}
else {
    Write-Log -LogText "Mindestens eine Serienummer gefunden." -LogStatus Info -Absatz
}


# Seriennummern von einem String in ein Array konvertieren
$aSerialNumbers = $SerialNumber -split ';'


# Falls der Parameter "csv" angegeben wurde, wird die CSV Datei angelegt.
if ($csv) {
    Add-Content -Path "$strCsvFile"  -Value '"Seriennummer";"Produkt";"AdlerProdukt";"AdlerProduktFamilie";"Support Code";"Support Start";"Support Ende";"Produkt Support Ende";"Support Details";"Garantie Gruppe";"Support Offering Gruppe";"Bestellnummer"' -Encoding UTF8
}


ForEach ($sn in $aSerialNumbers) {

    Write-Log -LogText "Überprüfen des Muster/Länger der Seriennummer '$sn'." -LogStatus Info
    if (ValidSerialNumber $sn ) {
        Write-Log -LogText "Gültige Seriennummer '$sn' erkannt." -LogStatus Success -Absatz


        Write-Log -LogText "Aktuellen Token der Webseite auslesen" -LogStatus Info
        $wroSearchHtml = Invoke-WebRequest -Method Get -Uri "https://support.ts.fujitsu.com/IndexWarranty.asp?lng=de"
        [string] $strFtsWebsiteToken = (($wroSearchHtml.tostring() -split "[`r`n]" | Select-String "Token" | Select -First 1) -split ":")[1].Trim() -replace "'", ""


        Write-Log -LogText "Abfrage der Daten des Geräts bei Fujitsu." -LogStatus Info
        $wroSearchHtml = Invoke-WebRequest -Method Post -Headers $htFtsHeaders -Uri "https://support.ts.fujitsu.com/ProductCheck/Default.aspx" `
                            -Body "lng=de&GotoDiv=Warranty/FWarrantyStatus&DivID=indexwarranty&GotoUrl=IndexWarranty&RegionID=1&Ident=$sn&Token=$strFtsWebsiteToken"

        
        Write-Log -LogText "Erhaltene Daten filtern und speichern." -LogStatus Info
        [array] $arrFujitsuDeviceWarrentyInfos = $wroSearchHtml.InputFields | Where-Object { ($_.name -eq "Ident") -or ($_.name -eq "Product") -or ($_.name -eq "AdlerProduct") -or ($_.name -eq "AdlerProductFam") -or ($_.name -eq "MS90") `
            -or ($_.name -eq "Firstuse") -or ($_.name -eq "WarrantyEndDate")  -or ($_.name -eq "WCode") -or ($_.name -eq "WCodeDesc") -or ($_.name -eq "PartNumber") -or ($_.name -eq "WGR") -or ($_.name -eq "SOG") } | Select-Object Name, Value
        

        # Ausgabe der Daten
        Write-Log -LogText "`tSeriennummer:`t`t`t$($arrFujitsuDeviceWarrentyInfos[0].value)" -LogStatus Info
        Write-Log -LogText "`tProdukt:`t`t`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[1].value)" -LogStatus Info
        Write-Log -LogText "`tAdlerProdukt:`t`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[2].value)" -LogStatus Info
        Write-Log -LogText "`tAdlerProduktFamilie:`tFujitsu $($arrFujitsuDeviceWarrentyInfos[3].value)" -LogStatus Info
        Write-Log -LogText "`tSupport Code:`t`t`t$($arrFujitsuDeviceWarrentyInfos[4].value)" -LogStatus Info

        Write-Log -LogText "`tSupport Start:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[5].value -Format "dd.MM.yyyy")" -LogStatus Info

        if( (Get-Date $arrFujitsuDeviceWarrentyInfos[7].value) -gt (Get-Date)) {
            Write-Log -LogText "`tSupport Ende:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")" -LogStatus Success
            Write-Log -LogText "`tSupport Status:`t`t`tDas Produkt ist unter Support." -LogStatus Success
            [string] $strSeviceStatus = "Das Produkt ist unter Service."
        }
        else {
            Write-Log -LogText "`tSupport Ende:`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")" -LogStatus Error
            Write-Log -LogText "`tSupport Status:`t`t`tDas Produkt hat keinen Support mehr." -LogStatus Error
            [string] $strSeviceStatus = "Das Produkt hat keinen Service mehr."
        }
        
        Write-Log -LogText "`tProdukt Support Ende:`t$([DateTime]::ParseExact( ( ($arrFujitsuDeviceWarrentyInfos[6].value).TrimEnd(" *") ), "M/dd/yyyy", $null).ToString("dd.MM.yyyy"))" -LogStatus Info
        Write-Log -LogText "`tSupport Details:`t`t$($arrFujitsuDeviceWarrentyInfos[8].value)" -LogStatus Info
        Write-Log -LogText "`tGarantie Gruppe:`t`t$($arrFujitsuDeviceWarrentyInfos[9].value)" -LogStatus Info
        Write-Log -LogText "`tSupport Offering Gruppe:$($arrFujitsuDeviceWarrentyInfos[10].value)" -LogStatus Info
        Write-Log -LogText "`tBestellnummer:`t`t`t$($arrFujitsuDeviceWarrentyInfos[11].value)" -LogStatus Info -Absatz


        # Falls der Parameter "csv" angegeben wurde, wird der jeweilige Datenssatz hinzugefügt.
        if ($csv) {
            Write-Log -LogText "`Schreibe die Daten in die CSV Datei '$strCsvFileName'." -LogStatus Info -Absatz
            Add-Content -Path "$strCsvFile" -Value "`"$($arrFujitsuDeviceWarrentyInfos[0].value)`";`"$($arrFujitsuDeviceWarrentyInfos[1].value)`";`"$($arrFujitsuDeviceWarrentyInfos[2].value)`";`"$($arrFujitsuDeviceWarrentyInfos[3].value)`";`"$($arrFujitsuDeviceWarrentyInfos[4].value)`";`"$(Get-Date $arrFujitsuDeviceWarrentyInfos[5].value -Format "dd.MM.yyyy")`";`"$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")`";`"$([DateTime]::ParseExact($arrFujitsuDeviceWarrentyInfos[6].value, "M/dd/yyyy", $null).ToString("dd.MM.yyyy"))`";`"$($arrFujitsuDeviceWarrentyInfos[8].value)`";`"$($arrFujitsuDeviceWarrentyInfos[9].value)`";`"$($arrFujitsuDeviceWarrentyInfos[10].value)`";`"$($arrFujitsuDeviceWarrentyInfos[11].value)`"" -Encoding UTF8
        }
    }
    else {
        Write-Log -LogText "Die Seriennummer '$sn' ist ungültig!" -LogStatus Error
    }
}


# Falls der Parameter "interactive" angegeben wurde, wird das Skript am Ende pausiert.
if ($interactive) {
    pause
}

exit
