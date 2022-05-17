### Requires CloudBase Powershell-Yaml module
# Provide Directory path to manifests files

[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$rootDir
)

#$rootDir = "C:\Krunal\git-work\winget-pkgs\manifests\m\Microsoft\"

$files = (Get-ChildItem $rootDir -Recurse -File) 
$array = @()
ForEach ($file in $files) {
	$obj = (Get-Content $file.FullName | ConvertFrom-yaml)
	If ($obj.ManifestType -eq "installer") { 
		Foreach ($item in $obj.Installers) {
			$entry = New-Object PSObject

			$entry | Add-Member -MemberType NoteProperty -Name "PackageIdentifier" -Value $obj.PackageIdentifier
			$entry | Add-Member -MemberType NoteProperty -Name "PackageVersion" -Value $obj.PackageVersion
			$entry | Add-Member -MemberType NoteProperty -Name "ManifestVersion" -Value $obj.ManifestVersion
			$entry | Add-Member -MemberType NoteProperty -Name "Platform" -Value "$($obj.Platform)"

			$entry | Add-Member -MemberType NoteProperty -Name "Installer.Platform" -Value "$($item.Platform)"
			$entry | Add-Member -MemberType NoteProperty -Name "MinimumOSVersion" -Value $item.MinimumOSVersion
			$entry | Add-Member -MemberType NoteProperty -Name "InstallerType" -Value $item.InstallerType
			$entry | Add-Member -MemberType NoteProperty -Name "Architecture" -Value $item.Architecture
			$entry | Add-Member -MemberType NoteProperty -Name "InstallerUrl" -Value $item.InstallerUrl
			$entry | Add-Member -MemberType NoteProperty -Name "InstallerSha256" -Value $item.InstallerSha256
			$entry | Add-Member -MemberType NoteProperty -Name "SignatureSha256" -Value $item.SignatureSha256
			$entry | Add-Member -MemberType NoteProperty -Name "PackageFamilyName" -Value $item.PackageFamilyName
			$entry | Add-Member -MemberType NoteProperty -Name "ProductCode" -Value $item.ProductCode
			$entry | Add-Member -MemberType NoteProperty -Name "UnsupportedOSArchitectures" -Value $item.UnsupportedOSArchitectures

			$array += $entry
		}
	}
}

$array | Export-Csv -Delimiter '#' -NoTypeInformation -Path .\Pkgs.csv