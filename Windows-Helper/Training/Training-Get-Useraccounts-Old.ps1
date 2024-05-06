
Import-Module ActiveDirectory

get-aduser -properties description, whencreated, whenchanged, enabled, memberof -filter * | Where-Object {($_.enabled -eq $true) -and ($_.whencreated -ge "01.01.2018")} | Format-Table samaccountname, name, whencreated, whenchanged, description | Out-File C:\Scripts\created_since_2018.txt

get-aduser -properties description, whencreated, whenchanged, enabled, memberof -filter * | Where-Object {($_.enabled -eq $false) -and ($_.whenchanged -ge "01.01.2018")} | Format-Table samaccountname, name, whencreated, whenchanged, description | Out-File C:\Scripts\disabled_in_2018.txt

get-aduser -properties description, whencreated, whenchanged, enabled, memberof -filter * | Where-Object {($_.enabled -eq $false)} | Format-Table samaccountname, name | out-file C:\Scripts\disabled.txt
