
## TEST WMI 
$strComputer = "comp01"
$colSettings = Get-WmiObject Win32_OperatingSystem -ComputerName $strComputer
$colSettings

$strComputer = "comp02"
$colSettings = Get-WmiObject Win32_OperatingSystem -ComputerName $strComputer
$colSettings


## TEST PS remoting
enter-pssession -computername comp01
enter-pssession -computername '10.0.34.4'

enter-pssession -computername comp02
enter-pssession -computername '10.0.34.5'


## ENABLE WINRM (https listener is not working but i dont give a shit)
Enable-PSRemoting -Force
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
winrm set winrm/config/client '@{TrustedHosts ="10.0.0.50,10.0.34.2,10.0.34.3"}'
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow remoteip=any
cmd.exe /c 'sc config winrm start= auto'
Restart-Service winrm


## ENABLE RemoteRegistry
sc config RemoteRegistry start= delayed-auto
net start RemoteRegistry
netsh firewall set service RemoteAdmin enable

## FIREWALL 
Set-NetFirewallProfile -Profile Domain -Enabled false
Set-NetFirewallProfile -Profile Public, Private -Enabled true