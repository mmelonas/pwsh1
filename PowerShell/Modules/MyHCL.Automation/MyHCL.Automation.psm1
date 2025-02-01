
Function Get-VMInformation {
<#
.SYNOPSIS
    Get information from a VM object. Properties inlcude Name, PowerState, vCenterServer, Datacenter, Cluster, VMHost, Datastore, Folder, GuestOS, NetworkName, IPAddress, MacAddress, VMTools


.NOTES   
    Name: Get-VMInformation
    Author: theSysadminChannel
    Version: 1.0
    DateCreated: 2019-Apr-29


.EXAMPLE
    For updated help and examples refer to -Online version.


.LINK
    https://thesysadminchannel.com/get-vminformation-using-powershell-and-powercli -

#>

    [CmdletBinding()]

    param(
       [Parameter(
            Position=0,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="NonPipeline"
            )]
        [Alias("VM")]
        [string[]]$Name,

        [Parameter(
            Position=1,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Pipeline"
            )]
        [PSObject[]]$InputObject
    )

    BEGIN {
        if (-not $Global:DefaultVIServer) {
            Write-Error "Unable to continue.  Please connect to a vCenter Server." -ErrorAction Stop
        }

        #Verifying the object is a VM
        if ($PSBoundParameters.ContainsKey("Name")) { 
            $InputObject = Get-VM $Name
        }

        $i = 1
        $Count = $InputObject.Count
    }

    PROCESS {
        if (($null -eq $InputObject.VMHost) -and ($null -eq $InputObject.MemoryGB)) {
            Write-Error "Invalid data type. A virtual machine object was not found" -ErrorAction Stop
        }

        foreach ($Object in $InputObject) {
            try {
                $vCenter = $Object.Uid -replace ".+@"; $vCenter = $vCenter -replace ":.+"
                [PSCustomObject]@{
                    Name                 = $Object.Name
                    PowerState           = $Object.PowerState
                    vCenter              = $vCenter
                    Datacenter           = $Object.VMHost | Get-Datacenter | select -ExpandProperty Name
                    Cluster              = $Object.VMhost | Get-Cluster | select -ExpandProperty Name
                    VMHost               = $Object.VMhost
                    Datastore            = ($Object | Get-Datastore | select -ExpandProperty Name) -join ', '
                    vSphereFolderName    = $Object.Folder
                    CPUs                 = $object.NumCPU
                    Cores                = $object.CoresPerSocket
                    RAM                  = Set-HumanReadableByteSize ($object.MemoryGB * 1073741824)
                    GuestOS              = $Object.ExtensionData.Config.GuestFullName
                    TotalNICs            = ($Object | Get-NetworkAdapter | Select-Object -ExpandProperty NetworkName).count
                    NetworkName          = ($Object | Get-NetworkAdapter | Select-Object -ExpandProperty NetworkName) -join ', '
                    MacAddress           = ($Object | Get-NetworkAdapter | Select-Object -ExpandProperty MacAddress) -join ', '
                    IPs                  = ($Object.ExtensionData.Summary.Guest.IPAddress) -join ', '
                    VMTools              = $Object.ExtensionData.Guest.ToolsVersionStatus2 -join ', '
                    ProvisionedSpace     = Set-HumanReadableByteSize ($Object.ProvisionedSpaceGB * 1073741824)
                    UsedSpace            = Set-HumanReadableByteSize ($Object.UsedSpaceGB * 1073741824)
                    UsedDiskSpacePercent = [String]([math]::Round((($object.UsedSpaceGB/$object.ProvisionedSpaceGB)*100),3))+'%'
                    vmdkDiskSpace        = [String]((Get-HardDisk -VM $Object | select -ExpandProperty capacitygb) | foreach {[string]$_ + 'GB'}).split(" ")
                    VMPartitions         = [String](Convert-GuestVMPartitionInformation -Version DiskSpaceTotal -VM $Object)
                    VMPartitionFreeGB    = [String](Convert-GuestVMPartitionInformation -Version DiskSpaceFreeGB -VM $Object)
                    VMPartitionFreePCT   = [String](Convert-GuestVMPartitionInformation -Version DiskPercentageFree -VM $Object)
                    CreatedDateTime      = $Object.CreateDate
                    vGPUs                = $Object.ExtensionData.Config.Hardware.Device.Backing.vgpu
                }

            } catch {
                Write-Error $_.Exception.Message

            } finally {
                if ($PSBoundParameters.ContainsKey("Name")) {
                    $PercentComplete = ($i/$Count).ToString("P")
                    Write-Progress -Activity "Processing VM: $($Object.Name)" -Status "$i/$count : $PercentComplete Complete" -PercentComplete $PercentComplete.Replace("%","")
                    $i++
                } else {
                    Write-Progress -Activity "Processing VM: $($Object.Name)" -Status "Completed: $i"
                    $i++
                }
            }
        }
    }

    END {}

}#End Get-VMInformation

function Get-IPFromVM {

<#
.SYNOPSIS
    Get VM object information from an IP; default values are equivalent to Get-VM.


.NOTES   
    Name: Get-IPFromVM
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07

    Crap I need to fix:
    [ValidateScript(IsThis-aValidSystemName $_,ErrorMessage="{0} is not valid; enter a proper hostname dummy!")] 

.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,
            ParameterSetName='VM',
            Position=0,
            HelpMessage='Enter the machine name you are looking for to get the IPv4 address:')] 
        [string[]]$VMs
    )

    $AllVMs = (Get-VM | Where-Object {$_.name -match $VMs}).Name
    $VMDataSets = @()

    foreach ($EachVM in $AllVMs) {

        Write-Host "    Current VM is $EachVM" -ForegroundColor Cyan

        $VMDataSets += Get-VMInformation -VM $EachVM
                        <#select name,powerstate,*cpu,cores*,*gb, `
                        @{l='UsedDiskSpacePercent';e={[string]([math]::Round((($_.UsedSpaceGB/$_.ProvisionedSpaceGB)*100),3))+'%'}},
                        @{l='IPs';e={($_.ExtensionData.Summary.Guest.IPAddress) -join ', '}}#>

    }#End foreach

    return $VMDataSets

}#End Get-IPFromVM

function Get-VMFromIP {

<#
.SYNOPSIS
    Get IP Information from a VM name.


.NOTES   
    Name: Get-VMFromIP
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07

    Crap I need to fix:
    [ValidateScript(IsThisaValidIPv4Address $_,ErrorMessage="{0} is not valid; enter a proper IPv4 address dummy!")] 

.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,
            ParameterSetName='IP',
            Position=0,
            HelpMessage='Enter the IPv4 address(es) you are looking for with ALL octets present (X.X.X.X) using comma seperation:')]
        [string[]]$IPs
    )

    $IPDataSets = @()

    foreach ($EachIP in $IPs) {

        Write-Host "    Current VM is $EachIP" -ForegroundColor Cyan

        $IPDataSets += Get-VMInformation -VM (Get-VM | Where-Object {$_.guest.ipaddress -match $EachIP}).Name 
                        <#| select name,powerstate,cpu*,cores*,*gb, `
                        @{l='IPs';e={($_.ExtensionData.Summary.Guest.IPAddress) -join ', '}}#>

    }#End foreach

    return $IPDataSets

<#

    if ([System.Net.IPAddress]::TryParse($UserInput_IPtoParse,[ref]$null)) {

        Get-VM | ? {$_.guest.ipaddress -eq $UserInput_IPtoParse}

    }#End if

    else {Write-Host `n "Try again dummy." `n -ForegroundColor Red}#End else
#>

}#End Get-VMFromIP

function Test-LDAPPorts {

<#
.SYNOPSIS
    Testing ldap ports with PowerShell.


.NOTES   
    Name: Test-LDAPPorts
    Author: Przemyslaw Klys
    Version: 1.0
    DateCreated: 2023-AUG-17

    Using [System.Net.Dns]::GetHostEntry(<Computer>) instead of Resolve-DnsName due to Limitations of the Linux PowerShell Library.
    Reference is here: https://stackoverflow.com/questions/51423281/powershell-does-not-recognize-the-command-resolve-dnsname

.EXAMPLE
    Test-LDAPPort -Servername 'AD1' -Port 636 | Format-Table

.LINK
    https://evotec.xyz/testing-ldap-and-ldaps-connectivity-with-powershell/

#>

    [CmdletBinding()]
    param(
        [string] $ServerName,
        [int] $Port
    )
    if ($ServerName -and $Port -ne 0) {
        try {
            $LDAP = "LDAP://" + $ServerName + ':' + $Port
            $Connection = [ADSI]($LDAP)
            $Connection.Close()
            return $true
        } catch {
            if ($_.Exception.ToString() -match "The server is not operational") {
                Write-Warning "Can't open $ServerName`:$Port."
            } elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
                Write-Warning "Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $Server`:$Port"
            } else {
                Write-Warning -Message $_
            }
        }
        return $False
    }
} #End Test-LDAPPorts


