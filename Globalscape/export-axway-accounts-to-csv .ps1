[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$axwayxmlfile)

$completeaccounts = Select-xml -Path $axwayxmlfile -XPATH "//completeAccount"
Set-Content -Path .\account.csv -Force "businessUnit,vUser.loginName,vUser.authExternal,vUser.locked,vUser.lastLogin,authByEmail,unlicensed,isUnlicensedAllowedToReply,disabled,id,name,type,usrid,grpid,homeFolder,email,phone,htmlTemplateFolderPath,notes,mappedUser,deliveryMethod,enrollmentTypes,implicitEnrollmentType,customProperties,cert.name,cert.type,cert.usage,cert.isAccountCertificate,cert.certificate"
ForEach ($completeaccount in $completeaccounts) {
    $account = $completeaccount.node.account
    $bUnit = $completeaccount.node.businessUnit
    $vUser = $completeaccount.node.virtualUser
    $certs = $completeaccount.node.completeCertificate
    $notes = ""

    if ($($account.notes)) {

        $notes = $account.notes.Replace("`n","--")
        $notes = $notes.Replace("`r","--")
        $notes = $notes.Replace(",","--")
    }

    $fline = "$($bUnit),$($vUser.loginName),$($vUser.authExternal),$($vUser.locked),$($vUser.lastLogin),$($account.authByEmail),$($account.unlicensed),$($account.isUnlicensedAllowedToReply),$($account.disabled),$($account.id),$($account.name),$($account.type),$($account.usrid),$($account.grpid),$($account.homeFolder),$($account.email),$($account.phone),$($account.htmlTemplateFolderPath),$($notes),$($account.mappedUser),$($account.deliveryMethod),$($account.enrollmentTypes),$($account.implicitEnrollmentType),"
    
    $entries = $account.customAttributes.customProperties.entry
    ForEach ($entry in $entries) {
        $fline = "$($fline) $($entry.key)=$($entry.get_InnerXML())"
    }
    
    
        $certname=' '
        $certtype=' '
        $certusage=' '
        $certisAC=' '
        $certcert=' '
    
        ForEach ($cert in $certs) {
            $certname = "$($certname)--$($cert.certificateReference.name.get_InnerXML())"
            $certtype = "$($certtype)--$($cert.certificateReference.type)"
            $certusage = "$($certusage)--$($cert.certificateReference.usage)"
            $certisAC = "$($certisAC)--$($cert.certificateReference.isAccountCertificate)"
            $certcert = "$($certcert)--$($cert.certificate)"
        }
      
        $fline = "$($fline),$($certname),$($certtype),$($certusage),$($certisAC),$($certcert)"
    

    $fline = $fline.Replace("`n","--").replace("`r","--")
    $fline | Out-File -FilePath .\account.csv -Append -Force -Encoding ascii
    #Add-Content -Path .\account.csv "$($fline)"
}
