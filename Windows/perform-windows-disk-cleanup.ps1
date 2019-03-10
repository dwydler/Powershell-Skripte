# Datentärgerbereiningung im Hintergrund via Aufgabenplanung

Try{
    $OS = Get-WmiObject Win32_OperatingSystem
    $CleanupName = "StateFlags0032"
    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    
	#Verzeichnisse, die geleert werden sollen.	
	$FoldersWinXP = @("Active Setup Temp Folders","Compress old files", "Content Indexer Cleaner", "Downloaded Program Files","Internet Cache Files", "Memory Dump Files", "Microsoft Office Temp Files ", "Offline Files", "Offline Pages Files", "Office Setup Files", "Old ChkDsk Files", "Recycle Bin", "Remote Desktop Cache Files", "Setup Log Files", "System Restore", "Temporary Files", "Temporary Offline Files", "Uninstall Backup Image", "WebClienr and WebPublisher Cache")

    $FoldersWin7 = @("Active Setup Temp Folders", "Content Indexer Cleaner", "Downloaded Program Files", "GameNewsFiles", "GameStatisticsFiles", "GameUpdateFiles", "Internet Cache Files", "Memory Dump Files", "Offline Pages Files", "Old ChkDsk Files", "Previous Installations", "Recycle Bin", "Service Pack Cleanup", "Setup Log Files", "System error memory dump files", "System error minidump files", "Temporary Files","Temporary Setup Files", "Temporary Sync Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "Windows Error Reporting Archive Files", "Windows Error Reporting Queue Files", "Windows Error Reporting System Archive Files", "Windows Error Reporting System Queue Files", "Windows Upgrade Log Files")
	
	$FoldersWin81 = @("Active Setup Temp Folders", "BranchCache", "Content Indexer Cleaner", "Device Driver Packages", "Downloaded Program Files", "GameNewsFiles", "GameStatisticsFiles", "GameUpdateFiles", "Internet Cache Files", "Memory Dump Files", "Microsoft Office Temp Files", "Offline Pages Files", "Old ChkDsk Files", "Previous Installations", "Recycle Bin", "Service Pack Cleanup", "Setup Log Files", "System error memory dump files", "System error minidump files", "Temporary Files", "Temporary Setup Files", "Temporary Sync Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "User file versions", "Windows Defender", "Windows Error Reporting Archive Files", "Windows Error Reporting Queue Files", "Windows Error Reporting System Archive Files", "Windows Error Reporting System Queue Files", "Windows ESD installation files", "Windows Upgrade Log Files")
	
	$FoldersWin2008R2 = @("Active Setup Temp Folders", "Content Indexer Cleaner", "Downloaded Program Files", "Internet Cache Files", "Memory Dump Files", "Offline Pages Files", "Old ChkDsk Files", "Previous Installations", "Recycle Bin", "Service Pack Cleanup", "Setup Log Files", "System error memory dump files", "System error minidump files", "Temporary Files", "Temporary Setup Files", "Temporary Sync Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "Windows Error Reporting Archive Files", "Windows Error Reporting Queue Files", "Windows Error Reporting System Archive Files", "Windows Error Reporting System Queue Files", "Windows Upgrade Log Files")
	
	$FoldersWin2012R2 = @("Active Setup Temp Folders", "Content Indexer Cleaner", "Device Driver Packages", "Downloaded Program Files", "Internet Cache Files", "Memory Dump Files", "Offline Pages Files", "Old ChkDsk Files", "Previous Installations", "Recycle Bin", "Service Pack Cleanup", "Setup Log Files", "System error memory dump files", "System error minidump files", "Temporary Files", "Temporary Setup Files", "Temporary Sync Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "Windows Error Reporting Archive Files", "Windows Error Reporting Queue Files", "Windows Error Reporting System Archive Files", "Windows Error Reporting System Queue Files", "Windows ESD installation files", "Windows Upgrade Log Files")

	
	# Abfrage welches Betriebssystem läuft
    If($OS.Caption.Contains("Windows XP")) {
        $TempFolders = $FoldersWinXP
    }
    ElseIf($OS.Caption.Contains("Microsoft Windows 7")) {
        $TempFolders = $FoldersWin7
    }
	ElseIf($OS.Caption.Contains("Microsoft Windows 8.1")) {
        $TempFolders = $FoldersWin81
    }
	ElseIf($OS.Caption.Contains("Microsoft Windows Server 2008 R2")) {
        $TempFolders = $FoldersWin2008R2
    }
	ElseIf($OS.Caption.Contains("Microsoft Windows Server 2012 R2")) {
        $TempFolders = $FoldersWin2012R2
    }

	
    For($i=0;$i -lt $TempFolders.Count; $i++) {
        $RegKey = $RegistryPath + "\" + $TempFolders[$i]
        $StateValue = (Get-ItemProperty $RegKey).$CleanupName
        If (-not $StateValue) {
            New-ItemProperty -Path $RegKey -Name $CleanupName -Value "2" -PropertyType "dword" | out-null
        }
        Else {
            Set-ItemProperty -Path $RegKey -Name $CleanupName -Value "2"
        }
    $RegKey = $RegistryPath
    }
    
	# Datentärgerbereiningung ausführen
	CLEANMGR /sagerun:32 | out-null

	
    ForEach($TemFolder in $TempFolders) {
    Write-Host $TemFolder
    }
    Write-Host  "Skriptprüfung bestanden."
	
	# Rechner neustarten
	Restart-Computer
	
    Exit 0
}
Catch {
    Write-Host  "Skriptprüfung fehlerhaft!"
    Exit 1001
}