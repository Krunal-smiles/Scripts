[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)][string]$axwayxmlfile)

# Read all complete account nodes
$completeaccounts = Select-xml -Path $axwayxmlfile -XPATH "//completeAccount"

# Read all site custom properties entry to build csv header
$siteline = "accountname,name,protocol,transferType,anchor,siteTemplate,maxConcurrentConnections,default"
$sitekeys = $completeaccounts.node.site.customAttributes.customProperties.entry.key | Select-Object -Unique
ForEach ($sitekey in $sitekeys) {
    $siteline = $siteline + "," + $sitekey
}

# Write CSV headers
Set-Content -Path .\sites.csv -Force $siteline
Set-Content -Path .\account.csv -Force "businessUnit,vUser.loginName,vUser.authExternal,vUser.locked,vUser.lastLogin,authByEmail,unlicensed,isUnlicensedAllowedToReply,disabled,id,name,type,usrid,grpid,homeFolder,email,phone,htmlTemplateFolderPath,notes,mappedUser,deliveryMethod,enrollmentTypes,implicitEnrollmentType,customProperties,cert.name,cert.type,cert.usage,cert.isAccountCertificate,cert.certificate"

# Loop through each complete account node
ForEach ($completeaccount in $completeaccounts) {
    # read individual sub node
    $account = $completeaccount.node.account
    $bUnit = $completeaccount.node.businessUnit
    $vUser = $completeaccount.node.virtualUser
    $certs = $completeaccount.node.completeCertificate
    $sites = $completeaccount.node.site

    # remove newline, formfeed and comma character from notes
    $notes = ""
    if ($($account.notes)) {
        $notes = $account.notes.Replace("`n","--").Replace("`r","--").Replace(",","--")
    }

    # build account record
    $accline = "$($bUnit),$($vUser.loginName),$($vUser.authExternal),$($vUser.locked),$($vUser.lastLogin),$($account.authByEmail),$($account.unlicensed),$($account.isUnlicensedAllowedToReply),$($account.disabled),$($account.id),$($account.name),$($account.type),$($account.usrid),$($account.grpid),$($account.homeFolder),$($account.email),$($account.phone),$($account.htmlTemplateFolderPath),$($notes),$($account.mappedUser),$($account.deliveryMethod),$($account.enrollmentTypes),$($account.implicitEnrollmentType),"
    $entries = $account.customAttributes.customProperties.entry
    ForEach ($entry in $entries) {
        $accline = "$($accline) $($entry.key)=$($entry.get_InnerXML())"
    }

    # handle multiple certificate for account
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
    
    # add certificate data to line
    $accline = "$($accline),$($certname),$($certtype),$($certusage),$($certisAC),$($certcert)"
    $accline = $accline.Replace("`n","--").replace("`r","--")
    $accline | Out-File -FilePath .\account.csv -Append -Force -Encoding ascii

    # loop through each transfer site for an account
    Foreach ($site in $sites){
        # build site record
        $siteline = "$($account.name),$($site.name),$($site.protocol),$($site.transferType),$($site.anchor),$($site.siteTemplate),$($site.maxConcurrentConnections),$($site.default)"
        
        # handle custom properties, making sure all properties are in order
        $sitecsattrs = $site.customAttributes.customProperties.entry
        ForEach ($sitekey in $sitekeys) {
            ForEach ($sitecsattr in $sitecsattrs) {
                $match = ""
                if($sitekey -eq $sitecsattr.key) {
                    $match = "1"
                    break;
                }
            }
            if ($match -eq 1) {
                $siteline = $siteline + "," +$sitecsattr.get_InnerXML()
            } else {
                $siteline = $siteline + ","
            }
        }

        # write record in site csv
        $siteline = $siteline.Replace("`n","--").Replace("`r","--")
        $siteline | Out-File -FilePath .\sites.csv -Append -Force -Encoding ascii
    }
}
