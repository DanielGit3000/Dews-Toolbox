<#

.Description
    This creates a VM - to get help use "get-help .\install-vm.ps1 -full"

.PARAMETER VMName
    define the VMname 

.PARAMETER VlanId
    define the VlanId  

.EXAMPLE
    Client VM Installation
    .\install_vm.ps1 -VMName HSCLIENT001 -VlanId 138
.EXAMPLE
     Admin VM Installation
    .\install_vm.ps1 -VMName HSCLIENT001 -VlanId 139
#>


param(
    [Parameter(Position = 0,mandatory=$true)]
    [string]$VMName,
    [Parameter(Position = 1,mandatory=$true)]
    [string]$VlanId
    )


Write-host INPUT for VMName: $VMName
Write-host INPUT for VlanID: $VlanId

# Set VM Name, Switch Name, and Installation Media Path.
#$VMName = 'TEST001'
$Switch = 'VMNetwork'
$InstallMedia = 'C:\Install\Windows10_64_UK_23_08_2023.iso'

# Create New Virtual Machine
New-VM -Name $VMName -MemoryStartupBytes 4GB -Generation 2 -NewVHDPath C:\ClusterStorage\$env:COMPUTERNAME-Volume\$VMName.vhdx -NewVHDSizeBytes 25GB -SwitchName $Switch

# Add DVD Drive to Virtual Machine
Add-VMScsiController -VMName $VMName
Add-VMDvdDrive -VMName $VMName -ControllerNumber 1 -ControllerLocation 0 -Path $InstallMedia

# Mount Installation Media
$DVDDrive = Get-VMDvdDrive -VMName $VMName

# Configure Virtual Machine to Boot from DVD
Set-VMFirmware -VMName $VMName -FirstBootDevice $DVDDrive

# Change VLAN ID for VM network Adapter to 138
Set-VMNetworkAdapterVlan -VMName $VMName -Access -VlanId $VlanId