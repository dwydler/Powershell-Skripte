Clear-Host

write-host @"
===========================================================================
Inaktive Activesync - Geräte auslesen
===========================================================================
Autor:     Daniel Wydler
Script:    Delete-Old-ActiveSync-Devices.ps1
Version:   0.1
Datum:     08.02.2015
Umgebung:  Windows Server 2012R2 (DC) + Exchange Server 2010 SP3
`n
"@

< #
===========================================================================
Powershell Variable und Konstante
===========================================================================
#>
[int] $intOlderDays = -90


# -----------------------------------------------------------------------------
# Type: 		    Function
# Name: 		    CheckSnapIn
# Description:	    Checks, if the Snapin is registered and loaded.
# Parameters:		snapin name
# Return Values:	
# Requirements:					
# -----------------------------------------------------------------------------
function CheckSnapIn ([string] $name) {
    if (get-pssnapin $name -ea "silentlycontinue") {
        write-host "PSsnapin $name ist geladen."
    }
    elseif (get-pssnapin $name -registered -ea "silentlycontinue") {
        Add-PSSnapin $name
        write-host "PSsnapin $name ist geladen."
    }
    else {
        write-host "PSSnapin $name nicht gefunden!"
        exit
    }
}

Write-host @"
===========================================================================
Powershell SnapIns und Module laden
===========================================================================
"@
[string] $strSnapIn="Microsoft.Exchange.Management.PowerShell.E2010"
CheckSnapIn ($strSnapIn)

Write-Host @"
`n
===========================================================================
Geräte werden nun ausgelesen, Älter als 90 Tage
===========================================================================
"@

$easmailboxes = Get-CASMailbox -Resultsize Unlimited -wa 0 -ea 0 | Where {$_.HasActiveSyncDevicePartnership}
if ($easmailboxes) {
    foreach ($easmailbox in $easmailboxes) {
		Get-ActiveSyncDeviceStatistics -Mailbox $easmailbox.Identity -ea 0 -wa 0 | Where {$_.LastSuccessSync -lt $( (get-date).AddDays($intOlderDays).ToString("MM\/dd\/yyyy 00:00:00") ) }
    }
}
else {
    write-host "Keine ActiveSync-Geräte gefunden!"
}
