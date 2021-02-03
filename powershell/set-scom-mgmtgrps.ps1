[CmdletBinding()]
param([Parameter(Mandatory=$True,Position=1)][string]$csvfile)

$computers = Import-Csv -Path $csvfile

foreach($pc in $computers){
    try {
        #Invoke-Command -ComputerName $pc.computername -ScriptBlock {(New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').AddManagementGroup($pc.managementGroupName,$pc.ManagementServer,$pc.managementServerPort)}
        (New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg').AddManagementGroup($pc.managementGroupName,$pc.ManagementServer,$pc.managementServerPort)
    } catch {
        Write-host "Failed with exception: $_"
    }
}
