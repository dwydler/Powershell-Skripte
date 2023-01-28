#Requires -Version 2.0
Set-StrictMode -Version Latest

Function global:Get-PSCredential 
{

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
		[String]$UserName
	)

	Function Import-PSCredential
	{
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[String]$PSCredentialFile
		)

		Try 
		{
			$HashTable		= Import-Clixml $PSCredentialFile
			$PSCredential	= New-Object System.Management.Automation.PSCredential $HashTable.UserName, $($HashTable.Password | ConvertTo-SecureString)
		} 
		Catch 
		{
			Throw "Content of Credential file $PSCredentialFile is not valid. Please delete the file and run the script again."
		}
		Write-Output $PSCredential
	}


	Function New-PSCredential
	{
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$True)]
			[AllowEmptyString()]
			[String]$PSCredentialFile,
			
			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[String]$PSCredentialStorePath,

			[Parameter(Mandatory=$True)]
			[ValidateNotNullOrEmpty()]
			[String]$PSCredentialFileSuffix
		)

		Try 
		{
			$PSCredential = Get-Credential $UserName -ErrorAction Stop
		}
		Catch 
		{
			Throw "Get-Credential was canceled by the user."
		}

		Try
		{
			$HashTable = @{
							UserName = $PSCredential.UserName;
							Password = $PSCredential.Password | ConvertFrom-SecureString
			}
		}
		Catch
		{
			Throw "Password is empty. This is not allowed for security reasons."
		}
	
		$UserDomain				= $PSCredential.GetNetworkCredential().Domain
		$PSCredentialSubPath	= "$PSCredentialStorePath\$UserDomain"
		$PSCredentialFile		= "$PSCredentialStorePath\$($PSCredential.UserName).$PSCredentialFileSuffix"
		
		If ((Test-Path $PSCredentialSubPath) -eq $False)
		{ 
			New-Item $PSCredentialSubPath -type directory | Out-Null 
		}

		# Corrects PowerShell 2.0 issue with Get-Content: UserName starts with "\" if no domain is given
		If ($PSCredential.GetNetworkCredential().Domain -eq "")
		{
		$HashTable.UserName = $HashTable.UserName.Split("\")[-1]
		}
		
		$HashTable | Export-Clixml $PSCredentialFile

		Write-Output $PSCredential
	}

	
	$PSCredentialFileSuffix	= "PSCredential"
	$PSCredentialStorePath	= ".\PSCredentials"
	If ((Test-Path $PSCredentialStorePath) -eq $False)
	{
		New-Item $PSCredentialStorePath -type Directory | Out-Null
	}

	$PSCredentialFile = "$PSCredentialStorePath\$UserName.$PSCredentialFileSuffix"
	If ((Test-Path $PSCredentialFile) -eq $True) 
	{
		$PSCredential = Import-PSCredential $PSCredentialFile
	} 
	Else 
	{
		$PSCredential = New-PSCredential $UserName $PSCredentialStorePath $PSCredentialFileSuffix
	}

	Write-Output $PSCredential
}
