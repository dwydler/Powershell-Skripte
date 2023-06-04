<#
Little tool to create for an Javascript file an SRI hash value

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

.DESCRIPTION


.PARAMETER
None

.INPUTS
None
 
.OUTPUTS
Output the html code
 
.NOTES
File:           Posh-SriHashGenerator.ps1
Version:        1.0
Author:         Daniel Wydler
Creation Date:  04.06.2023
 

.COMPONENT
None

.LINK
None

.EXAMPLE
.\Posh-SriHashGenerator.ps1 -FilePath "C:\Temp\test.js" -hashType "sha384"

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

Param (
    [Parameter(
        Mandatory=$true,
        Position=0
    )]
    [string] $FilePath, 

    [Parameter(
        Mandatory=$true,
        Position=1
    )]
    [ValidateSet('sha256', 'sha384', 'sha512')]
    [string] $hashType
)

Clear-Host

#----------------------------------------------------------[Declarations]----------------------------------------------------------

[string] $strJsSourceCode = ""
[string] $strJsText = "<script type=`"text/javascript`" src=`"{0}`" integrity=`"{1}-{2}`" crossorigin=`"anonymous`"></script>"
[string] $strFileContent = ""
[string] $strBase64Hash = ""

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Get-Sha($type) {

    switch($type) {
        "sha256" { return [System.Security.Cryptography.SHA256]::Create() }
        "sha384" { return [System.Security.Cryptography.SHA384]::Create() }
        "sha512" { return [System.Security.Cryptography.SHA512]::Create() }
        
        default { Write-Host "Unsupported SHA hashing algorithm." }
    }
}

#------------------------------------------------------------[Modules]-------------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

if ( -not(Test-Path -Path $FilePath -PathType Leaf) ) {
    Write-Host "Datei konnte nicht gefunden werden."
}
else {

    $strFileContent = Get-Content $FilePath -Raw
    $sha = Get-Sha $hashType

    try {
        [byte[]] $bytesHash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($strFileContent))
        [string] $strBase64Hash = [System.Convert]::ToBase64String($bytesHash)
    
        $strJsSourceCode = [string]::format($strJsText, $FilePath, $hashType, $strBase64Hash)
        Write-Host $strJsSourceCode
    }
    finally {
        Clear-Variable -Name sha -Force
        Clear-Variable -Name bytesHash -Force
        Clear-Variable -Name strBase64Hash -Force
    }
}