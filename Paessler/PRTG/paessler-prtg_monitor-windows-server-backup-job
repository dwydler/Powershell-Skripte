# Test and Demo PowerShell Custom Sensor for PRTG
# Just a dirty hack using Powershell
# Requires: 
# + PowerShell on the local probe
# + enabled WinRM on target hosts
# + WindowsBackup scripting feature on the local probe
# + WindowsBackup scripting feature on target system
# 
# Required Parameters:
# + %device 
# The cretentials being used are the ones with witch the script is invoked (usually the account under which the probe is running). 
# This account need the approiate permissions on the target hosts.
#
# Set Limits for channel to 0.5 to get OK for "0" and error for all others.
#
# Written and Cpoyright by: Andreas Hümmer <andreas.huemmer@elaxy.com> 
# Elaxy BSS GmbH & Co KG 
# 
#
# Version
#  08.03.2014   V 0.1  initial release
#
$DEVICE=$args[0]

$BackupStatus = Invoke-Command -Computername $DEVICE -ScriptBlock { add-Pssnapin Windows.serverbackup; Get-WBSummary }

"<prtg>"
    "<Text>"
       echo $BackupStatus|Select-Object -ExpandProperty PSComputerName
       ## write-host " Last Backup: " -NoNewLine
       ## echo $BackupStatus|Select-Object -ExpandProperty LastBackupTime
       write-host "Last successfull Backup: " -NoNewLine
       echo $BackupStatus|Select-Object -ExpandProperty LastSuccessfulBackupTime
       ## write-host "Next Backup: " -NoNewLine
       ## echo $BackupStatus|Select-Object -ExpandProperty NextBackupTime
    "</Text>"
    "<result>"
        "<channel>"
            "BackupStatus"
        "</channel>"
        "<value>"
            echo $BackupStatus|Select-Object -ExpandProperty LastBackupResultHR
        "</value>"
        "<FLOAT>0</FLOAT>"
        "<CustomUnit>Status</CustomUnit>"
    "</result>"
 "</prtg>"
