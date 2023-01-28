#-----------------------------------------------------------[Functions]------------------------------------------------------------
function ReplaceBatchVariables {
    param (
        [parameter(
            Mandatory=$true,    
            Position=0)
        ]
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

#-----------------------------------------------------------[Execution]------------------------------------------------------------

ReplaceBatchVariables -StringPath $MsDefenderExclusionItem