Function Test-LDAP {

<#
.SYNOPSIS
    Testing ldap and ldaps connectivity with PowerShell.


.NOTES   
    Name: Test-LDAP
    Author: Przemyslaw Klys
    Version: 1.0
    DateCreated: 2023-AUG-17

    Using [System.Net.Dns]::GetHostEntry(<Computer>) instead of Resolve-DnsName due to Limitations of the Linux PowerShell Library.
    Reference is here: https://stackoverflow.com/questions/51423281/powershell-does-not-recognize-the-command-resolve-dnsname

.EXAMPLE
    Test-LDAP -ComputerName 'AD1','AD2' | Format-Table


.LINK
    https://evotec.xyz/testing-ldap-and-ldaps-connectivity-with-powershell/

#>

    [CmdletBinding()]
    param (
        [alias('Server', 'IpAddress')][Parameter(Mandatory = $True)][string[]]$ComputerName,
        [int] $GCPortLDAP = 3268,
        [int] $GCPortLDAPSSL = 3269,
        [int] $PortLDAP = 389,
        [int] $PortLDAPS = 636
    )
    # Checks for ServerName - Makes sure to convert IPAddress to DNS
    foreach ($Computer in $ComputerName) {
        #[Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue)
        [Array] $ADServerFQDN = [System.Net.Dns]::GetHostEntry($Computer) 
        if ($ADServerFQDN) {
            if ($ADServerFQDN.HostName) {
                $ServerName = $ADServerFQDN[0].HostName
            } <#else {
                [Array] $ADServerFQDN = (Resolve-DnsName -Name $Computer -ErrorAction SilentlyContinue)
                $FilterName = $ADServerFQDN | Where-Object { $_.QueryType -eq 'A' }
                $ServerName = $FilterName[0].Name
            } #End if else #>
        } else {
            $ServerName = ''
        }

        $GlobalCatalogSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAPSSL
        $GlobalCatalogNonSSL = Test-LDAPPorts -ServerName $ServerName -Port $GCPortLDAP
        $ConnectionLDAPS = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAPS
        $ConnectionLDAP = Test-LDAPPorts -ServerName $ServerName -Port $PortLDAP

        $PortsThatWork = @(
            if ($GlobalCatalogNonSSL) { $GCPortLDAP }
            if ($GlobalCatalogSSL) { $GCPortLDAPSSL }
            if ($ConnectionLDAP) { $PortLDAP }
            if ($ConnectionLDAPS) { $PortLDAPS }
        ) | Sort-Object
        [pscustomobject]@{
            Computer           = $Computer
            ComputerFQDN       = $ServerName
            GlobalCatalogLDAP  = $GlobalCatalogNonSSL
            GlobalCatalogLDAPS = $GlobalCatalogSSL
            LDAP               = $ConnectionLDAP
            LDAPS              = $ConnectionLDAPS
            AvailablePorts     = $PortsThatWork -join ','
        }
    }
} #End Test-LDAP

