# Variables
[string] $strSourceGroup = "NameDerQuellGrueppe"
[string] $strDestinationGroup = "NameDerZielGruppe"

# Main programm
Get-ADGroupMember $strSourceGroup | Select SAMAccountName | ForEach { Add-ADGroupMember $strDestinationGroup -Members $_.SAMAccountName }