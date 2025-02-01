##################################################################
#                   User Defined Variables
##################################################################

# Names of VMs to backup separated by semicolon (Mandatory)
#$VMNames = ""

# Name of vCenter or standalone host VMs to backup reside on (Mandatory)
$HostName = "vcsv01.hcl.lmco.com"

# Directory that VM backups should go to (Mandatory; for instance, C:\Backup)
$Directory = "E:\VeeamZIP"

# Desired compression level (Optional; Possible values: 0 - None, 4 - Dedupe-friendly, 5 - Optimal, 6 - High, 9 - Extreme) 
$CompressionLevel = "5"

# Quiesce VM when taking snapshot (Optional; VMware Tools are required; Possible values: $True/$False)
$EnableQuiescence = $false

# Protect resulting backup with encryption key (Optional; $True/$False)
# $EnableEncryption = $True

# Encryption Key (Optional; path to a secure string)
# $EncryptionKey = ""

# Retention settings (Optional; By default, VeeamZIP files are not removed and kept in the specified location for an indefinite period of time. 
# Possible values: Never , Tonight, TomorrowNight, In3days, In1Week, In2Weeks, In1Month)
$Retention = "In1Week"

##################################################################
#                   Notification Settings
##################################################################

# Enable notification (Optional)
$EnableNotification = $TRUE

# Email SMTP server
$SMTPServer = "smtp.us.lmco.com"

# Email FROM
$EmailFrom = "no-reply-veeam@hcl.lmco.com" 

# Email TO
$EmailTo = "martin.j.parlier@lmco.com"

# Email subject
$EmailSubject = "Snapshot Complete ($VMNames)"

##################################################################
#                   Email formatting 
##################################################################

$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"

##################################################################
#                   VMs to Back Up
##################################################################

Start-VBRZip -Entity ahcl0uv-admin01 -Folder $Directory -Compression $CompressionLevel -DisableQuiesce -AutoDelete $Retention