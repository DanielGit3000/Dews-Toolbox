$computer = @()

$computer = "PC001","PC002","PC003"


Write-Host Run Script for the following Hosts in OU Disabled Computers
$computer
  
foreach ($comp in $computer) {    
    try{
        new-pssession -computername $comp
        $ShutdownCommand = Invoke-command -computername $comp -scriptblock {shutdown -r -t 00} -ErrorVariable ShutdownError  -ErrorAction Stop
    }
    catch{ 
        Write-Host ---ERROR-SHUTDOWN-------------------
        Write-Host computer: $comp
        Write-Host --- 
        Write-Host ShutdownError: $ShutdownError
        Write-Host ---
        Write-Host ExceptionMessage: $_.Exception.Message
        Write-Host ------------------------------------
    }
    finally{
        Get-PSSession | Where-Object ComputerName -eq $comp | Remove-PSSession
    }
}