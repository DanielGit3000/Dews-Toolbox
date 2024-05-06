#######################################
## Deployment 2-Node Azure Stack HCI ##
#######################################


#region #################################################### Variables ####################################################


$member1 = "HSSRVHYP01"
$member2 = "HSSRVHYP02"
$clustername = "HSSRVCLU01"
$clusterip = "10.0.0.10"
#endregion


#region #################################################### Preperation ####################################################


## install Rolles & Features & run Windows-Updates ##
Install-WindowsFeature -name Failover-Clustering, Data-Center-Bridging, Hyper-V, RSAT-Clustering-PowerShell, Hyper-V-PowerShell -IncludeManagementTools -IncludeAllSubFeature -Restart


## rename NICs ##
Get-NetAdapter | Sort-Object Name, MacAddress | ft Name, InterfaceDescription, Status, MacAddress


## check TimeZone ##
Set-TimeZone -Id "W. Europe Standard Time" -PassThru
#endregion


#region #################################################### configure Network ####################################################


## Disable NetAdapter PowerManagement ##
Invoke-Command -ComputerName (hostname) -ScriptBlock {
    $NICs = Get-NetAdapter -Physical
        foreach($Nic in $NICs ){
            $PowerSaving = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi | ? { $_.InstanceName -match [Regex]::Escape($Nic.PnpDeviceID)}
            if($PowerSaving.Enable){
                $PowerSaving.Enable = $false
                $PowerSaving | Set-CimInstance}
        }
}


#region SET-Team for MGMT
#(Infos: https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v-virtual-switch/rdma-and-switch-embedded-teaming)
New-VMSwitch -Name MGMT -NetAdapterName MGMT1, MGMT2 -EnableEmbeddedTeaming $true -AllowManagementOS $false -EnableIov $false
Set-VMSwitchTeam -Name MGMT -LoadBalancingAlgorithm HyperVPort
Add-VMNetworkAdapter -ManagementOS -SwitchName MGMT -Name MGMT
Rename-NetAdapter -Name "*(MGMT)*" -NewName MGMT
Enable-NetAdapterRsc -Name MGMT1, MGMT2, MGMT
Enable-NetAdapterRss -Name MGMT1, MGMT2, MGMT
Enable-NetAdapterVmq -Name MGMT1, MGMT2
Set-VMSwitch -Name MGMT -EnableSoftwareRsc $True
#endregion


#region SET-Team for VMNetwork (2 NICs)
#(Infos: https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v-virtual-switch/rdma-and-switch-embedded-teaming)
New-VMSwitch -Name VMNetwork -NetAdapterName VMNetwork1, VMNetwork2 -EnableEmbeddedTeaming $true -AllowManagementOS $false -EnableIov $false
Set-VMSwitchTeam -Name VMNetwork -LoadBalancingAlgorithm HyperVPort
Enable-NetAdapterRsc -Name VMNetwork1, VMNetwork2
Enable-NetAdapterRss -Name VMNetwork1, VMNetwork2
Enable-NetAdapterVmq -Name VMNetwork1, VMNetwork2
Set-VMSwitch -Name VMnetwork -EnableSoftwareRsc $True
#endregion


#region IP-Config for SMB-NICs
## redundant SMB-Connect ##
#Node1:
New-NetIPAddress –InterfaceAlias SMB1 -IPAddress 192.168.100.10 –PrefixLength 24; 
New-NetIPAddress –InterfaceAlias SMB2 -IPAddress 192.168.200.10 –PrefixLength 24; 
Set-NetAdapter –Name SMB1 -VlanID 100 -Confirm:$false; 
Set-NetAdapter -Name SMB2 -VlanID 200 -Confirm:$false; 
Disable-NetAdapterBinding –InterfaceAlias SMB1, SMB2 –ComponentID ms_tcpip6; 
Get-NetAdapter SMB* | Set-DNSClient –RegisterThisConnectionsAddress $False
#Node2:
New-NetIPAddress –InterfaceAlias SMB1 -IPAddress 192.168.100.20 –PrefixLength 24; 
New-NetIPAddress –InterfaceAlias SMB2 -IPAddress 192.168.200.20 –PrefixLength 24; 
Set-NetAdapter –Name SMB1 -VlanID 100 -Confirm:$false; 
Set-NetAdapter -Name SMB2 -VlanID 200 -Confirm:$false; 
Disable-NetAdapterBinding –InterfaceAlias SMB1, SMB2 –ComponentID ms_tcpip6; 
Get-NetAdapter SMB* | Set-DNSClient –RegisterThisConnectionsAddress $False
#endregion