function IsThisaValidIPv4Address ($ips) {

<#
.SYNOPSIS
    Validate System Name Information.


.NOTES   
    Name: IsThis-aValidSystemName
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07

    The old way of doing this which doesn't take into account limits up to 255, or potential negative or irrational numbers.
    return ($ip -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" -and [bool]($ip -as [ipaddress]))


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    foreach ($ip in $ips) {
        return ($ip -match "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" -and [bool]($ip -as [ipaddress]))
    }#End foreach

}#End IsThisaValidIPv4Address

function Check-PowerCLIConfiguration {

<#
.SYNOPSIS
    Check the PowerCLIConfiguration, and set to accept self signed certificates.


.NOTES   
    Name: Check-PowerCLIConfiguration
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Write-Host "
    Checking and setting PowerCLI Configuration for Self-Signed Certificates . . ." -ForegroundColor DarkYellow

    if ((Get-PowerCLIConfiguration | Where-Object { $_.InvalidCertificateAction -notmatch 'Ignore' }) -ne $null) {

        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -InvalidCertificateAction Ignore -Confirm:$false 

    }#End if

}#End Check-PowerCLIConfiguration

function Get-MyHCL-Commands {

<#
.SYNOPSIS
    Get all commands for the MyHCL.Automation Module.


.NOTES   
    Name: Get-MyHCL-Commands
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Write-Host "
    Here is your list of commands for the MyHCL.Automation.psm1 Module.
    " -ForegroundColor Cyan 

    Get-Command -Module myhcl.automation

}#End Get-MyHCL-Commands

function GoTo-HCL-DC1 {

<#
.SYNOPSIS
    Use Enter-PSSession to DC1 with securely stored credentials.


.NOTES   
    Name: GoTo-HCL-DC1
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Enter-PSSession $PrimaryDC -Credential $da_creds

}#End GoTo-HCL-DC1

function GoTo-HCL-DC2 {

<#
.SYNOPSIS
    Use Enter-PSSession to DC2 with securely stored credentials.


.NOTES   
    Name: GoTo-HCL-DC2
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Enter-PSSession $SecondaryDC -Credential $da_creds

}#End GoTo-HCL-DC2

function GoTo-HCL-vSphere {

<#
.SYNOPSIS
    Use Connect-VIServer to vSphere with securely stored credentials.


.NOTES   
    Name: GoTo-HCL-vSphere
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Connect-VIServer -Server $vSphere -Credential $ms_creds

}#End GoTo-HCL-vSphere

function GoTo-HCL-HorizonView {

<#
.SYNOPSIS
    Use Connect-HVServer to Horizon View with securely stored credentials.


.NOTES   
    Name: GoTo-HCL-HorizonView
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-AUG-02


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Connect-HVServer $HVServer -Credential $ms_creds

}#End GoTo-HCL-HorizonView

function Get-NoOSorIPsInfoOnlineVMs {

    Get-VM | select name,powerstate, `
                    @{l='OS';e={@($_.extensiondata.guest.guestfullname)}}, `
                    @{l='IP';e={@($_.guest.ipaddress)}} |
                            Where-Object {$_.name -notmatch 'vCLS-' -and `
                                      $_.powerstate -eq 'PoweredOn'} |
                            Where-Object {$_.os -eq $null -or $_.ip -eq $null}

}#End Get-NoOSorIPsInfoOnlineVMs

function Convert-GuestVMPartitionInformation {

<#
.SYNOPSIS
    Convert VMware VM partition data to Human readable format.
    This is good for associating partitions with their associated sizes.


.NOTES   
    Name: Convert-GuestVMPartitionInformation
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true
        )]
        [ValidateSet('DiskSpaceTotal','DiskSpaceFreeGB','DiskPercentageFree')]
        [string]$Version,

        [Parameter(

            Position=1,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$VM

        
    )

    $TheVM             = Get-VMGuestDisk -VM $Object | select *
    [array]$DiskName   = $TheVM | select -ExpandProperty DiskPath
    [array]$FreeSpace  = $TheVM | select -ExpandProperty FreeSpaceGB
    [array]$AllSpace   = $TheVM | select -ExpandProperty CapacityGB
    [array]$FinalSpace = @()

    switch ($Version) {

        DiskSpaceTotal {
            For ($i=0; $i -lt $DiskName.count; $i++) {
                $FinalSpace += ([string]$DiskName[$i] + '=' + [string]([System.Math]::Round($AllSpace[$i],2)) + 'GB')
            }#End For loop
            $Finalspace
        }#End DiskSpaceTotal

        DiskSpaceFreeGB {
            For ($i=0; $i -lt $DiskName.count; $i++) {
                $Finalspace += [string]$DiskName[$i] + '=' + [string]([System.Math]::Round($FreeSpace[$i],2)) + 'GB-Free'
            }#End For loop
            $FinalSpace
        }#End DiskSpaceFree

        DiskPercentageFree {
            For ($i=0; $i -lt $DiskName.count; $i++) {
                if ($AllSpace[$i] -ne 0) {
                    $CalculatedFreeAll = ([System.Math]::Round((($FreeSpace[$i])/($AllSpace[$i]))*100,2))
                    $FinalSpace += [string]$DiskName[$i] + '=' + $CalculatedFreeAll + '%FREE'
                }# End if
            }#End For loop
            $FinalSpace
        }#End DiskPercentageFree

    }#End switch selection

}#End Convert-GuestVMInformation

function Restart-NoOSorIPsInfoOnlineVMs {

<#
.SYNOPSIS
    Restarts VMs found in the query Get-NoOSorIPsInfoOnlineVMs


.NOTES   
    Name: Restart-NoOSorIPsInfoOnlineVMs
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Get-NoOSorIPsInfoOnlineVMs | foreach {Restart-VM -VM $_.name -Confirm:$false}

    Write-Host `n "
    Waiting two minutes before restarting the query . . . 
    " `n -ForegroundColor Magenta

    sleep 120

    Query-4VMsWithNoIPsOrOSInfo; break

}#End Restart-NoOSorIPsInfoOnlineVMs

function Query-4VMsWithNoIPsOrOSInfo {

<#
.SYNOPSIS
    Loop which Queries for VMs found in the filter Get-NoOSorIPsInfoOnlineVMs


.NOTES   
    Name: Query-4VMsWithNoIPsOrOSInfo
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    while ($true) {

    cls

    Write-Host "        ################################################################################" -ForegroundColor Magenta
    Write-Host "
        ________________________________________________________________________________
       |                                                                                |
       |   Querying for VMs with no IP or OS information in vSphere, please wait . . .  |
       |________________________________________________________________________________|
        " -ForegroundColor Cyan
    Write-Host "        ################################################################################" -ForegroundColor Magenta
    Write-Host ""
    Write-Host ""

    $OnlineVMsWithNoIPs = Get-NoOSorIPsInfoOnlineVMs

        if ($OnlineVMsWithNoIPs -ne $null) {

            $OnlineVMsWithNoIPs | Sort-Object name| ft -AutoSize

        Write-Host "
        There are problem VMs needing attention.
        You will be prompted to take action soon . . .
        " -ForegroundColor Yellow

            sleep 5

            Menu4VMsWithNoIPsOrOSInfo; break 
        
        }#End if

    Write-Host "
        Waiting 30 seconds before running the query again . . .    
    " -ForegroundColor Green

    sleep 30

    }#End while

}#End Query-4VMsWithNoIPsOrOSInfo

function Check-KeyPress ($sleepSeconds = 10) {

<#
.SYNOPSIS
    Specialized Loop awaiting user interaction with a ten second timeout.


.NOTES   
    Name: Check-KeyPress
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    cls

    $timeout = New-TimeSpan -Seconds $sleepSeconds
    $stopWatch = [Diagnostics.Stopwatch]::StartNew()
    $interrupted = $false

    while ($stopWatch.Elapsed -le $timeout) {

        cls

        Write-Host `n `n "                                                                 
                                                                 
        #########################################################
        # You have VMs showing up without IP or OS information. #
        #########################################################
                                                                 
        ***  Press the ANY key to GoTo the Menu to take action on the listed systems.  ***
        ***  If not just wait for the query to run again.  ***
                                                                 
        " `n -ForegroundColor Yellow -BackgroundColor Black

        Write-Host "        Counting up with "          -ForegroundColor Yellow -NoNewline
        Write-Host $stopWatch.Elapsed.Seconds           -ForegroundColor Cyan   -NoNewline
        Write-Host " seconds passed "                   -ForegroundColor Yellow -NoNewline
        Write-Host "until 10 seconds are reached."      -ForegroundColor Yellow -NoNewline
        Write-Host " Then the query begins again . . .
        " `n `n `n `n `n `n `n `n `n                    -ForegroundColor Yellow 

        sleep 1

        if ($Host.UI.RawUI.KeyAvailable) {
                $keyPressed = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp, IncludeKeyDown")
                if ($keyPressed.KeyDown -eq "True") { 
                     $interrupted = $true
                     break          
                }#End if 
            }#End if
        }#End while
    return $interrupted
}#End Check-Keypress

function Menu4VMsWithNoIPsOrOSInfo  {

<#
.SYNOPSIS
    Menu for the user to initiate the Query for VMs with no IP or OS Information,
    restart VMs with No OS or IP Information,
    or exit to the shell.


.NOTES   
    Name: Menu4VMsWithNoIPsOrOSInfo
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    if (Check-Keypress) {

        Write-Host `n `n "        Wait for the menu to load . . . " `n `
        -ForegroundColor Yellow

        $CurrentProblemVMs = Get-NoOSorIPsInfoOnlineVMs

        cls

        $CurrentProblemVMs | Sort-Object name | ft -AutoSize

        write-host {

        ##############################################################
        #                                                            #
        #                   Menu for Problem VMs                     #
        #                                                            #
        ##############################################################
        #                                                            #
        #  1) Run Query-4VMsWithNoIPsOrOSInfo again.                 #
        #                                                            #
        #  2) Restart the listed systems using:                      #
        #     Restart-NoOSorIPsInfoOnlineVMs                         #
        #                                                            #
        #  3) Exit to the shell                                      #
        #                                                            #
        ##############################################################
        } -ForegroundColor Green -BackgroundColor Black

        Write-Host "        There are currently <" -ForegroundColor DarkGray -NoNewline
        Write-Host $CurrentProblemVMs.count -ForegroundColor Yellow -NoNewline
        Write-Host "> problem VMs." -ForegroundColor DarkGray

        Pause

        Write-Host `n "        Please make your selection:
        " `n -ForegroundColor Magenta -NoNewline

        $selection = Read-Host '
        Enter here'
    
        switch ($selection) {
            1 {Query-4VMsWithNoIPsOrOSInfo;break}
            2 {Restart-NoOSorIPsInfoOnlineVMs;break}
            3 {break}

            }#End Switch

        }#End if

        else { Query-4VMsWithNoIPsOrOSInfo }#End else

}#End Menu4VMsWithNoIPsOrOSInfo 

function Get-MyADUserAccountsDetails {

<#
.SYNOPSIS
    Get common Active Directory user information
    normally checked in an Enterpise Domain.


.NOTES   
    Name: Get-MyADUserAccountsDetails
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Invoke-Command -ComputerName HCL-DC01.hcl.lmco.com `
        -Credential $da_creds `
        -ScriptBlock {  $MyLastName4ADUCQuery = ('*' + ($env:USERNAME).substring(2)).Trim() 
                        Write-Host "     Checking your samaccountname search criteria = $MyLastName4ADUCQuery" -NoNewline -ForegroundColor Green
                        Write-Host " in ADUC returning information for all of your accounts." -ForegroundColor Green
                        Get-ADUser -f {samaccountname -like $MyLastName4ADUCQuery} -prop * |
                            select name,sam*me,en*,when*,lock*, `
                                @{l='Account Lockout Time';e={[datetime]::FromFileTime($_.AccountLockoutTime)}}, `
                                @{l='Last Logon Timestamp';e={[datetime]::FromFileTime($_.lastlogontimestamp)}}, `
                                last*te,@{l='Last Logon';e={[datetime]::FromFileTime($_.lastlogon)}}}#End ScriptBlock

}#End Get-MyADUserAccountsDetails

function PressEnterToStartQueryingProblemVMs {

<#
.SYNOPSIS
    Regularly used function for programmatic use with
    the Query involving VMs with no OS or IP information.


.NOTES   
    Name: PressEnterToStartQueryingProblemVMs
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Write-Host ""
    Write-Host ""
    Write-Host "
        Press enter to start querying problem VMs.
    " -ForegroundColor Green 
    Write-Host ""
    Write-Host ""
    Write-Host "    " -NoNewline

    Pause

}#End PressEnterToStartQueryingProblemVMs

function Ask-ToRunYourADUserAcctsQuery {

<#
.SYNOPSIS
    This is used to ask whether or not the user wants to
    kick off Get-MyADUserAccountsDetails, and then start
    querying for VMs with no OS or IP information.


.NOTES   
    Name: Ask-ToRunYourADUserAcctsQuery
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Write-Host "
    #####################################################################################################
    #                                                                                                   #
    #                    Would you like to check the status of your ADUC accounts?                      #
    #                                                                                                   #
    #####################################################################################################
    " -ForegroundColor Green

    $MyAnswer = Read-Host "Answer [N]o or Default [Y]es"

    Write-Host `n `n "You answered $MyAnswer" `n `n -ForegroundColor DarkGray

    switch -Regex ($MyAnswer) {

        $DefaultYesMatch { Get-MyADUserAccountsDetails | ft -AutoSize
                    PressEnterToStartQueryingProblemVMs } #End $YesMatch

        $NoMatch { PressEnterToStartQueryingProblemVMs } #End NoMatch

        default { Write-Host "
                  You were given a simple Yes or No question with two very obvious options.
                  However, you decided to say something stupid instead.

                  Going to the VM check anyway.

                  " -ForegroundColor Yellow ; PressEnterToStartQueryingProblemVMs } #End default

    }#End switch selection

    Query-4VMsWithNoIPsOrOSInfo

}#End Ask-ToRunYourADUserAcctsQuery

function CommonActiveDirectoryCommands {

<#
.SYNOPSIS
    Useful information commonly needed for PowerShell users.


.NOTES   
    Name: CommonActiveDirectoryCommands
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    Write-Host '
                                                                                                              
      ncpa.cpl   -------------------------> Opens the Network Connections to change IP settings in the Windows GUI.
      mstsc.exe  -------------------------> Opens RDP GUI.                                                         
      sysdm.cpl ,3 (using cmd.exe)                                                                            
      (sysdm.cpl works in PowerShell)                                                                         
       or SystemPropertiesAdvanced -------> Opens System properties to change the hostname or domain/workgroup.
      ssh-agent [bash|pwsh|PowerShell] ---> Initiates ssh agent to be run in the shell specified on RHEL or Windows.
      ssh-add <yourPrivateSSHKey> --------> adds your SSH key to the shell prompting for your passphrase if necessary.
       adding your ssh key allows the current shell session to ssh without password/passphrase prompts to remote systems.
                                                                                                              
      Common Commands I use on the DC:                                                                        
                                                                                                              
      Import-Module ActiveDirectory ------> Directly adds the ActiveDirectory PowerShell Module to your current session.
      Get-ADUser -f {name -like "*melonas*"} -prop * |
                    ft name,sam*me,en*,when*,lock*, `
                    @{l="Account Lockout Time";e={[datetime]::FromFileTime($_.AccountLockoutTime)}}, `
                    @{l="Last Logon Timestamp";e={[datetime]::FromFileTime($_.lastlogontimestamp)}}, `
                    last*te,@{l="Last Logon";e={[datetime]::FromFileTime($_.lastlogon)}} -autosize
      # Checks details of a user account to see status information like last lockout time, if it is enabled, and other info.
    ' -ForegroundColor Cyan

}#End CommonActiveDirectoryCommands 

function Set-MyVariables {

<#
.SYNOPSIS
    Regex vars for setting credentials to secure global varables.


.NOTES   
    Name: Set-MyVariables
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    # Global Yes and No Regex matches for user input filtration
    $global:YesMatch        = '^y(?:e)?(?:s)?$'
    $global:DefaultYesMatch = '^y(?:e)?(?:s)?$|^\s+$|^$'
    $global:NoMatch         = '^n(?:o)?$'
    $global:DefaultNoMatch  = '^n(?:o)?$|^\s+$|^$'
    #>

    $global:Typehasher = @{
    accdb = "Microsoft Access database file";
    accde = "Microsoft Access execute-only file";
    accdr = "Microsoft Access runtime database";
    accdt = "Microsoft Access database template";
    avi = "Audio Video Interleave movie or sound file";
    bat = "PC batch file";
    bin = "Binary compressed file";
    bmp = "Bitmap file";
    cab = "Windows Cabinet file";
    c = "C Programming File";
    cc = "C++ Programming File";
    cfg = "Configuration File";
    cda = "CD Audio Track";
    cer = "Certificate File";
    cert = "Certificate File";
    ckl = "STIG Checklist";
    cmd = "Windows Command File";
    csh = "C Shell File";
    csv = "Comma-separated values file";
    dif = "Spreadsheet data interchange format file";
    dir = "Directory";
    dll = "Dynamic Link Library file";
    doc = "Microsoft Word document before Word 2007";
    docm = "Microsoft Word macro-enabled document";
    docx = "Microsoft Word document";
    exe = "Executable program file";
    flat = "Flat File";
    flv = "Flash-compatible video file";
    gif = "Graphical Interchange Format file";
    go = "golang File";
    h = "C Programming Core File";
    htm = "Hypertext markup language page";
    html = "Hypertext markup language page";
    in = "Input File";
    ini = "Windows initialization configuration file";
    init = "Initialization Configuration File";
    iso = "ISO-9660 disc image";
    jar = "Java architecture file";
    jpg = "Joint Photographic Experts Group photo file";
    jpeg = "Joint Photographic Experts Group photo file";
    json = "JavaScript Object Notation";
    m4a = "MPEG-4 audio file";
    man = "Manual File";
    manifest = "Manifest File";
    md = "Markdown Language File";
    mdb = "Microsoft Access database before Access 2007";
    mid = "Musical Instrument Digital Interface file";
    midi = "Musical Instrument Digital Interface file";
    mov = "Apple QuickTime movie file";
    mp3 = "MPEG layer 3 audio file";
    mp4 = "MPEG 4 video";
    mpeg = "Moving Picture Experts Group movie file";
    mpg = "MPEG 1 system stream";
    msi = "Microsoft installer file";
    ok = "Digest File";
    pam = "Pluggable Authentication Module";
    pdf = "Portable Document Format file";
    png = "Portable Network Graphics file";
    pot = "Microsoft PowerPoint template before PowerPoint";
    potm = "Microsoft PowerPoint macro-enabled template";
    potx = "Microsoft PowerPoint template";
    ppam = "Microsoft PowerPoint add-in";
    pps = "Microsoft PowerPoint slideshow before PowerPoint";
    ppsm = "Microsoft PowerPoint macro-enabled slideshow";
    ppsx = "Microsoft PowerPoint slideshow";
    ppt = "Microsoft PowerPoint format before PowerPoint";
    pptm = "Microsoft PowerPoint macro-enabled presentation";
    pptx = "Microsoft PowerPoint presentation";
    prv = "Private File";
    psd = "Adobe Photoshop file";
    ps1 = "Powershell Script";
    psm1 = "Powershell Module";
    psd1 = "Powershell Manifest";
    pst = "Outlook data store";
    pub = "Microsoft Publisher file";
    py = "Python Programming File";
    pyc = "Python Code File";
    rar = "Roshal Archive compressed file";
    rc = "Resource File";
    rst = "reStructuredText markup language";
    rtf = "Rich Text Format file";
    rpm = "RedHat Package Manager software package";
    sldm = "Microsoft PowerPoint macro-enabled slide";
    sldx = "Microsoft PowerPoint slide";
    sln = "Visual Studio Solution File";
    sh = "bash Shell Script";
    ssh = "Secure Shell File";
    sshd = "Secure Shell File";
    sig = "Digital Signature File";
    spec = "spec String File"
    svg = "Scalable Vector Graphics";
    swf = "Shockwave Flash file";
    sys = "Microsoft DOS and Windows system settings and variables file";
    tar = "Tarball file";
    tif = "Tagged Image Format file";
    tiff = "Tagged Image Format file";
    tmp = "Temporary data file";
    txt = "Text Document";
    unk = "Unknown";
    vcproj = "Visual C++ File";
    vcxproj = "Visual C++ Project File";
    filters = "Visual C++ XML MSBuild File";
    vob = "Video object file";
    vsd = "Microsoft Visio drawing before Visio 2013";
    vsdm = "Microsoft Visio macro-enabled drawing";
    vsdx = "Microsoft Visio drawing file";
    vs = "Vertex Shader File";
    vsh = "Vertex Shader File";
    vss = "Microsoft Visio stencil before Visio 2013";
    vssm = "Microsoft Visio macro-enabled stencil";
    vst = "Microsoft Visio template before Visio 2013";
    vstm = "Microsoft Visio macro-enabled template";
    vstx = "Microsoft Visio template";
    wav = "Wave audio file";
    wbk = "Microsoft Word backup document";
    wix = "Windows Installer XML (WiX) File";
    wixproj = "Windows Installer XML (WiX) Project File";
    wks = "Microsoft Works file";
    wma = "Windows Media Audio file";
    wmd = "Windows Media Download file";
    wmv = "Windows Media Video file";
    wmz = "Windows Media skins file";
    wms = "Windows Media skins file";
    wpd = "WordPerfect document";
    wp5 = "WordPerfect document";
    wxs = "WordPress Export File in XML Format";
    xla = "Microsoft Excel add-in or macro file";
    xlam = "Microsoft Excel add-in after Excel 2007";
    xll = "Microsoft Excel DLL-based add-in";
    xlm = "Microsoft Excel macro before Excel 2007";
    xls = "Microsoft Excel workbook before Excel 2007";
    xlsm = "Microsoft Excel macro-enabled workbook after Excel 2007";
    xlsx = "Microsoft Excel workbook after Excel 2007";
    xlt = "Microsoft Excel template before Excel 2007";
    xltm = "Microsoft Excel macro-enabled template after Excel 2007";
    xltx = "Microsoft Excel template after Excel 2007";
    xml = "XML Document";
    xps = "XML-based document";
    yml = "Yet Another Markup Language";
    yaml = "Yet Another Markup Language";
    zip = "Compressed ZIP file";
    } #End Typehasher

    # My admin creds vars using Get-Credential.
    Write-Host "    Prepare to enter your credentials for secure storage in this shell using the Get-Credential cmd-let." -ForegroundColor Green
    Write-Host ""
    Pause

    # Manually set variables to what you want here if you wish (or DARE . . .)

    $global:MyVM       = (hostname)
    $global:dausername = Read-Host -Prompt "Enter Domain Admin username" 
    $global:da_creds   = Get-Credential -Message "Enter the Domain Admin Password" -UserName ($dausername + '@' + $env:USERDNSDOMAIN)
    $global:msusername = Read-Host -Prompt "Enter Member Server Admin username" 
    $global:ms_creds   = Get-Credential -Message "Enter the Member Server Admin Password" -UserName ($msusername + '@' + $env:USERDNSDOMAIN)
    $global:wausername = Read-Host -Prompt "Enter Workstation Admin username" 
    $global:wa_creds   = Get-Credential -Message "Enter the Member Server Admin Password" -UserName ($wausername + '@' + $env:USERDNSDOMAIN)
    $global:First_DC   = Read-Host -Prompt "Enter the Primary Domain Server Name" 
    $global:PrimaryDC  = $First_DC + '@' + $env:USERDNSDOMAIN
    $global:Second_DC  = Read-Host -Prompt "Enter the Primary Domain Server Name" 
    $global:SecondaryDC= $Second_DC + '@' + $env:USERDNSDOMAIN
    $global:vSphereSRV = Read-Host -Prompt "Enter the vSphere Server Name" 
    $global:vSphere    = $vSphereSRV + '@' + $env:USERDNSDOMAIN
    $global:HorizenView= Read-Host -Prompt "Enter the Horizon View Server Name" 
    $global:HVServer   = $HorizenView + '@' + $env:USERDNSDOMAIN
    #>

    <# My admin creds vars.
    $global:MyLastName  = (($env:USERNAME).substring(2)).Trim() 
    $global:NameToCheckADUC = ($env:USERNAME).substring(2) 
    $global:DomainAdmin        = "da" + $MyLastName + "@" + $env:USERDNSDOMAIN
    $global:MemberServerAdmin  = "ms" + $MyLastName + "@" + $env:USERDNSDOMAIN
    $global:SuperSecret     = Read-Host "Enter PowerCodes" -AsSecureString
    $global:da_creds = New-Object System.Management.Automation.PSCredential -ArgumentList ("da" + $global:NameToCheckADUC + "@hcl.lmco.com").ToString(),$SuperSecret
    $global:ms_creds = New-Object System.Management.Automation.PSCredential -ArgumentList ("ms" + $global:NameToCheckADUC + "@hcl.lmco.com").ToString(),$SuperSecret
    #>

}#End Set-MyVariables

#Extra untested functions

Function Get-GPUProfile {

    #http://www.virtu-al.net/2015/10/26/adding-a-vgpu-for-a-vsphere-6-0-vm-via-powercli/

    Param ($VMHost)
    $VMHost = (Get-VMhost) -match $VMhost
    $VMHost | Select-Object Name,Version,PowerState,ConnectionState,NumCPU, `
                $_.ExtensionData.Config.SharedPassthruGpuTypes,
                @{l='PercentCPUUsed';e={([string][System.Math]::Round(($_.ExtensionData.Config.SharedPassthruGpuTypes.CpuUsageMhz / $_.ExtensionData.Config.SharedPassthruGpuTypes.CpuTotalMhz)*100,2) + '%USED')}}, `
                @{l='PercentMemoryUsed';e={([string][System.Math]::Round(($_.ExtensionData.Config.SharedPassthruGpuTypes.MemoryUsageGB / $_.ExtensionData.Config.SharedPassthruGpuTypes.MemoryUsageGB)*100,2) + '%USED')}}
} #End Get-GPUProfile

  #                                     [string]([System.Math]::Round($AllSpace[$i],2)) + 'GB'

Function Get-vGPUDevice {

    #http://www.virtu-al.net/2015/10/26/adding-a-vgpu-for-a-vsphere-6-0-vm-via-powercli/

    Param ($VM)
    $VM = (Get-VM) -match $VM
    $vGPUDevice = $VM.ExtensionData.Config.hardware.Device | Where { $_.backing.vgpu}
    $vGPUDevice | Select Key,ControllerKey,Unitnumber, `
                    @{Name="Device";Expression={$_.DeviceInfo.Label}}, @{Name="Summary";Expression={$_.DeviceInfo.Summary}}
} #End Get-vGPUDevice

Function Remove-vGPU {

    #http://www.virtu-al.net/2015/10/26/adding-a-vgpu-for-a-vsphere-6-0-vm-via-powercli/

    Param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,Position=0)] $VM,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true,Position=1)] $vGPUDevice
    )
  
    $ControllerKey = $vGPUDevice.controllerKey
    $key = $vGPUDevice.Key
    $UnitNumber = $vGPUDevice.UnitNumber
    $device = $vGPUDevice.device
    $Summary = $vGPUDevice.Summary
  
    $VM = Get-VM $VM
  
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
    $spec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $spec.deviceChange[0].operation = 'remove'
    $spec.deviceChange[0].device = New-Object VMware.Vim.VirtualPCIPassthrough
    $spec.deviceChange[0].device.controllerKey = $controllerkey
    $spec.deviceChange[0].device.unitNumber = $unitnumber
    $spec.deviceChange[0].device.deviceInfo = New-Object VMware.Vim.Description
    $spec.deviceChange[0].device.deviceInfo.summary = $summary
    $spec.deviceChange[0].device.deviceInfo.label = $device
    $spec.deviceChange[0].device.key = $key
    $_this = $VM  | Get-View
    $nulloutput = $_this.ReconfigVM_Task($spec)
} #End Remove-vGPU

Function New-vGPU {

    #http://www.virtu-al.net/2015/10/26/adding-a-vgpu-for-a-vsphere-6-0-vm-via-powercli/

    Param ($VM, $vGPUProfile)
    $VM = Get-VM $VM
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
    $spec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $spec.deviceChange[0].operation = 'add'
    $spec.deviceChange[0].device = New-Object VMware.Vim.VirtualPCIPassthrough
    $spec.deviceChange[0].device.deviceInfo = New-Object VMware.Vim.Description
    $spec.deviceChange[0].device.deviceInfo.summary = ''
    $spec.deviceChange[0].device.deviceInfo.label = 'New PCI device'
    $spec.deviceChange[0].device.backing = New-Object VMware.Vim.VirtualPCIPassthroughVmiopBackingInfo
    $spec.deviceChange[0].device.backing.vgpu = "$vGPUProfile"
    $vmobj = $VM | Get-View
    $reconfig = $vmobj.ReconfigVM_Task($spec)
    if ($reconfig) {
        $ChangedVM = Get-VM $VM
        $vGPUDevice = $ChangedVM.ExtensionData.Config.hardware.Device | Where { $_.backing.vgpu}
        $vGPUDevice | Select Key, ControllerKey, Unitnumber, @{Name="Device";Expression={$_.DeviceInfo.Label}}, @{Name="Summary";Expression={$_.DeviceInfo.Summary}}
  
    }   
} #End New-vGPU

function Set-vGPUtoDesignatedVMs {

    #http://www.virtu-al.net/2015/10/26/adding-a-vgpu-for-a-vsphere-6-0-vm-via-powercli/


    <#
    $VMHost = Get-VMHost 10.114.64.86
    $vGPUProfile = Get-GPUProfile -vmhost $VMHost
    
    Write-Host "The following vGPU Profiles are available to choose for this host"
    $vGPUProfile
    
    # Choose a profile to use from the list
    $ChosenvGPUProfile = $vGPUProfile | Where {$_ -eq "grid_m60-4q" }
    
    # Get a VM to add it to
    $VM = Get-VM 3DVM_Win7_20GB_86
    
    Write-Host "Adding the vGPU to $vm"
    New-vGPU -VM $vm -vGPUProfile $ChosenvGPUProfile
    
    # At a later date
    Read-Host "The device has been added, press enter to remove again"
    Write-Host "Removing the GPU Devices in $VM"
    Remove-vGPU -VM $vm -vGPUDevice (Get-vGPUDevice -vm $VM)


    #>

} #End Set-vGPUtoDesignatedVMs

Function Get-SerialPort {

    #https://blogs.vmware.com/PowerCLI/2012/05/working-with-vm-devices-in-powercli.html

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        $VM
    )
    Process {
        Foreach ($VMachine in $VM) {
            Foreach ($Device in $VMachine.ExtensionData.Config.Hardware.Device) {
                If ($Device.gettype().Name -eq "VirtualSerialPort"){
                    $Details = New-Object PsObject
                    $Details | Add-Member Noteproperty VM -Value $VMachine
                    $Details | Add-Member Noteproperty Name -Value $Device.DeviceInfo.Label
                    If ($Device.Backing.FileName) { $Details | Add-Member Noteproperty Filename -Value $Device.Backing.FileName }
                    If ($Device.Backing.Datastore) { $Details | Add-Member Noteproperty Datastore -Value $Device.Backing.Datastore }
                    If ($Device.Backing.DeviceName) { $Details | Add-Member Noteproperty DeviceName -Value $Device.Backing.DeviceName }
                    $Details | Add-Member Noteproperty Connected -Value $Device.Connectable.Connected
                    $Details | Add-Member Noteproperty StartConnected -Value $Device.Connectable.StartConnected
                    $Details
                }
            }
        }
    }
} #End Get-SerialPort

Function Remove-SerialPort {

    #https://blogs.vmware.com/PowerCLI/2012/05/working-with-vm-devices-in-powercli.html

    Param (
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)]
        $VM,
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)]
        $Name
    )
    Process {
        $VMSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $VMSpec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $VMSpec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $VMSpec.deviceChange[0].operation = "remove"
        $Device = $VM.ExtensionData.Config.Hardware.Device | Foreach {
            $_ | Where {$_.gettype().Name -eq "VirtualSerialPort"} | Where { $_.DeviceInfo.Label -eq $Name }
        }
        $VMSpec.deviceChange[0].device = $Device
        $VM.ExtensionData.ReconfigVM_Task($VMSpec)
    }
} #End Remove-SerialPort

Function Get-ParallelPort {

    #https://blogs.vmware.com/PowerCLI/2012/05/working-with-vm-devices-in-powercli.html

    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        $VM
    )
    Process {
        Foreach ($VMachine in $VM) {
            Foreach ($Device in $VMachine.ExtensionData.Config.Hardware.Device) {
                If ($Device.gettype().Name -eq "VirtualParallelPort"){
                    $Details = New-Object PsObject
                    $Details | Add-Member Noteproperty VM -Value $VMachine
                    $Details | Add-Member Noteproperty Name -Value $Device.DeviceInfo.Label
                    If ($Device.Backing.FileName) { $Details | Add-Member Noteproperty Filename -Value $Device.Backing.FileName }
                    If ($Device.Backing.Datastore) { $Details | Add-Member Noteproperty Datastore -Value $Device.Backing.Datastore }
                    If ($Device.Backing.DeviceName) { $Details | Add-Member Noteproperty DeviceName -Value $Device.Backing.DeviceName }
                    $Details | Add-Member Noteproperty Connected -Value $Device.Connectable.Connected
                    $Details | Add-Member Noteproperty StartConnected -Value $Device.Connectable.StartConnected
                    $Details
                }
            }
        }
    }
} #End Get-ParallelPort

Function Remove-ParallelPort {

    #https://blogs.vmware.com/PowerCLI/2012/05/working-with-vm-devices-in-powercli.html

    Param (
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)]
        $VM,
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)]
        $Name
    )
    Process {
        $VMSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $VMSpec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $VMSpec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $VMSpec.deviceChange[0].operation = "remove"
        $Device = $VM.ExtensionData.Config.Hardware.Device | Foreach {
            $_ | Where {$_.gettype().Name -eq "VirtualParallelPort"} | Where { $_.DeviceInfo.Label -eq $Name }
        }
        $VMSpec.deviceChange[0].device = $Device
        $VM.ExtensionData.ReconfigVM_Task($VMSpec)
    }
} #End Remove-ParallelPort

function Yet-AnotherGPUScript {

    <#
    Yet Another Script:

    The following script can changes this profile based on the available on the server.
    https://www.logitblog.com/change-vmware-vgpu-settings-powershell/

    Please note: Changing profiles may cause problems so use the script at your own risk.
    #>

    Param (
            [Parameter(Mandatory=$true)] $hostname,
            [Parameter(Mandatory=$true)] $username,
            [Parameter(Mandatory=$true)] $password,
            [Parameter(Mandatory=$true)] $vmname
        )
        
    # Load VMware snapin
    Add-PSSnapin VMware*

    # Connect to the VMware Host
    Connect-VIServer -Server $hostname -User $username -Password $password | Out-Null

    # Collect host information
    $vmHost = Get-VMHost $hostname

    # Define vGPU Profiles
    $vGpuProfiles = $vmhost.ExtensionData.Config.SharedPassthruGpuTypes

    Write-Host "#############################"
    Write-Host "# Available vGPU profiles   #"
    Write-Host "# Select your vGPU profiles #"
    Write-Host "#############################"

    $i = 0
    foreach ($vGpuProfile in $vGpuProfiles)
    {
        Write-Host "[$i] - $vGpuProfile"
        $i++
    }
    Write-Host "#############################"

    do 
    {
        try 
        {	
            $validated = $true
            $max = $i -1 
            [int]$vGpuSelectionInt = Read-Host -Prompt "Please choose a vGPU profile (select between 0 - $max)"
        }
        catch {$validated = $false}
    }
    until (($vGpuSelectionInt -ge 0 -and $vGpuSelectionInt -le $max) -and $validated)
    $vGpuSelection = $vGpuProfiles[$vGpuSelectionInt]
    Write-Host "You have selected:" $vGpuSelection

    # Collect the VM's that need to change the vGPU profile
    $vms = Get-VM -Name $vmName
    $vmsOn = $vms | Where-Object {$_.PowerState -eq "PoweredOn"}

    Write-Host "VM's wihtin the selection:" $vms.Count
    Write-Host "Couple VM's are still powered on, shutdown command will be executed for:" $vmsOn.Count

    # Go into the shutdown loop when VM's are still on
    if ($vmsOn.Count -gt 0)
    {
        do
        {
            # Collect the VM's that need to change the vGPU profile
            $vmsOn = Get-VM -Name $vmName | Where-Object {$_.PowerState -eq "PoweredOn"}
            
            $activeShutdown = $false
            # Shutdown PoweredOn VM's 
            foreach ($vmOn in $vmsOn)
            {
                    Write-Host "Shutdown VM:" $vmOn
                    if ($vmOn.ExtensionData.Guest.GuestState -eq "running")
                    {
                        $vmOn | Stop-VMGuest -Confirm:$false | Out-Null
                    }
                    else
                    {
                        $vmOn | Stop-VM -Confirm:$false | Out-Null
                    }
                    
                    $activeShutdown = $true
            }
            
            # Sleep when shutdown is active
            if ($activeShutdown)
            {
                Start-Sleep -Seconds 10
            }
        }
        until ($vmsOn.Count -le 0)
    }

    foreach ($vm in $vms)
    {

        $vGPUDevices = $vm.ExtensionData.Config.hardware.Device | Where { $_.backing.vgpu}
            if ($vGPUDevices.Count -gt 0)
        {
            Write-Host "Remove existing vGPU configuration from VM:" $vm.Name
            foreach ($vGPUDevice in $vGPUDevices)
            {
                $controllerKey = $vGPUDevice.controllerKey
                $key = $vGPUDevice.Key
                $unitNumber = $vGPUDevice.UnitNumber
                $device = $vGPUDevice.device
                $summary = $vGPUDevice.Summary
            
                $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
                $spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
                $spec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
                $spec.deviceChange[0].operation = 'remove'
                $spec.deviceChange[0].device = New-Object VMware.Vim.VirtualPCIPassthrough
                $spec.deviceChange[0].device.controllerKey = $controllerKey
                $spec.deviceChange[0].device.unitNumber = $unitNumber
                $spec.deviceChange[0].device.deviceInfo = New-Object VMware.Vim.Description
                $spec.deviceChange[0].device.deviceInfo.summary = $summary
                $spec.deviceChange[0].device.deviceInfo.label = $device
                $spec.deviceChange[0].device.key = $key
                $_this = $VM  | Get-View
                $nulloutput = $_this.ReconfigVM_Task($spec)
            }
        }

        Write-Host "Adding new vGPU configuration from VM:" $vm.Name
        $vmSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $vmSpec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (1)
        $vmSpec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec
        $vmSpec.deviceChange[0].operation = 'add'
        $vmSpec.deviceChange[0].device = New-Object VMware.Vim.VirtualPCIPassthrough
        $vmSpec.deviceChange[0].device.deviceInfo = New-Object VMware.Vim.Description
        $vmSpec.deviceChange[0].device.deviceInfo.summary = ''
        $vmSpec.deviceChange[0].device.deviceInfo.label = 'New PCI device'
        $vmSpec.deviceChange[0].device.backing = New-Object VMware.Vim.VirtualPCIPassthroughVmiopBackingInfo
        $vmSpec.deviceChange[0].device.backing.vgpu = "$vGpuSelection"

        $vmobj = $vm | Get-View

        $reconfig = $vmobj.ReconfigVM_Task($vmSpec)
        if ($reconfig) {
            $changedVm = Get-VM $vm
            $vGPUDevice = $changedVm.ExtensionData.Config.hardware.Device | Where { $_.backing.vgpu}
        }   
    }
    Write-Host "Done with configuration"
    timeout /t 15

} #End Yet-AnotherGPUScript

function Remove-UserProfiles {

<#
.SYNOPSIS
    Untested function to remove users profiles from remote Windows systems.


.NOTES   
    Name: Remove-UserProfiles
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://letmegooglethat.com/

#>

    [CmdletBinding(DefaultParameterSetName='Computer')]
    param(
        [Parameter(Mandatory = $false, 
            ParameterSetName ='Computers',
            ValueFromPipeline = $true,
            Position = 0)]
            [String[]]$Computers,
        [Parameter(Mandatory = $false, 
            ParameterSetName ='Computer',
            HelpMessage = 'Enter computers (Default is this machine)',
            ValueFromPipeline = $true,
            Position = 0)]
            [String[]]$Computer = (hostname),
        [Parameter(Mandatory = $true, 
        ParameterSetName ='Usernames',
        ValueFromPipeline = $true)]
        [String[]]$Usernames = (Read-Host "Enter samaccount User ID you want to delete: ")
        )

    foreach ($Computer in $Computers) {

        Invoke-Command -ComputerName $computer -ScriptBlock {
            foreach ($user in $Usernames) {
                #param($user)
                $localpath = 'c:\users\' + $user
                Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.LocalPath -eq $localpath} | 
                Remove-WmiObject -WhatIf
            }#End foreach user in Usernames 
        } -ArgumentList $Usernames #End the scriptblock.

    }#End foreach Computer in Computers.

}#End Remove-UserProfiles

function Set-HumanReadableByteSize ($Size) {

<#
.SYNOPSIS
    Get File sizes of the files and directories in the PWD.


.NOTES   
    Name: Remove-UserProfiles
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://www.reddit.com/r/PowerShell/comments/hchq59/get_file_type/
    
#>

    switch ($Size) {

    {$_ -gt 1PB} {[string]([Math]::Round($size / 1PB,3)) + "PB";break}
	{$_ -gt 1TB} {[string]([Math]::Round($size / 1TB,3)) + "TB";break}
	{$_ -gt 1GB} {[string]([Math]::Round($size / 1GB,3)) + "GB";break}
	{$_ -gt 1MB} {[string]([Math]::Round($size / 1MB,3)) + "MB";break}
	{$_ -gt 1KB} {[string]([Math]::Round($size / 1KB,3)) + "KB";break}
    {$_ -lt 1KB} {[string]([Math]::Round($size,3));break}

	default {"$size"}

	} #End switch

} #End Set-HumanReadableByteSize

function Get-AllItemsByteSizes {

        gi -LiteralPath (gci).name | select Attributes,Name,Extension,LastWriteTime, `
        @{l='ByteSize';e={(Set-HumanReadableByteSize -Size (gci $_.Name -Recurse -Force | Measure-Object Length -Sum).Sum)}}

} #End Get-AllItemsByteSizes

function Get-FileAndFolderInformation {

<#
.SYNOPSIS
    Get the type and size of the files and folders passed to this function.


.NOTES   
    Name: Get-FileAndFolderInformation
    Author: Michael Melonas
    Version: 1.0
    DateCreated: 2023-JUN-07


.EXAMPLE
    For updated help and examples refer to GoogleFu.


.LINK
    https://www.reddit.com/r/PowerShell/comments/hchq59/get_file_type/
    
#>

    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="Pipeline"
            )]
        [PsObject[]]$AllThings = (gci)
    )

    BEGIN {
        #Verifying the object is a Directory Item
        #if ($null -eq $AllThings.Extension) { 
        #    $AllThings.Extension = 'dir'
        #}
        #Write-Host $AllThings -ForegroundColor Green
        # $i = 1
        # $Count = $AllThings.Count
    } #End BEGIN

    # This works: 
    # gi -LiteralPath (gci).name | % {Write-Host $_.name,$_.extension,$_.size -ForegroundColor Green;HumanReadableByteSize -Size (gci $_.Name -Recurse -Force | Measure-Object Length -Sum).Sum}

    PROCESS {
        foreach($AnItem in $AllThings){

        #Write-Host $AnItem -ForegroundColor Cyan

        try {

            IdentifyFileType -TheItems $AnItem

            } catch {
                write-Error "Something went wrong." 
                Write-Error $_.Exception.Message
            } #End try catch

        } #End foreach
    } #End Process
    #$FileTypeDataSets

    End {}
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

} #End Get-FileAndFolderInformation

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
        [PsObject[]]$TheItems
    )

    #$items = Get-ChildItem "C:\temp"

    foreach($item in $TheItems){
        [PSCustomObject]@{
        ItemName          = $Item.Name
        ItemAttributes    = $Item.Attributes
        ItemLiteralName   = $Item.FullName
        ItemExtension     = if ($Item.Attributes -eq $Typehasher.dir){[string]"dir"}
                            elseif ($Item.Extension -match '\S+'){($($item.Extension).Substring(1))}
                            elseif ($Item.Extension -eq $null) {[string]'unk'}
                            else {[string]'flat'} #End if elseif else
        ItemExtFullName   = if ($Item.Attributes -eq $Typehasher.dir){($Typehasher.dir)}
                            elseif ($Item.Extension -match '\S+'){$Typehasher.($($item.Extension).Substring(1))} 
                            elseif ($Item.Extension -eq $null) {$Typehasher.unk.Substring(0)}
                            else {$Typehasher.flat.Substring(0)} #End if elseif else
        ItemLastWriteTime = $Item.LastWriteTime
        ItemByteSize      = Set-HumanReadableByteSize -Size (gci $Item.FullName -Recurse -Force | Measure-Object Length -Sum).Sum
        } #End PSCustomObject
    }# End foreach

} #End IdentifyFileType

