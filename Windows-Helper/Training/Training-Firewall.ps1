#All Allow Rule Displaynames
$rrules = Get-NetFirewallRule | Where-Object {($_.Action -eq 'Allow') -and ($_.DisplayName -like '*')} 
#$rules
$rrules | ForEach-Object {Write-host -ForegroundColor Yellow -BackgroundColor Green ($_.DisplayName) }
$rrules | ForEach-Object {(get-netfirewallrule -DisplayName ($_.DisplayName) | Get-NetFirewallApplicationFilter).apppath}

#All Allow Rules
Get-NetFirewallRule | Where-Object {($_.Action -eq 'Allow') -and ($_.DisplayName -like '*') -and ($_.Profile -notlike '*Public*' )}
(Get-NetFirewallRule | Where-Object {($_.Action -eq 'Allow') -and ($_.DisplayName -like '*') }).Profile

#Only Private and Public Allow Rules
(Get-NetFirewallRule | Where-Object {($_.Action -eq 'Allow') -and ($_.DisplayName -like '*') -and ($_.Profile -notlike '*Domain*' )}).Profile
$prules = (Get-NetFirewallRule | Where-Object {($_.Action -eq 'Allow') -and ($_.DisplayName -like '*') -and ($_.Profile -notlike '*Domain*' )})
Write-host $prules
Write-host Firewall Rule Count: $prules.Count
