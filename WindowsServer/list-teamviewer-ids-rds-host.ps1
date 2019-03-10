Clear-Host
Write-host "Domäne\Benutzername -- Teamviewer ID"
Write-host "-------------------------------------"

# Subkeys von HKEY_USERS durchlaufen
Get-ChildItem REGISTRY::HKEY_USERS | Select PSPath, PSChildName | %{
    $intTeamviewerID = Get-ItemProperty -Name 'ClientIDOfTSUser' -Path "$($_.PSPath)\Software\TeamViewer" -ErrorAction Ignore | Select -Expand ClientIDOfTSUser
    if($intTeamviewerID){
        $objUsername = (New-Object System.Security.Principal.SecurityIdentifier($_.PSChildName)).Translate([System.Security.Principal.NTAccount]).Value
        "$objUsername -- $intTeamviewerID"
    }
}

if(-not($objUsername)) {
    Write-Host "Keine Teamviewer IDs gefunden!" -ForegroundColor Red
}

pause