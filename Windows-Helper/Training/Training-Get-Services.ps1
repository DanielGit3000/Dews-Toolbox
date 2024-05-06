Get-Service | Where-Object -Property Status -eq running

Get-Service | Where-Object {$_.Status -eq "running"}

Get-Service | Where-Object -Property StartType -eq auto | Measure-Object
Get-Service | Where-Object -Property StartType -NE manual | Where-Object -Property Status -EQ stopped

get-command | Where-Object -Property CommandType -eq cmdlet
get-command | Where-Object -Property CommandType -eq cmdlet | Measure-Object

Get-ChildItem -path  C:\users\DanielSchramm\ -include *.txt -Recurse -File
Get-ChildItem -path  C:\users\DanielSchramm\ -include * -Recurse -File -Hidden

Get-Command | where-Object CommandType -eq Cmdlet 
Get-Command | where-Object CommandType -eq Cmdlet | Where-Object -Property Name -Like "set-*"

Get-Command | where-Object CommandType -eq Cmdlet | Where-Object -Property Name -Like *
Get-Command | where-Object CommandType -eq Cmdlet | Where-Object -Property Module -Like *

Get-ChildItem -Path .\ -Include *.log -file -Recurse | Get-Content 
Get-ChildItem -Path .\ -Include *.log -file -Recurse | Write-Host 
Get-ChildItem -Path .\ -Include * -hidden -Recurse | Write-Host 
Get-ChildItem -Path .\ -Include * -Filter * -hidden -Recurse -WarningAction Ignore -ErrorAction Ignore| Write-Host 

#Base64 Encoding of a file
$file = "c:\file.txt"
$data = Get-Content $file
[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($data)) | Out-File -Encoding "ASCII" encodedfile.txt
Get-ChildItem decodedfile.txt

# Get-member 
Get-Command | Get-Member -Name *
Get-Command | Get-Member -MemberType *
Get-Command | Get-Member -View *
# :)
get-localuser | get-member

#User managment
get-localuser
get-localuser -sid asdfasdfasfdasdfasdfasdf234234234234234
Get-LocalUser | Select-Object Name,SID
Get-LocalUser | Where-Object -Property passwordrequired -match false | Select-Object name
Get-LocalGroups

#Networking
Get-NetIPAddress
Get-NetTCPConnection
Get-NetTCPConnection | Where-Object -Property State -eq Listen
Get-NetTCPConnection | Where-Object -Property LocalPort -eq 445

#Patchmanagment
Get-hotfix 
Get-hotfix | where-object -Property hotfixid -eq KB5020613

#Search in files
Get-ChildItem -Recurse -File -Include *.txt | Select-String -Pattern blah