## SMB-NICs disable NetBIOS ##
Invoke-Command -ComputerName (hostname) -ScriptBlock {
    $Adapters = (Get-WmiObject win32_Networkadapterconfiguration)
    $NICs = Get-NetAdapter -Name 'SMB*'
    foreach($NIC in $NICs) {
        foreach($Adapter in $Adapters) {
            if($NIC.InterfaceDescription -eq $Adapter.description) {
            $Adapter.settcpipnetbios(2) }
        }
    }
}


## Set Mellanox specific Options ##
Set-NetAdapterAdvancedProperty -Name SMB* -DisplayName 'Dcbxmode' -DisplayValue 'Host in charge' -Verbose; Set-NetAdapterAdvancedProperty -Name SMB* -DisplayName 'NetworkDirect Technology' -DisplayValue 'RoCEv2' -Verbose
#endregion


#region #################################################### RoCEv2/RDMA ####################################################


## Enable RDMA on SMB-NICs ##
Get-NetAdapterrdma | ? {$_.Name -NotLike 'SMB*' -and $_.Enabled -eq  $true} | Set-NetAdapterRdma -Enabled $false -Verbose; Get-NetAdapterrdma | ? {$_.Name -like 'SMB*' -and $_.Enabled -eq  $false} | Set-NetAdapterRdma -Enabled $true -Verbose


## remove old RoCE-Config ##
#Get-NetQosTrafficClass | Remove-NetQosTrafficClass; Get-NetQosPolicy | Remove-NetQosPolicy -Confirm:$false


## DCBx disable ##
Set-NetQosDcbxSetting -Willing $false -Confirm:$false -Verbose


## define PFC-Classes (PFC=Priority Flow Control)
New-NetQosPolicy 'SMB Direct' -NetDirectPortMatchCondition 445 -PriorityValue8021Action 3
New-NetQosPolicy 'SMB' -SMB -PriorityValue8021Action 3
New-NetQosPolicy 'Cluster' -Cluster -PriorityValue8021Action 6


## configure ETS (ETS=Enhanced Transmission Selection)
New-NetQosTrafficClass 'SMB Direct' -Priority 3 -Bandwidthpercentage 50 -Algorithm ETS
New-NetQosTrafficClass 'Cluster' -Priority 6 -Bandwidthpercentage 1 -Algorithm ETS


## enable PFC on Priority 3
Disable-NetQosFlowControl 0,1,2,3,4,5,6,7; Enable-NetQosFlowControl -Priority 3 -Verbose


## enable QoS on SMB-NICs
Disable-NetAdapterQos -Name '*' -Verbose ; Enable-NetAdapterQos -Name 'SMB*' -Verbose


## recheck RoCE-Config ##
Get-NetAdapterRdma | Sort-Object Name
Get-NetQosTrafficClass | Sort-Object Priority
Get-NetQosFlowControl
Get-NetAdapterQos | Sort-Object Enabled,Name
#endregion


#region #################################################### System ####################################################


