# Variables
$vCenterIP="10.10.20.100"
$UserName=$env:UserName

# To avoid certificate issues...
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Login to vCenter
Write-Output ""
Write-Output "Let's gather account/password information to log you into vCenter..."
Write-Output "Be patient. The login takes a few seconds."
Write-Output ""
$MSAccount = Read-Host -Prompt "Input your MS account"

$MSAccountPassword = Read-Host -AsSecureString -Prompt "Input password for ${MSAccount}"
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MSAccountPassword)
$MSAccountPasswordClearText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

$Server = Connect-VIServer $vCenterIP -User "hcl\$MSAccount" -Password "$MSAccountPasswordClearText"
Write-Output ""

Write-Output ""
Write-Output "Disconnecting from vCenter..."
Disconnect-VIServer -Server $Server -Confirm:$false
Write-Output ""