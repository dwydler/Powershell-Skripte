#-----------------------------------------------------------[Functions]------------------------------------------------------------

# -----------------------------------------------------------------------------
# Type: 		    Function
# Name: 		    ReplaceUmlaute
# Description:	    Replace all Umlaute and Leerzeichen with Hashtable
# Parameters:		Textstring
# Return Values:	
# Requirements:					
# -----------------------------------------------------------------------------
function ReplaceUmlaute {
    param (
        [Parameter(Mandatory=$True)]
        [string] $strText
    )


    # create HashTable with replace map
    $characterMap = @{}
    $characterMap.([Int][Char]'ä') = "ae"
    $characterMap.([Int][Char]'ö') = "oe"
    $characterMap.([Int][Char]'ü') = "ue"
    $characterMap.([Int][Char]'ß') = "ss"
    $characterMap.([Int][Char]'Ä') = "Ae"
    $characterMap.([Int][Char]'Ü') = "Ue"
    $characterMap.([Int][Char]'Ö') = "Oe"
    $characterMap.([Int][Char]'ß') = "ss"
    
    # Replace chars
    ForEach ($key in $characterMap.Keys) {
        $strText = $strText -creplace ([Char]$key),$characterMap[$key] 
    }
 
    # return result
    $strText
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

ReplaceUmlaute -strText "ÄÖÜöäü"