# Import localized string data
$uiLanguage = Import-LocalizedData -BaseDirectory (Join-Path -Path $PSScriptRoot -ChildPath .)

# If you want to force the script to look for a specific UI Culture (Spanish, for example):
# $s = Import-LocalizedData -BaseDirectory (Join-Path -Path $PSScriptRoot -ChildPath Localized) -UICulture es-ES

# Access string value by referencing its key
#[System.Windows.Forms.MessageBox]::Show($s.MessageBody, $s.MessageTitle) | Out-Null
