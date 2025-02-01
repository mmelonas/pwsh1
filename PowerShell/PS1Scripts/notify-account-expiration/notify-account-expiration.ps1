######################################################################################################################
# Variables
# SMTP will need to be updated in the future using an authenticated account
######################################################################################################################
$date = Get-Date -Format yyyyMMdd-hhmmss
$smtpServer = "smtp-lmiden.ems.lmco.com"
$localfolder = "c:\scripts"

######################################################################################################################
# Create the local folder if it does not exist.
######################################################################################################################
if ((Test-Path -Path $localfolder) -eq $false) {
    New-Item -Path "$localfolder" -ItemType Directory
}

if ((Test-Path -Path "$localfolder\logs") -eq $false) {
    New-Item -Path "$localfolder" -Name "logs" -ItemType Directory
}

Start-Transcript -Path "$localfolder\logs\$date.log"

######################################################################################################################
# Find out which accounts will expire in 35 days
######################################################################################################################
$Users = Search-ADAccount -AccountExpiring -TimeSpan (New-TimeSpan -Days 35) |
         Where-Object {$_.enabled -eq $true} | Select-Object  -ExpandProperty SamAccountName

######################################################################################################################
# For each account expiring within 35 days, notify via email and create local csv
######################################################################################################################
foreach ($item in $Users) {
    $EmailAddress = Get-ADUser -Identity $item -Properties EmailAddress | Select-Object -ExpandProperty EmailAddress
    $35days = Get-ADUser -Identity $item -Properties * | Select-Object -ExpandProperty AccountExpirationDate
    $CSV = New-Object psobject
    $CSV | Add-Member -MemberType NoteProperty "Users" -Value "$item"
    $CSV | Add-Member -MemberType NoteProperty "Email Address" -Value "$EmailAddress"
    $CSV | Add-Member -MemberType NoteProperty "Expiration Date" -Value "$35days"
    $CSV | Export-Csv "$localfolder\$date-var-expiration-dates.csv" -Append -NoTypeInformation


    # Draft the body of the email
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
        cc = 'heather.l.haley@lmco.com','holly.hembree@lmco.com','sonya.l.simon@lmco.com','ronald.w.finlaw.jr@lmco.com'
        Subject = 'MASC-F Account Expiration Dates Report'
        body = 'Please see attached report of upcoming account expirations.'
        SmtpServer = $smtpServer
        Attachments = "$localfolder\$date-var-expiration-dates.csv"
    }

    Send-MailMessage @mailParamAdmins
}

Stop-Transcript