function notify-account-expiration {

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
            Subject = 'MASC-F Account Expiration Dates Report'
            body = 'Please see attached report of upcoming account expirations.'
            SmtpServer = $smtpServer
            Attachments = "$localfolder\$date-var-expiration-dates.csv"
        }

        Send-MailMessage @mailParamAdmins
    }

    Stop-Transcript

}#End notify-account-expiration

function New-DynamicAnsibleInventoryGenerator {

    [CmdletBinding(SupportsPaging)]

    <#
    .SYNOPSIS
    Create a Dynamic Ansible Inventory file from a list of IPs gathered from vSphere VM name matches.

    .DESCRIPTION
    Create a Dynamic Ansible Inventory file from a list of IPs gathered from vSphere VM name matches.
    Default values -TheListedItems grab every VM out of vSphere along with it's associated IP, and
    -OutputFile is set to ~/Documents/NewAnsibleDynamicInventory.ini

    .EXAMPLE
    New-DynamicAnsibleInventoryGenerator
    $MyResults =  New-DynamicAnsibleInventoryGenerator

    .LINKS
    https://qwant.com
    #>

    param(
        [Parameter(ValueFromPipeline=$true)]$TheListedItems=(Get-IPFromVM . | Select-Object name,powerstate,ips | Where-Object {$_.Powerstate -eq 'PoweredOn'}),
        [Parameter(ValueFromPipeline=$true)]$OutputFile="IPs_DynamicInventory",
        [Parameter(ValueFromPipeline=$true)]$HostnameOutputFile="Hostnames_DynamicInventory"
    )#>

    BEGIN {
        #remember [ipaddress]$_ sets and identifies the value as an IP address in PowerShell. 
        $ansible_hostname_blob;$ip_blob;$ansible_ip_blob;$ProdPurposeKeyCombo;$ProdPurposeValueCombo
        $FullOutputFile = ($OutputFile + (Get-Date -Format FileDateTime) + ".ini")
        $HostnameFullOutputFile = ($HostnameOutputFile + (Get-Date -Format FileDateTime) + ".ini")
        $hostname_blob = $TheListedItems | Select-Object Name,IPs
        $self += @{products=@{o1x="1X";o2x="2X";pro="prototype";srv="servers"}}
        $self += @{purpose=@{dev="development";tst="testing";run="runtime";glr="glrunner";
                   bzr="bazelremote";aqu="aquasec";aap="ansible";gpu="nvidia";sbx="sandbox"}}
        $self += @{IPInventory = @{}};$self += @{SetIPs = @{}};$self += @{SetHostnames = @{}}
        $self += @{LinuxInfrastructure = @{Linux=@{}}};$self += @{WindowsInfrastructure = @{Windows=@{}}}
    }#End Begin

    PROCESS {

        if (!(Test-Path ~/Documents/AnsibleInventoryFiles)) {

            mkdir -p ~/Documents/AnsibleInventoryFiles

        }# End if

        foreach ($productKey in $self.products.Keys) {
            foreach ($purposeKey in $self.purpose.Keys) {
                #Write-Host $productKey "and" $purposeKey -ForegroundColor DarkYellow

                $ip_blob = @()
                $ansible_hostname_blob = @()
                $ProdPurposeKeyCombo   = (($productKey)+'-'+($purposeKey))
                $ProdPurposeValueCombo = (($self.products.$productKey)+'_'+($self.purpose.$purposeKey))

                $ansible_hostname_blob = $hostname_blob | Where-Object {$_.Name -match $ProdPurposeKeyCombo} | Sort-Object Name -Unique
                Write-Host "    The count of the Hostnames in $ProdPurposeValueCombo is" $ansible_hostname_blob.Count -ForegroundColor DarkYellow
                #Pause

                $self.SetHostnames += @{$ProdPurposeKeyCombo = @{$ProdPurposeValueCombo = (
                                        $ansible_hostname_blob | foreach {$_.Name + ' ansible_host=' + $_.IPs})}}
                                        #Write-Host $self.SetHostnames.$ProdPurposeKeyCombo.$ProdPurposeValueCombo
                                        #Pause

                $ip_blob += ($TheListedItems | Where-Object {
                            $_.Name -match $ProdPurposeKeyCombo
                            }).IPs | Select-Object -Unique
                Write-Host "    The count of the IPS in $ProdPurposeValueCombo is" $ip_blob.count `n -ForegroundColor DarkYellow
                #Pause

                $grouped_ip_blob = $ip_blob | Group-Object -AsHashTable {
                                   $_.Substring(0, $_.LastIndexOf('.')) }

                $self.IPInventory += @{$ProdPurposeKeyCombo = @{$ProdPurposeValueCombo = $grouped_ip_blob}}

                #Now Setting the Ansible IP Sets in these nested loops:
                ForEach ($EachKey in $($grouped_ip_blob.Keys)) {

                    $ansible_ip_blob = @()

                    #Write-Host $EachKey -ForegroundColor Magenta
                    #Write-Host $grouped_ip_blob.$EachKey -ForegroundColor DarkYellow

                    [string[]]$TempIPRange = (($grouped_ip_blob.$EachKey.ForEach({[IPAddress]$_})) |
                                             Sort-Object Address).IPAddressToString #End $TempIPRange Variable

                    #Write-Host $TempIPRange -ForegroundColor Cyan                    

                    [string]$TheStartIteration = $TempIPRange[0]

                    for ($j = 0;$j -lt $TempIPRange.Count; $j++) {

                        if  ($j -eq ($TempIPRange.Count -1) -and `
                            ([int]($TempIPRange[$j-1].Split('.')[3]) +1) `
                            -eq [int]($TempIPRange[$j].Split('.')[3])) {
                            $ansible_ip_blob += (($EachKey + '.[' + $TheStartIteration.Split('.')[3] `
                            + ':' + ($TempIPRange[($TempIPRange.count - 1)]).Split('.')[3] + ']'))
                        }#End if

                        elseif  ($j -eq ($TempIPRange.Count -1)) {$ansible_ip_blob +=  $TempIPRange[$j]}#End if

                        elseif (
                            ([int]($TempIPRange[$j].Split('.')[3]) - 1) -ne ([int]($TempIPRange[$j-1].Split('.')[3])) -and `
                            ([int]($TempIPRange[$j].Split('.')[3]) + 1) -ne ([int]($TempIPRange[$j+1].Split('.')[3]))
                        ) {
                            $ansible_ip_blob +=  $TempIPRange[$j];$TheStartIteration = $TempIPRange[$j+1]
                        }#End elseif

                        elseif (
                            ([int]($TempIPRange[$j].Split('.')[3]) +1) -ne [int]($TempIPRange[$j+1].Split('.')[3]) 
                        ) {
                            $ansible_ip_blob += $EachKey + '.[' + [string]$TheStartIteration.Split('.')[3] `
                                                + ':' + [string]$TempIPRange[$j].Split('.')[3]  + ']'
                            $TheStartIteration = $TempIPRange[$j+1]
                        }#End elseif
                    }#End for $j loop

                $self.SetIPs += @{$($ProdPurposeKeyCombo+'_'+$EachKey) = @{$($ProdPurposeValueCombo+'_'+$EachKey) = $ansible_ip_blob}}

                }#End foreach $EachKey loop

            #Match value to use $ProdPurposeValueCombo

            if ($self.SetIPs.Values.Keys -match $ProdPurposeValueCombo) {

                Write-Host "    Output Inventory Group $ProdPurposeValueCombo" -ForegroundColor Green
                Write-Host "    for IP range going into file ~/Documents/AnsibleInventoryFiles/$FullOutputFile" -ForegroundColor Green
                ('['+$ProdPurposeValueCombo+']') | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$FullOutputFile -Append

                Write-Host "    Output IPs for the currently iterative Group $ProdPurposeValueCombo" -ForegroundColor DarkGreen
                ($self.SetIPs.Values | Where-Object {$_.keys -match $ProdPurposeValueCombo}) |
                Select-Object -ExpandProperty Values | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$FullOutputFile -Append
                "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$FullOutputFile -Append #For carriage returns use "`r"
            }# End if

            }#End foreach
        
        }#End foreach

        Write-Host `n `n "      Writing to the Hostname and IP Inventory files . . ." `n `n -ForegroundColor Blue

        "[Infrastructure:children]" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        $self.LinuxInfrastructure.Keys | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        $self.WindowsInfrastructure.Keys | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append #For carriage returns use "`r"

        $PopulatedHostKeysAndValues = $self.SetHostnames.Values | Where-Object {$_.Values -ne $null}

        "[IaC:children]" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        $PopulatedHostKeysAndValues.Keys | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append #For carriage returns use "`r"

        "[Linux]" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        $self.LinuxInfrastructure = @{Linux = $TheListedItems |
            Where-Object {$_.IPs -like "*.50.*" -and $_.GuestOS -match 'Linux'} |
            Sort-Object Name | foreach {$_.Name + ' ansible_host=' + $_.IPs}}
        $self.LinuxInfrastructure.Values | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append #For carriage returns use "`r"

        "[Windows]" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        $self.WindowsInfrastructure = @{Windows = $TheListedItems |
            Where-Object {$_.IPs -like "*.50.*" -and $_.GuestOS -match 'Windows'} |
            Sort-Object Name | foreach {$_.Name + ' ansible_host=' + $_.IPs}}
        $self.WindowsInfrastructure.Values | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
        "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append #For carriage returns use "`r"

        foreach ($HostKey in $PopulatedHostKeysAndValues) {
            "["+$HostKey.Keys+"]" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
            $HostKey.Values | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append
            "`n" | Out-File -FilePath ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile -Append #For carriage returns use "`r"
        }

    }#End PROCESS

    END {
        
        sleep 3
        Write-Host `n `n `n 
        Write-Host "Your accumulated IP results in Ansible ini file format are located here in ~/Documents/AnsibleInventoryFiles/$FullOutputFile." `n -ForegroundColor DarkCyan
        Write-Host "Your accumulated Hostname results in Ansible ini file format are located here in ~/Documents/AnsibleInventoryFiles/$HostnameFullOutputFile." -ForegroundColor Blue
        Write-Host `n `n `n
        return $self
    }#End END

}#End New-DynamicAnsibleInventory
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
   
}#End Remove-DNSEntry

