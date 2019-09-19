<#
===========================================================================
Paessler PRTG Sensor fuer Veeam Backup Jobs
===========================================================================
Autor:     Daniel Wydler
Script:    veeam-backupjob-status.ps1
Parameter: Veeam Backup Job Name, Servername auf dem Veeam läuft
Version:   0.2
Datum:     11.02.2017
Umgebung:  Windows Server 2012R2 + Veeeam Backup & Replication 9.5U1

Hinweis: Grundlage für das Skript ist folgender Blog:
http://www.vmbaggum.nl/2015/03/monitor-veeam-backup-jobs-with-prtg/
#>

<#
===========================================================================
Powershell Variable und Konstante
===========================================================================
#>
[bool] $strVeeamBackupEntpointJob = $false

[string] $strVeeamBackupServer = ""
[string] $strVeeamBackupJobId = ""
[string] $strVeeamBackupJobName = ""
[string] $strVeeamBackupJobResult = ""
[string] $strVeeamBackupJobSession = ""

<#
===========================================================================
Argumente einlesen
===========================================================================
#>
If ($Args.Count -le 0) {
    Write-host "Keine Argumente übergeben!"
    exit 2;
    }
ElseIf($Args.Count -gt 2) {
    Write-host "Zu viele Argumente übergeben!"
    exit 2;
    }
ElseIf ($Args.Count -eq 1) {
    Write-host "Die Variable %device ist nicht angegeben!"
    exit 2;
    }
Else {
    # Argument Variable zuweisen
    $strVeeamBackupJobName = $Args[0]
    $strVeeamBackupServer = $Args[1]
}

<#
===========================================================================
Hauptprogramm
===========================================================================
#>

#Powershell Remote Session starten
try {
    $PSSession = New-PSSession -ComputerName $strVeeamBackupServer -ErrorAction Stop } catch {
    write-host "Keine Verbindung zu $strVeeamBackupServer möglich!"
    exit 2;
}

#Invoke remote commands
$strVeeamBackupJobResult = Invoke-Command -Session $PSSession -ScriptBlock { 

	#Passing Variable
	param($strVeeamBackupJobName)

	#Nachladen des Veeam Powershell SnapIn
    try {
	    Add-PSSnapin -Name VeeamPSSnapIn -WarningAction SilentlyContinue -ErrorAction Stop
    } catch {
        #Fehlercode & -meldung zurückgeben.
        return "2:Veeam Powershell Snapin konnte nicht geladen werden."
    }

	#Get the Backup History from the Backup Job
    try {
        $strVeeamBackupJobId = Get-VBREPJob -Name $strVeeamBackupJobName -WarningAction SilentlyContinue -ErrorAction Stop | Select -ExpandProperty Id
        $strVeeamBackupEntpointJob = $true
    }
    catch {
        try {
            $strVeeamBackupJobId = Get-VBRJob -Name $strVeeamBackupJobName -WarningAction SilentlyContinue | Select -ExpandProperty Id
            $strVeeamBackupEntpointJob = $false
        }
        catch {
        
        }
    }
  
    # Überprüft, ob ein Veeam Backup Job gefunden wurde
    if($strVeeamBackupJobId.count -ne 1) {
        # Setzen des Fehlercodes
        $strVeeamBackupJobResult =  "2:Keinen Backup Job gefunden!"
    }
    else {
	    #Get the information from the latest Backup Job
        if($strVeeamBackupEntpointJob -eq $true) {
            $strVeeamBackupJobSession = Get-VBREPSession -WarningAction SilentlyContinue -ErrorAction Stop | Select JobId, Result, CreationTime | `
                ?{$_.JobId -eq $strVeeamBackupJobId} | Sort -Descending -Property "CreationTime" | Select -First 1
        }
        else {
                $strVeeamBackupJobSession = Get-VBRBackupSession -WarningAction SilentlyContinue | Select JobId, Result, CreationTime | `
                    ?{$_.JobId -eq $strVeeamBackupJobId} | Sort -Descending -Property "CreationTime" | Select -First 1
        }
  
        
        # Auswertung des letzten Backup Jobs
	    If ($strVeeamBackupJobSession.Result -eq "Success") { $strVeeamBackupJobResult = "0:" }
        ElseIf ($strVeeamBackupJobSession.Result -eq "None") {$strVeeamBackupJobResult = "0:" }
	    ElseIf ($strVeeamBackupJobSession.Result -eq "Warning") {$strVeeamBackupJobResult = "1:" }
	    Else { $strVeeamBackupJobResult = "2:"}

        # Zeitstempel anhängen
        $strVeeamBackupJobResult += $strVeeamBackupJobSession.CreationTime.ToString("dd.MM.yyyy HH:mm")

    }
	#Variable aus Scriptblock an Hauptskript zurückgeben
	return $strVeeamBackupJobResult

} -Args $strVeeamBackupJobName


# Powershell Remote Session beenden
Remove-PSSession -ComputerName "$strVeeamBackupServer"

# String splitten
$exitcode = $strVeeamBackupJobResult -Split(':')

# Ausgabe für PRTG
write-host $strVeeamBackupJobResult

# Script beenden
exit $exitcode[0]
