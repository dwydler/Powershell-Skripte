<#
===========================================================================
Fujitsu Garantie / Service Status ueberpruefen
===========================================================================
Autor:     Daniel Wydler
Umgebung:  Windows 10 (1607), Powershell 5.1
#>

param(
    [Parameter(
        Position=0,
        Mandatory=$false
    )] [string] $SerialNumber = ""
)

clear-host


<#
===========================================================================
Funktionen
===========================================================================
#>
Function ValidSerialNumber ([string] $strLocSerialNumber) {
    
    if($strLocSerialNumber -match "^[a-zA-Z]{2}[\da-zA-Z][a-zA-Z]\d{6}$") {
        return $true
    }
    else {
        return $false

    }
}

Function GetWarrantyInfo ([string] $strLocSerialNumber) {
    
    # Garantiedaten auf der Fujitsu-Webseite abfragen
    try {
        [Microsoft.PowerShell.Commands.WebResponseObject] $wroLocHtml = Invoke-WebRequest "http://support.ts.fujitsu.com/Warranty/WarrantyStatus.asp?lng=DE&IDNR=$strLocSerialNumber"
    }
    catch {
        Write-Host $($_.Exception.Message) -ForegroundColor Red
        break;
    }


    # Filtern der notwendigen Informationen aus der HTML Quellcode
    return ($wroLocHtml.ParsedHtml.getElementsByTagName("td") | Where { ($_.className -eq ‘contenttext’)-or ($_.className -eq ‘alink’) }).outertext    
}

Function SetWarrantyEnd ([array] $aLocProductInfo) {

    [array] $htMatches = @()

    # Verlängerung von 3 auf 4 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerb
    #if($aProductInfo[2] -match "[A-Za-zä\s]{0,18}\d\s[a-z]{0,3}\s\d\s[A-Za-z\s\-]{0,21}") {
    if($aLocProductInfo[2] -match "[A-Za-zä\s]+\d[A-Za-zä\s]+\d[A-Za-zä\s\-]+") {
        $htMatches = $aLocProductInfo[2] -split "(\d+)"
        return (Get-Date $aLocProductInfo[6]).AddYears($htMatches[3])
    }
    # 5 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerbs
    #elseif ($aProductInfo[2] -match "(\d\s[A-Za-z\s\-]{0,21}\,\s\d[x]\d)") {
    elseif ($aLocProductInfo[2] -match "\d[a-zA-Z\s\-]+\,\s\dx\d") {
        $htMatches = $aLocProductInfo[2] -split "([\sA-Za-z\-\,ä]+)(\d[x]\d)"
        return (Get-Date $aLocProductInfo[6]).AddYears($htMatches[0])
    }
    else {
        Write-Host "Unbekannter Garantiestatus!" -ForegroundColor Red
        break;
    }

}

Function OutputInformations ([array] $aLocProductInfo, [datetime] $dtLocServiceEnd) {

    Write-Host "Produktname:`t`tFujitsu $($aLocProductInfo[0].Trim())"
    Write-Host "Bestellnummer:`t`t$($aLocProductInfo[3].Trim())"
    Write-Host "Service Code:`t`t$($aLocProductInfo[5].Trim())"
    Write-Host "Service Start:`t`t$($aLocProductInfo[6].Trim())"
    Write-Host "Service Ende:`t`t" -NoNewline
        if ($dtLocServiceEnd -gt (get-date)) { write-host "$($dtLocServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Green }
        elseif ($dtLocServiceEnd -lt (get-date)) { write-host "$($dtLocServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Red }

    Write-Host "Service Status:`t`t$($aLocProductInfo[1].Trim())"
    Write-Host "Garantie Gruppe: `t$($aLocProductInfo[4].Trim())"
    Write-Host "Garantie Art:`t`t$($aLocProductInfo[2].Trim())"
}



<#
===========================================================================
Hauptprogramm
===========================================================================
#>

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        Fujitsu Garantie / Service Status ueberpruefen
                                                        Version: 0.2

------------------------------------------------------------------------------------------------------------------------
"@

# Abfrage, ob Seriennummer übergeben worden ist. Falls nicht, kann diese manuell eingegeben werden.
if( -not($SerialNumber) ) {
    $SerialNumber = Read-Host -Prompt "Seriennummer des Geraets eingeben (z.B. YLLC001597 oder YM5G017873 )"
    [bool] $cli = $false
}
else {
    Write-Host "Seriennummer als Parameter übergeben."
    [bool] $cli = $true
}


# Überprüfen des Muster/Länger der Seriennummer
if( -not(ValidSerialNumber "$SerialNumber") ) {
    write-host "Keine gültige Seriennummer eingegeben!" -ForegroundColor Red
}
else {
    Write-Host "`n"

    # Garantiedaten auf der Fujitsu-Webseite abfragen
    [array] $aProductInfo = GetWarrantyInfo ($SerialNumber)

    # 
    [datetime] $dtWarrantyEnd = SetWarrantyEnd ($aProductInfo)

    # Ausgabe der Daten
    OutputInformations $aProductInfo $dtWarrantyEnd
}

# Ende
if($cli -eq $false) {
    pause
}