## Powersaving to High-Performance-Profile ##
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
#endregion
#region #################################################### Failover-Clustering ####################################################
## validate Failover-Cluster ##Test-Cluster -Node $member1, $member2 -Include "Hyper-V Configuration", Inventory, Network, "Storage Spaces Direct", "System Configuration" -Verbose## create Failover-Cluster ##New-Cluster -Name $clustername -Node $member1, $member2 -StaticAddress $clusterip -NoStorage -Verbose## rename Clusternetwork ##Get-ClusterNetwork | FT Name, Address, Role, State
(Get-ClusterNetwork -Name "Cluster Network 1").Name = "SMB1-Network"
(Get-ClusterNetwork -Name "Cluster Network 2").Name = "SMB2-Network"
(Get-ClusterNetwork -Name "Cluster Network 3").Name = "MGMT-Network"
## configure ClusterQuorum ##   #File-Share wird auf einem externen System erstellt, dem Knoten- & Cluster-Objekt wird Vollzugriff auf das Share und das Filesystem gegeben   #Einbindung des File-Shares im Failovercluster-Manager   #Set-ClusterQuorum -FileShareWitness \\X.X.X.X\Quorum$## resize CSVBlockCache ##Get-Cluster | ft BlockCacheSize -AutoSize(Get-Cluster).BlockCacheSize = 8192## reconfig ResiliencyDefaultPeriod ##Get-Cluster | ft ResiliencyDefaultPeriod(Get-Cluster).ResiliencyDefaultPeriod = 30## reconfig VM Load Balancer ##Get-Cluster | ft AutoBalancerLevel(Get-Cluster).AutoBalancerLevel = 2## configure Live-Migration settings ##Get-ClusterNode |% {Invoke-Command -ComputerName $_ {Set-VMHost -VirtualMachineMigrationPerformanceOption SMB; Set-VMHost -MaximumVirtualMachineMigrations 4}}#endregion#region #################################################### Storage Spaces Direct ####################################################
## enable S2D ##Enable-ClusterS2D -Autoconfig $true -Confirm:$false -Verbose## show Storage-Pool ##Get-Storagepool S2D* | FT FriendlyName, FaultDomainAwarenessDefault, OperationalStatus, HealthStatusGet-StorageSubSystem Clu* | Get-PhysicalDisk | Sort-Object MediaType, Usage -Descending | FT FriendlyName, Model, MediaType, UsageGet-StorageSubSystem Clu* | Get-PhysicalDisk | Group-Object Usage | FT Count, Name## show Storage-Tiering ##Get-StorageTier -FriendlyName *MirrorOn* | FT FriendlyName, ResiliencySettingName, MediaType, PhysicalDiskRedundancy, NumberOfDataCopies## create Volumes ###Capacity-Planning: 3x 3200GB -> 9600GB - 50GB Cluster-Performance-History -> 9550GB /2 -> 4775GB => 4446 GiB nutzbare NVMe-Kapazität (2223 GiB pro Volume)#Each Node one identical Volume with the Node-NameGet-ClusterNode |% {New-Volume -FriendlyName "$_-Volume" -StoragePoolFriendlyName S2D* -FileSystem CSVFS_ReFS -StorageTierfriendlyNames NestedMirrorOnSSD -StorageTierSizes 2223GB}Get-ClusterNode |% {(Get-ClusterSharedVolume -Name *$_*).Name = "$_-Volume"}; (Get-ClusterResource -Name *ClusterPerformanceHistory*).Name = "ClusterPerformanceHistory"      #Virtual-Disks können alternativ auch im Failovercluster-Manager umbenannt werden

#Move Volumes to correct Node
Get-ClusterSharedVolume -Name $member1* | ? {$_.OwnerNode -notlike $member1} | Move-ClusterSharedVolume -Node $member1; Get-ClusterSharedVolume -Name $member2* | ? {$_.OwnerNode -notlike $member2} | Move-ClusterSharedVolume -Node $member2; Get-ClusterSharedVolume | ft Name, OwnerNode
## Enable Volume/CSV Balancer ##(get-cluster).CsvBalancer = 1


## StorageHealth-Service Settings ##
#Set in WAC to the next 10% Step
#Activate the Pool-Reserve-Capacity-Check
Get-StorageSubSystem Cluster* | Get-StorageHealthSetting -Name System.Storage.StoragePool.CheckPoolReserveCapacity.Enabled
Get-StorageSubSystem Cluster* | Set-StorageHealthSetting -Name System.Storage.StoragePool.CheckPoolReserveCapacity.Enabled -Value True#endregion#region #################################################### Windows Admin Center (WAC) ####################################################
## WAC installieren auf MGMT-Server, MGMT-VM oder WAC-VM #### Cluster-Objekt dem WAC hinzufügen #### Im AD der OU des Cluster-Objektes das Recht zum Erstellen & Löschen von Computerobjekten erteilen #### CAU im Cluster-Manager im WAC testen #### ggf. (bei Rechteproblemen) RBAC für Knoten- & Cluster Objekte im WAC konfigurieren (https://4sysops.com/archives/windows-admin-center-role-based-access-control/) ##

## ggf. (bei Rechteproblemen) Kerberos Constrained Delegation im AD konfigurieren (für Knoten- & Cluster Objekte)

