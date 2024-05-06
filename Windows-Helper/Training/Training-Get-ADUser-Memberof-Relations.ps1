###################################################
# Create line by line output

$userlist = get-aduser -filter * | select SamAccountname

foreach ($username in $userlist) {

write-host -foreground Black -BackgroundColor Green '### USERNAME:' $username.SamAccountname
get-aduser -identity  $username.SamAccountname -Properties memberof | select -ExpandProperty memberof | get-adgroup | select-object name 

}


###################################################
### Table Output

Import-Module ActiveDirectory
Get-ADUser -Filter {Enabled -eq $True} -Properties MemberOf |
Select-Object Name, @{Name="Group"; Expression={($_.MemberOf | % {(Get-ADGroup $_).Name}) -join ', '}} |
Format-Table -AutoSize

###################################################
### Export to CSV
# Create an empty array to store user data
$UserList = @()

# Get all Active Directory Users and store in UserList array
Get-ADUser -Filter {Enabled -eq $True} -Properties Name, SamAccountName, SID, memberOf | % {
    $UserData = "" | Select Name, SamAccountName, SID, memberOf
    $UserData.Name = $_.Name
    $UserData.SamAccountName = $_.SamAccountName
    $UserData.SID = $_.SID
    $UserData.memberOf = ($_.memberOf -join ';')
    $UserList += $UserData
}

# Export user data into CSV
$UserList | Export-Csv -Path ‘.\list_user_groups_realations.csv’ -NoTypeInformation
