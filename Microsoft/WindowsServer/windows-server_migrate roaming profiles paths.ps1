Clear-Host

write-host @"
===========================================================================
Active-Directorybenutzer anlegen
===========================================================================
Autor:     Daniel Wydler
Beispiel:  Setzt einen neuen Servernamen / Freigabename für server-
		   gespeicherte Profile
Umgebung:  Windows Server 2012R2 (DC)
`n
"@

<#
===========================================================================
Powershell Variable und Konstante
===========================================================================
#>

$strOldUserProfileServer = "filer01"

$strNewUserProfileServer = "filer02"
$strNewUserProfilePath = "user-profiles"


$strNewRdsProfileServer = "filer02" 
$strNewRdsProfilePath = "rds-profiles"

$strSAMAccountName = ""



# -----------------------------------------------------------------------------
# Type: 		    Function
# Name: 		    CheckModule
# Description:	    Checks, if the module exists on the system and loaded
# Parameters:		module name
# Return Values:	
# Requirements:					
# -----------------------------------------------------------------------------
Function CheckModule ([string] $name) {
	if(-not(Get-Module -name $name)) {
		if(Get-Module -ListAvailable | Where-Object { $_.name -eq $name }) {
			Import-Module -Name $name
            write-host "PSsnapin $name ist geladen."
		}
		else { 
            write-host "PSSnapin $name nicht gefunden!" -foregroundcolor Red
            exit
		}
	}
	else {
		write-host "PSsnapin $name ist geladen."
	}
}

write-host @"
===========================================================================
Powershell SnapIns und Module laden
===========================================================================
"@
[string] $strModule = "ActiveDirectory"
CheckModule ($strModule)


Write-Host @"
`n
===========================================================================
Active Directorybenutzer werden nun angepasst...
===========================================================================
"@

# Alle Benutzer aus der Organisationseinheit ausgeben. Ausgelesen wird nur das Attriut ProfilePath
Get-ADUser -SearchBase "OU=w,DC=x,DC=y,DC=z" -Filter "*" -Properties ProfilePath | Foreach {

	# Benutzernamen in die Varible schreiben
    $strSAMAccountName = $_.SamAccountName

	# Falls der Pfad den alten Servernamen enhält, tifft die Abfrage zu.
    if ($_.ProfilePath -like "*$strOldUserProfileServer*") {

		# Neuen Pfad für das servergespeicherte Profil setzen
		Set-ADUser $_ -ProfilePath "\\$strUserProfileServer\$strUserProfilePath\$strSAMAccountName"

		# neuen Pfad für das Remotedesktop-Profile setzen
        $ADSI = [ADSI]('LDAP://{0}' -f $_.DistinguishedName)
        try {
            $ADSI.InvokeSet('TerminalServicesProfilePath',"\\$strRdsProfileServer\$strRdsProfilePath\$strSAMAccountName")
            $ADSI.SetInfo()
        }
		# Falls der Befehl nicht erfolgreich ausgeführt werden kann, wird die Fehlermeldung ausgegeben.
        catch {
            Write-Error $Error[0]
        }
    }
}

pause
