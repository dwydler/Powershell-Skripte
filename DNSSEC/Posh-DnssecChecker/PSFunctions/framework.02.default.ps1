function ReplaceBatchVariables {
    param (
        [parameter(Position=0)]
        [string] $StringPath
    )

    # Replace all batch variables
    if ($StringPath -match "%ALLUSERSPROFILE%") {
        $StringPath = $StringPath.Replace("%ALLUSERSPROFILE%", "$env:ALLUSERSPROFILE")
    }
    elseif ($StringPath -match "%windir%") {
        $StringPath = $StringPath.Replace("%windir%", "$env:windir")
    }
    elseif ($StringPath -match "%SystemRoot%") {
        $StringPath = $StringPath.Replace("%SystemRoot%", "$env:systemroot")
    }
    elseif ($StringPath -match "%PROGRAMFILES%") {
        $StringPath = $StringPath.Replace("%PROGRAMFILES%", "$env:PROGRAMFILES")
    }
    elseif ($StringPath -match "%ProgramData%") {
        $StringPath = $StringPath.Replace("%ProgramData%", "$env:ProgramData")
    }

    return $StringPath
}


Function Get-UnusedDriveLetter {
	
    #
    Param (
		[Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
		[switch] $AsString = $false
	)

    # Determine all single-letter drive names.
    [array] $aTakenDriveLetters = (Get-PSDrive).Name -like '?'


    # Find the first unused drive letter.
    [char] $chFirstUnusedDriveLetter = [char[]] (0x41..0x5a) | Where-Object { $_ -notin $aTakenDriveLetters } | Select-Object -first 1

    #
    if ($AsString -eq $true) {
        return $chFirstUnusedDriveLetter.ToString()
    }
    else {
        return $chFirstUnusedDriveLetter
    }
}


function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}