<#foreach ($GroupN in $IP_Grouping) {
    Pause
    $CurrentIteratedIP = [int]$ActualUniqueIPasIP[$i].IPAddressToString.Split('.')[3]
    $TheLastIteratedIP = [int]$ActualUniqueIPasIP[$i-1].IPAddressToString.Split('.')[3]
    if  ($i -eq ($ActualUniqueIPasIP.IPAddressToString.Count -1)) {
        $ip_blob += ([string](($IP_Grouping.name) + '.[' + $TheStartIteration.Split('.')[3] + ':' `
            + $ActualUniqueIPasIP[($IP_Grouping.count - 1)].IPAddressToString.Split('.')[3] + ']'))
    }#End if

    elseif (
        $TheLastIteratedIP -ne ($CurrentIteratedIP - 1) -and `
        ($CurrentIteratedIP + 1) -ne ([int]$ActualUniqueIPasIP[$i+1].IPAddressToString.Split('.')[3])
    ) {
        $ip_blob += ($ActualUniqueIPasIP[$i].IPAddressToString)
        $TheStartIteration = $ActualUniqueIPasIP[$i+1].IPAddressToString
    }#End elseif

    elseif (
        ($TheLastIteratedIP +1) -ne $CurrentIteratedIP 
        ) {$TheStartIteration = $ActualUniqueIPasIP[$i].IPAddressToString}#End elseif

    elseif (([int]$ActualUniqueIPasIP[$i+1].IPAddressToString.Split('.')[3]) -ne ($CurrentIteratedIP + 1)) {
        $ip_blob += ([string]$IP_Grouping.name + '.[' + [string]$TheStartIteration.Split('.')[3] `
                     + ':' + [string]$ActualUniqueIPasIP[$i].IPAddressToString.Split('.')[3]  + ']')
        $TheStartIteration = $ActualUniqueIPasIP[$i].IPAddressToString
    }#End elseif 

    }#End foreach loop#>

Function Get-VMDeleteHistory {
   <#
        .NOTES
        ===========================================================================
        Created by: William Lam
        Organization: VMware
        Blog: www.virtuallyghetto.com
        Twitter: @lamw
        ===========================================================================
        .PARAMETER MaxSamples
            Specifies the maximum number of retrieved events (default 500)
        .EXAMPLE
            Get-VMDeleteHistory
        .EXAMPLE
            Get-VMDeleteHistory -MaxSamples 100
                .VERSION 1.0.0
        .GUID 62fd99cb-5129-47b4-ae95-8bdf31d829dc
        .AUTHOR William Lam
        .COMPANYNAME VMware
        .COPYRIGHT Copyright 2021, William Lam
        .TAGS VMware VM Deleted
        .LICENSEURI
        .PROJECTURI https://github.com/lamw/vghetto-scripts/blob/master/powershell/VmDeleteHistory.ps1
        .ICONURI https://blogs.vmware.com/virtualblocks/files/2018/10/PowerCLI.png
        .EXTERNALMODULEDEPENDENCIES
        .REQUIREDSCRIPTS
        .EXTERNALSCRIPTDEPENDENCIES
        .RELEASENOTES
            1.0.0 - Initial Release
        .PRIVATEDATA
        .DESCRIPTION This function retrieves information about deleted VMs
        .SITE
        https://www.powershellgallery.com/packages/VmDeleteHistory/1.0.0
    #>
    param(
        [Parameter(Mandatory=$false)]$MaxSamples=500
    )

    $results = @()
    $events = Get-VIEvent -MaxSamples $MaxSamples -Types Info | 
              where {$_.GetType().Name -eq "TaskEvent" -and `
              $_.FullFormattedMessage -eq "Task: Delete virtual machine" }

    foreach ($event in $events) {
        $tmp = [pscustomobject] @{
            VM = $event.Vm.Name;
            User = $event.UserName;
            Date = $event.CreatedTime;
        }
        $results += $tmp
    }
    $results
}#End Get-VMDeleteHistory

function Get-ClusterCapacityCheck {

    #https://yadhutony.blogspot.com/2019/09/get-cluster-resources-using-powercli.html

    [CmdletBinding()]
    param(
    [Parameter(Position=0,Mandatory=$true,HelpMessage="Name of the cluster to test",
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
    $Clusters,
    [Parameter(Position=1,Mandatory=$false,HelpMessage="How many days ago to evaluate;Default is one day")]
    [int]$HowManyDaysAgo=1
    )

    begin {
        $Finish = (Get-Date -Hour 0 -Minute 0 -Second 0)
        $Start = $Finish.AddDays(-($HowManyDaysAgo)).AddSeconds(1)
    }

    process {

        $Clusters | ft -a

        foreach ($Cluster in $Clusters) {

            $ClusterCPUCores = $Cluster.ExtensionData.Summary.NumCpuCores
            $ClusterVMs = $Cluster | Get-VM

            [PSCustomObject]@{
            Name                          = $Cluster.Name
            TotalVmCount                  = $Cluster.ExtensionData.Summary.UsageSummary.TotalVmCount
            ClusterCPUCores               = $ClusterCPUCores
            ClusterAllocatedvCPUs         = ($ClusterVMs | Measure-Object -Property NumCPu -Sum).Sum
            ClustervCPUpCPURatio          = [math]::round($ClusterAllocatedvCPUs / $ClusterCPUCores,2)
            ClusterEffectiveMemory        = Set-HumanReadableByteSize -Size (($Cluster.ExtensionData.Summary.EffectiveMemory) * 1048576)
            ClusterAllocatedMemory        = Set-HumanReadableByteSize -Size (($ClusterVMs | Measure-Object -Property MemoryMB -Sum).Sum  * 1048576)
            ClusterActiveMemoryPercentage = [math]::round(($Cluster | 
                                                Get-Stat -Stat mem.usage.average -Start $Start -Finish $Finish | 
                                                Measure-Object -Property Value -Average).Average,0)
            ClusterFreeDiskspace          = Set-HumanReadableByteSize -Size (((Get-Datastore) -match $Cluster.Name).FreeSpaceGB * 1073741824)
            ClusterTotalDiskspace         = Set-HumanReadableByteSize -Size (((Get-Datastore) -match $Cluster.Name).CapacityGB  * 1073741824)
            CpuDemandMhz                  = $Cluster.ExtensionData.Summary.UsageSummary.CpuDemandMhz
            CpuEntitledMhz                = $Cluster.ExtensionData.Summary.UsageSummary.CpuEntitledMhz
            CpuReservationMhz             = $Cluster.ExtensionData.Summary.UsageSummary.CpuReservationMhz
            PoweredOffCpuReservationMhz   = $Cluster.ExtensionData.Summary.UsageSummary.PoweredOffCpuReservationMhz
            TotalCpuCapacityMhz           = $Cluster.ExtensionData.Summary.UsageSummary.TotalCpuCapacityMhz
            MemDemand                     = Set-HumanReadableByteSize -Size ($Cluster.ExtensionData.Summary.UsageSummary.MemDemandMB * 1048576)
            MemEntitled                   = Set-HumanReadableByteSize -Size ($Cluster.ExtensionData.Summary.UsageSummary.MemEntitledMB * 1048576)
            MemReservation                = Set-HumanReadableByteSize -Size ($Cluster.ExtensionData.Summary.UsageSummary.MemReservationMB * 1048576)
            PoweredOffMemReservation      = Set-HumanReadableByteSize -Size ($Cluster.ExtensionData.Summary.UsageSummary.PoweredOffMemReservationMB * 1048576)
            TotalMemCapacity              = Set-HumanReadableByteSize -Size (($Cluster.ExtensionData.Summary.UsageSummary.TotalMemCapacityMB) * 1048576)
            PoweredOffVmCount             = $Cluster.ExtensionData.Summary.UsageSummary.PoweredOffVmCount
            StatsGenNumber                = $Cluster.ExtensionData.Summary.UsageSummary.StatsGenNumber
            }#End New-Object
        }#End foreach
    }#End process
}# End Get-ClusterCapacityCheck

function Get-vSphereStatistics {

    $OGPWD      = pwd
    $DoxHomeDir = "$HOME/Documents"
    cd $DoxHomeDir

    $VMsQuery     = Get-IPFromVM '.+' 2>'VMErrors.txt'      #1>'VMOutputs.txt'
    $HostsQuery   = Get-VMHost        2>'HostsErrors.txt'   #1>'HostsOutputs.txt'
    $ClusterQuery = Get-ClusterCapacityCheck -Clusters (Get-Cluster) | Where-Object {$null -ne $_.Name} |
                        Select-Object Name,TotalVmCount,TotalCpuCapacityMhz,TotalMemCapacity,PoweredOffVmCount, `
                                      PoweredOffCpuReservationMhz,PoweredOffMemReservation,ClusterCPUCores,     `
                                      ClusterAllocatedvCPUs,ClustervCPUpCPURatio,CpuDemandMhz,CpuEntitledMhz,   `
                                      CpuReservationMhz,ClusterActiveMemoryPercentage,ClusterAllocatedMemory,   `
                                      ClusterEffectiveMemory,ClusterFreeDiskspace,ClusterTotalDiskspace,        `
                                      MemDemand,MemEntitled,MemReservation,StatsGenNumber 2>'ClusterErrors.txt' #1>'ClusterOutputs.txt'
    $ErroredFiles = Get-ChildItem  | Where-Object {$_.name -match 'ors\.txt' -and $_.Length -ne 0} 

    if (!(Test-Path vSphereStatistics)) {

        mkdir vSphereStatistics

    }# End if

    cd "$DoxHomeDir\vSphereStatistics"

    if ($null -ne $ErroredFiles) {
        Write-Host "    There are errors occuring; would you like to review them before continuing?"
        Write-Host "    Press CTRL+C to stop OR,"
        Pause
    }# End if

    $VMsQuery     | Sort-Object Name | Export-Csv VM_vHardware.csv     -NoTypeInformation
    $HostsQuery   | Sort-Object Name | Export-Csv Host_Hardware.csv    -NoTypeInformation
    $ClusterQuery | Sort-Object Name | Export-Csv Cluster_Hardware.csv -NoTypeInformation

    if (!(Test-Path VMStats)) {

        mkdir VMStats

    }# End if

    cd "$DoxHomeDir\vSphereStatistics\VMStats"

    write-host "Starting VM Information Exports . . ." -ForegroundColor Cyan

    ($VMsQuery).name | 
        ForEach-Object {Write-Host "Current VM is $_" -ForegroundColor Green
            Get-Stat $_ | Select-Object entity,time*,met*,Value,unit | 
            Sort-Object time* | Export-Csv "$_.csv" -NoTypeInformation
        }# End ForEach-Object

    cd "$DoxHomeDir\vSphereStatistics"

    if (!(Test-Path HostStats)) {

        mkdir HostStats

    }# End if

    cd "$DoxHomeDir\vSphereStatistics\HostStats"

    write-host "Starting Host Information Exports . . ." -ForegroundColor Blue

    ($HostsQuery).name | 
        ForEach-Object {Write-Host "Current Host is $_" -ForegroundColor Green
            Get-Stat $_ | Select-Object entity,time*,met*,Value,unit | 
            Sort-Object time* | Export-Csv "$_.csv" -NoTypeInformation
        }# End ForEach-Object

    cd "$DoxHomeDir\vSphereStatistics"

    if (!(Test-Path ClusterStats)) {

        mkdir ClusterStats

    }# End if

    cd "$DoxHomeDir\vSphereStatistics\ClusterStats"

    write-host "Starting Cluster Information Exports . . ." -ForegroundColor Magenta

    ($ClusterQuery).Name |
        ForEach-Object {
            Write-Host "Current Cluster is $_" -ForegroundColor Green
            Get-Stat $_ | Select-Object entity,time*,met*,Value,unit | 
            Sort-Object time* | Export-Csv "$_.csv" -NoTypeInformation
        }# End ForEach-Object

    cd $OGPWD

    Write-Host ""
    Write-Host ""
    Write-Host "    Your results are in the $HOME/Documents/vSphereStatistics folder." -ForegroundColor Cyan
    Write-Host ""
    Write-Host ""

}# End Get-vSphereStats

function Get-WhoDidStuffINvSphere {

    [CmdletBinding()]
    param(
    [Parameter(Position=0,Mandatory=$false,HelpMessage="Username for the person of interest. This is defaulted to you.",
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
    [System.String]$DomainUserName=$ms_creds.UserName,
    [Parameter(Position=1,Mandatory=$false,HelpMessage="How many days ago to evaluate")]
    [int]$HowManyDaysAgo=1,
    [Parameter(Position=2,Mandatory=$false,HelpMessage="The latest date to finish the query. This is defaulted to today.",
    ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
    $FinishDate=(Get-Date)
    )

    $start = $FinishDate.AddDays(-($HowManyDaysAgo))

    Get-VIEvent -Start $start -Finish $FinishDate |
        where {$_ -is [VMware.Vim.TaskEvent] -and $_.UserName -eq $userName} |
            Select CreatedTime, UserName, FullFormattedMessage,
            @{N = 'Datacenter'; E = {$_.Datacenter.Name}},
            @{N = 'Cluster'; E = {$_.ComputeResource.Name}},
            @{N = 'VMHost'; E = {$_.Host.Name}},
            @{N = 'VM'; E = {$_.VM.Name}},
            @{N = 'Datastore'; E = {$_.Ds.Name}}

}# End Get-WhoDidStuffINvSphere 
#>
