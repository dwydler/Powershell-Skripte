Clear-Host

#Arbeitsverzeichnis
cd C:\Jobs\_vmware

write-host @"
===========================================================================
Festplattenkapazität von VDI VMs vergrößern
===========================================================================
Autor:     Daniel Wydler
Script:    Sicherung der Konfiguration aller ESXi Server über das jeweilige
           vCenter Servers.
Umgebung:  VMWare vCenter Server 6.7, VMWare vSphere ESXi 6.5, 
           VMWare PowerCli 11.3.0
`n
"@

<#
===========================================================================
Powershell Variable und Konstante
===========================================================================
#>
[array] $aVMWareVcenterHost = @("vcenter01.abc.de", "vcenter02.abc.de")
[string] $strVMWareVcenterProtocol = "https"

[string] $strVmWareBackupPath = "\\fqdn\sicherungen\vmware-esxi"
[string] $strVmWareBackupFolder = Get-Date -Format yyyy-MM-dd_HH-mm-ss


write-host @"
===========================================================================
Powershell SnapIns und Module laden
===========================================================================
"@

try {
    & 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1'
}
catch {
    Write-Host "VMWare PowerCLI Environment konnte nicht eingebunden werden." -ForegroundColor Red
    exit
}

Write-Host @"
`n
===========================================================================
Basisdaten abfragen
===========================================================================
"@

Write-host "Erzeuge das das neue Verzeichnis für die Ablage der Sicherungen."
New-Item "$strVmWareBackupPath\$strVmWareBackupFolder" -ItemType directory


foreach ($strVMWareVcenterHost in $aVmWareVcenterHost) {

Write-Host @"
`n
===========================================================================
Verbindung zum vCenter wird aufgebaut
===========================================================================
"@

Connect-VIServer -Server $strVMWareVcenterHost -Protocol $strVMWareVcenterProtocol


Write-Host @"
`n
===========================================================================
Alle Hosts im vCenter abfragen
===========================================================================
"@

Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath "$strVmWareBackupPath\$strVmWareBackupFolder"

Write-Host @"
`n
===========================================================================
Verbindung zum VMWare vCenter Server wird beendet.
===========================================================================
"@
Disconnect-VIServer -Server $strVMWareVcenterHost -Confirm:$false

}

Write-Host @"
`n
===========================================================================
Vorgang wurde erfolgreich beendet.
===========================================================================
"@
