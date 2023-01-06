<#
.SYNOPSIS
This script retrieves the warranty information of a device from the manufacturer Fujitsu

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER SerialNumber
Specification of the serial number of the device that is to be queried

.PARAMETER csv
Output of the device data in a CSV file

.PARAMETER Interactive
Script does not exit automatically when finished

.INPUTS
The serial number of the device
 
.OUTPUTS
Output of the warranty information of the device
 
.NOTES
File:           fujitsu-warranty-status-checker.ps1
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:32 Uhr

.COMPONENT
The script supports a multilingual environment. Default language is english. More details on that:
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-localizeddata?view=powershell-7.3

.LINK
https://codeberg.org/wd/Powershell-Skripte/src/branch/master/Fujitsu/FujitsuWarrantyStatusChecker/

.EXAMPLE
.\fujitsu-warranty-status-checker.ps1 -SerialNumber "YM5G017837"
.\fujitsu-warranty-status-checker.ps1 -SerialNumber "YM5G017837" -Interactive
.\fujitsu-warranty-status-checker.ps1 -SerialNumber "YM5G017837;YLPW019174" -csv
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
[string] $strLogfilePath = $(Get-Location).Path
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = "Log_"
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName


### Variables for this script 
[array] $aSerialNumbers = @()

[string] $strCsvFilePath = $(Get-Location).Path
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

    # Splittet aus dem vollstaendigen Dateipfad den Verzeichnispfad heraus
    # Beispiel: D:\Daniel\Temp\Unbenannt2.ps1 -> D:\Daniel\Temp
    [string] $strWorkingdir = Split-Path $MyInvocation.PSCommandPath -Parent

    # Wenn Variable wahr ist, gebe Text aus.
    if ($Debugging) {
        Write-Host "[DEBUG] PS $strWorkingdir`>" -ForegroundColor Gray
    }

    # In das Verzeichnis wechseln
    Set-Location $strWorkingdir
}

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $LogText,

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
        $strLogFileHeader += "{0,-21} {1,0}" -f "# BenutzerKonto:", "$env:username`n"
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

# Changes to the directory in which the PowerShell script is located
WorkingDir

# Import Locale data
. .\locale\UICulture.ps1

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        $($uiLanguage.ScriptTitle)

------------------------------------------------------------------------------------------------------------------------
"@

#
Write-Log -LogText $uiLanguage.CheckParmSerial -LogStatus Info
if ($SerialNumber -eq "") {
    Write-Log -LogText $uiLanguage.CheckParmSerialErrorText -LogStatus Info -Absatz

    do {
        $SerialNumber = Read-Host $uiLanguage.QuerySerialInfoText
    } while ($SerialNumber -eq "")    
}
else {
    Write-Log -LogText $uiLanguage.CheckParmSerialResult -LogStatus Info -Absatz
}


# Convert serial numbers from a string to an array
$aSerialNumbers = $SerialNumber -split ';'


# If the "csv" parameter was specified, the CSV file is created.
if ($csv) {
    Add-Content -Path "$strCsvFile"  -Value $uiLanguage.CsvFileTitles -Encoding UTF8
}

