
function FindMoveAndDisable-InactiveAccounts {

    [CmdletBinding(DefaultParameterSetName='OrganizationalUnits')]
    param([Parameter(Mandatory = $false, 
                     ValueFromPipeline = $true,
                     ParameterSetName='OrganizationalUnit')]
                     [String[]]$OrganizationalUnits = 'DC=hcl,DC=lmco,DC=com')

    begin{

            Import-Module ActiveDirectory

            # Set the number of days since last logon
            $DaysInactive = 35
            $InactiveDate = (Get-Date).AddDays(-($DaysInactive))
            $Date = (Get-Date -Format yyyy-MM-dd)
            $Path = "c:\Reports\InactiveUsersReport"

    }#End begin

    process{

        Foreach($OrganizationalUnit in $OrganizationalUnits){

            # Get ALL Users
            $AllUsers = Get-ADUser -f * -prop * -SearchBase $OrganizationalUnit -SearchScope Subtree | 
                select @{l="Username"; e={$_.SamAccountName}}, `
                name,dist*,en*,*when*,lock*, `
                @{l='Account Lockout Time';e={[datetime]::FromFileTime($_.AccountLockoutTime)}},last*te, `
                @{l='Last Logon Timestamp';e={[datetime]::FromFileTime($_.lastlogontimestamp)}}, `
                @{l='Last Logon';e={[datetime]::FromFileTime($_.lastlogon)}}

            # Find Inactive Users
            $AllInactiveUsers = $AllUsers |
	                ? {$_.username -notlike '*svc*' `
                        -and $_.distinguishedname -notmatch 'Service' `
                        -and $_.enabled -eq $true `
                        -and $_.'last logon timestamp' -le ($InactiveDate | Get-Date -Format G) `
                        -and $_.'last logon' -le ($InactiveDate | Get-Date -Format G) `
                        -and $_.lastlogondate -le $InactiveDate `
                        -and $_.whencreated -le $InactiveDate} |
                        sort *name,when*,en*,last*,dist*

            $AllInactiveUsers = $AllInactiveUsers | sort username,name,en*,*when*,lock*,Acc*lock*,last*te,la*me,last*n,dist* 
            $AllInactiveUsers | ft -AutoSize
            pause

            # Export Results to CSV
            if ($AllInactiveUsers -eq 0) {

            Write-Host "No inactive Users for $OrganizationalUnit" -ForegroundColor Green

            }#End if

            elseif ($AllInactiveUsers) {
                Write-Host $($AllInactiveUsers.username) -ForegroundColor Magenta
                $AllInactiveUsers | Export-Csv "$Path\$Date-InactiveUsers.csv" -NoTypeInformation -Append

                # Disable inactive users, and move them to the Disabled OU
                ForEach ($item in $AllInactiveUsers) {
                    # Disable Accounts
                    $Distname = $item.DistinguishedName
                    Disable-ADAccount -Identity $Distname -WhatIf

                    Get-ADUser -Filter { DistinguishedName -eq $Distname } | 
                    select @{ Name="Username"; Expression={$_.SamAccountName} }, Name, Enabled

                    # Write-Host "$($CapturedUsers.name)" -ForegroundColor Yellow -BackgroundColor Black

                    Move-ADObject -Identity $Distname -TargetPath "OU=Disabled,DC=hcl,DC=lmco,DC=com" -WhatIf

                }#End foreach

            }#End if

        }#End foreach

    }#End process

    end{}#End end

}#End FindMoveAndDisable-InactiveAccounts

$QuestionTheUser1 = '                                                                                                       
                                                                                                        
            #########################################################################################   
            #                                                                                       #   
            # If you Would you like to only check the HCL and MASC Organizational Units type [Y]es. #   
            #                                                                                       #   
            # If you Would to check all NON HCL MASC OUs then type:                                 #   
            #  "check" with at least the first character "c".                                       #   
            #                                                                                       #   
            # Otherwise, if you want to check the entire domain select no, or just enter [Default]. #   
            #                                                                                       #   
            #########################################################################################   
                                                                                                        
                                                                                                       '

Write-Host `n `n "$QuestionTheUser1" `n `n -Fore gre -ba bla

$AskUser_If_HCL_MASC_Prompt = Read-Host "Enter your option"

