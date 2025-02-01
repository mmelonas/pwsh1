#$OU="OU=ExternalUsers,DC=spacefence,DC=ssn,DC=afspc,DC=af,DC=smil,DC=mil"
#$OU="DC=spacefence,DC=ssn,DC=afspc,DC=af,DC=smil,DC=mil"
$CWD = (Get-Location).Path
$OU = (Get-ADDomain).DistinguishedName
$date = (Get-Date).ToString("yyyyMMdd-hhmmss")
$DNS_Root = (Get-ADDomain).DNSRoot

$UserList = Get-WmiObject -Class Win32_UserAccount

[System.Collections.ArrayList]$List = New-Object System.Collections.ArrayList($null)

Function Get-LocalGroupMembershipRecursive {
    param (
        $ObjIdentity
    )
    [System.Collections.ArrayList]$MembershipList = New-Object System.Collections.ArrayList($null)
    $MembershipOf = Get-ADPrincipalGroupMembership -Identity $ObjIdentity
    
    ForEach ($Member in $MembershipOf) {
        if ($Member.objectClass -eq "group") {
            $MembershipList.Add((Get-ADPrincipalGroupMembershipRecursive -ObjIdentity $Member)) | Out-Null
        } else {
            $MembershipList.Add($Member) | Out-Null
        }
    }

    if (-Not $MembershipList.Contains($ObjIdentity)) {
        $MembershipList.Add($ObjIdentity) | Out-Null
    }
    return $MembershipList
}

$UserList | ForEach-Object {
    $User = $_

    # Get memberships
    $UserGroups = Get-LocalGroupMembershipRecursive -Identity $User

    [System.Collections.ArrayList]$TempGroupNames = New-Object System.Collections.ArrayList($null)
    $UserGroups | ForEach-Object {
        $CurrGroup = $_
        $UserMembershipsGroups = @()

        $UserMembershipsGroups = Get-LocalGroupMembershipRecursive -ObjIdentity $CurrGroup

        ForEach($SingleMember in $UserMembershipsGroups) {
            if (-Not $TempGroupNames.Contains($SingleMember.Name)) {
                $TempGroupNames.Add($SingleMember.Name) | Out-Null

                $List.Add([PSCustomObject]@{
                    DisplayName = $User.DisplayName
                    SamAccountName = $User.samaccountname
                    Name = $User.Name
                    Enabled = $User.Enabled
                    Group = $SingleMember.Name
                }  # end of PSCustomObject
                ) | Out-Null
            }
        }       
    } 
}

#$List | Sort-Object -Property DisplayName,samaccountname
$List | Sort-Object -Property DisplayName,samaccountname | Export-Csv -Path "$CWD\UsersGroups_for_$DNS_Root-$date.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Complete. Exported to: $CWD\UsersGroups_for_$DNS_Root-$date.csv"
