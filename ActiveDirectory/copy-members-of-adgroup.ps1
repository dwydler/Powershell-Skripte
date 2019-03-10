# Variables
[string] $strSourceGroup = "NameDerQuellGrueppe"
[string] $strDestinationGroup = "NameDerZielGruppe"

# Main process
Get-ADGroupMember $strSourceGroup | Select SAMAccountName | ForEach { Add-ADGroupMember $strDestinationGroup -Members $_.SAMAccountName }