Switch -Regex ($AskUser_If_HCL_MASC_Prompt){

    '^y(?:e)?(?:s)?$' {

        Write-Host `n "Checking for users in HCL and MASC Organizational Units." -ForegroundColor Gray `n`n
        $HCL_MASC_OUs     = (Get-ADOrganizationalUnit -f * | select dist* | ? {$_.DistinguishedName -match '^OU=HCL,|^OU=MASC'}).DistinguishedName
        FindMoveAndDisable-InactiveAccounts -OrganizationalUnits $HCL_MASC_OUs
        Write-Host `n "Finished checking for users in HCL and MASC Organizational Units." -ForegroundColor Gray `n`n

     }#End ^(?:1|t(?:rue)?|y(?:es)?|ok(?:ay)?)$

     '^c(?:h)?(?:e)?(?:c)?(?:k)?$'{
        Write-Host `n "Checking for users NOT in HCL and MASC Organizational Units." -ForegroundColor Yellow `n`n
        $NON_HCL_MASC_OUs = (Get-ADOrganizationalUnit -f * | select dist* | ? {$_.DistinguishedName -notmatch 'OU=HCL|OU=MASC'}).DistinguishedName
        FindMoveAndDisable-InactiveAccounts -OrganizationalUnits $NON_HCL_MASC_OUs
        Write-Host `n "Finished checking for users NOT in HCL and MASC Organizational Units." -ForegroundColor Yellow `n`n
     }#NON_HCL_MASC check

     default {
        Write-Host `n "Checking for ALL users in the entire domain." -ForegroundColor Green `n`n
        $GetAllOfTheDomain = (Get-ADDomain).forest
        Write-Host `n`n "You selected $GetAllOfTheDomain." -ForegroundColor Cyan `n`n
        FindMoveAndDisable-InactiveAccounts
     }#End ^(f(?:alse)?|n(?:o\sway)?)$ aka default

}#End Switch



<#Get-ADUser -Filter { LastLogonDate -lt $InactiveDate -and Enabled -eq $true } -Properties LastLogonDate |
Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName #>


<#

Write-Host `n "Checking for users NOT in HCL and MASC Organizational Units" -ForegroundColor Yellow `n`n

FindMoveAndDisable-InactiveAccounts -OrganizationalUnit $NOT_HCL_MASC_OUs



<#
foreach ($HCL_MASC_OU in $HCL_MASC_OUs) {

            Write-Host `n`n "Checking for users in HCL and MASC Organizational Units:" -ForegroundColor Green `n
            Write-Host "This is $HCL_MASC_OU." -ForegroundColor Gray

            $HCL_MASC_InactiveUsers += where {$AllInactiveUsers.distinguishedname -like "*$HCL_MASC_OU"}#End ? 

            Write-Host $HCL_MASC_InactiveUsers -ForegroundColor Magenta



            # Export Results to CSV for HCL and MASC accounts
            Write-Host `n "Exporting list for users in HCL and MASC Organizational Units
            $HCL_MASC_InactiveUsers"  -ForegroundColor Green `n`n 

            $HCL_MASC_InactiveUsers | Export-Csv "$Path\$Date-HCL_MASC_InactiveUsers.csv" -NoTypeInformation


            Write-Host `n`n "Checking for users NOT in HCL and MASC Organizational Units" -ForegroundColor Yellow `n

            $AllOther_InactiveUsers += where {$AllInactiveUsers.distinguishedname -notmatch "*$HCL_MASC_OU"}#End ?

            

            # Export Results to CSV for all others
            Write-Host `n "Exporting list for users NOT in HCL and MASC Organizational Units
               $AllOther_InactiveUsers"  -ForegroundColor Yellow `n`n 

            $AllOther_InactiveUsers | Export-Csv "$Path\$Date-All_Other_InactiveUsers.csv" -NoTypeInformation

           }#>#End foreach
#Email Portion to be worked; no -whatif option.


<#
######################################################################################################################
# For each account expiring within 35 days, notify via email and create local csv
######################################################################################################################
foreach ($item in $InactiveUsers) {
    
    $EmailAddress = $HCL_MASC_InactiveUsers.emailaddress #Get-ADUser -Identity $item -Properties EmailAddress | Select-Object -ExpandProperty EmailAddress
    $35days = Get-ADUser -Identity $item -Properties * | Select-Object -ExpandProperty AccountExpirationDate
    $CSV = New-Object psobject
    $CSV | Add-Member -MemberType NoteProperty "Users" -Value "$item"
    $CSV | Add-Member -MemberType NoteProperty "Email Address" -Value "$EmailAddress"
    $CSV | Add-Member -MemberType NoteProperty "Expiration Date" -Value "$35days"
    $CSV | Export-Csv "(get-dat)$date-var-expiration-dates.csv" -Append -NoTypeInformation


    #I need to work on an email to send to users 7 days before their account expires when this script runs.
    
    #Draft the body of the email
    $body = "
Hello!

You are receiving this email because your MASC-F accounts will be expiring on $35days. You are a valued team member, and we want to make sure you can continue doing great work for the MASC-F team.

Please check with your company's FSO to verify that your Visitor Access Request (VAR) is renewed before $35days.

Thank you!
"

    # Email Parameters
    $mailParam = @{
        To = "$EmailAddress"
        From = "hcl-admin@hcl.lmco.com"
        Subject = 'MASC-F Account Expiring Soon'
        body = $body
        SmtpServer = $smtpServer
    }

    # Send the message
    foreach ($item in $EmailAddress) {
        Send-MailMessage @mailParam
    }
}

if ((Test-Path -Path "$localfolder\$date-var-expiration-dates.csv") -eq $true) {
    $mailParamAdmins = @{
        To = "masc-f_systemteam.dl-rms@exch.ems.lmco.com"
        From = "hcl-admin@hcl.lmco.com"
        Subject = 'MASC-F Account Inactivity Report'
        body = 'Please see attached report of Account Inactivity.'
        SmtpServer = $smtpServer
        Attachments = "$Path\$Date-HCL_MASC_InactiveUsers.csv"
    }

    Send-MailMessage @mailParamAdmins
}

#>