ForEach ($sn in $aSerialNumbers) {

    Write-Log -LogText "$($uiLanguage.CheckSerialInfoText) '$sn'." -LogStatus Info
    if (ValidSerialNumber $sn ) {
        Write-Log -LogText $uiLanguage.CheckSerialInfoOk -LogStatus Success -Absatz


        Write-Log -LogText $uiLanguage.WebsiteFtsQueryTokenInfo -LogStatus Info
        $wroSearchHtml = Invoke-WebRequest -Method Get -Uri "https://support.ts.fujitsu.com/IndexWarranty.asp?lng=de"
        [string] $strFtsWebsiteToken = (($wroSearchHtml.tostring() -split "[`r`n]" | Select-String "Token" | Select-Object -First 1) -split ":")[1].Trim() -replace "'", ""


        Write-Log -LogText $uiLanguage.WebsiteFtsQueryDataInfo -LogStatus Info
        $wroSearchHtml = Invoke-WebRequest -Method Post -Headers $htFtsHeaders -Uri "https://support.ts.fujitsu.com/ProductCheck/Default.aspx" `
                            -Body "lng=de&GotoDiv=Warranty/FWarrantyStatus&DivID=indexwarranty&GotoUrl=IndexWarranty&RegionID=1&Ident=$sn&Token=$strFtsWebsiteToken"

        
        Write-Log -LogText $uiLanguage.WebsiteFtsDataFilterInfo -LogStatus Info
        [array] $arrFujitsuDeviceWarrentyInfos = $wroSearchHtml.InputFields | Where-Object { ($_.name -eq "Ident") -or ($_.name -eq "Product") -or ($_.name -eq "AdlerProduct") -or ($_.name -eq "AdlerProductFam") -or ($_.name -eq "MS90") `
            -or ($_.name -eq "Firstuse") -or ($_.name -eq "WarrantyEndDate")  -or ($_.name -eq "WCode") -or ($_.name -eq "WCodeDesc") -or ($_.name -eq "PartNumber") -or ($_.name -eq "WGR") -or ($_.name -eq "SOG") } | Select-Object Name, Value
        

        # Output of device data
        Write-Log -LogText "`t$($uiLanguage.DeviceDataSerial):`t`t`t$($arrFujitsuDeviceWarrentyInfos[0].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProduct):`t`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[1].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataAdlerProduct):`t`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[2].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataAdlerProductFamily):`t`tFujitsu $($arrFujitsuDeviceWarrentyInfos[3].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportCode):`t`t`t$($arrFujitsuDeviceWarrentyInfos[4].value)" -LogStatus Info

        Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportStartDate):`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[5].value -Format "dd.MM.yyyy")" -LogStatus Info

        if( (Get-Date $arrFujitsuDeviceWarrentyInfos[7].value) -gt (Get-Date)) {
            Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportEndDate):`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")" -LogStatus Success
            Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportStatus):`t`t`t$($uiLanguage.DeviceDataSupportStatusTextOk)" -LogStatus Success
            [string] $strSeviceStatus = $uiLanguage.DeviceDataSupportStatusTextOk
        }
        else {
            Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportEndDate):`t`t`t$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")" -LogStatus Error
            Write-Log -LogText "`t$($uiLanguage.DeviceDataSupportStatus):`t`t`t$($uiLanguage.DeviceDataSupportStatusTextEnd)" -LogStatus Error
            [string] $strSeviceStatus = $uiLanguage.DeviceDataSupportStatusTextEnd
        }
        
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProductSupportEndDate):`t`t$([DateTime]::ParseExact( ( ($arrFujitsuDeviceWarrentyInfos[6].value).TrimEnd(" *") ), "M/dd/yyyy", $null).ToString("dd.MM.yyyy"))" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProductSupportDetails):`t`t$($arrFujitsuDeviceWarrentyInfos[8].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProductWarrentyGroup):`t`t$($arrFujitsuDeviceWarrentyInfos[9].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProductSupportOfferingGroup):`t$($arrFujitsuDeviceWarrentyInfos[10].value)" -LogStatus Info
        Write-Log -LogText "`t$($uiLanguage.DeviceDataProductOrderNumber):`t`t`t$($arrFujitsuDeviceWarrentyInfos[11].value)" -LogStatus Info -Absatz


        # If the "csv" parameter is specified, the data record is added.
        if ($csv) {
            Write-Log -LogText "$($uiLanguage.CsvFileCreateInfo) '$strCsvFileName'." -LogStatus Info -Absatz
            Add-Content -Path "$strCsvFile" -Value "`"$($arrFujitsuDeviceWarrentyInfos[0].value)`";`"$($arrFujitsuDeviceWarrentyInfos[1].value)`";`"$($arrFujitsuDeviceWarrentyInfos[2].value)`";`"$($arrFujitsuDeviceWarrentyInfos[3].value)`";`"$($arrFujitsuDeviceWarrentyInfos[4].value)`";`"$(Get-Date $arrFujitsuDeviceWarrentyInfos[5].value -Format "dd.MM.yyyy")`";`"$(Get-Date $arrFujitsuDeviceWarrentyInfos[7].value -Format "dd.MM.yyyy")`";`"$([DateTime]::ParseExact($arrFujitsuDeviceWarrentyInfos[6].value, "M/dd/yyyy", $null).ToString("dd.MM.yyyy"))`";`"$($arrFujitsuDeviceWarrentyInfos[8].value)`";`"$($arrFujitsuDeviceWarrentyInfos[9].value)`";`"$($arrFujitsuDeviceWarrentyInfos[10].value)`";`"$($arrFujitsuDeviceWarrentyInfos[11].value)`"" -Encoding UTF8
        }
    }
    else {
        Write-Log -LogText $uiLanguage.CheckSerialInfoError -LogStatus Error
    }
}

# If the parameter "interactive" is specified, the script will be paused at the end.
if ($interactive) {
    pause
}

exit