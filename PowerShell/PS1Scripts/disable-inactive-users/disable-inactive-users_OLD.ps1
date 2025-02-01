Import-Module ActiveDirectory

# Set the number of days since last logon
$DaysInactive = 35
$InactiveDate = (Get-Date).AddDays(-($DaysInactive))
$Date = (Get-Date -Format yyyy-MM-dd)
$Path = "c:\Reports\InactiveUsersReport"

# Find Inactive Users
$Users = Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true } -Properties LastLogonDate | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName

# Export Results to CSV
$Users | Export-Csv "$PATH\$Date-InactiveUsers.csv" -NoTypeInformation

# Disable inactive users
foreach ($item in $Users) {
    $Distname = $item.DistinguishedName
    Disable-ADAccount -Identity $Distname
    Get-ADUser -Filter { DistinguishedName -eq $Distname } | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, Enabled
    Move-ADObject -Identity $Distname -TargetPath "OU=Disabled,DC=hcl,DC=lmco,DC=com"
}
