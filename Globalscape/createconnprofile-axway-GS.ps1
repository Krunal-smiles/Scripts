[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$axwaysitecsvfile,
                                            [string]$gsserver_ip="127.0.0.1",
                                            [uint32]$gsserver_port=1100,
                                            [string]$gsserver_user="admin",
                                            [string]$gsserver_site="MySite")

$gsserver_pwd = ""
[System.security.SecureString]$gsserver_pwd = Read-Host -Prompt "Enter password" -AsSecureString
$ps_cred = New-Object System.Management.Automation.PSCredential -ArgumentList $gsserver_user,$gsserver_pwd 

$server = New-Object -ComObject SFTPCOMInterface.CIServer
$server.connect($gsserver_ip,$gsserver_port,$gsserver_user,$ps_cred.GetNetworkCredential().Password)
if ($null -eq $server) {
    Write-Host "Failed to connect $($gsserver_ip) server"
    exit
}

$site_list = $server.Sites()
for ($i = 0; $i -lt $site_list.Count(); $i++) {
    $site = $site_list.Item($i)
    if ($site.Name -eq $gsserver_site) {
        break
    }
}

if ($site.Name -ne $gsserver_site) {
    Write-Host "No such site ($($gsserver_site)) on the server"
    $server.close()
    exit
}

$axwayconns = Import-Csv -Path $axwaysitecsvfile 
Foreach ($axwaycp in $axwayconns) {
    switch ($axwaycp.port) {
        {$_ -eq 21} {
            $cpo = New-Object -ComObject SFTPCOMInterface.CIConnectionProfileParams
            $cpo.User = $axwaycp.username
            $cpo.Name = $axwaycp.name
            $cpo.Protocol = 0
            $cpo.Host = $axwaycp.host
            $cpo.Password = "PuZ4XVCH"
            $cpo.Port = $axwaycp.port
            Write-Host "Creating connection profile $($axwaycp.name)"
            $cpindex = $site.AddConnectionProfile($cpo)
            break
        } 
        {$_ -eq 22} {
            $cpo = New-Object -ComObject SFTPCOMInterface.CIConnectionProfileParams
            $cpo.User = $axwaycp.username
            $cpo.Name = $axwaycp.name
            $cpo.Protocol = 3
            $cpo.Host = $axwaycp.host
            $cpo.Password = "PuZ4XVCH"
            $cpo.Port = $axwaycp.port
            Write-Host "Creating connection profile $($axwaycp.name)"
            $cpindex = $site.AddConnectionProfile($cpo)
            break
        }
        
        Default { Write-Host "Skipping $($axwaycp.name) because of unknown protocol"}
    }
}

$server.close()