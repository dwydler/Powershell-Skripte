<#
.SYNOPSIS
Dieses Skript installiert bzw. aktualisiert Mozilla Firefox auf dem aussführenden Server.

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.INPUTS
None
 
.OUTPUTS
Ausgabe der verschiedenen Prüfroutinen (z.B. Verzeichnis vorhanden, Start des Scan, Ergebnis des Scans, etc.).

 
.NOTES
File:           Posh-MozillaFirefoxUpdateScript.ps1
Author:         Daniel Wydler
Creation Date:  17.05.2023 Uhr

.COMPONENT
None

.LINK
None

.EXAMPLE
.\Posh-MozillaFirefoxUpdateScript.ps1

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host


#----------------------------------------------------------[Declarations]----------------------------------------------------------

### function Write-Log/Delete-Log
[string] $strLogfilePath = "$PSScriptRoot\Logs"
[string] $strLogfileDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
[string] $strLogfileNamePrefix = ""
[string] $strLogfileName = $($strLogfileNamePrefix + $strLogfileDate + ".log")
[string] $strLogfile = $strLogfilePath + "\" + $strLogfileName
[int] $intLogFilesOlderThanDays = -60

### Variables for this script
[string] $strDomain = ""
[string] $strDnsServer = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -ExpandProperty ifIndex | Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses

$QueryResultRrsig = $null

[array] $aDnsQueryDnsRecordAs = @()
[array] $aDnsQueryDnsRecordPtrs = @()

#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Load default functions from folder "PSFunctions"
Get-ChildItem -Path "$PSScriptRoot\PSFunctions" | Select-Object Name, Fullname | Sort-Object Name | ForEach-Object {

    # Load function of the particular file
    . $_.FullName
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# global settings
$ErrorActionPreference = "STOP"
$error.Clear()

# Changes to the directory in which the PowerShell script is located
Set-WorkingDir


### Query the DNS Domain which should be checked
do {
    $strDomain = Read-Host -Prompt "Please enter a domain (e.g. google.de) to be checked"
}
while ([string]::IsNullOrEmpty($strDomain) )

### Query the DNS Domain which should be checked
[string] $strDefaultPromptValue = $strDnsServer
$strDnsServer = Read-Host -Prompt "Please enter an other dns Server [$($strDnsServer)]"

if ($strDnsServer -eq "") {
    $strDnsServer = $strDefaultPromptValue
}

Write-Log -LogText "Checking domain: $strDomain" -LogStatus Info
Write-Log -LogText "Using follow DNS server: $strDnsServer" -LogStatus Info -Absatz


### Check if a dns zone for the given domain exist
Write-Log -LogText "Query informations to the given domain. Please wait..." -LogStatus Info
try {
    Resolve-DnsName -Name $strDomain | Out-Null
    Write-Log -LogText "The dns zone for the given domain are found." -LogStatus Success -Absatz
}
catch {
    Write-Log -LogText "$($error[0].Exception.Message)." -LogStatus Error -Absatz
    exit 1
}


### DNSSEC Check
Write-Log -LogText "Checking if the $($strDomain) is signed." -LogStatus Info
try {
    $QueryResultRrsig = Resolve-DnsName -Name $strDomain -DnssecOk -Server $strDnsServer
    
    if ($QueryResultRrsig.Type -eq "RRSIG") {
        Write-Log -LogText "The $($strDomain) seems to be signed." -LogStatus Success
        Write-Log -LogText "MXer is signed propably." -LogStatus Success -Absatz
    }
    else {
        Write-Log -LogText "The $($strDomain) seems to be not signed, validation result: Unsigned." -LogStatus Warning
        Write-Log -LogText "Make sure you are using a DNSSEC capable DNS server and that the zone is propably signed." -LogStatus Warning -Absatz
    }
}
catch {
    Write-Log -LogText "$($error[0].Exception.Message)." -LogStatus Error -Absatz
}


# Query dns informations
$objDnsQueryDnsRecordMx = Resolve-DnsName -Name $strDomain -Type MX -Server $strDnsServer

### Display informations about MX records
Write-Log -LogText "MX Records:" -LogStatus Info
Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info

if ($objDnsQueryDnsRecordMx.Type -ne "MX") {
    Write-Log -LogText "There is no MX record for this domain." -LogStatus Error
}
else {
    # Display informations
    $objDnsQueryDnsRecordMx | ForEach-Object {
        Write-Log -LogText "$($_.Name). $($_.TTL) IN $($_.Type) $($_.Preference) $($_.NameExchange)." -LogStatus Info
    }
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info -Absatz


    ### Display informations about A (and AAA) records
    Write-Log -LogText "A Records:" -LogStatus Info
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info
    
    # Query dns informations
    $objDnsQueryDnsRecordMx | ForEach-Object {
        $objDnsQueryDnsRecordA = Resolve-DnsName -Name $_.NameExchange -Type A_AAAA -Server $strDnsServer
        $aDnsQueryDnsRecordAs += $objDnsQueryDnsRecordA
    }
    # Display informations
    $aDnsQueryDnsRecordAs | ForEach-Object {
        Write-Log -LogText "$($_.Name). $($_.TTL) IN $($_.Type) $($_.IPAddress)" -LogStatus Info
    }
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info -Absatz


    ### Display informations about PTR records
    Write-Log -LogText "PTR Records:" -LogStatus Info
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info

    # Query dns informations
    $aDnsQueryDnsRecordAs | ForEach-Object {
        $objDnsQueryDnsRecordPtr = Resolve-DnsName -Name $_.IPAddress -Type PTR -Server $strDnsServer
        $aDnsQueryDnsRecordPtrs += $objDnsQueryDnsRecordPtr
    }

    # Display informations
    $aDnsQueryDnsRecordPtrs | ForEach-Object {
        Write-Log -LogText "$($_.Name). $($_.TTL) IN $($_.Type) $($_.NameHost)." -LogStatus Info
    }    
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info -Absatz


    ### Display informations about NS records
    Write-Log -LogText "NS Records:" -LogStatus Info
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info
    Resolve-DnsName -Name $strDomain -Type NS | ForEach-Object {
        Write-Log -LogText "$($_.Name). $($_.TTL) IN $($_.Type) $($_.NameHost)." -LogStatus Info
    }
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info -Absatz


    ### Display informations about TLSA records
    Write-Log -LogText "TSLA Records:" -LogStatus Info
    Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info
 
    $objDnsQueryDnsRecordMx | ForEach-Object {
        try {
            # Query dns informations
            $objDnsQueryDnsRecordTlsa = Resolve-DnsName -Name "_25._tcp.$($_.NameExchange)" -DnssecOk -Server $strDnsServer

            # Display informations
            Write-Log -LogText "$($objDnsQueryDnsRecordTlsa[3].Name). $($objDnsQueryDnsRecordTlsa[3].TTL) IN $($objDnsQueryDnsRecordTlsa[3].QueryType) $($_.NameExchange)" -LogStatus Info
        }
        catch {
            # Display informations
            Write-Log -LogText "$($_.Exception.Message)." -LogStatus Warning
        }
    }
    
}
Write-Log -LogText "------------------------------------------------------------------------" -LogStatus Info -Absatz

# End
Write-Log -LogText "Das Skript ist am Ende angekommen." -LogStatus Info

pause
exit
