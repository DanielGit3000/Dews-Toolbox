###############################
## VMfleet - Azure Stack HCI ##
###############################


#https://www.jfe.cloud/how-to-setup-vmfleet-to-stress-test-your-storage-spaces-direct-deployment/
#https://github.com/microsoft/diskspd/wiki
#https://techcommunity.microsoft.com/t5/azure-stack-blog/vmfleet-2-0-quick-start-guide/ba-p/2824778


#region #################################################### create specific VMfleet Volumes ####################################################


Get-ClusterNode |% {New-Volume -StoragePoolFriendlyName S2D* -FriendlyName $_ -FileSystem CSVFS_ReFS -StorageTierfriendlyNames NestedMirrorOnSSD -StorageTierSizes 2150GB}
New-Volume -StoragePoolFriendlyName S2D* -FriendlyName collect -FileSystem CSVFS_ReFS -StorageTierFriendlyNames NestedMirrorOnSSD -StorageTierSizes 146GB
#endregion


#region #################################################### RDMA Network Test (Live-Migration) ####################################################


New-VM -Name Migrationtest -MemoryStartupBytes 300GB -NoVHD -Generation 2 -Path C:\ClusterStorage\collect; Set-VM Migrationtest -CheckpointType Disabled -AutomaticStartAction Nothing -AutomaticStopAction TurnOff
Start-VM Migrationtest
#endregion


#region #################################################### deploy VMFleet Master-VM ####################################################


New-VHD -Path C:\ClusterStorage\collect\Master.VHDX -Fixed 20GB; New-VM -Name Master -MemoryStartupBytes 8GB -VHDPath C:\ClusterStorage\collect\Master.VHDX -Generation 2 -Path C:\Users\$env:USERNAME\Desktop\Master; Add-VMDvdDrive -VMName Master -Path C:\VMFleet\WS2022EN.iso; Set-VMFirmware -VMName Master -FirstBootDevice (Get-VMDvdDrive -VMName Master);Set-VMProcessor -VMName Master -Count 4; vmconnect localhost Master
Remove-VM -Name Master -Force; Remove-Item -r C:\Users\$env:USERNAME\Desktop\Master
#endregion


#region #################################################### VMFleet 2.0 ####################################################


## Install VMFleet ##
cd C:\VMfleet\diskspd-master\Frameworks\VMFleet; Install-Module -Name "VMFleet"
Import-Module VMFleet
Install-Fleet
cd C:\ClusterStorage\Collect\control


## Deploy VMFleet ##
$NodeUser = "ad\vmfleet"
$NodePassword = "password"

New-Fleet -BaseVhd C:\ClusterStorage\collect\Master.VHDX -AdminPass Relation123 -ConnectUser $NodeUser -ConnectPass $NodePassword -VMs 1
(Get-ClusterNetwork | ? Name -EQ 'Cluster Network 1' | ? State -EQ Partitioned).Role = 0; Get-ClusterNode |% {Invoke-Command -ComputerName $_ {Disable-NetAdapterBinding -InterfaceAlias "vEthernet (FleetInternal)" –ComponentID ms_tcpip6}}
New-Fleet -BaseVhd C:\ClusterStorage\collect\Master.VHDX -AdminPass Relation123 -ConnectUser $NodeUser -ConnectPass $NodePassword

Set-Fleet -ProcessorCount 2 -MemoryStartupBytes 8GB -MemoryMinimumBytes 8GB -MemoryMaximumBytes 8GB


## Test with VMFleet ##
Start-Fleet
Stop-Fleet

Import-Module VMFleet; Watch-FleetCluster
Start-Process PowerShell -ArgumentList "-noexit", "-Command &{Import-Module VMFleet; Watch-FleetCluster}"
Start-Process PowerShell -ArgumentList "-noexit", "-Command &{Import-Module VMFleet; Watch-FleetCPU}"

Import-Module VMFleet; Set-FleetPause
Start-Process PowerShell -ArgumentList "-Command &{Import-Module VMFleet; Set-FleetPause}"
Clear-FleetPause


Start-FleetSweep -b 8 -t 2 -o 16 -w 30 -d 600000
Start-FleetSweep -b 4 -t 4 -o 16 -w 0 -d 600000
Start-FleetSweep -b 1024 -t 4 -o 8 -w 0 -d 600000

#Measure-FleetCoreWorkload
#endregion


#region #################################################### Remove VMfleet ####################################################


## Delete VMFleet ##
Remove-Fleet


## remove VMfleet Volumes ##
Get-ClusterNode |% { Remove-VirtualDisk -FriendlyName $_ }
Remove-VirtualDisk -FriendlyName collect


## Reenable CSVBalancer ##
(Get-Cluster).CsvBalancer = 1


## resize CSVBlockCache ##
(Get-Cluster).BlockCacheSize = 8192


## Delete VMFleet Folder
#Remove-Item -r C:\VMfleet\
#endregion