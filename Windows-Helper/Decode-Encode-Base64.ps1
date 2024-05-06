$StringMsg = "username"
# Gets the bytes of String
$StringBytes = [System.Text.Encoding]::Unicode.GetBytes($StringMsg)
# Encode string content to Base64 string
$EncodedString =[Convert]::ToBase64String($StringBytes)
Write-Host "Encode String: " $EncodedString

# Decode String from Base64 string
$DecodedString = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedString))
Write-Output $DecodedString

$StringMsg = "*password"
# Gets the bytes of String
$StringBytes = [System.Text.Encoding]::Unicode.GetBytes($StringMsg)
# Encode string content to Base64 string
$EncodedString =[Convert]::ToBase64String($StringBytes)
Write-Host "Encode String: " $EncodedString

# Decode String from Base64 string
$DecodedString = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedString))
Write-Output $DecodedString