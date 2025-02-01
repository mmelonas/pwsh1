
<# Deprecated code, but potentially useful in whole or part for future endeavors.

function IsThis-aValidSystemName ($SystemNames) {

<#
.SYNOPSIS
    Validate System Name Information.


.NOTES   
    Name: IsThis-aValidSystemName
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>
#
#    foreach ($SystemName in $SystemNames) {
#        return ($SystemName -match "^[a-zA-Z0-9\-]{?,8}[a-zA-Z0-9\-]{7,15}$")
#    }#End foreach
#
#}#End IsThis-aValidSystemName
#
#
#
 
<#Regex vars for my matches.

#My admin creds vars using Get-Credential.
Write-Host "                Enter DA credentials" -ForegroundColor Green
Pause
$global:da_creds = Get-Credential
Write-Host "                Enter MS credentials" -ForegroundColor Green
Pause
$global:ms_creds = Get-Credential

#My admin creds vars.
$global:NameToCheckADUC = ($env:USERNAME).substring(2) 
$global:SuperSecret      = Read-Host "Enter PowerCodes" -AsSecureString
$global:da_creds = New-Object System.Management.Automation.PSCredential -ArgumentList ("da" + $global:NameToCheckADUC + "@hcl.lmco.com").ToString(),$SuperSecret
$global:ms_creds = New-Object System.Management.Automation.PSCredential -ArgumentList ("ms" + $global:NameToCheckADUC + "@hcl.lmco.com").ToString(),$SuperSecret

#
$global:YesMatch = '^y(?:e)?(?:s)?$|^\s+$|^$'
$global:NoMatch  = '^n(?:o)?$'


<#
    #$FileTypeDataSets = @()


    $PSDefaultParameterValues = @{
    $AllThings = gci | ? {$_.extension -match '\S+'} | select *;
    $Name  = hostname
    }

#    $AllThings = Get-ChildItem "C:\temp"

    if ($AllThings -eq $null) {

        $AllThings = gci | ? {$_.extension -match '\S+'} | select *

    } #End if

    write-host $AllThings -ForegroundColor Green

#>

#>

<#

function IdentifyFileType {

    [CmdletBinding()]
    param(
       [Parameter(
            Position=0,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Pipeline"
            )]
        [Alias("FileOrDirectory")]
        [PsObject[]]$TheItems = (gci)
    )

    #$items = Get-ChildItem "C:\temp"

    foreach($item in $TheItems){
        [PSCustomObject]@{
        TheFullName  = $item.fullname
        TheExtension = $($item.Extension).Substring(1)
        ExtFullName  = $Typehasher.($($item.Extension).Substring(1))
        #$hash.($($item.Extension).Split(".")[1])
        } #End PSCustomObject
    }# End foreach

} #End IdentifyFileType

#>