## Selbastaktualisierungsmodus im Failovercluster-Manager für CAU deaktivieren ##
#endregion#################################################################################################################################################################################################################################region #################################################### Show Cluster Health ####################################################
## On Failure/Reboot #########################Get-StorageJobGet-VirtualDiskGet-PhysicalDiskGet-HealthFault
## as a 3 sec loop ##do {Get-StorageJob ; Get-VirtualDisk | ft ; Get-PhysicalDisk | where Operationalstatus -ne OK | ft ; sleep 3} while($true)## as a all-in-one command ##Get-StorageJob ; Get-Virtualdisk | where OperationalStatus -ne OK | ft ; Get-PhysicalDisk | where Operationalstatus -ne OK | ft#endregion#################################################################################################################################################################################################################################region #################################################### Features on Demand - for Windows Core Version ####################################################

##Install (reboot is required)
Add-WindowsCapability -Online -Name ServerCore.AppCompatibility*

##Check if installed
Get-WindowsCapability -Online -Name ServerCore.AppCompatibility* | fl Name, State


##PowerShell-ISE
powershell_ise.exe

##File-Explorer
explorer.exe

##Task-Manager
taskmgr

##Network-Connections
ncpa.cpl

##Device-Manager
devmgmt.msc

##Disk-Manager
diskmgmt.msc

##Notepad
notepad

##Registry-Editor
regedit

##MMC
mmc#endregion#region #################################################### some Get commands ####################################################
#HDD/SSD anzeigenGet-StorageSubSystem Clu* | Get-PhysicalDisk | Sort-Object MediaType -Descending | FT FriendlyName, Model, MediaTypeGet-StorageSubSystem Clu* | Get-PhysicalDisk | Group-Object MediaType | FT Count, Name#Cache-Devices anzeigenGet-StorageSubSystem Clu* | Get-PhysicalDisk | Sort-Object MediaType -Descending | FT FriendlyName, Model, MediaType, Usage#List Disks from each Node
Get-PhysicalDisk -PhysicallyConnected -StorageNode(Get-StorageNode)[1]
#Fault-Domains anzeigenGet-ClusterFaultDomain#Volumes anzeigenGet-VolumeGet-ClusterSharedVolume#Hyper-V-Einstellungen anzeigenGet-VMHost | FT VirtualHardDiskPath, VirtualMachinePathGet-VMSwitch#Netzwerkeinstellungen anzeigenGet-NetAdapter | FT Name, Status, LinkSpeed, Address#start RebalanceOptimize-StoragePool -FriendlyName S2D*
#pro VM die letzten 5 MinGet-StorageQoSFlow#pro Volume die letzten 5 MinGet-StorageQoSVolume#Bug bei 2-Node -> Reboot = Detatch von Volumes (Windows Server 2016)Enable-StorageMaintenanceMode#Storage Health Report
Get-ClusterPerformanceHistory#Is something wrong?Get-HealthFault#endregion#region #################################################### Deinstall/Remove S2D ####################################################
Get-VirtualDisk#Get-VirtualDisk | Remove-VirtualDiskGet-StorageTier#Get-StorageTier | Remove-StorageTierGet-Storagepool -FriendlyName S2D*#Get-Storagepool -FriendlyName S2D* | Remove-StoragePool#Disable-ClusterS2D<#
icm (Get-Cluster -Name (Get-Cluster) | Get-ClusterNode) {
    Update-StorageProviderCache
    Get-StoragePool | ? IsPrimordial -eq $false | Set-StoragePool -IsReadOnly:$false -ErrorAction SilentlyContinue
    Get-StoragePool | ? IsPrimordial -eq $false | Get-VirtualDisk | Remove-VirtualDisk -Confirm:$false -ErrorAction SilentlyContinue
    Get-StoragePool | ? IsPrimordial -eq $false | Remove-StoragePool -Confirm:$false -ErrorAction SilentlyContinue
    Get-StorageTier | Remove-StorageTier    Disable-ClusterS2D
    Get-PhysicalDisk | Reset-PhysicalDisk -ErrorAction SilentlyContinue
    Get-Disk | ? Number -ne $null | ? IsBoot -ne $true | ? IsSystem -ne $true | ? PartitionStyle -ne RAW | % {
        $_ | Set-Disk -isoffline:$false
        $_ | Set-Disk -isreadonly:$false
        $_ | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
        $_ | Set-Disk -isreadonly:$true
        $_ | Set-Disk -isoffline:$true
    }
    Get-Disk |? Number -ne $null |? IsBoot -ne $true |? IsSystem -ne $true |? PartitionStyle -eq RAW | Group -NoElement -Property FriendlyName
} | Sort -Property PsComputerName,Count
#>

Get-Cluster
#Get-Cluster | Remove-Cluster
#endregion