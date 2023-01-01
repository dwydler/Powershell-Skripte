<#
.SYNOPSIS
Mit Hilfe dises Skriptes kann über die RESTful API der OPNsense und dem Plugin WOL über vorhandene Einträge Geräte aufgewecket/gestartet werden.

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER
None
 
.INPUTS
UUID des zu startenden Geräts
 
.OUTPUTS
Ausgabe aller existieren Einträge für WakeOnLan (WOL)

 
.NOTES
File:           OPNSense-WakeOnLanDevcies.ps1
Author:         Daniel Wydler
Creation Date:  31.12.2022

.COMPONENT
None

.LINK
https://forum.opnsense.org/index.php?topic=11439.0
https://blog.fuzzymistborn.com/opnsense-wol/
https://github.com/opnsense/plugins/blob/master/net/wol/src/opnsense/mvc/app/controllers/OPNsense/Wol/Api/WolController.php
https://github.com/fvanroie/PS_OPNsense/blob/ff970f242056ff58f8c141f21b4d0198cd7c1a07/Private/Invoke-OPNsenseApiRestCommand.ps1

.EXAMPLE
.\OPNSense-WakeOnLanDevcies.ps1

#>
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Credentials to access the RESTful API
[string] $strOpnSenseUsername = ""
[string] $strOpnSensePassword = ""

[string] $strOpnSenseUri = ""

#
[int] $nr = 1

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

function ExitScript {
    param (
        [parameter(Position=0)]
        [string] $Text,
        [parameter(Position=1)]
        [string] $Color = "Red"
    )

    Write-host $Text -ForegroundColor $Color

    pause
    exit

}
#------------------------------------------------------------[Modules]-------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Host @"
------------------------------------------------------------------------------------------------------------------------

                                                Programm wird gestartet...

------------------------------------------------------------------------------------------------------------------------
"@ -ForegroundColor DarkYellow

# Change the directory in which the script is located
WorkingDir


# Ignoring self signed ssl/tls certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


# Check variables
if ( -not ($strOpnSenseUsername) ) {
    ExitScript -Text "Kein RESTful API Key konfiguriert!" -Color "Red"
}

if ( -not ($strOpnSensePassword) ) {
    ExitScript -Text "Kein RESTful API Secret konfiguriert!" -Color "Red"
}

if ( -not ($strOpnSenseUri) ) {
    ExitScript -Text "Keine IP-Adresse/DNS-Namen der OPNsense konfiguriert!" -Color "Red"
}


# Join them into a single string, seperated by a colon (:)
$pair = "{0}:{1}" -f ($strOpnSenseUsername, $strOpnSensePassword)


# Turn the string into a base64 encoded string
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$token = [System.Convert]::ToBase64String($bytes)


# Define a basic 'Authorization' header with the token
$headers = @{
    Authorization = "Basic {0}" -f ($token)
}


# Create the Request properties
$RequestWolGetEntries = @{
    Uri         = "https://$strOpnSenseUri/api/wol/wol/get"
    Method      = "GET"
    #ContentType = 'application/json'

}

# Execute the Query via RESTful API
$Result = Invoke-RestMethod @RequestWolGetEntries -Headers $headers


# Evaluate the execution output
if( ($Result.wol.wolentry | Measure-Object).Count -gt 0) {

    #
    [array] $aOutputWolList =  ("{0,-1} | {1,-12} | {2,-17} | {3,1}" -f "Nr","Beschreibung","MAC-Adresse","UUID")

    #Filter to get all keys of the CustomObject
    $Result.wol.wolentry | Get-Member -MemberType NoteProperty | Select-Object Name | ForEach-Object {
        
        # Assign UUID to variable
        $key = $_.Name

        # Pass through all UUIDs to get the properties
        foreach ($WolEntry in ($Result.wol.wolentry."$key") ) {
            
            # Output and format the properties of the entry
            $aOutputWolList += ("{0,-2} | {1,-12} | {2,-17} | {3,1}" -f $nr,$($WolEntry.descr),$($WolEntry.mac),$key)
        }

        # Count up for every entry
        $nr++
   }
}
else {

    # Exit the script
    ExitScript -Text "Keine Einträge vorhanden. Das Skript wird beendet." -Color "Red"
}

# List all existing entries for wol hosts
$aOutputWolList


# Query which device should be woke up
do {
    [int] $WolEntryNr = Read-Host -Prompt "`nAuswahl von 1 bis $($nr-1), 0 = Abbruch"
}
while ( ($WolEntryNr -gt $nr) -or ($WolEntryNr -lt 0) )
 

# If the choice is Zero, the script ends 
if($WolEntryNr -eq 0) {

    # Exit the script
    ExitScript -Text "`nAbbruch! Das Skript wird beendet!" -Color "Red"

}
else {

    # Split the string of the choice.
    $WolEntryUuid = $aOutputWolList[$WolEntryNr].Split("|").trim()


    # Create the Request properties
    $RequestWolSetUuid = @{
        Uri         = "https://$strOpnSenseUri/api/wol/wol/set"
        Method      = "POST"
        ContentType = "application/json"
        Body        = "{ `"uuid`": `"$($WolEntryUuid[3])`"}"
    }


    # Execute the Query via RESTful API
    Write-Host "`nDas Gerät wird nun aufgeweckt. Bitte warten..."
    try {
        $Result = Invoke-RestMethod @RequestWolSetUuid -Headers $headers
        Write-host "Das Gerät wurde erfolgreich aufgeweckt." -ForegroundColor Green
    }
    catch {
        Write-host $_ -ForegroundColor Red
    }
    finally {
        pause
    }
}
