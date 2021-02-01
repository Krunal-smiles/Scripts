[CmdletBinding()]
param([Parameter(Mandatory=$True,Position=1)][string]$csvfile)

$computers = Import-Csv -Path $csvfile
$array = @()
foreach($pc in $computers){
    $computername=$pc.computername
    
    #Define the variable to hold the location of Currently Installed Programs
    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

    #Create an instance of the Registry Object and open the HKLM base key
    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername)

    #Drill down into the Uninstall key using the OpenSubKey Method
    $regkey=$reg.OpenSubKey($UninstallKey) 

    #Retrieve an array of string that contain all the subkey names
    $subkeys=$regkey.GetSubKeyNames()

    #Open each Subkey and use GetValue Method to return the required values for each
    foreach($key in $subkeys){
        $thisKey=$UninstallKey+"\\"+$key
        $thisSubKey=$reg.OpenSubKey($thisKey)
        $dName=$thisSubKey.GetValue("DisplayName")
        if($dName -eq "Microsoft Monitoring Agent") {
            $obj = New-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername
            $obj | Add-Member -MemberType NoteProperty -Name "Name" -Value $($thisSubKey.GetValue("DisplayName"))
            $obj | Add-Member -MemberType NoteProperty -Name "Version" -Value $($thisSubKey.GetValue("DisplayVersion"))
            #$obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))
            #$obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))
            $array += $obj
        }
    }
}

$array | Format-Table -auto