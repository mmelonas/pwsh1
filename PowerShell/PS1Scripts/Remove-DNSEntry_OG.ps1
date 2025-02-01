function Remove-DNSEntry {
    <#PSScriptInfo
 
.VERSION 1.0
 
.GUID d7dd928d-a0ad-4dc8-9911-cbcee9fe60d7
 
.AUTHOR Michael K.
 
.COMPANYNAME
 
.COPYRIGHT
 
.TAGS
 
.LICENSEURI
 
.PROJECTURI
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
 
#>

<#
 
.DESCRIPTION
 Function removes DNS "A" Record and "PTR" record (if found) from DNS Server
 
#> 


### Prerequisites ######
# Get all reverse zones first
# specify DNS server to be used for getting all zones
$dcserver = "dc01.global.cotonso.com"
$zones = Get-DnsServerZone -ComputerName $dcserver | Select ZoneName, IsReverseLookupZone | Where {$_.IsReverseLookupZone -eq "True"}

Function Remove-DNSEntry {

    <#
    .SYNOPSIS
    Remove DNS A Record and PTR Record (if found) from DNS Server
    .DESCRIPTION
    Remove DNS A Record and PTR Record (if found) from DNS Server
    .EXAMPLE
Remove-DNSEntry -NodeToDelete "it01"

    .EXAMPLE
Remove-DNSEntry -NodeToDelete "it01" -ZoneName "global.cotonso.com"

    .EXAMPLE
Remove-DNSEntry -NodeToDelete "it01" -DNSServer "dc01.global.cotonso.com" -ZoneName "global.cotonso.com"

    .NOTES
    CmdletBinding is pre-populated with default values if additional parameter wont be provided while executing function

    #>

[CmdletBinding()]
   Param 
   (
   [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
   [string]$NodeToDelete,
   [parameter(Mandatory=$false,Position=1,ValueFromPipeline=$true)]
   [string]$DNSServer = "hcl-dc01.hcl.lmco.com", 
   [parameter(Mandatory=$false,Position=2,ValueFromPipeline=$true)]
   [string]$ZoneName = "hcl.lmco.com"
   )


    # clear Variables
    $NodeARecord = $null
    $NodePTRRecord = $null

    # Error Action Preference
    $ErrorActionPreference = "SilentlyContinue"

    # Finds A record in DNS
    $NodeARecord = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -Node $NodeToDelete -RRType A -ErrorAction SilentlyContinue

    # Continue if A record was found
    If ($NodeARecord -ne $null) {

    # Create variables to search for reverse lookup zones by name
    $IPAddress = $NodeARecord.RecordData.IPv4Address.IPAddressToString
    $IPAddressArray = $IPAddress.Split(".")
    $ReverseZoneName1 = $IPAddress -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$3.$2.$1.in-addr.arpa'
    $ReverseZoneName2 = $IPAddress -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$2.$1.in-addr.arpa'
    $ReverseZoneName3 = $IPAddress -replace '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','$1.in-addr.arpa'

    # Format IP Address for reverse lookup pattern
    $IPAddressFormatted1 = ($IPAddressArray[3])
    $IPAddressFormatted2 = ($IPAddressArray[3]+"."+$IPAddressArray[2])
    $IPAddressFormatted3 = ($IPAddressArray[3]+"."+$IPAddressArray[2]+"."+$IPAddressArray[1])

    # Try to find PTR record for each formatted name
    $NodePTRRecord1 = Get-DnsServerResourceRecord -ZoneName $ReverseZoneName1 -ComputerName $DNSServer -Node $IPAddressFormatted1 -RRType Ptr -ErrorAction SilentlyContinue 
    $NodePTRRecord2 = Get-DnsServerResourceRecord -ZoneName $ReverseZoneName2 -ComputerName $DNSServer -Node $IPAddressFormatted2 -RRType Ptr -ErrorAction SilentlyContinue
    $NodePTRRecord3 = Get-DnsServerResourceRecord -ZoneName $ReverseZoneName3 -ComputerName $DNSServer -Node $IPAddressFormatted3 -RRType Ptr -ErrorAction SilentlyContinue

        If ($NodePTRRecord1 -ne $null){
            $NodePTRRecord = $NodePTRRecord1
            $ReverseZoneName = $ReverseZoneName1
            $IPAddressFormatted = $IPAddressFormatted1
            }

      
        Elseif ($NodePTRRecord2 -ne $null){       
                $NodePTRRecord = $NodePTRRecord2
                $ReverseZoneName = $ReverseZoneName2
                $IPAddressFormatted = $IPAddressFormatted2
                }

        Elseif ($NodePTRRecord3 -ne $null){ 
                $NodePTRRecord = $NodePTRRecord3 
                $ReverseZoneName = $ReverseZoneName3
                $IPAddressFormatted = $IPAddressFormatted3
                }

        Else {Write-Output "There was no PTR Record for $NodeToDelete"}
        
        
        # Remove A Record and PTR Record
       
       If ($NodePTRRecord -ne $null){
        Remove-DnsServerResourceRecord -ZoneName $ReverseZoneName -ComputerName $DNSServer -InputObject $NodePTRRecord -Force
        Write-Host ("PTR record: "+$IPAddressFormatted+" from zone: "+$ReverseZoneName+" was removed")
        }


        Remove-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -InputObject $NodeARecord -Force
        Write-Host ("A record: "+$NodeARecord.HostName+" from zone: "+$ZoneName+" was removed")
        Write-Host ""
        
     }

     Else
     {
        Write-Host "No A record found for $NodeToDelete"
        Write-Host ""
     }
   
}

}#End Remove-DNSEntry