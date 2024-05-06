[cmdletbinding()]
Param(
[Parameter(ValuefromPipeline=$true,Mandatory=$false)][string[]]$computer
)

$computer = @()
$computer = "VM001","VM002","VM003","VM004"
Write-Host Run Script for the following Hosts in OU Disabled Computers
$computer


foreach ($comp in $computer) {    
    try{
        new-pssession -computername $comp
        $DateCommand = Invoke-command -computername $comp -scriptblock {get-date} -ErrorVariable ShutdownError -ErrorAction Stop  
        $DateCommand
    }
    catch{ 
        Write-Host ---ERROR----------------------------
        Write-Host computer: $comp
        Write-Host $_.Exception.Message
        Write-Host ------------------------------------
    }
}

