Import-Module ActiveDirectory

# Set the number of days since last logon
$DaysInactive = 35
$InactiveDate = (Get-Date).AddDays(-($DaysInactive))
$Date = (Get-Date -Format yyyy-MM-dd)
$Path = "c:\Reports\InactiveUsersReport"


# Get ALL Users
$AllUsers = Get-ADUser -f * -prop * | 
    select name,dist*,en*,last*te,*when*, `
    @{l="Username"; e={$_.SamAccountName}}, `
    @{l='Last Logon';e={[datetime]::FromFileTime($_.lastlogon)}}, `
    @{l='Last Logon Timestamp';e={[datetime]::FromFileTime($_.lastlogontimestamp)}}

# Find Inactive Users
$InactiveUsers = $AllUsers | 
	    ? {$_.username -notlike '*svc*' `
            -and $_.distinguishedname -notmatch 'Service' `
            -and $_.enabled -eq $true `
            -and $_.'last logon timestamp' -le ($InactiveDate | Get-Date -Format G) `
            -and $_.'last logon' -le ($InactiveDate | Get-Date -Format G) `
            -and $_.lastlogondate -le ($InactiveDate | Get-Date -Format G)}

#Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName

# Export Results to CSV
$InactiveUsers | Export-Csv "$PATH\$Date-InactiveUsers.csv" -NoTypeInformation

# Disable inactive users
foreach ($item in $InactiveUsers) {
    $Distname = $item.DistinguishedName
    Disable-ADAccount -Identity $Distname -WhatIf
    Get-ADUser -Filter { DistinguishedName -eq $Distname } | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, Enabled
    Move-ADObject -Identity $Distname -TargetPath "OU=Disabled,DC=hcl,DC=lmco,DC=com" -WhatIf
}