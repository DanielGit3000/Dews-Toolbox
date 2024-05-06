[cmdletbinding()]
Param(
[Parameter(ValuefromPipeline=$true,Mandatory=$false)][string[]]$computer
)

$computer = @()
#$computer = get-adobject -Filter * -SearchBase "OU=Disabled_Computers,OU=Computer,DC=contoso,DC=local" | where-object ObjectClass -eq computer | Select-Object Name
$computer = "PC001"
Write-Host Run Script for the following Hosts in OU Disabled Computers
$computer 


foreach ($comp in $computer) {    
    try{
        new-pssession -computername $comp
        $ShutdownCommand = Invoke-command -computername $comp -scriptblock {shutdown -s -f -t 00} -ErrorVariable ShutdownError  
    }
    catch{ 
        Write-Host ---ERROR-SHUTDOWN-------------------
        Write-Host computer: $comp
        Write-Host $_.Exception.Message
        Write-Host ------------------------------------
    }
    finally{
        Get-PSSession | Where-Object ComputerName -eq $comp | Remove-PSSession
    }

   try{
        set-adcomputer -Identity $comp -Enabled $false 
    }
    catch{ 
        Write-Host ---ERROR-DISABLE-----------
        Write-Host computer: $comp
        Write-Host $_.Exception.Message
        Write-Host ------------------------------------
    }
}

