<#
.SYNOPSIS
Dieses Skript ruft Informationen zum Job der Windows Server Sicherung ab.

Daniel Wydler

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION

 
.PARAMETER PrtgDevice
Der Gerätename als NetBIOS oder FQDN

 
.INPUTS
Name des abzufragenden Geräts
 
.OUTPUTS
Ausgabe des Status der Sicherung im XML-Format
 
.NOTES
File:           paessler-prtg_monitor-windows-server-backup-job.ps1
Version:        1.1
Author:         Daniel Wydler
Creation Date:  10.03.2019, 10:32 Uhr
Purpose/Change:
 
Date                   Comment
-----------------------------------------------
10.03.2019, 11:12 Uhr  Initial community release
10.03.2019, 17:01 Uhr  Code base revised


.COMPONENT
Windows Server Sicherung auf dem Server, welcher gerpüft werden soll.

.LINK
https://github.com/dwydler/Powershell-Skripte/blob/master/Paessler/PRTG/paessler-prtg_monitor-windows-server-backup-job.ps1

.EXAMPLE
.\paessler-prtg_monitor-windows-server-backup-job.ps1 -PrtgDevice dc01
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Param (
   [Parameter(
        ValueFromPipelineByPropertyName,
        Position=0,
        Mandatory=$true
    )]
   [string] $PrtgDevice
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strXmlOutput = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Set-PrtgError {
	Param (
		[Parameter(Position=0)]
		[string]$PrtgErrorText
	)
	
	@"
<prtg>
  <error>1</error>
  <text>$PrtgErrorText</text>
</prtg>
"@

exit
}

#-------------------------------------------------------------[Modules]------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Prüfe, ob das Feature 'Windows Server Sicherung" auf dem Server installiert ist
$WindowsServerBackupInstalled = Invoke-Command -Computername $PrtgDevice -ScriptBlock { Get-WindowsFeature | where {$_.Name -eq "Windows-Server-Backup"} | Select -ExpandProperty Installed }

if (-not ($WindowsServerBackupInstalled) ) {
    Set-PrtgError -PrtgErrorText "Das Feature 'Windows Server Sicherung ist nicht installiert!"
}
else {
    $WindowsServerBackupStatus = Invoke-Command -Computername $PrtgDevice -ScriptBlock { Get-WBSummary }

    $strXmlOutput = "<?xml version=""1.0"" encoding=""utf-8"" standalone=""yes""?>`n"
    $strXmlOutput += "<prtg>`n"
    $strXmlOutput += "`t<Text>`n"
    $strXmlOutput += "`tLast successfull Backup: "
    $strXmlOutput += "$(get-date $WindowsServerBackupStatus.LastSuccessfulBackupTime -Format "dd.MM.yyyy HH:mm:ss")`n"
    $strXmlOutput += "`t</Text>`n"
    $strXmlOutput += "`t<result>`n"
    $strXmlOutput += "`t`t<Channel>Fehlercode</Channel>`n"
    $strXmlOutput += "`t`t<value>$($WindowsServerBackupStatus.LastBackupResultHR)</value>`n"
    $strXmlOutput += "`t</result>`n"
    $strXmlOutput += '</prtg>'

    # Return Xml
    $strXmlOutput
}
