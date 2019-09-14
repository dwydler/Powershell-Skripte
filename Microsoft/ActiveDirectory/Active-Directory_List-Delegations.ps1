Clear-Host
 
[int] $intCounter = 0
[int] $intModuloTeiler = 15
[string] $strADDomainDN = $null
[string] $strADDomainForest = $null
[string] $strOrganizationUnit = $nulll
[string] $strGroupName = "GRUPPENNAME, NACHDEM GESUCHT WERDEN SOLL"
[array] $arrOrganizationUnits = @()
 
$SearchResults = New-Object System.Collections.Generic.List[object]
 
 
# Auslesen des DistinguishedName der Active Directory Domäne
$strADDomainDN = (Get-ADDomain).DistinguishedName
 
# Auslesen des Forest des Active Directory
$strADDomainForest = (Get-ADDomain).Forest
 
# Auslesen aller Organisationseinheiten
$arrOrganizationUnits = (Get-ADOrganizationalUnit -Filter * -SearchBase $strADDomainDN).DistinguishedName | Sort-Object
 
 
Write-Host "Active Directory wird durchsucht. Bitte warten..."
ForEach ($strOrganizationUnit in $arrOrganizationUnits) {
 
    # Ausgabe des Fortschitts in Prozent, Berechnung erfolgt auf der maximalen Anzahl von Organisationseinheiten.
    # Die Variable $intModuloTeiler legt fest, wie oft eine Ausgabe erfolgt.
    if($intCounter % ([Math]::Round($arrOrganizationUnits.Count/$intModuloTeiler)) -eq 0) {
        write-host $(([Math]::Round($intCounter*100/$arrOrganizationUnits.count, 0) -as "String") +"%..") -NoNewline
    }
 
    (Get-Acl -Path "AD:\$strOrganizationUnit").Access | Select IdentityReference, IsInherited, ActiveDirectoryRights | `
        ? IdentityReference -like "*$strGroupName*" | ? IsInherited -eq $false | ForEach {
 
        $obj = New-Object Psobject -Property @{
	        "Organisationseinheit" = $strOrganizationUnit
	        "Gruppe" = $_.IdentityReference
            "Vererbt" = $_.IsInherited
            "Rechte" = $_.ActiveDirectoryRights
        }
        $SearchResults.add($obj)
    }
    $intCounter++;
 
    if ($intCounter -eq $arrOrganizationUnits.Count) {
        Write-Host "100%"
    }
}
Write-Host "`nDie Suche im Active Directory ist abgeschlossen."
pause
 
# Ausgabe des Suchergebnisses
$SearchResults | Select-Object -Property Organisationseinheit, Gruppe, Vererbt, Rechte | Out-Gridview -Title "Suchergebnis aus dem Active Diretory $strADDomainForest"
