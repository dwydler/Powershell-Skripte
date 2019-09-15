<#
===========================================================================
Fujitsu Garantie / Service Status ueberpruefen
===========================================================================
Autor:     Daniel Wydler
Umgebung:  Windows 10 (1703), Powershell 5.1.15063.502
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
        $wroSearchHtml= Invoke-WebRequest "http://support.ts.fujitsu.com/include/Suchfunktion.asp?lng=DE&GotoURL=IndexWarranty&Search=$strLocSerialNumber" -SessionVariable session
        $wroLocHtml = Invoke-WebRequest "http://support.ts.fujitsu.com/Warranty/WarrantyStatus.asp?lng=DE&IDNR=$strLocSerialNumber&HardwareGUID=428EF436-8E40-49C1-9C07-F10F56903BF3&Version=3.51" -WebSession $session
    }
    catch {
        Write-Host $($_.Exception.Message) -ForegroundColor Red
        break;
    }


    # Filtern der notwendigen Informationen aus der HTML Quellcode
    return ($wroLocHtml.ParsedHtml.getElementsByTagName("td") | Where { ($_.className -eq ‘contenttext’) }).outertext    
}

Function SetWarrantyEnd ([array] $aLocProductInfo) {

    [array] $htMatches = @()

    # Verlängerung von 3 auf 4 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerb
    #if($aProductInfo[2] -match "[A-Za-zä\s]{0,18}\d\s[a-z]{0,3}\s\d\s[A-Za-z\s\-]{0,21}") {
    if($aLocProductInfo[2] -match "[A-Za-zä\s]+\d[A-Za-zä\s]+\d[A-Za-zä\s\-]+") {
        $htMatches = $aLocProductInfo[2] -split "(\d+)"
        return (Get-Date $aLocProductInfo[7]).AddYears($htMatches[3])
    }
    # 5 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerbs
    #elseif ($aProductInfo[2] -match "(\d\s[A-Za-z\s\-]{0,21}\,\s\d[x]\d)") {
    elseif ($aLocProductInfo[2] -match "\d[a-zA-Z\s\-]+\,\s\dx\d") {
        $htMatches = $aLocProductInfo[2] -split "([\sA-Za-z\-\,ä]+)(\d[x]\d)"
        return (Get-Date $aLocProductInfo[7]).AddYears($htMatches[0])
    }
    else {
        #Write-Host "Unbekannter Garantiestatus!" -ForegroundColor Red
        return (Get-Date $aLocProductInfo[7])
    }

}

Function OutputInformations ([array] $aLocProductInfo, [datetime] $dtLocServiceEnd) {

    Write-Host "Produktname:`t`tFujitsu $($aLocProductInfo[0].Trim())"
    Write-Host "Bestellnummer:`t`t$($aLocProductInfo[3].Trim())"
    Write-Host "Service Code:`t`t$($aLocProductInfo[6].Trim())"
    Write-Host "Service Start:`t`t$($aLocProductInfo[7].Trim())"
    Write-Host "Service Ende:`t`t" -NoNewline
        if ($aLocProductInfo[1] -eq "Der Service für das Produkt ist abgelaufen") { Write-Host "" }
        elseif ($dtLocServiceEnd -gt (get-date)) { write-host "$($dtLocServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Green }
        elseif ($dtLocServiceEnd -lt (get-date)) { write-host "$($dtLocServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Red }
        

    Write-Host "Service Status:`t`t$($aLocProductInfo[1].Trim())"
    Write-Host "Garantie Gruppe: `t$($aLocProductInfo[4].Trim())"
    Write-Host "Garantie Art:`t`t" -NoNewline
        if ($aLocProductInfo[2] -ne $null) { $aLocProductInfo[2].Trim() }
        else { Write-host "---" -ForegroundColor Red }
}



<#
===========================================================================
Hauptprogramm
===========================================================================
#>

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                        Fujitsu Garantie / Service Status ueberpruefen
                                                        Version: 0.3

------------------------------------------------------------------------------------------------------------------------
"@

# Abfrage, ob Seriennummer übergeben worden ist. Falls nicht, kann diese manuell eingegeben werden.
if( -not($SerialNumber) ) {
    $SerialNumber = Read-Host -Prompt "Seriennummer des Geraets eingeben (z.B. YLLC001597 oder YM5G017873)"
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
