function HumanReadableByteSize {

    param (
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [int64] $SizeinBytes
    )


    switch ($SizeinBytes) {
	    { $_ -gt 1TB } { ($SizeinBytes / 1TB).ToString("n2") + " TB"; break}
	    { $_ -gt 1GB } { ($SizeinBytes / 1GB).ToString("n2") + " GB"; break}
	    { $_ -gt 1MB } { ($SizeinBytes / 1MB).ToString("n2") + " MB"; break}
	    { $_ -gt 1KB}  { ($SizeinBytes / 1KB).ToString("n2") + " KB"; break}
	    default {"$SizeinBytes B"}
	}
}

HumanReadableByteSize -SizeinBytes 1048576
HumanReadableByteSize -SizeinBytes 1073741824