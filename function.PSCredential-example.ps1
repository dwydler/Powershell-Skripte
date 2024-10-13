#Requires -Version 2.0
Set-StrictMode -Version Latest

function global:Get-PSCredential {

<#
.SYNOPSIS
	Returns PSCredential object.
.DESCRIPTION
	Returns PSCredential object from file. Prompts user for credentials and creates file if not present.
	Credential store will be created within the user profile ($env:AppData\PSCredentials)	
.PARAMETER UserName
	UserName format: [[<hostname or NetBIOS domain name>\]<UserName>]
.EXAMPLE
	Get-PSCredential
	If no UserName is given, the script promts for credentials.
.EXAMPLE
	Get-PSCredential user1
	The script promts for the password if no PSCredential file exists.
.EXAMPLE
	Get-PSCredential host1\user1
	The script promts for the password if no PSCredential file exists.
.EXAMPLE
	Get-PSCredential domain1\user1
	The script promts for the password if no PSCredential file exists.
.EXAMPLE
	Read-Host 'Please enter username' | Get-PSCredential
	Pipeline input is accepted.
.INPUTS
	UserName as String
.OUTPUTS
	PSCredential object
.LINK
	German Blog : http://www.powercli.de
	English Blog: http://www.thomas-franke.net
.NOTES
	NAME:     Get-PSCredential.ps1
	VERSION:  1.2a
	AUTHOR:   thomas.franke@sepago.de / sepago GmbH
	LASTEDIT: 11.04.2014
#>

	[CmdletBinding()]
	Param(
		[Parameter(ValueFromPipeline=$True)]
		[string] $UserName
	)

	function Import-PSCredential {
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $PSCredentialFile
		)

		try {
			$HashTable		= Import-Clixml $PSCredentialFile
			$PSCredential	= New-Object System.Management.Automation.PSCredential $HashTable.UserName, $($HashTable.Password | ConvertTo-SecureString)
		} 
		catch {
			throw "Content of Credential file $PSCredentialFile is not valid. Please delete the file and run the script again."		
		}
		
		# Returns the values of the object
		Write-Output $PSCredential
	}


	function New-PSCredential {
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)]
			[AllowEmptyString()]
			[string] $PSCredentialFile,
			
			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $PSCredentialStorePath,

			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[string] $PSCredentialFileSuffix
		)

		try {
			$PSCredential = Get-Credential $UserName -ErrorAction Stop
		}
		catch {
			throw "Get-Credential was canceled by the user."
		}

		try {
			$HashTable = @{
				UserName = $PSCredential.UserName;
				Password = $PSCredential.Password | ConvertFrom-SecureString
			}
		}
		catch {
			throw "Password is empty. This is not allowed for security reasons."
		}
	
		# Assign values to each variable
		$UserDomain				= $PSCredential.GetNetworkCredential().Domain
		$PSCredentialSubPath	= "$PSCredentialStorePath\$UserDomain"
		$PSCredentialFile		= "$PSCredentialStorePath\$($PSCredential.UserName).$PSCredentialFileSuffix"
		
		if ((Test-Path $PSCredentialSubPath) -eq $False) { 
			New-Item $PSCredentialSubPath -type directory | Out-Null 
		}

		# Corrects PowerShell 2.0 issue with Get-Content: UserName starts with "\" if no domain is given
		if ($PSCredential.GetNetworkCredential().Domain -eq "") {
			$HashTable.UserName = $HashTable.UserName.Split("\")[-1]
		}
		
		$HashTable | Export-Clixml $PSCredentialFile

		# Returns the values of the object
		Write-Output $PSCredential
	}

	# Assign values to each variable
	$PSCredentialFileSuffix	= "PSCredential"
	$PSCredentialStorePath	= ".\PSCredentials\$($env:username)"

	if ((Test-Path $PSCredentialStorePath) -eq $False) {
		New-Item $PSCredentialStorePath -type Directory | Out-Null
	}

	$PSCredentialFile = "$PSCredentialStorePath\$UserName.$PSCredentialFileSuffix"
	if ((Test-Path $PSCredentialFile) -eq $True)  {
		$PSCredential = Import-PSCredential $PSCredentialFile
	} 
	else {
		$PSCredential = New-PSCredential $UserName $PSCredentialStorePath $PSCredentialFileSuffix
	}

	# Returns the values of the object
	Write-Output $PSCredential
}
