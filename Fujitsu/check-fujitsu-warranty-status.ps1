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
Variable und Konstante
===========================================================================
#>
#[string] $SerialNumber = ""
[array] $aProductInfo = @()
[array] $htMatches = @()
[datetime] $dtServiceEnd = Get-Date "01.01.1970"
[Microsoft.PowerShell.Commands.WebResponseObject] $wroHtml = $null


<#
===========================================================================
Hauptprogramm
===========================================================================
#>
Write-Host @"
-------------------------------------------------------------------------------------------------------------------------------------

                                        Fujitsu Garantie / Service Status ueberpruefen
                                                        Version: 0.1

-------------------------------------------------------------------------------------------------------------------------------------`n
"@

# Abfrage, ob Seriennummer übergeben worden ist. Falls nicht, kann diese manuell eingegeben werden.
if($SerialNumber){
    Write-Host "Seriennummer als Parameter übergeben." -ForegroundColor Green
}
else {
    $SerialNumber = Read-Host -Prompt "Seriennummer des Geraets eingeben (z.B. YLLC001597 oder YM5G017873 )"
}


# Überprüfung, ob es eine gültige Seriennummer ist
if( -not ($SerialNumber -match "^[a-zA-Z]{2}[\da-zA-Z][a-zA-Z]\d{6}$" ) ) {
    write-host "Keine gültige Seriennummer eingegeben!" -ForegroundColor Red
    pause
    exit
}


# Garantiedaten auf der Fujitsu-Webseite abfragen
try {
    $wroHtml = Invoke-WebRequest "http://support.ts.fujitsu.com/Warranty/WarrantyStatus.asp?lng=DE&IDNR=$SerialNumber"
}
catch {
    Write-Host $($_.Exception.Message) -ForegroundColor Red
    pause
    exit
}
Write-Host "`n"


# Filtern der notwendigen Informationen aus der HTML Quellcode
$aProductInfo = ($wroHtml.ParsedHtml.getElementsByTagName("td") | Where { ($_.className -eq ‘contenttext’)-or ($_.className -eq ‘alink’) }).outertext


# Auswertung der Garantielaufzeit
## Verlängerung von 3 auf 4 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerb
#if($aProductInfo[2] -match "[A-Za-zä\s]{0,18}\d\s[a-z]{0,3}\s\d\s[A-Za-z\s\-]{0,21}") {
if($aProductInfo[2] -match "[A-Za-zä\s]+\d[A-Za-zä\s]+\d[A-Za-zä\s\-]+") {
    $htMatches = $aProductInfo[2] -split "(\d+)"
    $dtServiceEnd = (Get-Date $aProductInfo[6]).AddYears($htMatches[3])
}
## 5 Jahre Vor-Ort Service, 9x5, nächster Arbeitstag Antrittszeit, gilt im Land des Erwerbs
#elseif ($aProductInfo[2] -match "(\d\s[A-Za-z\s\-]{0,21}\,\s\d[x]\d)") {
elseif ($aProductInfo[2] -match "\d[a-zA-Z\s\-]+\,\s\dx\d") {
    $htMatches = $aProductInfo[2] -split "([\sA-Za-z\-\,ä]+)(\d[x]\d)"
    $dtServiceEnd = (Get-Date $aProductInfo[6]).AddYears($htMatches[0])
}
else {
    Write-Host "Unbekannter Garantiestatus!"
}


# Ausgabe der Daten
Write-Host "Produkt:`t`t`tFujitsu $($aProductInfo[0].Trim())"
Write-Host "Bestellnummer:`t`t$($aProductInfo[3].Trim())"
Write-Host "Service Code:`t`t$($aProductInfo[5].Trim())"
Write-Host "Service Start:`t`t$($aProductInfo[6].Trim())"
Write-Host "Service Ende:`t`t" -NoNewline
    if ($dtServiceEnd -gt (get-date)) { write-host "$($dtServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Green }
    elseif ($dtServiceEnd -lt (get-date)) { write-host "$($dtServiceEnd.ToString("dd.MM.yyyy"))" -ForegroundColor Red }

Write-Host "Service Status:`t`t$($aProductInfo[1].Trim())"
Write-Host "Garantie Gruppe: `t$($aProductInfo[4].Trim())"
Write-Host "Garantie Art:`t`t$($aProductInfo[2].Trim())"

pause