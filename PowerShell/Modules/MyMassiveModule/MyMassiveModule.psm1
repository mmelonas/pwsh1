

<#

Hella scripts converted to functions to make awesome cmd-lets in a superbadass module.

Some global variables for the module are listed here.

For keyboard shortcut help in PowerShell ISE go to:
https://technet.microsoft.com/en-us/library/jj984298.aspx

Tab completion help http://stackoverflow.com/questions/17114701/auto-complete-user-input-powershell-2-0

#>

#Ensure PowerCLI global search path in PowerShell.
#Reference article: http://blogs.vmware.com/PowerCLI/2015/03/powercli-6-0-introducing-powercli-modules.html
$PowerCLIModulePath = “C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules”
$OldModulePath = [Environment]::GetEnvironmentVariable(‘PSModulePath’,’Machine’)
if ($OldModulePath -notmatch “PowerCLI”) {
Write-Host “[Adding PowerCLI Module directory to Machine PSModulePath]” -ForegroundColor Green
 $OldModulePath += “;$PowerCLIModulePath”
[Environment]::SetEnvironmentVariable(‘PSModulePath’,”$OldModulePath”,’Machine’)
 } else {
 Write-Host “[PowerCLI Module directory already in PSModulePath. No action taken]” -ForegroundColor Cyan
 }

#Set the execution policy

Set-ExecutionPolicy Bypass

#MassiveModule Variables

#This variable gets the current user logged on.
$CurrentUser = [Environment]::UserName

#This variable is for outputting results into HTML5 and CSS formatting.
$CSS = @'
<style>

body {
    font-family:Helvetica, Arial, sans-serif;
    font-size:8pt;
    background: #000050
}

h2 {
    color:white;
    text-align:center;
    text-decoration:underline;
    font-size:18pt;
 }

h3 {
    color:white;
    text-align:center;
    text-decoration:underline;
    font-size:18pt;
    animation-name: colours;
    animation-timing-function: ease;
    animation-iteration-count: infinite;
    animation-duration: 1s;
}

@keyframes colours {
    0% {color: red; }
    100% {color: inherit; }
}

table.MyTable {margin-left: auto;margin-right: auto;font-family:Verdana;font-size:10pt;margin-left: auto;margin-right: auto}
.MyTable th{color:yellow; background-Color:black;}
.MyTable tr {color:white}
.MyTable TR:Nth-Child(even) {Background-Color: #191970;}
.MyTable tr,td,th {padding: 2px; margin: 0px;text-align: center;vertical-align:top}
.MyTable tr:hover {background-color: darkgray;}
</style>
'@

<#

I left this code as a reference to the $CSS variable.

table.ErrorTable {margin-left: auto;margin-right: auto;font-family:Verdana;font-size:10pt;margin-left: auto;margin-right: auto}
.ErrorTable th{color:yellow; background-Color:black;}
.ErrorTable tr {color:white;background-Color:green}
.ErrorTable TR:Nth-Child(even) {Background-Color: red;}
.ErrorTable tr,td,th {padding: 2px; margin: 0px;text-align: center;vertical-align:top}
.ErrorTable tr:hover {background-color: deeppink;}
</style>


[string]$ServiceHTML = "<h2>TEST</h2>$(get-process notepad | select * |convertTo-HTML  -fragment | out-string |
 Add-HTMLTableAttribute  -AttributeName 'class' -Value 'MyTable')"

#>

#Now starts the functions turned into cmd-lets!

Function Add-HTMLTableAttribute {
    Param
    (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]
    $HTML,

    [Parameter(Mandatory=$true)]
    [string]
    $AttributeName,

    [Parameter(Mandatory=$true)]
    [string]
    $Value

    )

    $xml=[xml]$HTML
    $attr=$xml.CreateAttribute($AttributeName)
    $attr.Value=$Value
    $xml.table.Attributes.Append($attr) | Out-Null
    Return ($xml.OuterXML | out-string)
}#End Add-HTMLTableAttribute

function WinRM_ClientQuery {

    $ErrorActionPreference = "SilentlyContinue"
    $Complist = gc .\_Comps.txt #Suggest using a Read-Host for a filename here.

    Write-Host "

    Option 1: Query Updates Information.


    Option 2: Install Available Updates.


    "

    $choices = "1|2"

    do{ $question = Read-Host -Prompt 'Enter Option 1 or 2 '

      } until ($question -match $choices)




    switch ($question)
    {

    1 {


	    foreach ($c in $Complist) 
	    {

	    $CurrentSession = New-Pssession $c -port 80
	    #Get-PSSession

	    $RebootCheck = (get-wmiobject -Namespace 'ROOT\ccm\ClientSDK' -Class 'CCM_ClientUtilities' -list).DetermineIfRebootPending().RebootPending


	    $FailedUpdateCount = Invoke-Command -Session $CurrentSession -ScriptBlock {(get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.EvaluationState -eq 13}).count}
	    $AvaliableUpdatesCount = Invoke-Command -Session $CurrentSession -ScriptBlock {(get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.ComplianceState -eq 0 -AND $_.EvaluationState -eq 0}).count}
	    $UpdatesInProgressCount = Invoke-Command -Session $CurrentSession -ScriptBlock {(get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.EvaluationState -eq 6 -OR $_.EvaluationState -eq 7}).count}


	    Write-Host `n`n "$c"
	    Write-Host "--------------"
	    Write-Host "Reboot Pending = $RebootCheck"

	    Write-Host "Available Updates Count:   $AvaliableUpdatesCount"
	    Invoke-Command -Session $CurrentSession -ScriptBlock {get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.ComplianceState -eq 0 -AND $_.EvaluationState -eq 0} | Select PSComputerName,ArticleID,Name,Publisher | FT -Auto -wrap}


	    Write-Host `n"In Progress Updates Count: $UpdatesInProgressCount"
	    Invoke-Command -Session $CurrentSession -ScriptBlock {get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.EvaluationState -eq 6 -OR $_.EvaluationState -eq 7} | Select PSComputerName,ArticleID,Name,Publisher | FT -Auto -wrap}


	    Write-Host `n"Failed Updates Count:      $FailedUpdateCount"
	    Invoke-Command -Session $CurrentSession -ScriptBlock {get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.EvaluationState -eq 13} | Select PSComputerName,ArticleID,Name,Publisher | FT -Auto -wrap}

	    Get-PSSession | Remove-PSSession
	    $CurrentSession = ""
	    $FailedUpdateCount = ""
	    $AvaliableUpdatesCount = ""
	    $UpdatesInProgressCoun = ""
	    }
      }


    2 {

	    foreach ($c in $Complist) 
	    {
	    $CurrentSession = New-Pssession $c
	    $AllUpdates = Invoke-Command -Session $CurrentSession -ScriptBlock {get-wmiobject -query "SELECT * FROM CCM_SoftwareUpdate" -namespace "ROOT\ccm\ClientSDK" | ?{$_.ComplianceState -eq 0 -AND $_.EvaluationState -eq 0}}
	    Invoke-Command -Session $CurrentSession -ScriptBlock {(Get-WmiObject -Namespace 'root\ccm\clientsdk' -Class 'CCM_SoftwareUpdatesManager' -List).InstallUpdates([System.Management.ManagementObject[]]$AllUpdates)}
	    Get-PSSession | Remove-PSSession
	    $CurrentSession = ""
	    }
      }

    }


}#End WinRM_ClientQuery

function Top {

    [CmdletBinding()]
    param(
	    [Parameter(Position=0,ValueFromPipeline=$true)]
	    [Alias("CN","Computer")]
	    [String[]]$ComputerName="$env:COMPUTERNAME"
        )

    while (1) {ps | sort -desc cpu | select -first 30; 
    sleep -seconds 2; cls; 
    write-host "Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id ProcessName"; 
    write-host "-------  ------    -----      ----- -----   ------     -- -----------"}

}#End Top

function Test-ServiceHealth_AllExchangeServers {

    #Get the list of Exchange servers in the organization
    $servers = Get-ExchangeServer

    #Loop through each server
    ForEach ($server in $servers)
    {
	    Write-Host -ForegroundColor White "---------- Testing" $server

	    #Initialize an array object for the Test-ServiceHealth results
	    [array]$servicehealth = @()

	    #Run Test-ServiceHealth
	    $servicehealth = Test-ServiceHealth $server

	    #Output the results
	    ForEach($serverrole in $servicehealth)
	    {
		    If ($serverrole.RequiredServicesRunning -eq $true)
		    {
			    Write-Host $serverrole.Role -NoNewline; Write-Host -ForegroundColor Green "Pass"
		    }
		    Else
		    {
			    Write-Host $serverrole.Role -nonewline; Write-Host -ForegroundColor Red "Fail"
			    [array]$notrunning = @()
			    $notrunning = $serverrole.ServicesNotRunning
			    ForEach ($svc in $notrunning)
			    {
				    $alertservices += $svc
			    }
			    Write-Host $serverrole.Role "Services not running:"
			    ForEach ($al in $alertservices)
				    {
					    Write-Host -ForegroundColor Red `t$al
				    }
		    }
	    }
    }

}#End Test-ServiceHealth_AllExchangeServers

function Shut-TheFuckUP {

    # This is for people that need to shut the fuck up because they LOL to youtube 12 hours a day.

    #For Joe Ash
    Invoke-Command -ComputerName kdhrwkafgn550dt -ScriptBlock {ipconfig /release}

    #For Titus
    Invoke-Command -ComputerName kdhrwkafgn550cj -ScriptBlock {ipconfig /release}

    #For Casey
    Invoke-Command -ComputerName kdhrnbafgna534c -ScriptBlock {ipconfig /release}

    #Faggot computer will be rebooted!

    #For Joe Ash
    Get-Service -DisplayName *net* -ComputerName kdhrwkafgn550dt | ? -Property status -Like running
    Stop-Service (Get-Service -DisplayName *net* -ComputerName kdhrwkafgn550dt) -Force

    Invoke-Command -ComputerName kdhrwkafgn550dt -ScriptBlock {ipconfig /release}

    #For Titus
    Get-Service -DisplayName *net* -ComputerName kdhrwkafgn550cj | ? -Property status -Like running
    Stop-Service (Get-Service -Name lmhosts,napagent,nlasvc,iphlpsvc -ComputerName kdhrwkafgn550cj) -Force
    Stop-Service (Get-Service -Name nsi -ComputerName kdhrwkafgn550cj) -Force
    Stop-Service (Get-Service -Name net* -ComputerName kdhrwkafgn550cj) -Force

    Invoke-Command -ComputerName kdhrwkafgn550cj -ScriptBlock {ipconfig /release}

    #For Casey
    Get-Service -DisplayName *net* -ComputerName kdhrnbafgna534c | ? -Property status -Like running
    Stop-Service (Get-Service -DisplayName *net* -ComputerName kdhrnbafgna534c) -Force

    Invoke-Command -ComputerName kdhrnbafgna534c -ScriptBlock {ipconfig /release}

    #Faggot computer will be rebooted! <-This is an optional message placed here for your convenience.

}#End Shut-TheFuckUP

function Restart-ExchangeServices {

    #Use this command to check the status of the critical Exchange Services (replace $Hostname with the actual computer name:

    $Hostname = Read-Host "Enter an Exchange Server name or IP":

    gsv -Name "MSE*" -ComputerName $Hostname

    #Note gsv is short for Get-Service

    #Use this command to Start the remote service:

    #Start-Service (gsv -Name "MSE*" -ComputerName $Hostname)

    #Use this command to Stop the remote service:

    #Stop-Service (gsv -Name "MSE*" -ComputerName $Hostname)

    #Use this command to Restart the service:

    #Restart-Service (gsv -Name "MSE*" -ComputerName $Hostname)

    #THIS command usually does the trick, and it is why it's not commented out. HOWEVER ------
    #A check for all services starting with MSE* is done after the command for YOU to verify NOT ME!!!!
    
    Write-Host -BackgroundColor DarkBlue -ForegroundColor Cyan "Enter 1 to restart MSExchangeADTopology or anything else to NOT!"`n`n`n
    $UserAnswer = Read-Host

    if ($UserAnswer -eq '1') {
        Write-Host -BackgroundColor Black -ForegroundColor Magenta "HEY!!!"`n`n
        Write-Host -BackgroundColor DarkBlue -ForegroundColor Cyan "This may take a while so be patient!"`n`n

        Restart-Service (gsv -Name "msexchangead*" -ComputerName $Hostname)

        Write-Host `n`n

        gsv -Name "MSE*" -ComputerName $Hostname

        Write-Host -BackgroundColor DarkBlue -ForegroundColor Cyan `n"Ensure necessary services are running. Use Test-ServiceHealth."`n`n
    }#End if

    else {
        
        Write-host -BackgroundColor DarkBlue -ForegroundColor Cyan "abort!"

    }#End else

    <#

    Sometimes you may have to utilize a combiniation of stopping a combination of services that are depended
    on by the ones that won't start. For example don't just stop a specific service such as MSExchangeSA, but 
    MSExchan*, which will stop all services starting with MSExchan. Then after the command completes start all
    services beginning with MSExchan*. If you have trouble not getting a service to stop or start it may be
    stuck in a startup loop, which can happen, and the only real remedy is going to services, changing the 
    Properties of the service to a 'Automatic Delayed Start' status, and then reboot the system.

    You may have to put some effort into trouble shooting. Don't come whining to me if these suggestions aren't
    working for ya'.

    #>

}#End Restart-ExchangeServices

function Check-AdobeConnectServices {

<#
.SYNOPSIS
This is a work in progress script to start services on a remote machine from a list of machines in the 
comps.txt file where this script is located. You can create the Text file if you want as long as it 
exists in the same directory. Have fun!
#>

    $Hostnames = Read-Host "Enter a computer name(s) in single quotes here seperated by commas." #gc .\comps.txt

    foreach ($HostName in $HostNames) {
        
        Write-Host -ForegroundColor Magenta -BackgroundColor DarkBlue `n "Current Status of services on this $Hostnames"

        $Services = gsv -Name Connec*,Fms* -ComputerName $Hostname

        foreach ($Service in $Services) {

            if ($Service.status -eq 'Running') {
    
                Write-Host -ForegroundColor Cyan -BackgroundColor DarkBlue `n`n $ServiceName.name "is already running."
    
            }#End If Statement

            else {
        
                Write-Host -ForegroundColor Yellow -BackgroundColor DarkGreen "Starting" $ServiceName.name
        
                Start-Service (gsv -Name $ServiceName.name -ComputerName $Hostname)

            }#End else
        
        }#End foreach $Services

    }#End foreach $HostNames

    Write-Host -ForegroundColor Magenta -BackgroundColor DarkBlue `n "Adobe Services on $Hostnames"

    gsv -Name "Connec*","Fms*" -ComputerName $Hostname | select -Property name,status

}#End Check-AdobeConnectServices

function Invoke-WinrmQuickConfig {

    #Run winrm quickconfig defaults
    echo Y | winrm quickconfig

    #Run enable psremoting command with defaults
    enable-psremoting -force

    #Enabled Trusted Hosts for Universial Access
    cd wsman:
    cd localhost\client
    Set-Item TrustedHosts * -force
    restart-Service winrm
    echo "Complete"

}#End Invoke-WinrmQuickConfig

function Get-RDCManLatestSystems4KAF{

<#
This nifty function will pull all systems on the domain, and make an RDG file that
Remote Desktop Connection Manager can use. 
#>

    ########################################################################### 
    # 
    # NAME: New-RDCManFile 
    # 
    # AUTHOR: Jan Egil Ring 
    # EMAIL: jer@powershell.no 
    # 
    # COMMENT: Script to create a XML-file for use with Microsoft Remote Desktop Connection Manager 
    #          For more details, see the following blog-post: 
    #          http://blog.powershell.no/2010/06/02/dynamic-remote-desktop-connection-manager-connection-list 
    # 
    # You have a royalty-free right to use, modify, reproduce, and 
    # distribute this script file in any way you find useful, provided that 
    # you agree that the creator, owner above has no warranty, obligations, 
    # or liability for such use. 
    # 
    # VERSION HISTORY: 
    # 1.0 02.06.2010 - Initial release 
    # 
    ########################################################################### 
 
    #Initial variables 

    $domain = $env:userdomain 
    $OutputFile = "C:\Users\michael.melonas\Desktop\$domain.rdg" 
 
#Create a template XML 
$template = @' 
<?xml version="1.0" encoding="utf-8"?> 
<RDCMan schemaVersion="1"> 
    <version>2.2</version> 
    <file> 
        <properties> 
            <name></name> 
            <expanded>True</expanded> 
            <comment /> 
            <logonCredentials inherit="FromParent" /> 
            <connectionSettings inherit="FromParent" /> 
            <gatewaySettings inherit="FromParent" /> 
            <remoteDesktop inherit="FromParent" /> 
            <localResources inherit="FromParent" /> 
            <securitySettings inherit="FromParent" /> 
            <displaySettings inherit="FromParent" /> 
        </properties> 
        <group> 
            <properties> 
                <name></name> 
                <expanded>True</expanded> 
                <comment /> 
                <logonCredentials inherit="None"> 
                    <userName></userName> 
                    <domain></domain> 
                    <password storeAsClearText="False"></password> 
                </logonCredentials> 
                <connectionSettings inherit="FromParent" /> 
                <gatewaySettings inherit="None"> 
                    <userName></userName> 
                    <domain></domain> 
                    <password storeAsClearText="False" /> 
                    <enabled>False</enabled> 
                    <hostName /> 
                    <logonMethod>4</logonMethod> 
                    <localBypass>False</localBypass> 
                    <credSharing>False</credSharing> 
                </gatewaySettings> 
                <remoteDesktop inherit="FromParent" /> 
                <localResources inherit="FromParent" /> 
                <securitySettings inherit="FromParent" /> 
                <displaySettings inherit="FromParent" /> 
            </properties> 
            <server> 
                <name></name> 
                <displayName></displayName> 
                <comment /> 
                <logonCredentials inherit="FromParent" /> 
                <connectionSettings inherit="FromParent" /> 
                <gatewaySettings inherit="FromParent" /> 
                <remoteDesktop inherit="FromParent" /> 
                <localResources inherit="FromParent" /> 
                <securitySettings inherit="FromParent" /> 
                <displaySettings inherit="FromParent" /> 
            </server> 
        </group> 
    </file> 
</RDCMan> 
'@ 
 
    #Output template to xml-file 
    $template | Out-File C:\Users\michael.melonas\Desktop\RDCMan-template.xml -encoding UTF8 
 
    #Load template into XML object 
    $xml = New-Object xml 
    $xml.Load("C:\Users\michael.melonas\Desktop\RDCMan-template.xml") 
 
    #Set file properties 
    $file = (@($xml.RDCMan.file.properties)[0]).Clone() 
    $file.name = $domain 
    $xml.RDCMan.file.properties | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.ReplaceChild($file,$_) } 
 
    #Set group properties 
    $group = (@($xml.RDCMan.file.group.properties)[0]).Clone() 
    $group.name = $env:userdomain 
    $group.logonCredentials.Username = $env:username 
    $group.logonCredentials.Domain = $domain 
    $xml.RDCMan.file.group.properties | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.group.ReplaceChild($group,$_) } 
 
    #Use template to add servers from Active Directory to xml  
    $server = (@($xml.RDCMan.file.group.server)[0]).Clone() 
    Get-ADComputer -f {name -like 'KDH*'} | select name,dnshostname | 
    ForEach-Object { 
    $server = $server.clone()     
    $server.DisplayName = $_.Name     
    $server.Name = $_.DNSHostName 
    $xml.RDCMan.file.group.AppendChild($server) > $null} 
    #Remove template server 
    $xml.RDCMan.file.group.server | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.group.RemoveChild($_) } 
 
    #Save xml to file 
    $xml.Save($OutputFile) 
 
    #Remove template xml-file 
    Remove-Item C:\Users\michael.melonas\Desktop\RDCMan-template.xml -Force

}#End Get-RDCManLatestSystems4KAF

function Get-RDCManLatestSystems {

#This is the original script with an LDAP filter instead of Get-ADComputer

    ########################################################################### 
    # 
    # NAME: New-RDCManFile 
    # 
    # AUTHOR: Jan Egil Ring 
    # EMAIL: jer@powershell.no 
    # 
    # COMMENT: Script to create a XML-file for use with Microsoft Remote Desktop Connection Manager 
    #          For more details, see the following blog-post: http://blog.powershell.no/2010/06/02/dynamic-remote-desktop-connection-manager-connection-list 
    # 
    # You have a royalty-free right to use, modify, reproduce, and 
    # distribute this script file in any way you find useful, provided that 
    # you agree that the creator, owner above has no warranty, obligations, 
    # or liability for such use. 
    # 
    # VERSION HISTORY: 
    # 1.0 02.06.2010 - Initial release 
    # 
    ########################################################################### 
 
    #Importing Microsoft`s PowerShell-module for administering ActiveDirectory 
    Import-Module ActiveDirectory 
 
    #Initial variables 

    $domain = $env:userdomain 
    $OutputFile = "C:\Users\michael.melonas\Desktop\$domain.rdg" 
 
#Create a template XML 
$template = @' 
<?xml version="1.0" encoding="utf-8"?> 
<RDCMan schemaVersion="1"> 
    <version>2.2</version> 
    <file> 
        <properties> 
            <name></name> 
            <expanded>True</expanded> 
            <comment /> 
            <logonCredentials inherit="FromParent" /> 
            <connectionSettings inherit="FromParent" /> 
            <gatewaySettings inherit="FromParent" /> 
            <remoteDesktop inherit="FromParent" /> 
            <localResources inherit="FromParent" /> 
            <securitySettings inherit="FromParent" /> 
            <displaySettings inherit="FromParent" /> 
        </properties> 
        <group> 
            <properties> 
                <name></name> 
                <expanded>True</expanded> 
                <comment /> 
                <logonCredentials inherit="None"> 
                    <userName></userName> 
                    <domain></domain> 
                    <password storeAsClearText="False"></password> 
                </logonCredentials> 
                <connectionSettings inherit="FromParent" /> 
                <gatewaySettings inherit="None"> 
                    <userName></userName> 
                    <domain></domain> 
                    <password storeAsClearText="False" /> 
                    <enabled>False</enabled> 
                    <hostName /> 
                    <logonMethod>4</logonMethod> 
                    <localBypass>False</localBypass> 
                    <credSharing>False</credSharing> 
                </gatewaySettings> 
                <remoteDesktop inherit="FromParent" /> 
                <localResources inherit="FromParent" /> 
                <securitySettings inherit="FromParent" /> 
                <displaySettings inherit="FromParent" /> 
            </properties> 
            <server> 
                <name></name> 
                <displayName></displayName> 
                <comment /> 
                <logonCredentials inherit="FromParent" /> 
                <connectionSettings inherit="FromParent" /> 
                <gatewaySettings inherit="FromParent" /> 
                <remoteDesktop inherit="FromParent" /> 
                <localResources inherit="FromParent" /> 
                <securitySettings inherit="FromParent" /> 
                <displaySettings inherit="FromParent" /> 
            </server> 
        </group> 
    </file> 
</RDCMan> 
'@ 
 
    #Output template to xml-file 
    $template | Out-File C:\Users\michael.melonas\Desktop\RDCMan-template.xml -encoding UTF8 
 
    #Load template into XML object 
    $xml = New-Object xml 
    $xml.Load("C:\Users\michael.melonas\Desktop\RDCMan-template.xml") 
 
    #Set file properties 
    $file = (@($xml.RDCMan.file.properties)[0]).Clone() 
    $file.name = $domain 
    $xml.RDCMan.file.properties | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.ReplaceChild($file,$_) } 
 
    #Set group properties 
    $group = (@($xml.RDCMan.file.group.properties)[0]).Clone() 
    $group.name = $env:userdomain 
    $group.logonCredentials.Username = $env:username 
    $group.logonCredentials.Domain = $domain 
    $xml.RDCMan.file.group.properties | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.group.ReplaceChild($group,$_) } 
 
    #Use template to add servers from Active Directory to xml  
    $server = (@($xml.RDCMan.file.group.server)[0]).Clone() 
    Get-ADComputer -LDAPFilter "(operatingsystem=*server*)" | select name,dnshostname | 
    ForEach-Object { 
    $server = $server.clone()     
    $server.DisplayName = $_.Name     
    $server.Name = $_.DNSHostName 
    $xml.RDCMan.file.group.AppendChild($server) > $null} 
    #Remove template server 
    $xml.RDCMan.file.group.server | Where-Object { $_.Name -eq "" } | ForEach-Object  { [void]$xml.RDCMan.file.group.RemoveChild($_) } 
 
    #Save xml to file 
    $xml.Save($OutputFile) 
 
    #Remove template xml-file 
    Remove-Item C:\Users\michael.melonas\Desktop\RDCMan-template.xml -Force
}#End Get-RDCManLatestSystems

function Get-HardDriveSpace{

#Gets basic Hard Drive information from a target computer you specify

    Write-Host -BackgroundColor DarkBlue -ForegroundColor Cyan "Enter a computer name(s) or IP(s) enclosed in `n
    single quotes, and seperated by commas"

    [string[]]$Hostnames = Read-Host 

    foreach ($Hostname in $Hostnames) {
        Get-WmiObject Win32_LogicalDisk -filter "DriveType=3" -ComputerName $Hostname |
        Select SystemName,DeviceID,VolumeName,
            @{Name="Size(GB)"; Expression={$_.size / 1GB -as [int]}},
            @{Name="FreeSpace(GB)"; Expression={$_.freespace / 1GB -as [int]}},
            @{Name="PercentFree(GB)"; Expression={($_.freespace / $_.size) *100 -as [int]}} |
        ? -Property DeviceID -Like F:

    }#End foreach

}#End Get-HardDriveSpace

function Get-IPrange {

<# 
.SYNOPSIS  
Get the IP addresses in a range 
.EXAMPLE 
Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
.EXAMPLE 
Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
.EXAMPLE 
Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 
param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
 
function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
 
 
for ($i = $startaddr; $i -le $endaddr; $i++) 
{ 
  INT64-toIP -int $i 
}

}#End Get-IPRange

function Get-FolderSize{

    Get-ChildItem C:\* -recurse | Where-Object {$_.PSIsContainer} | 
    ForEach-Object {New-Object PSObject -Property @{Path = $_.FullName 
    Size = [Math]::Round((Get-ChildItem $_.FullName -recurse | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB, 2)}} | 
    Where-Object {$_.Size -gt 1} | Select Path,Size | FT -AutoSize -Wrap

}#End Get-FolderSize

function Get-DirStats {

#REFERENCE Website: https://gallery.technet.microsoft.com/scriptcenter/Outputs-directory-size-964d07ff


# Get-DirStats
# Written by Michael Melonas
# Outputs file system directory statistics. 
 
#requires -version 2 
 
<# 
.SYNOPSIS 
Outputs file system directory statistics. 
 
.DESCRIPTION 
Outputs file system directory statistics (number of files and the sum of all file sizes) for one or more directories. 
 
.PARAMETER Path 
Specifies a path to one or more file system directories. Wildcards are not permitted. The default path is the current directory (.). 
 
.PARAMETER LiteralPath 
Specifies a path to one or more file system directories. Unlike Path, the value of LiteralPath is used exactly as it is typed. 
 
.PARAMETER Only 
Outputs statistics for a directory but not any of its subdirectories. 
 
.PARAMETER Every 
Outputs statistics for every directory in the specified path instead of only the first level of directories. 
 
.PARAMETER FormatNumbers 
Formats numbers in the output object to include thousands separators. 
 
.PARAMETER Total 
Outputs a summary object after all other output that sums all statistics. 
#> 
 
    [CmdletBinding(DefaultParameterSetName="Path")] 
    param( 
      [parameter(Position=0,Mandatory=$false,ParameterSetName="Path",ValueFromPipeline=$true)] 
        $Path=(get-location).Path, 
      [parameter(Position=0,Mandatory=$true,ParameterSetName="LiteralPath")] 
        [String[]] $LiteralPath, 
        [Switch] $Only, 
        [Switch] $Every, 
        [Switch] $FormatNumbers, 
        [Switch] $Total 
    ) 
 
    begin { 
      $ParamSetName = $PSCmdlet.ParameterSetName 
      if ( $ParamSetName -eq "Path" ) { 
        $PipelineInput = ( -not $PSBoundParameters.ContainsKey("Path") ) -and ( -not $Path ) 
      } 
      elseif ( $ParamSetName -eq "LiteralPath" ) { 
        $PipelineInput = $false 
      } 
 
      # Script-level variables used with -Total. 
      [UInt64] $script:totalcount = 0 
      [UInt64] $script:totalbytes = 0 
 
      # Returns a [System.IO.DirectoryInfo] object if it exists. 
      function Get-Directory { 
        param( $item ) 
 
        if ( $ParamSetName -eq "Path" ) { 
          if ( Test-Path -Path $item -PathType Container ) { 
            $item = Get-Item -Path $item -Force 
          } 
        } 
        elseif ( $ParamSetName -eq "LiteralPath" ) { 
          if ( Test-Path -LiteralPath $item -PathType Container ) { 
            $item = Get-Item -LiteralPath $item -Force 
          } 
        } 
        if ( $item -and ($item -is [System.IO.DirectoryInfo]) ) { 
          return $item 
        } 
      } 
 
      # Filter that outputs the custom object with formatted numbers. 
      function Format-Output { 
        process { 
          $_ | Select-Object Path, 
            @{Name="Files"; Expression={"{0:N0}" -f $_.Files}}, 
            @{Name="Size"; Expression={"{0:N0}" -f $_.Size}} 
        } 
      } 
 
      # Outputs directory statistics for the specified directory. With -recurse, 
      # the function includes files in all subdirectories of the specified 
      # directory. With -format, numbers in the output objects are formatted with 
      # the Format-Output filter. 
      function Get-DirectoryStats { 
        param( $directory, $recurse, $format ) 
 
        Write-Progress -Activity "Get-DirStats" -Status "Reading '$($directory.FullName)'" 
        $files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer } 
        if ( $files ) { 
          Write-Progress -Activity "Get-DirStats" -Status "Calculating '$($directory.FullName)'" 
          $output = $files | Measure-Object -Sum -Property Length | Select-Object ` 
            @{Name="Path"; Expression={$directory.FullName}}, 
            @{Name="Files"; Expression={$_.Count; $script:totalcount += $_.Count}}, 
            @{Name="Size"; Expression={$_.Sum; $script:totalbytes += $_.Sum}} 
        } 
        else { 
          $output = "" | Select-Object ` 
            @{Name="Path"; Expression={$directory.FullName}}, 
            @{Name="Files"; Expression={0}}, 
            @{Name="Size"; Expression={0}} 
        } 
        if ( -not $format ) { $output } else { $output | Format-Output } 
      } 
    } 
 
    process { 
      # Get the item to process, no matter whether the input comes from the 
      # pipeline or not. 
      if ( $PipelineInput ) { 
        $item = $_ 
      } 
      else { 
        if ( $ParamSetName -eq "Path" ) { 
          $item = $Path 
        } 
        elseif ( $ParamSetName -eq "LiteralPath" ) { 
          $item = $LiteralPath 
        } 
      } 
 
      # Write an error if the item is not a directory in the file system. 
      $directory = Get-Directory -item $item 
      if ( -not $directory ) { 
        Write-Error -Message "Path '$item' is not a directory in the file system." -Category InvalidType 
        return 
      } 
 
      # Get the statistics for the first-level directory. 
      Get-DirectoryStats -directory $directory -recurse:$false -format:$FormatNumbers 
      # -Only means no further processing past the first-level directory. 
      if ( $Only ) { return } 
 
      # Get the subdirectories of the first-level directory and get the statistics 
      # for each of them. 
      $directory | Get-ChildItem -Force -Recurse:$Every | 
        Where-Object { $_.PSIsContainer } | ForEach-Object { 
          Get-DirectoryStats -directory $_ -recurse:(-not $Every) -format:$FormatNumbers 
        } 
    } 
 
    end { 
      # If -Total specified, output summary object. 
      if ( $Total ) { 
        $output = "" | Select-Object ` 
          @{Name="Path"; Expression={"<Total>"}}, 
          @{Name="Files"; Expression={$script:totalcount}}, 
          @{Name="Size"; Expression={$script:totalbytes}} 
        if ( -not $FormatNumbers ) { $output } else { $output | Format-Output } 
      } 
    }

}#End Get-DirStats

function Get-DHCPLeases {

    # Get-DHCPLeases

    # Author : Assaf Miron

    # Description : This Script is used to get all DHCP Scopes and Leases from a specific DHCP Server

    #

    # Input : 

    # Output: 3 Log Files - Scope Log, Client Lease Log, Reserved Clients Log


    $DHCP_SERVER = "kdhra5afgn04002" # The DHCP Server Name

    $LOG_FOLDER = "m:\dhcp" # A Folder to save all the Logs

    # Create Log File Paths

    $ScopeLog = $LOG_FOLDER+"\ScopeLog.csv"

    $LeaseLog = $LOG_FOLDER+"\LeaseLog.csv"

    $ReservedLog = $LOG_FOLDER+"\ReservedLog.csv"


    #region Create Scope Object

    # Create a New Object

    $Scope = New-Object psobject

    # Add new members to the Object

    $Scope | Add-Member noteproperty "Address" ""

    $Scope | Add-Member noteproperty "Mask" ""

    $Scope | Add-Member noteproperty "State" ""

    $Scope | Add-Member noteproperty "Name" ""

    $Scope | Add-Member noteproperty "LeaseDuration" ""

    # Create Each Member in the Object as an Array

    $Scope.Address = @()

    $Scope.Mask = @()

    $Scope.State = @()

    $Scope.Name = @()

    $Scope.LeaseDuration = @()

    #endregion


    #region Create Lease Object

    # Create a New Object

    $LeaseClients = New-Object psObject

    # Add new members to the Object

    $LeaseClients | Add-Member noteproperty "IP" ""

    $LeaseClients | Add-Member noteproperty "Name" ""

    $LeaseClients | Add-Member noteproperty "Mask" ""

    $LeaseClients | Add-Member noteproperty "MAC" ""

    $LeaseClients | Add-Member noteproperty "Expires" ""

    $LeaseClients | Add-Member noteproperty "Type" ""

    # Create Each Member in the Object as an Array

    $LeaseClients.IP = @()

    $LeaseClients.Name = @()

    $LeaseClients.MAC = @()

    $LeaseClients.Mask = @()

    $LeaseClients.Expires = @()

    $LeaseClients.Type = @()

    #endregion


    #region Create Reserved Object

    # Create a New Object

    $LeaseReserved = New-Object psObject

    # Add new members to the Object

    $LeaseReserved | Add-Member noteproperty "IP" ""

    $LeaseReserved | Add-Member noteproperty "MAC" ""

    # Create Each Member in the Object as an Array

    $LeaseReserved.IP = @()

    $LeaseReserved.MAC = @()

    #endregion


    #region Define Commands

    #Commad to Connect to DHCP Server

    $NetCommand = "netsh dhcp server \\$DHCP_SERVER"

    #Command to get all Scope details on the Server

    $ShowScopes = "$NetCommand show scope"

    #endregion


    function Get-LeaseType( $LeaseType )

    {

    # Input : The Lease type in one Char

    # Output : The Lease type description

    # Description : This function translates a Lease type Char to it's relevant Description


    Switch($LeaseType){

    "N" { return "None" }

    "D" { return "DHCP" }

    "B" { return "BOOTP" }

    "U" { return "UNSPECIFIED" }

    "R" { return "RESERVATION IP" }

    }

    }


    function Check-Empty( $Object ){

    # Input : An Object with values.

    # Output : A Trimmed String of the Object or '-' if it's Null.

    # Description : Check the object if its null or not and return it's value.

    If($Object -eq $null)

    {

    return "-"

    }

    else

    {

    return $Object.ToString().Trim()

    }

    }


    function out-CSV ( $LogFile, $Append = $false) {

    # Input : An Object with values, Boolean value if to append the file or not, a File path to a Log File

    # Output : Export of the object values to a CSV File

    # Description : This Function Exports all the Values and Headers of an object to a CSV File.

    #  The Object is recieved with the Input Const (Used with Pipelineing) or the $inputObject

    Foreach ($item in $input){

    # Get all the Object Properties

    $Properties = $item.PsObject.get_properties()

    # Create Empty Strings - Start Fresh

    $Headers = ""

    $Values = ""

    # Go over each Property and get it's Name and value

    $Properties | %{ 

    $Headers += $_.Name+"`t"

    $Values += $_.Value+"`t"

    }

    # Output the Object Values and Headers to the Log file

    If($Append -and (Test-Path $LogFile)) {

    $Values | Out-File -Append -FilePath $LogFile -Encoding Unicode

    }

    else {

    # Used to mark it as an Powershell Custum object - you can Import it later and use it

    # "#TYPE System.Management.Automation.PSCustomObject" | Out-File -FilePath $LogFile

    $Headers | Out-File -FilePath $LogFile -Encoding Unicode

    $Values | Out-File -Append -FilePath $LogFile -Encoding Unicode

    }

    }

    }


    #region Get all Scopes in the Server 

    # Run the Command in the Show Scopes var

    $AllScopes = Invoke-Expression $ShowScopes

    # Go over all the Results, start from index 5 and finish in last index -3

    for($i=5;$i -lt $AllScopes.Length-3;$i++)

    {

    # Split the line and get the strings

    $line = $AllScopes[$i].Split("-")

    $Scope.Address += Check-Empty $line[0]

    $Scope.Mask += Check-Empty $line[1]

    $Scope.State += Check-Empty $line[2]

    # Line 3 and 4 represent the Name and Comment of the Scope

    # If the name is empty, try taking the comment

    If (Check-Empty $line[3] -eq "-") {

    $Scope.Name += Check-Empty $line[4]

    }

    else { $Scope.Name += Check-Empty $line[3] }

    }

    # Get all the Active Scopes IP Address

    $ScopesIP = $Scope | Where { $_.State -eq "Active" } | Select Address

    # Go over all the Adresses to collect Scope Client Lease Details

    Foreach($ScopeAddress in $ScopesIP.Address){

    # Define some Commands to run later - these commands need to be here because we use the ScopeAddress var that changes every loop

    #Command to get all Lease Details from a specific Scope - when 1 is amitted the output includes the computer name

    $ShowLeases = "$NetCommand scope "+$ScopeAddress+" show clients 1"

    #Command to get all Reserved IP Details from a specific Scope

    $ShowReserved = "$NetCommand scope "+$ScopeAddress+" show reservedip"

    #Command to get all the Scopes Options (Including the Scope Lease Duration)

    $ShowScopeDuration = "$NetCommand scope "+$ScopeAddress+" show option"

    # Run the Commands and save the output in the accourding var

    $AllLeases = Invoke-Expression $ShowLeases 

    $AllReserved = Invoke-Expression $ShowReserved 

    $AllOptions = Invoke-Expression $ShowScopeDuration

    # Get the Lease Duration from Each Scope

    for($i=0; $i -lt $AllOptions.count;$i++) 

    { 

    # Find a Scope Option ID number 51 - this Option ID Represents  the Scope Lease Duration

    if($AllOptions[$i] -match "OptionId : 51")

    { 

    # Get the Lease Duration from the Specified line

    $tmpLease = $AllOptions[$i+4].Split("=")[1].Trim()

    # The Lease Duration is recieved in Ticks / 10000000

    $tmpLease = [int]$tmpLease * 10000000; # Need to Convert to Int and Multiply by 10000000 to get Ticks

    # Create a TimeSpan Object

    $TimeSpan = New-Object -TypeName TimeSpan -ArgumentList $tmpLease

    # Calculate the $tmpLease Ticks to Days and put it in the Scope Lease Duration

    $Scope.LeaseDuration += $TimeSpan.TotalDays

    # After you found one Exit the For

    break;

    } 

    }

    # Get all Client Leases from Each Scope

    for($i=8;$i -lt $AllLeases.Length-4;$i++)

    {

    # Split the line and get the strings

    $line = [regex]::split($AllLeases[$i],"\s{2,}")

    # Check if you recieve all the lines that you need

    $LeaseClients.IP += Check-Empty $line[0]

    $LeaseClients.Mask += Check-Empty $line[1].ToString().replace("-","").Trim()

    $LeaseClients.MAC += $line[2].ToString().substring($line[2].ToString().indexOf("-")+1,$line[2].toString().Length-1).Trim()

    $LeaseClients.Expires += $(Check-Empty $line[3]).replace("-","").Trim()

    $LeaseClients.Type += Get-LeaseType $(Check-Empty $line[4]).replace("-","").Trim()

    $LeaseClients.Name += Check-Empty $line[5]

    }

    # Get all Client Lease Reservations from Each Scope

    for($i=7;$i -lt $AllReserved.Length-5;$i++)

    {

    # Split the line and get the strings

    $line = [regex]::split($AllReserved[$i],"\s{2,}")

    $LeaseReserved.IP += Check-Empty $line[0]

    $LeaseReserved.MAC += Check-Empty $line[2]

    }

    }

    #endregion 


    #region Export all the Data to nice log files

    # Export all data to XML Files for  later review

    $LeaseClients | Export-Clixml -Path $LOG_FOLDER"\Clients.xml"

    $LeaseReserved | Export-Clixml -Path $LOG_FOLDER"\Reserved.xml"

    $Scope | Export-Clixml -Path $LOG_FOLDER"\Scope.xml"

    #region Create a Temp Scope Object

    # Create a New Object

    $tmpScope = New-Object psobject

    # Add new members to the Object

    $tmpScope | Add-Member noteproperty "Address" ""

    $tmpScope | Add-Member noteproperty "Mask" ""

    $tmpScope | Add-Member noteproperty "State" ""

    $tmpScope | Add-Member noteproperty "Name" ""

    $tmpScope | Add-Member noteproperty "LeaseDuration" ""

    #endregion

    #region Create a Temp Lease Object

    # Create a New Object

    $tmpLeaseClients = New-Object psObject

    # Add new members to the Object

    $tmpLeaseClients | Add-Member noteproperty "IP" ""

    $tmpLeaseClients | Add-Member noteproperty "Name" ""

    $tmpLeaseClients | Add-Member noteproperty "Mask" ""

    $tmpLeaseClients | Add-Member noteproperty "MAC" ""

    $tmpLeaseClients | Add-Member noteproperty "Expires" ""

    $tmpLeaseClients | Add-Member noteproperty "Type" ""

    #endregion

    #region Create a Temp Reserved Object

    # Create a New Object

    $tmpLeaseReserved = New-Object psObject

    # Add new members to the Object

    $tmpLeaseReserved | Add-Member noteproperty "IP" ""

    $tmpLeaseReserved | Add-Member noteproperty "MAC" ""

    #endregion

    # Go over all the scope addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $Scope.Address.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpScope.Address = $Scope.Address[$l]

    $tmpScope.Mask = $Scope.Mask[$l]

    $tmpScope.State = $Scope.State[$l]

    $tmpScope.Name = $Scope.Name[$l]

    if($Scope.LeaseDuration[$l] -ne $Null)

    {

    $tmpLease = $Scope.LeaseDuration[$l].ToString()

    $tmpScope.LeaseDuration = $Scope.LeaseDuration[$l].ToString()

    }

    else

    {

    $tmpScope.LeaseDuration = $tmpLease

    }

    # Export with the Out-CSV Function to the Log File

    $tmpScope | Out-csv $ScopeLog -append $True

    }

    # Go over all the Client Lease addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $LeaseClients.IP.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpLeaseClients.IP = $LeaseClients.IP[$l]

    $tmpLeaseClients.Name = $LeaseClients.Name[$l]

    $tmpLeaseClients.Mask =  $LeaseClients.Mask[$l]

    $tmpLeaseClients.MAC = $LeaseClients.MAC[$l]

    $tmpLeaseClients.Expires = $LeaseClients.Expires[$l]

    $tmpLeaseClients.Type = $LeaseClients.Type[$l]

    # Export with the Out-CSV Function to the Log File

    $tmpLeaseClients | out-csv $LeaseLog -append $true

    }

    # Go over all the Reserved Client Lease addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $LeaseReserved.IP.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpLeaseReserved.IP = $LeaseReserved.IP[$l]

    $tmpLeaseReserved.MAC = $LeaseReserved.MAC[$l]

    # Export with the Out-CSV Function to the Log File

    $tmpLeaseReserved | out-csv $ReservedLog -append $true

    }

    #endregion 

}#End Get-DHCPLeases

function Get-CompsSoftware {

    Write-Host -ForegroundColor Blue -BackgroundColor Cyan `n `n 'Enter a computer name, and get the latest software information. Seperate multiple computers by comma.'`n`n

    $computers = (Read-Host).split(',') | % {$_.trim()}


    foreach ($computer in $computers) {Invoke-Command -cn $computer -ScriptBlock `
    {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    select DisplayName, Publisher, InstallDate }}

    <#

    $servers = *(Read-Host "Enter each IIS (separate with
     comma)").split(',') | % {$_.trim()}

    #>

}#End Get-CompsSoftware

function Get-AllSoftwareVersions {

    <# utilize Invoke-Command -Cn (the computers you want) -ScriptBlock {the command you want executed remotely} 
    for remote machines
    #>

    gp HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select DisplayName, DisplayVersion, Publisher, InstallDate, HelpLink, UninstallString | ogv

}#End Get-AllSoftwareVersions

function Test-OurADCompsConnection{


    Write-Host -ForegroundColor Blue -BackgroundColor Cyan `n`nCheck your desktop for the results. They will be in a folder called `"Ping`".`n`n

    $FilePath = "C:\Users\$CurrentUser\Desktop\Ping"

    $ADComputers = Get-ADComputer -f * -searchbase "ou=TAA,ou=tad,dc=nad,dc=ds,dc=usace,dc=army,dc=mil"

    $ADComputers = $ADComputers.name.trim()

    #$ADComputers > $FilePath

    $DeterminePingFolder = Test-Path $FilePath

    if ($DeterminePingFolder -eq $false ){

        mkdir $FilePath
        
    }#End if

    else {
    
        del $FilePath\* -Force
                
    }#End else

    function TestConnections {

        foreach ($ADcomputer in $ADComputers) {

            $CompPinged = Test-Connection $ADcomputer -count 1 -ErrorAction SilentlyContinue
    
                if ($CompPinged.StatusCode -eq 0) {
                        
                    Write-Host -ForegroundColor Blue -BackgroundColor Cyan "$ADcomputer online"
                    $ADcomputer >> $FilePath\OnlineSystems.txt

                    }#End if

                elseif ($CompPinged.StatusCode -ne 0) {

                    Write-Host -ForegroundColor Red -BackgroundColor Black "$ADcomputer offline"
                    $ADcomputer >> $FilePath\OfflineSystems.txt

                    }#End elseif

        }#End foreach

        Write-Host -ForegroundColor Yellow `n`n "     You have "(gc $FilePath\OnlineSystems.txt).count" online,`
        and "(gc $FilePath\OfflineSystems.txt).count" offline at this time "(Get-Date)"`."`n`n

    }#End TestConnections

    TestConnections

}#End Test-OurADCompsConnection

function Get-FileName {
        
    <#
    Reference website:
    http://stackoverflow.com/questions/22509719/how-to-enable-autocompletion-while-entering-paths

    To use in a different function just type $file = Get-FileName

    #>

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
    Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename

}#End Get-FileName

function FreeSpace {

    function Get-TheseDisksNow {
    
        Write-Host -ForegroundColor Yellow `n`n `
        "     Computers that can't be contacted for whatever
             reason will show up here in" -NoNewline
        Write-Host -ForegroundColor Red -BackgroundColor Black " RED!!!"`n`n`n
        
        $Servers = gc (Get-FileName)

        foreach ($Server in $Servers) {

            if(!(Test-Connection -Count 1 -ComputerName `
            $Server -ErrorAction SilentlyContinue)){
            
                Write-Host -f Red "     " $Server -NoNewline
                Write-Host -f Yellow " is not responding!"

            }#End if

            Get-WmiObject Win32_LogicalDisk -filter "DriveType=3" `
            -ComputerName $Server -ErrorAction SilentlyContinue

        }#End foreach

    }#End Get-TheseDisksNow

    [string]$ServiceHTML = "<h2>Server Hard Drives</h2>$(Get-TheseDisksNow |
    Select SystemName,DeviceID,VolumeName,FileSystem,
        @{Name="Size(GB)"; Expression={$_.size / 1GB -as [int]}},
        @{Name="FreeSpace(GB)"; Expression={$_.freespace / 1GB -as [int]}},
        @{Name="PercentFree(GB)"; Expression={($_.freespace / $_.size) *100 -as [int]}} |
    Sort-Object -Property SystemName -ErrorAction SilentlyContinue |
    ConvertTo-Html -fragment | out-string | Add-HTMLTableAttribute -AttributeName 'class' -Value 'MyTable')"

    $outputFilename = [System.IO.Path]::GetTempPath() + "Server_Hard_Drives.html"

    ConvertTo-Html -Body $ServiceHTML -Head $CSS -Title "Server Hard Drive Sheet" |
    Out-File $outputFilename

    # this will open the default web browser
    Invoke-Expression $outputFilename


    #Great reference article!
    #https://www.reddit.com/r/PowerShell/comments/2nni5r/the_power_of_converttohtml_and_css_part_2/

}#End FreeSpace

function Fix-PSTFiles {

<#
.SYNOPSIS
This command initializes the SCANPST.EXE program natively built into windows.
#>  
    Write-Host -ForegroundColor Cyan `n`n `
    "       Opening the built in PST scanner.
        Utilize this program to fix PSTs."`n`n

    Start-Process "C:\Program Files (x86)\Microsoft Office\Office15\SCANPST.exe"

}#End Fix-PSTFiles

function Count-GroupMembers {

    [cmdletbinding]
    Write-Host -ForegroundColor Blue -BackgroundColor Cyan `n`n "Enter some of the group name you know starting with the beginning"
    [string]$QGroup = $(Read-Host 'Enter name')
    $TheGroup = Get-ADGroup -f {name -like '$QGroup*'} | select name
    $GroupCount = $TheGroup.count

    Write-Host "You entered $QGroup"
    Write-Host "The groups returned $TheGroup"
    Write-Host "the number of groups for your query is $GroupCount"

    <#

    if ($GroupCount > 1) {
    
        Write-Host "You'll need to be a little more specific. Here is what I found from what you entered."
        (Get-ADGroup -f "name -like '$QGroup*'").samaccountname | more
    
        }
    else {
        Write-Host "The number of members in the group you queried"
        (Get-ADGroupMember (Get-ADGroup -f "name -like '$QGroup*'").samaccountname).count
     }

        #'kdhr tf*'


    #>

}#End Count-GroupMembers

function Check_KDHRDatabaseCopyStatus{

Get-MailboxDatabase | ?{$_.Name -like "KDHR*"} | Get-MailboxDatabaseCopyStatus

}#End Check_KDHRDatabaseCopyStatus

function Check_DatabasesQueuesKdhr {

    $DefaultColor =  $Host.ui.rawui.ForeGroundColor

    $TimeStamp = get-date

    $list = Get-ExchangeServer | ?{$_.Name -like "KDHR*"} 

    $OutPut = @()
    $DBStatusList = @()

    Write-Host -fore Yellow `n`n"					$TimeStamp"`n
    Write-Host -fore Yellow "******  Gathering the health status of Exchange Databases, Queues, and Mapi Connectivity  *******

					    Please wait ......"

    
        foreach ($server in $list) {
        $DBStatus = Get-MailboxDatabaseCopyStatus -Server $server | ?{$_.Status -notmatch "Healthy|Mounted" -or $_.ContentIndexState -ne "Healthy"}
        $DBStatusList += $DBStatus

        $MsgQueue = Get-Queue -Server $server | ?{$_.Identity -notlike "*\shadow\*" -AND $_.MessageCount -gt 10} | Select Identity, MessageCount, NextHopDomain | sort MessageCount -Descending | ft -AutoSize
        $MsgQueueList += $MsgQueue

        $TestMapi = Test-MapiConnectivity -Server $server -ErrorAction SilentlyContinue -warningaction SilentlyContinue | select Server,Database,Result
        $OutPut += $TestMapi

        }



    Write-Host `n`n"******* Exchange Database Results *******"
        If (($DBStatusList).count -gt 0){
        $Host.ui.rawui.ForeGroundColor = "Red"
        $DBStatusList
        $Host.ui.rawui.ForeGroundColor = $DefaultColor
        } Else {Write-Host -Fore Green "	All Databases are healthy."}



    Write-Host `n`n`n`n"******* Exchange Queue Results *******"
        If (($MsgQueueList).count -gt 0){
        $Host.ui.rawui.ForeGroundColor = "Red"
        $MsgQueueList
        $Host.ui.rawui.ForeGroundColor = $DefaultColor
        } Else {Write-Host -Fore Green "	No Queues have more than 10 Messages"}



    Write-Host `n`n"******* Mapi Connectivity Tests *******"
        $OutPut | FT -Auto











    #Test-MapiConnectivity -Server $server -ErrorAction SilentlyContinue -warningaction SilentlyContinue | select @{Name='ServerName';Expression={$_.Server}}, @{Name='DatabaseName';Expression={$_.Database}}, @{Name='Results';Expression={$_.Result}} | sort ServerName



}#End Check_DatabasesQueuesKdhr

function Get_ActiveUsers4KAF {

    Get-ADuser -Filter {name -like '*'} -SearchBase `
    'OU=Users,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil' -ResultSetSize $null |
    Measure-Object >> NKDHRADUsers1.txt

    Get-ADuser -Filter {name -like '*'} -SearchBase `
    'OU=Users,OU=HD_KDHQ,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil' -ResultSetSize $null |
    Measure-Object >> NKDHRADUsers2.txt

    Get-ADuser -Filter {name -like '*'} -SearchBase `
    'OU=Users,OU=HD_ARNA,OU=ARNA,OU=RC West,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil' -ResultSetSize $null |
    Measure-Object >> ARNAADUsers.txt
}#End Get_ActiveUsers4KAF

function Create_AccountHA {
<#
.SYNOPSIS
This script creates an elevated account called an HA account.
.DESCRIPTION
This script creates an elevated account called an HA account.
Feel free to modify this to create other related delegation accounts.
version 1.0 by Michael Melonas / 20 OCT 2015
#>
    param($username,$ITSM)

    Import-Module ActiveDirectory

    $HAUserGroups = "KDHR IMO Distribution"
    $HAElevatedGroups = "Helpdesk Admin Rights KDHR"
    $HALocation = "OU=HA,OU=Admins,OU=HD_DSST,OU=KDHR,OU=RC SOUTH,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $HAUPNDomain = "afghan.swa.ds.army.mil"
    $HAPassword = "PassWord123!@#"
    $HADescription = "Non-Elevated Account: "

    If ($ITSM -eq $null) {$ITSM = Read-Host "Enter ITSM Ticket Number"}

    If ($username -eq $null) {$username = Read-Host "Enter Users non-elevated account name"}

    $UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"

    Write-Host ""

    If ($UserCheck -eq $Null) {Write-Host "The user account $username does not exist"; Break}

    Write-Host ""

    If ($username.Length -gt 16) {Write-Host "The username is greater than 16 characters and cannot be directly converted to a HA account. Please specify a full HA account name with a length of fewer than 20 characters"; Write-Host ""; `
	    Do {$HAUserName = Read-Host "Enter HA Account Username (Fewer than 20 characters) "} while ($HAUserName.Length -gt 20)} Else {$HAUserName = "$username.ha".ToLower()}

    Write-Host ""

    Write-Host "You are about to create a new HA account for the following user with an HA account named $HAUserName per Ticket #$ITSM"

    Write-Host ""

    Get-ADUser $username

    Write-Host ""

    $AccountExpiration = (Get-ADUser -Properties AccountExpirationDate $username).AccountExpirationDate

    New-ADUser -SAMAccountName $HAUserName -Name $HAUserName -DisplayName $HAUserName `
	       -UserPrincipalName "$HAUserName@$HAUPNDomain" -ChangePasswordAtLogon $true `
	       -Office $HADescription$username -Enabled $true -Manager $username -path $HALocation `
	       -AccountPassword (ConvertTo-SecureString $HAPassword -AsPlainText -Force) `
	       -Description "ITSM: $ITSM" -AccountExpirationDate $AccountExpiration -Confirm

    Set-ADUser -Identity $username -Office "Elevated Account: $HAUserName" -Manager $HAUserName

    Add-ADPrincipalGroupMembership -Identity $username -MemberOf $HAUserGroups

    Add-ADPrincipalGroupMembership -Identity $HAUserName -MemberOf $HAElevatedGroups

    Write-Host ""

    Write-Host "New HA Account $HAUserName has been created and assigned to the following groups: $HAElevatedGroups"

    Write-Host "The account $username has been added to the following groups: $HAUserGroups"

    Write-Host ""

    Write-Host "Please note, this script does not add any unit specific security groups that may be needed."

    Write-Host ""

}#End Create_AccountHA

function Create_AccountIMO {
<#
.SYNOPSIS
This script creates an elevated account called an IMO account.
.DESCRIPTION
This script creates an elevated account called an IMO account.
Feel free to modify this to create other related delegation accounts.
version 1.0 by Michael Melonas / 20 OCT 2015
#>

    param($username,$ITSM)

    Import-Module ActiveDirectory

    $IMOUserGroups = "KDHR IMO Distribution"
    $IMOElevatedGroups = "KDHR IMO Security Group"
    $IMOLocation = "OU=IMO,OU=Admins,OU=HD_DSST,OU=KDHR,OU=RC SOUTH,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $IMOUPNDomain = "afghan.swa.ds.army.mil"
    $IMOPassword = "PassWord123!@#"
    $IMODescription = "Non-Elevated Account: "

    If ($ITSM -eq $null) {$ITSM = Read-Host "Enter ITSM Ticket Number"}

    If ($username -eq $null) {$username = Read-Host "Enter Users non-elevated account name"}

    $UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"

    Write-Host ""

    If ($UserCheck -eq $Null) {Write-Host "The user account $username does not exist"; Break}

    Write-Host ""

    If ($username.Length -gt 16) {Write-Host "The username is greater than 16 characters and thus cannot be directly converted to an IMO account. Please specify a full IMO account name with length less than 20 characters"; Write-Host ""; `
	    Do {$IMOUserName = Read-Host "Enter IMO Account Username (Less than 20 characters) "} while ($IMOUserName.Length -gt 20)} Else {$IMOUserName = "$username.imo".ToLower()}

    Write-Host ""

    Write-Host "You are about to create a new IMO account for the following user with an IMO account named $IMOUserName per Ticket #$ITSM"

    Write-Host ""

    Get-ADUser $username

    Write-Host ""

    $AccountExpiration = (Get-ADUser -Properties AccountExpirationDate $username).AccountExpirationDate

    New-ADUser -SAMAccountName $IMOUserName -Name $IMOUserName -DisplayName $IMOUserName `
	       -UserPrincipalName "$IMOUserName@$IMOUPNDomain" -ChangePasswordAtLogon $true `
	       -Office $IMODescription$username -Enabled $true -Manager $username -path $IMOLocation `
	       -AccountPassword (ConvertTo-SecureString $IMOPassword -AsPlainText -Force) `
	       -Description "ITSM: $ITSM" -AccountExpirationDate $AccountExpiration -Confirm

    Set-ADUser -Identity $username -Office "Elevated Account: $IMOUserName" -Manager $IMOUserName

    Add-ADPrincipalGroupMembership -Identity $username -MemberOf $IMOUserGroups

    Add-ADPrincipalGroupMembership -Identity $IMOUserName -MemberOf $IMOElevatedGroups

    Write-Host ""

    Write-Host "New IMO Account $IMOUserName has been created and assigned to the following groups: $IMOElevatedGroups"

    Write-Host "The account $username has been added to the following groups: $IMOUserGroups"

    Write-Host ""

    Write-Host "Please note, this script does not add an unit specific security groups that may be needed."

    Write-Host ""

}#End Create_AccountIMO

function Create_AccountNA {

<#
.SYNOPSIS
This script creates an elevated account called an NA account.
.DESCRIPTION
This script creates an elevated account called an NA account.
Feel free to modify this to create other related delegation accounts.
version 1.0 by Michael Melonas / 20 OCT 2015
#>

    param($username,$ITSM)

    Import-Module ActiveDirectory

    ## $NAUserGroups = "KDHR IMO Distribution"
    ## $NAElevatedGroups = "Helpdesk Admin Rights KDHR"
    $NALocation = "OU=NA,OU=Admins,OU=HD_DSST,OU=KDHR,OU=RC SOUTH,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $NAUPNDomain = "afghan.swa.ds.army.mil"
    $NAPassword = "PassWord123!@#"
    $NADescription = "Non-Elevated Account: "

    If ($ITSM -eq $null) {$ITSM = Read-Host "Enter ITSM Ticket Number"}

    If ($username -eq $null) {$username = Read-Host "Enter Users non-elevated account name"}

    $UserCheck = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"

    Write-Host ""

    If ($UserCheck -eq $Null) {Write-Host "The user account $username does not exist"; Break}

    Write-Host ""

    If ($username.Length -gt 16) {Write-Host "The username is greater than 16 characters and thus cannot be directly converted to a NA account. Please specify a full HA account name with length less than 20 characters"; Write-Host ""; `
	    Do {$NAUserName = Read-Host "Enter NA Account Username (Fewer than 20 characters) "} while ($NAUserName.Length -gt 20)} Else {$NAUserName = "$username.na".ToLower()}

    Write-Host ""

    Write-Host "You are about to create a new NA account for the following user with a NA account named $NAUserName per Ticket #$ITSM"

    Write-Host ""

    Get-ADUser $username

    Write-Host ""

    $AccountExpiration = (Get-ADUser -Properties AccountExpirationDate $username).AccountExpirationDate

    New-ADUser -SAMAccountName $NAUserName -Name $NAUserName -DisplayName $NAUserName `
	       -UserPrincipalName "$NAUserName@$NAUPNDomain" -ChangePasswordAtLogon $true `
	       -Office $NADescription$username -Enabled $true -Manager $username -path $NALocation `
	       -AccountPassword (ConvertTo-SecureString $NAPassword -AsPlainText -Force) `
	       -Description "ITSM: $ITSM" -AccountExpirationDate $AccountExpiration -Confirm

    Set-ADUser -Identity $username -Office "Elevated Account: $NAUserName" -Manager $NAUserName

    ## Add-ADPrincipalGroupMembership -Identity $username -MemberOf $NAUserGroups

    ## Add-ADPrincipalGroupMembership -Identity $NAUserName -MemberOf $NAElevatedGroups

    Write-Host ""

    ## Write-Host "New NA Account $NAUserName has been created and assigned to the following groups: $NAElevatedGroups"

    ## Write-Host "The account $username has been added to the following groups: $NAUserGroups"

    Write-Host ""

    Write-Host "Please note, this script does not add any unit specific security groups that may be needed."

    Write-Host ""

}#End Create_AccountNA

function ARNA-Get-DatabaseSizeReport {

    Get-MailboxDatabase -Status -Identity ARNA* | select ServerName,Name,DatabaseSize |
    Sort-Object Name | Out-GridView -Title "Kandahar Exchange Database Sizes"

}#End ARNA-Get-DatabaseSizeReport

function Change-EmailAddress {

    param($username)

    $ErrorActionPreference = "silentlycontinue"

    $Domain1 = "afghan.swa.army.mil"
    $Domain2 = "swa.army.mil"

    $UserCheck = (Get-ADUser $username).SamAccountName

    If ($username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $username).SamAccountName
		    }

	    Until ($username -ne $Null -and $UserCheck -ne $Null)
	    }


    Write-Host ""
    (Get-ADUser $username).Name
    Write-Host ""
    (Get-Mailbox $username).EmailAddresses
    Write-Host ""

    Do { $Confirm = Read-Host "Is this the user you wish to update the email address for? [Y/N]" } 
	    Until ($Confirm -eq "Y" -or $Confirm -eq "N")

    If ($Confirm -eq "N") {Break}

    $Option1 = (Get-ADUser $username).UserPrincipalName
    $Option1 = $Option1.Split("@")[0]

    $Option2 = (Get-ADUser $username).SamAccountName

    $Option3 = (Get-ADUser $username).mail
    $Option3 = $Option1.Split("@")[0]

    Write-Host "
    I am going to try and guess what you want it set to, if I do not guess correctly
    please select option 4 to enter your own data.

    Option 1: ($Option1) 
    $Option1@$Domain1 and $Option1@$Domain2

    Option 2: ($Option2)
    $Option2@$Domain1 and $Option2@$Domain2

    Option 3: ($Option3)
    $Option3@$Domain1 and $Option3@$Domain2

    Option 4: Select your own username for the email addresses.

    "
    Do {$OptionSelected = Read-Host "Enter the option you wish to use"}
	    Until ($OptionSelected -eq 1 -or $OptionSelected -eq 2 -or $OptionSelected -eq 3 -or $OptionSelected -eq 4)

    If ($OptionSelected -eq "4") {$NewEmailPrefix = Read-Host "Please enter the new email prefix you wish to use (the part before the @)"}
    ElseIf ($OptionSelected -eq "1") {$NewEmailPrefix = $Option1}
    ElseIf ($OptionSelected -eq "2") {$NewEmailPrefix = $Option2}
    ElseIf ($OptionSelected -eq "3") {$NewEmailPrefix = $Option3}

    Write-Host "
    The users new email addresses will be set to the following.

    $NewEmailPrefix@$Domain1
    $NewEmailPrefix@$Domain2
    "

    Do { $Confirm = Read-Host "Please confirm you wish to make this change [Y/N]:" } 
	    Until ($Confirm -eq "Y" -or $Confirm -eq "N")

    If ($Confirm -eq "N") {Break}

    Set-Mailbox $username -EmailAddressPolicyEnabled $false -EmailAddresses SMTP:$NewEmailPrefix@$Domain1,$NewEmailPrefix@$Domain2

    Write-Host "
    Update Completed, user account now has following email address:
    "

    (Get-Mailbox $username).EmailAddresses

    Write-Host ""

    pause

}#End Change-EmailAddress

function CheckDatabasesAndQueues-Kdhr {

    $DefaultColor =  $Host.ui.rawui.ForeGroundColor

    $TimeStamp = get-date

    $list = Get-ExchangeServer | ?{$_.Name -like "KDHR*"} 

    $OutPut = @()
    $DBStatusList = @()

    Write-Host -fore Yellow `n`n"					$TimeStamp"`n
    Write-Host -fore Yellow "******  Gathering the health status of Exchange Databases, Queues, and Mapi Connectivity  *******

					    Please wait ......"

    
        foreach ($server in $list) {
        $DBStatus = Get-MailboxDatabaseCopyStatus -Server $server | ?{$_.Status -notmatch "Healthy|Mounted" -or $_.ContentIndexState -ne "Healthy"}
        $DBStatusList += $DBStatus

        $MsgQueue = Get-Queue -Server $server | ?{$_.Identity -notlike "*\shadow\*" -AND $_.MessageCount -gt 10} | Select Identity, MessageCount, NextHopDomain | sort MessageCount -Descending | ft -AutoSize
        $MsgQueueList += $MsgQueue

        $TestMapi = Test-MapiConnectivity -Server $server -ErrorAction SilentlyContinue -warningaction SilentlyContinue | select Server,Database,Result
        $OutPut += $TestMapi

        }



    Write-Host `n`n"******* Exchange Database Results *******"
        If (($DBStatusList).count -gt 0){
        $Host.ui.rawui.ForeGroundColor = "Red"
        $DBStatusList
        $Host.ui.rawui.ForeGroundColor = $DefaultColor
        } Else {Write-Host -Fore Green "	All Databases are healthy."}



    Write-Host `n`n`n`n"******* Exchange Queue Results *******"
        If (($MsgQueueList).count -gt 0){
        $Host.ui.rawui.ForeGroundColor = "Red"
        $MsgQueueList
        $Host.ui.rawui.ForeGroundColor = $DefaultColor
        } Else {Write-Host -Fore Green "	No Queues have more than 10 Messages"}



    Write-Host `n`n"******* Mapi Connectivity Tests *******"
        $OutPut | FT -Auto

    #Test-MapiConnectivity -Server $server -ErrorAction SilentlyContinue -warningaction SilentlyContinue | select @{Name='ServerName';Expression={$_.Server}}, @{Name='DatabaseName';Expression={$_.Database}}, @{Name='Results';Expression={$_.Result}} | sort ServerName

}#End CheckDatabases&Queues-Kdhr

function Check-ElevatedExpDatesV1 {

<#
.SYNOPSIS
Elevated Account information
.DESCRIPTION
Retrieves the information for Elevated Accounts from the $Groups Array for doing the "Re-validation" MEMO,
The Script can be run as a Standard User on the Enclave. 
You'll need to change the $Groups variable as you move from site to site as well as the DC.
version 2.0 by Michael Melonas / 20 OCT 2015
.PARAMETER OutFile
Name of the Output File with the complete file path
.EXAMPLE
Check-ElevatedExpDates
This example retrieves the elevated account information and creates a csv file named "ElevatedExpDateList.Csv"
in the folder where the script is. "ElevatedExpDateList.Csv" is the default output file name
.EXAMPLE
Check-ElevatedExpDates -OutFile C:\EleAcctList.csv
This example retrieves the elevated account information and creates a csv file named "EleAcctList.csv"
in the C:\ drive root
#>
    param(
        [string]$OutFile = ".\ElevatedExpDateList.Csv"
    )
    BEGIN{}
    PROCESS{
        $Groups = "OU=Vectrus IA, OU=IA, OU=Admins, OU=KDHR","OU=Vectrus SA, OU=SA, OU=Admins, OU=KDHR","OU=Vectrus NA, OU=NA, OU=Admins, OU=KDHR","OU=Vectrus HA, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=Vectrus ADPE, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=DSST HA, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=NA, OU=Admins"
        $ElevatedGroup = foreach ($Group in $Groups){
            Get-ADUser -Filter * -Properties * -SearchBase "$Group, OU=RC South, DC=afghan, DC=swa, DC=ds, DC=army, DC=mil"}
        $ElevatedGroup | Sort AccountExpirationDate | Select-Object SamAccountName, AccountExpirationDate,
            @{Name='ITSM';Expression={$_.Description}}, Enabled, @{Name='eMail';Expression={(Get-ADUser $_.Manager -Properties *).emailaddress}},
            @{Name='Phone';Expression={(Get-ADUser $_.Manager -Properties *).OfficePhone}},
            @{Name='ITSM & Notes';Expression={$_.Company}} | Export-Csv $OutFile -NoTypeInformation
    }
    END{}

}#End Check-ElevatedExpDatesV1

function Check-ElevatedExpDatesV2 {

<#
.SYNOPSIS
Elevated Account information.
.DESCRIPTION
Retrieves the information for Elevated Accounts from the $Groups Array for doing the "Re-validation" MEMO,
The Script can be run as a Standard User on the Enclave. 
You'll need to change the $Groups variable as you move from site to site as well as the DC.
version 2.0 by Michael Melonas / 20 OCT 2015
.PARAMETER OutFile
Name of the Output File with the complete file path
.EXAMPLE
Check-ElevatedExpDates
This example retrieves the elevated account information and creates a csv file named "ElevatedExpDateList.Csv"
in the folder where the script is. "ElevatedExpDateList.Csv" is the default output file name
.EXAMPLE
Check-ElevatedExpDates -OutFile C:\EleAcctList.csv
This example retrieves the elevated account information and creates a csv file named "EleAcctList.csv"
in the C:\ drive root
#>
    param(
        [string]$OutFile = ".\ElevatedExpDateList.Csv"
    )
    BEGIN{}
    PROCESS{
        $Groups = "OU=Vectrus IA, OU=IA, OU=Admins, OU=KDHR","OU=Vectrus SA, OU=SA, OU=Admins, OU=KDHR","OU=Vectrus NA, OU=NA, OU=Admins, OU=KDHR","OU=Vectrus HA, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=Vectrus ADPE, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=DSST HA, OU=HA, OU=Admins, OU=HD_DSST, OU=KDHR","OU=NA, OU=Admins"
        $ElevatedGroup = foreach ($Group in $Groups){
            Get-ADUser -Filter * -Properties * -SearchBase "$Group, OU=RC South, DC=afghan, DC=swa, DC=ds, DC=army, DC=mil"}
        $ElevatedGroup | Sort AccountExpirationDate | Select-Object SamAccountName, AccountExpirationDate,
            @{Name='ITSM';Expression={$_.Description}}, Enabled, @{Name='eMail';Expression={(Get-ADUser $_.Manager -Properties EmailAddress).emailaddress}},
            @{Name='Phone';Expression={(Get-ADUser $_.Manager -Properties OfficePhone).OfficePhone}},
            @{Name='ITSM & Notes';Expression={$_.Company}} | Export-Csv $OutFile -NoTypeInformation
    }
    END{}


}#End Check-ElevatedExpDatesV2

function Check-Patches {

# #################################################################### #
#                                                                      #
# Script written and modified by Michael Melonas                       #
#                                                                      #
# Last Updated: 06/06/2014 @ 19:16                                v.1  #                           
# #################################################################### #

    param ($Computer,$DaysBack)

    Get-HotFix -ComputerName $Computer | Where {$_.InstalledOn -gt ($Time.AddDays(-30))} 
    # | Select-Object Description, HotFixID, InstalledOn | Sort-Object InstalledOn | ft -AutoSize

}#End Check-Patches

function Check-ReceiveConnector {

    param ($ip)

    $ExchangeServers = (Get-ExchangeServer -Identity KDHR*).Name | Sort-Object

    $ConnectorGroupName = "RC-S Digital Senders"




    foreach ($ExchangeServer in $ExchangeServers) {

	    $CheckIP = (Get-ReceiveConnector -Server $ExchangeServer | where {$_.Identity -eq "$ExchangeServer\$ConnectorGroupName"}).remoteipranges
	    $CheckIPResults = $CheckIP | Where {$_ -Like "*$ip*"} | Sort-Object {"{0:d3}.{1:d3}.{2:d3}.{3:d3}" -f @([int[]]$_.split('.'))}

	    if ($CheckIPResults -eq $null)

		    {
		    Write-Host -ForeGroundColor Red "$ExchangeServer : No Matches Found"
		    }

	    else

		    {
		    Write-Host -ForeGroundColor Green "Matches on Exchange Server $ExchangeServer"
		    Write-Host -ForeGroundColor Green "------------------------------------------"
		    foreach ($IPResult in $CheckIPResults) {Write-Host -ForeGroundColor Green $IPResult}
		    }

	    Write-Host ""

    }

}#End Check-ReceiveConnector

function Clean-SpillageV1 {

#The Next 4 lines are only used some Machines or Networks
#if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.Powershell.E2010"}))
#{
#   Add-PSSnapin Microsoft.Exchange.Management.Powershell.E2010 -ErrorAction SilentlyContinue
#}


    Write-Host "

    1. Generate a Log - To identify the Number of Emails Exist in a mailbox Specifying the Subject of the Email

    2. Remove a Email with a Specific Subject from One Mailbox

    3. Remove a Email with a Specific Subject from all the Mailboxs in the Organization -Logonly

    4. Remove a Email with a Specific Subject from all the Mailboxs in the Organization -DeleteContent

    5. Mailbox Dumbster Cleanup - Emptying a Specific Mailbox Dumpster" -Foreground "Cyan"


    $number = Read-Host "Choose the task"

    switch ($number)
    {


    1 {

    $GetAlias = Read-Host "Enter Alias of the User to Search for a Subject"

    $GetSubject = Read-Host "Enter the Subject"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    Search-mailbox -identity $GetAlias -searchquery "Subject: '$GetSubject'" -Logonly -Targetmailbox "$GetMailboxSendLog" -Targetfolder "Inbox"

     : break}

    2 {

    $GetAlias = Read-Host "Enter Alias of the User to Search for a Subject and Delete it"

    $GetSubject = Read-Host "Enter the Subject"

    Search-mailbox -identity $GetAlias -searchquery "Subject: '$GetSubject'" -DeleteContent

     : break}

    3 {

    $GetSubject = Read-Host "Enter the Subject of the Email to Search the Entire Organization"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    get-Mailbox -resultsize unlimited | Search-mailbox -searchquery "Subject: '$GetSubject'" -Logonly -Targetmailbox "$GetMailboxSendLog" -Targetfolder "Inbox"

     : break}

    4 {

    $GetSubject = Read-Host "Enter the Subject of the Email to Search the Entire Organization"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    $MBList = get-Mailbox -resultsize unlimited
    Foreach ($mb in $MBList) {
       Search-mailbox -identity "$mb" -searchquery "Subject:'$GetSubject'" -deletecontent -Targetmailbox "$GetMailboxtoSendLog" -Targetfolder "Inbox" -Force
       }

       ; break}

    5 {

    $GetAlias = Read-Host "Enter the Mailbox Name to Cleanup the dumpster Alone"

    Search-mailbox -identity $GetAlias -searchquery "Subject:'*'" -SearchDumpsterOnly -DeleteContent

     ; break}
 
    Default {Write-Host "No matches found , Enter Options 1 to 5" -Foreground "red"}


    }

}#End Clean-SpillageV1

function Clean-SpillageV2 {

    if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.Powershell.E2010"}))
    {
       Add-PSSnapin Microsoft.Exchange.Management.Powershell.E2010 -ErrorAction SilentlyContinue
    }


    Write-Host "

    1. Generate a Log - To identify the Number of Emails Exist in a mailbox Specifying the Subject of the Email

    2. Remove a Email with a Specific Subject from One Mailbox

    3. Remove a Email with a Specific Subject from all the Mailboxs in the Organization -Logonly

    4. Remove a Email with a Specific Subject from all the Mailboxs in the Organization -DeleteContent

    5. Mailbox Dumbster Cleanup - Emptying a Specific Mailbox Dumpster" -Foreground "Cyan"


    $number = Read-Host "Choose the task"

    switch ($number)
    {


    1 {

    $GetAlias = Read-Host "Enter Alias of the User to Search for a Subject"

    $GetSubject = Read-Host "Enter the Subject"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    Search-mailbox -identity $GetAlias -searchquery "Subject: '$GetSubject'" -Logonly -Targetmailbox "$GetMailboxSendLog" -Targetfolder "Inbox"

     : break}

    2 {

    $GetAlias = Read-Host "Enter Alias of the User to Search for a Subject and Delete it"

    $GetSubject = Read-Host "Enter the Subject"

    Search-mailbox -identity $GetAlias -searchquery "Subject: '$GetSubject'" -DeleteContent

     : break}

    3 {

    $GetSubject = Read-Host "Enter the Subject of the Email to Search the Entire Organization"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    get-Mailbox -resultsize unlimited | Search-mailbox -searchquery "Subject: '$GetSubject'" -Logonly -Targetmailbox "$GetMailboxSendLog" -Targetfolder "Inbox"

     : break}

    4 {

    $GetSubject = Read-Host "Enter the Subject of the Email to Search the Entire Organization"

    $GetMailboxSendLog = Read-Host "Enter the Mailbox Alias to send the Generated Log"

    $MBList = get-Mailbox -resultsize unlimited
    Foreach ($mb in $MBList) {
       Search-mailbox -identity "$mb" -searchquery "Subject:'$GetSubject'" -deletecontent -Targetmailbox "$GetMailboxtoSendLog" -Targetfolder "Inbox" -Force
       }

       ; break}

    5 {

    $GetAlias = Read-Host "Enter the Mailbox Name to Cleanup the dumpster Alone"

    Search-mailbox -identity $GetAlias -searchquery "Subject:'*'" -SearchDumpsterOnly -DeleteContent

     ; break}
 
    Default {Write-Host "No matches found , Enter Options 1 to 5" -Foreground "red"}


    }

}#End Clean-SpillageV2

function Clear-Dumpster {

    param ($Username)

    $ErrorActionPreference = "silentlycontinue"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }

    Search-Mailbox $Username -SearchDumpsterOnly -DeleteContent

}#End Clear-Dumpster

function Clone-Security {

<#
.SYNOPSIS
Script to clone group memberships from a source user to a target user.
#>
    Param ($Source, $Target)
    Write-Host ""
    Write-Host "WARNING: 

    This will remove existing security groups from 'Target User' to make exact clone of the 'Source User' groups.

    If wish to just copy sec groups from source to target user, please use the 'Copy-Security' script instead."`n`n`n

    If ($Source -ne $Null -and $Target -eq $Null)
    {
    
        $Target = Read-Host "Enter logon name of target user"
    }
    If ($Source -eq $Null)
    {
        $Source = Read-Host "Enter logon name of source user"
        $Target = Read-Host "Enter logon name of target user"
    }

    # Retrieve group memberships.
    $SourceUser = Get-ADUser $Source -Properties memberOf
    $TargetUser = Get-ADUser $Target -Properties memberOf

    # Hash table of source user groups.
    $List = @{}

    #Enumerate direct group memberships of source user.
    ForEach ($SourceDN In $SourceUser.memberOf)
    {
        # Add this group to hash table.
        $List.Add($SourceDN, $True)
        # Bind to group object.
        $SourceGroup = [ADSI]"LDAP://$SourceDN"
        # Check if target user is already a member of this group.
        If ($SourceGroup.IsMember("LDAP://" + $TargetUser.distinguishedName) -eq $False)
        {
            # Add the target user to this group.
            Add-ADGroupMember -Identity $SourceDN -Members $Target
        }
    }


    # Enumerate direct group memberships of target user.
    ForEach ($TargetDN In $TargetUser.memberOf)
    {
        # Check if source user is a member of this group.
        If ($List.ContainsKey($TargetDN) -eq $False)
        {
            # Source user not a member of this group.
            # Remove target user from this group.
            Remove-ADGroupMember $TargetDN $Target
        }
    }

}#End Clone-Security

function Computer-Check {


<#   

.SYNOPSIS

.DESCRIPTION
Script written and modified by Michael Melonas
Last Updated: 20 OCT 2015 Version 17

#>
    param ($Computer)
    
    . Var-Script-Variables
    . Get-LastLogon
    . Get-PendingReboot
    
    Import-Module .\Includes\Modules\PSRemoteRegistry\PSRemoteRegistry.psm1

    $ErrorActionPreference = "silentlycontinue"

    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName

    If ($Computer -eq $Null -or $ComputerCheck -eq $Null) 
	    {

	    Do 	{$Computer = Read-Host -Prompt "Please Enter Valid Computer Name" 
			    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName
		    }

	    Until ($Computer -ne $Null -and $ComputerCheck -ne $Null)
	    }

    Write-Host "
    Active Directory Information about Computer
    ---------------------------------------------"
    $ADComputerInfo = Get-ADComputer $Computer -Properties * | Select-Object Name, CanonicalName, DistinguishedName, SID, Enabled, IPv4Address, `
								    OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion, whenCreated, whenChanged, `
								    LastLogonDate, Description, Info
								
    $ADComputerInfo

    If ((Get-ADComputer $Computer).Enabled -eq $False) 
	    {Write-Host -ForegroundColor Yellow "*** WARNING *** Computer is Disabled, if disabled for inactivity, submit for reimage.`n"}


    Write-Host "
    Remote Information from Computer
    ---------------------------------------------"

    $ComputerStatus = Test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -ErrorAction 0 -quiet

    if ($ComputerStatus -eq $False) 

	    {
		    Write-Host -ForegroundColor Red "`n*** WARNING *** - Computer is either offline or had bad DNS information.`n"
		    $Manufacturer = ""
		    $Model = ""
		    $RemoteDate = ""
		    $InstallDate = ""
		    $OSArchitecture = ""
		    $SCCMInfo = ""
		    $RebootPending = ""
		    $FileRenamePending = ""
		    $Hotfix = ""
		    $LastLogon = ""
	    }
	
    ElseIf ($ComputerStatus -eq $True) 
	
	    {
	
		    $Manufacturer = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Manufacturer).data
		    $Model = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Model).data
		    $RemoteInfo = Get-WmiObject win32_operatingsystem -ComputerName $Computer
		    $RebootDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.LastBootUpTime)
		    $InstallDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.InstallDate)
		    $OSArchitecture = $RemoteInfo.OSArchitecture
		    $SCCMInfo = Get-PendingReboot -ComputerName $Computer
		    $RebootPending = $SCCMInfo.RebootPending
		    $FileRenamePending = $SCCMInfo.PendFileRename
		    $Hotfix = (Get-HotFix -ComputerName $Computer) | Select-Object Description, HotFixID, InstalledOn
		    $LastLogon = Get-LastLogon -ComputerName $Computer
		    $SecGroupNames = Get-ADPrincipalGroupMembership $Computer$
		
	

    Write-Host "
       Registry Information
       -----------------------------------------
       Manufacturer          : $Manufacturer
       Model                 : $Model
   
       WMI Information
       -----------------------------------------
       Last Rebooted         : $RebootDate
       Install Date          : $InstallDate
       OSArchitecture        : $OSArchitecture
   
       SCCM Information
       -----------------------------------------
       File Rename Pending   : $FileRenamePending
       System Reboot Pending : $RebootPending"

    If (($ComputerStatus -eq $True) -and ($Manufacturer -ne $Current_UGM_Manufacturer -or $Model -ne $Current_UGM_Model)) {Write-Host -ForegroundColor Red "`n   *** WARNING *** - This is not the currently approved UGM image, please have system baselined"}

    Write-Host "`n   
    Most Recently Applied Patches
    ---------------------------------------------"
			    $Hotfix[1]
   

    Write-Host "`nLast User to Logon to this Computer
    ---------------------------------------------"
			    $LastLogon
			
	    }	
	
    Write-Host "
    Computer is a member of the following groups
    ----------------------------------------------
    "
		
			    $SecGroupNames.name

    If ((Get-ADPrincipalGroupMembership $Computer$).count -eq 2) {}
	    Else {Write-Host -ForegroundColor Yellow "`n`n*** WARNING *** Computer does not have 2 security groups, verify 802.1x VLAN Assignment`n`n"}
	
    $ElevatedUser = $env:username
    $ElevatedGroups = Get-ADPrincipalGroupMembership $ElevatedUser
    $8021x_VLAN = (Get-ADPrincipalGroupMembership $Computer$).name | findstr.exe "8021x"

    # ################################ #
    # 802.1x Creation and Modification #
    # ################################ #

    If ($ElevatedGroups.name -contains "8021x_Modify_Group_Members")

	    {
		    Write-Host -ForegroundColor Green "`nCongratulations, you are a member of the 8021x_Modify_Group_Members security group!"
		
		    If ($8021x_VLAN -eq $Null) 
		
			    {

				    $8021x_ModifyChoice = Read-Host "`nThere is currently no 802.1x VLAN assignment on this Computer object, do you wish to assign one? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to assign this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
				    }
	
			    }
			
		    Else
			
			    {
				    $8021x_ModifyChoice = Read-Host "`nComputer Object $Computer is currently assigned to group $8021x_VLAN, do you wish to change it? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to change this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    Remove-ADgroupMember -Identity $8021x_VLAN -Member $Computer$ -Confirm:$False
				    }
				
			    }
	    }

    pause

}#End Computer-Check

function Copy-SecurityV1 {

<#
.SYNOPSIS
Script to copy group memberships from a source user to a target user.
#>
    Param ($Source, $Target)
    If ($Source -ne $Null -and $Target -eq $Null)
    {
        $Target = Read-Host "Enter logon name of target user"
    }
    If ($Source -eq $Null)
    {
        $Source = Read-Host "Enter logon name of source user"
        $Target = Read-Host "Enter logon name of target user"
    }

    # Retrieve group memberships.
    $SourceUser = Get-ADUser $Source -Properties memberOf
    $TargetUser = Get-ADUser $Target -Properties memberOf

    # Hash table of source user groups.
    $List = @{}

    #Enumerate direct group memberships of source user.
    ForEach ($SourceDN In $SourceUser.memberOf)
    {
        # Add this group to hash table.
        $List.Add($SourceDN, $True)
        # Bind to group object.
        $SourceGroup = [ADSI]"LDAP://$SourceDN"
        # Check if target user is already a member of this group.
        If ($SourceGroup.IsMember("LDAP://" + $TargetUser.distinguishedName) -eq $False)
        {
            # Add the target user to this group.
            Add-ADGroupMember -Identity $SourceDN -Members $Target
        }
    }

}#End Copy-SecurityV1

function Copy-Security2 {

# Script to copy group memberships from a source user to a target user.

Param ($Source, $Target)
If ($Source -ne $Null -and $Target -eq $Null)
{
    $Target = Read-Host "Enter logon name of target user"
}
If ($Source -eq $Null)
{
    $Source = Read-Host "Enter logon name of source user"
    $Target = Read-Host "Enter logon name of target user"
}

<#
.SYNOPSIS
Copy Groups
#>
    Get-ADPrincipalGroupMembership -Identity $Source |
    ForEach-Object { Add-ADPrincipalGroupMembership -Identity $Target -MemberOf $_.SamAccountName }

}#End Copy-Security2

function Create-Distribution {

    Write-Host " "`n`n
    If ($DistroName -eq $Null)
	    {

	    Do 	{
			    Write-Host "Note: NO special characters like slashes."`n`n
			    $DistroName = Read-Host -Prompt "Please Enter Distribution Name" 
			
		    }

	    Until ($DistroName -ne $Null)
	    }

    # the Main function that can be loaded or gets started at the end of the script 
  
    Function Browse-ActiveDirectory { 
    $root=[ADSI]''
    $StartingOU = (New-Object DirectoryServices.DirectoryEntry("LDAP://OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil")) 


    # Try to connect to the Domain root 

    &{trap {throw "$($_)"};[void]$Root.psbase.get_Name()}

 

    # Make the form 
    # add a reference to the forms assembly
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

      $form = new-object Windows.Forms.form    
      $form.Size = new-object System.Drawing.Size @(800,600)    
      $form.text = "PowerShell ActiveDirectory Browser"   

      # Make TreeView to hold the Domain Tree 

      $TV = new-object windows.forms.TreeView 
      $TV.Location = new-object System.Drawing.Size(10,30)   
      $TV.size = new-object System.Drawing.Size(770,470)   
      $TV.Anchor = "top, left, right"     

      # Add the Button to close the form and return the selected DirectoryEntry 
  
      $btnSelect = new-object System.Windows.Forms.Button  
      $btnSelect.text = "Select" 
      $btnSelect.Location = new-object System.Drawing.Size(710,510)   
      $btnSelect.size = new-object System.Drawing.Size(70,30)   
      $btnSelect.Anchor = "Bottom, right"   

      # If Select button pressed set return value to Selected DirectoryEntry and close form 

      $btnSelect.add_Click({ 
        $script:Return = new-object system.directoryservices.directoryEntry("LDAP://$($TV.SelectedNode.name)")
    
        $form.close() 
      }) 

      # Add Cancel button  

      $btnCancel = new-object System.Windows.Forms.Button  
      $btnCancel.text = "Cancel" 
      $btnCancel.Location = new-object System.Drawing.Size(630,510)   
      $btnCancel.size = new-object System.Drawing.Size(70,30)   
      $btnCancel.Anchor = "Bottom, right"   

      # If cancel button is clicked set returnvalue to $False and close form 

      $btnCancel.add_Click({$script:Return = $false ; $form.close()}) 

      # Create a TreeNode for the Starting OU or domain root, if you uncommented the Param at beginning of Function, and
      # you also have to replace the below $StartingOU.xxxxxx with $root.xxxxxxx

      $TNRoot = new-object System.Windows.Forms.TreeNode("Root") 
      $TNRoot.Name = $StartingOU.distinguishedname 
      $TNRoot.Text = $StartingOU.Name 
      $TNRoot.tag = "NotEnumerated" 

      # First time a Node is Selected, enumerate the Children of the selected DirectoryEntry 

      $TV.add_AfterSelect({ 
        if ($this.SelectedNode.tag -eq "NotEnumerated") { 

          $de = new-object system.directoryservices.directoryEntry("LDAP://$($TV.SelectedNode.name)") 

          # Add all Children found as Sub Nodes to the selected TreeNode 

          $de.get_Children() |  
          foreach { 
            $TN = new-object System.Windows.Forms.TreeNode 
            $TN.Name = $_.distinguishedname
            $TN.Text = $_.name
            $TN.tag = "NotEnumerated" 
            $this.SelectedNode.Nodes.Add($TN)
        
          } 

          # Set tag to show this node is already enumerated 
  
          $this.SelectedNode.tag = "Enumerated" 
        } 
      }) 

      # Add the RootNode to the Treeview 

      [void]$TV.Nodes.Add($TNRoot) 

      # Add the Controls to the Form 
   
      $form.Controls.Add($TV) 
      $form.Controls.Add($btnSelect )  
      $form.Controls.Add($btnCancel ) 

      # Set the Select Button as the Default 
  
      $form.AcceptButton =  $btnSelect 
      
      $Form.Add_Shown({$form.Activate()})    
      [void]$form.showdialog()  

      # Return selected DirectoryEntry, select the Object property of DistinguishedName, then expand the string for output to the variable $OUPath
       $script:Return | select-object -ExpandProperty DistinguishedName -outvariable OUPath | out-null

    } 



      # start Function 

      . Browse-ActiveDirectory $root 

      # Trim all spaces from input Distribution name to be used for the SamAccountName
      $SAMname = $DistroName.trim()

      # Create the Group type of 'Distribution' and Scope of 'Unversal' for 2010 Exchange compatibility
      $CreateDistro = New-ADGroup -Name "$DistroName" -SamAccountName "$SAMname" -GroupCategory "Distribution" -GroupScope "Universal" -DisplayName "$DistroName" -Path "$OUPath"
      $CreateDistro
    start-sleep -Seconds 15

      # Mail-Enable the Distro for Exchange 2007+
      If ($CreateDistro -ne $False)
         {
           Enable-DistributionGroup -identity "$DistroName"
         }

}#End Create-Distribution

function Create-DynamicDistribution {

    Write-Host " "`n`n
    If ($DistroName -eq $Null)
	    {

	    Do 	{
			    Write-Host "Note: NO special characters like slashes."`n`n
			    $DistroName = Read-Host -Prompt "Please Enter Distribution Name" 
			
		    }

	    Until ($DistroName -ne $Null)
	    }

    # the Main function that can be loaded or gets started at the end of the script 
  
    Function Browse-ActiveDirectory { 
    $root=[ADSI]''
    $StartingOU = (New-Object DirectoryServices.DirectoryEntry("LDAP://OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil")) 


    # Try to connect to the Domain root 

    &{trap {throw "$($_)"};[void]$Root.psbase.get_Name()}

 

    # Make the form 
    # add a reference to the forms assembly
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

      $form = new-object Windows.Forms.form    
      $form.Size = new-object System.Drawing.Size @(800,600)    
      $form.text = "PowerShell ActiveDirectory Browser"   

      # Make TreeView to hold the Domain Tree 

      $TV = new-object windows.forms.TreeView 
      $TV.Location = new-object System.Drawing.Size(10,30)   
      $TV.size = new-object System.Drawing.Size(770,470)   
      $TV.Anchor = "top, left, right"     

      # Add the Button to close the form and return the selected DirectoryEntry 
  
      $btnSelect = new-object System.Windows.Forms.Button  
      $btnSelect.text = "Select" 
      $btnSelect.Location = new-object System.Drawing.Size(710,510)   
      $btnSelect.size = new-object System.Drawing.Size(70,30)   
      $btnSelect.Anchor = "Bottom, right"   

      # If Select button pressed set return value to Selected DirectoryEntry and close form 

      $btnSelect.add_Click({ 
        $script:Return = new-object system.directoryservices.directoryEntry("LDAP://$($TV.SelectedNode.name)")
    
        $form.close() 
      }) 

      # Add Cancel button  

      $btnCancel = new-object System.Windows.Forms.Button  
      $btnCancel.text = "Cancel" 
      $btnCancel.Location = new-object System.Drawing.Size(630,510)   
      $btnCancel.size = new-object System.Drawing.Size(70,30)   
      $btnCancel.Anchor = "Bottom, right"   

      # If cancel button is clicked set returnvalue to $False and close form 

      $btnCancel.add_Click({$script:Return = $false ; $form.close()}) 

      # Create a TreeNode for the Starting OU or domain root, if you uncommented the Param at beginning of Function, and
      # you also have to replace the below $StartingOU.xxxxxx with $root.xxxxxxx

      $TNRoot = new-object System.Windows.Forms.TreeNode("Root") 
      $TNRoot.Name = $StartingOU.distinguishedname 
      $TNRoot.Text = $StartingOU.Name 
      $TNRoot.tag = "NotEnumerated" 

      # First time a Node is Selected, enumerate the Children of the selected DirectoryEntry 

      $TV.add_AfterSelect({ 
        if ($this.SelectedNode.tag -eq "NotEnumerated") { 

          $de = new-object system.directoryservices.directoryEntry("LDAP://$($TV.SelectedNode.name)") 

          # Add all Children found as Sub Nodes to the selected TreeNode 

          $de.get_Children() |  
          foreach { 
            $TN = new-object System.Windows.Forms.TreeNode 
            $TN.Name = $_.distinguishedname
            $TN.Text = $_.name
            $TN.tag = "NotEnumerated" 
            $this.SelectedNode.Nodes.Add($TN)
        
          } 

          # Set tag to show this node is already enumerated 
  
          $this.SelectedNode.tag = "Enumerated" 
        } 
      }) 

      # Add the RootNode to the Treeview 

      [void]$TV.Nodes.Add($TNRoot) 

      # Add the Controls to the Form 
   
      $form.Controls.Add($TV) 
      $form.Controls.Add($btnSelect )  
      $form.Controls.Add($btnCancel ) 

      # Set the Select Button as the Default 
  
      $form.AcceptButton =  $btnSelect 
      
      $Form.Add_Shown({$form.Activate()})    
      [void]$form.showdialog()  

      # Return selected DirectoryEntry, select the Object property of DistinguishedName, then expand the string for output to the variable $OUPath
       $script:Return | select-object -ExpandProperty DistinguishedName -outvariable OUPath | out-null

    } 



      # start Function 

      . Browse-ActiveDirectory $root 


      # Mail-Enable the Distro for Exchange 2007+
      New-DynamicDistributionGroup -Name "$DistroName" -RecipientFilter {RecipientType -eq 'UserMailbox'} -OrganizationalUnit "$OUPath"

}#End Create-DynamicDistribution

function Create-OrgBox {

    param ($Username)

    Import-Module ActiveDirectory


    #$ErrorActionPreference = "silentlycontinue"

    $OULocation = "OU=Group Mailboxes,OU=Groups,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $UPNDomain = "afghan.swa.ds.army.mil"
    $OrgBoxPassword = "MailBoxx123!@#"
    $DatabasePrefix = "KDHRDB0"
    $DatabaseRandom = Get-Random -InputObject 1, 2, 3, 5
    $DatabaseName = "$DatabasePrefix$DatabaseRandom"

    cls
    Write-Host " "`n`n
    If ($Username -eq $Null)
	    {

	    Do 	{
			    Write-Host "Note: Org Box name must be 'grp.KDHR.XXXXX.org' with NO spaces or slashes."`n`n`n
			    $Username = Read-Host -Prompt "Please Enter Org box Name" 
			
		    }

	    Until ($Username -ne $Null)
	    }



    If ($ITSM -eq $null) {$ITSM = Read-Host "Enter ITSM Ticket Number"}


    $string = $Username

    $NewString1 = $string.Substring(0,$string.Length-4)

    $NewString2 = $NewString1.Substring(9)

    #Write-Host $NewString2

    New-ADUser -GivenName $Username -SAMAccountName $NewString2 -Name $Username -DisplayName $Username `
	       -UserPrincipalName "$Username@$UPNDomain" -ChangePasswordAtLogon $False -CannotChangePassword $True -PasswordNeverExpires $True `
	       -Enabled $True -path $OULocation `
	       -AccountPassword (ConvertTo-SecureString $OrgBoxPassword -AsPlainText -Force) `
	       -Description "ITSM: $ITSM *DO NOT ENABLE PER CDO0091272* CONTACT 421-8613" -Confirm	


    $TestAcctCreation = Get-ADUser -Filter 'DisplayName -like "$Username"' 

    If ($TestAcctCreation -ne $False){
        start-sleep -Seconds 5

       Enable-Mailbox -Identity $Username@$UPNDomain -Database $DatabaseName -DomainController $DomainController

       #pause

      $TestMBAccessGrp = New-ADGroup -Name "$Username Mailbox Access" -SamAccountName "$Username Mailbox Access" -GroupCategory Security -GroupScope Universal -DisplayName "$Username Mailbox Access" -Path "$OULocation" 
      $TestMBSendAsGrp = New-ADGroup -Name "$Username Send As" -SamAccountName "$Username Send As" -GroupCategory Security -GroupScope Universal -DisplayName "$Username Send As" -Path "$OULocation" 
      $TestMBSendonBehalfGrp = New-ADGroup -Name "$Username Send on Behalf of" -SamAccountName "$Username Send on Behalf of" -GroupCategory "Distribution" -GroupScope Universal -DisplayName "$Username Send on Behalf of" -Path "$OULocation"
         If ($TestMBAccessGrp -eq $False){
             $TestMBAccessGrp
             }
         If ($TestMBSendAsGrp -eq $False){
             $TestMBSendAsGrp
             }
         If ($TestMBSendonBehalfGrp -eq $False){
             $TestMBSendonBehalfGrp
             }
       $TestSendAsMember = Add-ADGroupMember -identity "$Username Send As" -Members "$Username Mailbox Access"
         If ($TestSendAsMember -eq $False){
             $TestSendAsMember
             }
       $TestEnableDistro = Enable-DistributionGroup -identity "$Username Send on Behalf of" -DomainController $DomainController
         If ($TestEnableDistro -eq $False){
             $TestEnableDistro
             }


    Write-Host " 
      `n`n
      Please wait 15 seconds, while Exchange generates the mailbox and attributes ....
      The Script will continue automatically."

      start-sleep -Seconds 45
    ##  cls

      Write-Host "

 
     Org Box created       :  '$Username'
     Security Group created:  '$Username Mailbox Access'
     Security Group created:  '$Username Send As' 
     Security Group created:  '$Username Send on Behalf of'
     -----------------------  -----------------------------
 

     The Mailbox Access Secuirty Group has been added as a member to the Send As Security Group.

     The below security groups have been assigned to the mailbox:
    "

      Add-MailboxPermission –Identity “$Username” –User “$Username Mailbox Access” –AccessRights “FullAccess” |format-table User, AccessRights

      Add-ADPermission –identity “$Username” –User “$Username Send As” –AccessRights ExtendedRight –ExtendedRights “Send As” |format-table User, AccessRights

      #Set-Mailbox -Identity "$Username" -GrantSendOnBehalfTo "$Username Send on Behalf of"

      Disable-ADAccount -Identity "$NewString2" | out-null
    }

}#End Create-OrgBox

function Get-DatabaseStatus {

    param ($DatabaseName, [switch] $BadOnly)

    $DefaultColor = $Host.ui.rawui.ForegroundColor

    if ($BadOnly) 
		    { Get-ExchangeServer -Identity $DatabaseName | Sort-Object -Descending:$false Name | 
		    foreach {Get-MailboxDatabaseCopyStatus -ErrorAction silentlycontinue -Server $_.Name} | 
		    Where-Object {$_.Status -ne "Healthy" -and $_.Status -ne "Mounted"} |
		    Format-Table -Property Name, @{label = "Status"; Expression = {
			    if 	($_.Status -eq "Mounted" -or $_.Status -eq "Healthy") {$Host.ui.rawui.ForegroundColor = "green";$_.Status}
			    elseif 	($_.Status -eq "Seeding" -or $_.Status -eq "SeedingSource") {$Host.ui.rawui.ForegroundColor = "yellow";$_.Status}
			    else	{$Host.ui.rawui.ForegroundColor = "red";$_.Status} } } ,
			    CopyQueueLength, ReplayQueueLength, LastInspectedLogTime, ContentIndexState }
			
    else 
		    { Get-ExchangeServer -Identity $DatabaseName | Sort-Object -Descending:$false Name | 
		    foreach {Get-MailboxDatabaseCopyStatus -ErrorAction silentlycontinue -Server $_.Name} | 
		    Format-Table -Property Name, @{label = "Status"; Expression = {
			    if 	($_.Status -eq "Mounted" -or $_.Status -eq "Healthy") {$Host.ui.rawui.ForegroundColor = "green";$_.Status}
			    elseif 	($_.Status -eq "Seeding" -or $_.Status -eq "SeedingSource") {$Host.ui.rawui.ForegroundColor = "yellow";$_.Status}
			    else	{$Host.ui.rawui.ForegroundColor = "red";$_.Status} } } ,
			    CopyQueueLength, ReplayQueueLength, LastInspectedLogTime, ContentIndexState }

    $Host.ui.rawui.ForegroundColor = $DefaultColor

}#End Get-DatabaseStatus

function DigitalSenderReceiveConnector {

    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    #Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010
    $base64IconString = 'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAABIAAAASABGyWs+AABC0UlEQVR42u29eZxcV3Xg/z3nvXpdKpXa7aYthBCKEMY4jvE4jiEmIQRPQmBgQjIDgUlIBgIxeAjgJITFEAw2q5MQdiaQZQIM/AIzWXAYJ2QB4hDCYmwwIIwihCzL7bbcbrdapeqqV++e8/vjvupF6tbqRTL360+71F1vve/dc8899yyQSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSie9v5P6+gPubT3ziEwBalsbUVE/xin7njhwAzfP4IbmZ0e/1FAHNM3V3DcEUIBNVVdWiKNTMyrIqu+6UV111Re/1z309jqtsylqojOZ5pkWR0++X9Hp9y/PcGo0GoQpVFSprZDl5lhmqRqa4hwoMEalUlWazaa1Wy9zdLr300vu7+RKnOPn9fQH3N+6OiOQAIky4o8AYoMAEsY3W17+3gVyEtjsj9XY50Kx/xoBdwD+IsAe4HsgFyYEfA34RKOqfbv3TA0pgvyCd+t8l0Km/m623m6v/PgeUItIFqvu7/RKnNt8XAuBd7/pgDuj8/MwYoP3eoAlg5s1t3/oOAi0AzZpj4LiFNqC4jwmooWPupsROrma2BicHcgF1d3P3KoTQc/ceeIXHzqmFGkDlXmHeMxOrqoC7m4goUJiZOg7QcPdBsFDh3nazErdRx3vgXaAs+4Pu3L5OZZV1r3jtGypUKhExoETEmkWjk2eZAZ1XvPoVdn+3feLk5vtCALA4kj+T2Il/kDiin+nuhBA2AKh1ARCh5+5gwdyBihIwUakcrzxYB6hyzTruXrr7XFUNer3e/LQIt7WajZm6w7Lhwg0A1c4dt8y5+/f6fV8HjDaKoiiazWaoqrFBVTUFaalmzeAhD8HzKGAkBxQRhdiX3b0AyQXpiUgF7AV6Drskagr/RtQePl9/JhKrckoKgDe+8Y05oI1GsyUi2uvOt91dqxBaDlrkjZksyypg5neuuLwCM8DMHNzxenR29+n6kCWxh1WAiUhXRLBgpQjmTq/ergLM3bt15+sBA2JHG+4/DcwRVfThFAOg47BHnJaLt1icCozg3kSkwKOG4U4u8dnkiBQgGn9cQVrx7/EeJJ67UtEKAXcxc6y+Hj784Q/ngO7cecsmQKt+lQO0mmvmRIRGK5sDePSjH90FePKTn5y0hu8jTkkBQJxrN4GzgFHgPOA04Kxanf8kce7818Cc6qAEqkG/ih3DmQFRc/86QNEY2QtukvuUiNiDHvSgGXe3sixnRLCXvWzjjLuj+uxj7hyXXnrpsDPeXP8cFR/+8IcLIJ+ZOTBm5s2q6rbcQ9Ht9sfMvKn4uAgFyHoRKfI8P01V82BShioKnyVtpcBlRBvGeP37Z+vr+nz9ub3evnu015g49TmpBcA73/zOJpB3Bt224UVVVaOYF2W/Wo/QCtX8FhFpB7OH4t6sR9qyHp0XRkHiyKzAHuKoO1v/vrfeZrbebrb+vVt/1prBwih+n1HbCAwWtA9j8Xnl9bXl9bUWRMGnRA2kU98zg8FA67+X7l7WBk8dVINHIFjZicf/ylduGMXhNa953V7A2u32DGAbNpwxJyL86q/+ajI4PgA5qQUAce4+RhzhNwCPQdjg5lsQRsuqHI33IHtEpJfn+TdVdTZT6akudBxe+tKXDufCf3k8F3HZZff9jT/3uc+tiJ24dyLHmZ+fz4HczO8GSs30TBHJy0H5y4CKSAuwEGyHu1fElYse8LdAT0SuJwqfufu+FRL3NieFAHjXu97VBJr79u1vDwZVC6cNNGe7+zYJjLvKDziM4d4Er0Rk0mGvqBruBrKb+NJ+lzgiDn9Po1ZshxzYATRrzw8VkQ6AiKyvt+uKCIKMAVW/338M0L9l1+4WUF35+qsmgUpzmdFMq0dd8KhZEbFnPPkZqY1PYU4KAUBcZ98InC3Cw905G9g0sGor7hNiUopqBWwTmNYs/7Jm2Z0jI8W2RqMx517scF/bBXqveMV/T0asJbzkJS+Zqf/5iaV/f+97/3gzQLe77wJ31/kD3R939zwT/Wl3z6vB4JnEkX8v0C0ajeuJWsC/ALMi8mV3L1mcPiVOQe5TAfC+971PRSTfP3ugbWajg2owamZjc7P7N4vqJjd/qIquN7Fxd89VdRL3KUT2Eue1O4G7iM42HeqXkzgfrohr6YmjY2jsmwQU5+tALiIqIrm7T1E7PwliIdgGERnLyB7jgc63v3LzKE73TVe+ZZdDz6WYUtXqta/9zaFmcX/fX+IouE8FQG2AagFnEuf1/wE4r6rCFgibVZVMM3CfNHy6URRfGClG/t3crnfCbnff+5rXvCZZqe8BXvKSXxsugQ4/v7hz505EpLl9+/biG9/4xoWhsnbZG/wXM2sPqsFTREQFfYqZVf1+f1ZEpkeKkc8BtwJ/R9QQdtbHS5rYKcB9LQAUUHPTYEHd3Yhr7HuBUpBZEZkT1d1ivlfgO8AUsNfdO7V1P3EvISK4+3D1Y4q41PpvCC1RMRUt3H2Tu+ci0hKROXczRDTLvCliQ+GcOv8pwn0qAFQVQIOHvLJQ4F4hdMRlr4h08yy7sdVas725prnjRS9+0STRKSe9TPcRD3/4wyF2foBt9ecN73//+wvgmvlub7Szv/t4dx/L8vzHgZ7jJqCNho+C99LzOrW4RwXApz/9aQX0xhu/Ptrv9zcJUqhqy817Fqx79137emPjo90sy2arKmwjjvzfRRYCYHYTR56hZ116mU4OhsuAlbtvQ2gRn9HQCNgB9oBUf/AH797U7/VaZa8/hqCqWojobGNk7V6g+6pXvSwtJ55E3NMagBKdUjYBTwFOr/89jcgtIYSdwDdPP/20yUsvvfSbhzvQpb+eQl1PFl784hcPXZwhCukV+YM/ePd64EJgPcKjiVOINvBtosfhJMmf4KTiHhEAv3/177eATTd+9caxKoSt7r4Z53H1SDEGjIIjMKeqzXvqvImTAzMD0He/673FYDAYtRDWm9nZqlmhqqNmNnqgM/sgFfnum6966zYR2bt2ZM0kUF72ystOyNEpcWLcUx1xFLjQzLeGEH4WGBf0TCH+B75HoEC4W1WHgTCJBw4qIpqJNMsQxs3s4e5cBBSZZu0QQhWqQYVm28jzLwNfAq4jTh+SALgfOS4B8OEPf1iB5tRte0fnu73zDxyY34DwJBHGVXSDmTerUPVUda+qbkdkJ/AVls/xEw8QRMTcHWKH/pqIzKhqKSKbQgjn47SzLBtX1fWOnxdCaN3dmV2votvf9ua3bQOmX/3aV8+c0EUkjovj1QCG2XG2AL9o5hvN7adVlaLIMavKEELX3Xc0Ror/I8jNV1zxmuvu75tN3DvUTj9GtBNMf/CDH/wa8MXpO2ceW5aDHNiS5/l6oj1ok7mdG8ye6Mo/AoXj3wSSALgfOCYB8La3va0ANu2+5daxqrIniPNgRM4VkVExAaEXQpgG9mSZXi+i3wW+RrT2J75/qIBZUb1ZVf8C/FE40+6+cTAYnAUUqjqK+3nd+fmWqG666qo3bWiMNHde9LSnTLp79R8f/ei0AnQfcKwaQEHMorM5VOEFItLK82wrLmRZhrt3g9kuEblhfOL0PwFmf+M3fmP3MZ4jcYrzwhe+sATKb3zjG3MicvO1n7r23EE5uKtfVj9ehbA1y7K8keVjVaguDGYXqMimDHko8GlgWtIS8H3GUQmAt77pdwvgzEG/Wl+FwS8CYyqyHpGinvt1zX23wE5V/RtR2ePuUyKSDDzfx9RTg4q4/PcFUelmZJWInBmCnYujKporshnzvJzv5df9xV9vbjQa13/kIx/ZAfR+5Vd+JXl/3oscrQZQAOfgbDbzZwKaa9YafunuHXfbjsjXHvrQB38CKC+55JJk6Ps+59xzzx2O4lPA1Fvf+rszwFx/vv/kEMJZIhSqiohsxtnsZuPmdo4ivXqfYZq1xL3EYQXAG95wVRO4sFfOj2P8CsKoqhYSjYA43sXZjbCzkTf+PxGm6nx5SX1LrMQ08DXNNEeoLITzQgjnZ5qpqamoTOSSF8CTb9m1e2Oe59f94R/+4Xagc+mll5YneO7EChxJAyiInl0PNren49BoNKjVfnB6DjsFuemixz32WqB60pOelNT+xIpcfvkrZ4CZ3/3dt1dAp7O/U7j7ueaWZ2QqIuNZlo0HC1jws0RtmjpQjMUYhcQ9yIoC4B3veHcOnNnr9cYP7O88GWjVIztVVUHMQT8Nsisv8o9IjNfvkQw3iaPAnb3ATZnquOR54c5ZZn6mWaCqKsVpOb7RzH7ijjvuHM/zxt9/9KMf3QH0nvOc56R37B5kNQ1AgS0iMuHuF9Z/K2MOfTOgK6qTCDsectYj/p448icJnTgqXvWql88Cs29509vGgVZZDgoz2xhCUDdTRJoi0nbsPIcJVdtGdCKrSJrAPcqKAqDXmzdg52BQTYUqvBkA8QpERbNCkFJFp0RkmsUMuonEseHsQhZyOP6Lm1sVAiKCqIDLnJj1iCnLUym0e4EV8za97GUvUxEZdXOlT9vcbN7myzwvdHT0QW0RrU4/fcMsUF1++YuTtT9xQlxxxVvGRRifm9tf7d/fqbLMLMvcQshy0Bx8+gMfeHd6z+4FcmBo1NNr/+ZavWXXLee4O6WVbRwsAAJe55YnLs9UgwFd8DTyJ04YkVjH4KEPPWO96oPXi7viqLmrO2iWbXznO99jjUYxXRTNLjBzySXPTcbme4AFAVA7bSiwEYE8z2PBzJFGz9011qSju3ZtcxKonv/856e5WOIe4corX1MC5R/+4R9uEJFRq6xw85x6ajkIoemL09VZUk6Be4wc4O1vf48CF5qFZu9A53JEUNVhgxtAMENFJ1UnribOx5J/f+Ie4QMfuF4B7pr+x3Nw/0kR2QyyPlQVZoaoqoiqu+1099mR5sgfXX/99dvcvXrMYx6TtNATYOkUYKOZt4LZEw7eyN0xc3PxHe7eJhn9Evc8GqqwHvwsETlXRDcHsygAHFTBzCbAZ93sL4gpzJNR8ATJAQ505hT4WaAY5nMfDAYIdZAPXrrbHpBd69YVN5OssYl7llh/0dkJ8q8hhAknbLahABAjBAF8IzBRBTvzi1+8fpqYgjwZB0+AHMDMFNgK5Jkq7o6b4zhZlkEsNz3n7rP//b+fNwPw3Ofe35eeeKDwohddCGBvecNb5oDJgXnH8WGqsVpDdYg1JVruPhZCGCOlljth8ne9639uHgwGxd133XkOoLhHAbC0yo5QYT6FML2kam0icY+ijcZeQK3sT5tbry4kk3v9TmZZhqpiwR49N7uvIPoPzN7f130qkwPtWGeeMYjSdsHXH6KngEPtsNFTTUaXxL1DVhQ9YM4OeLeuVJxrrZFCDC+OtSV8zMweQsotecLkvfnuubjnWZblwNDXfxkiYlnemCXNtxL3IiMjeQeoMtVZiyP7OEvU/NoVHYSt4GMjIyMT11577R6g99SnPjUNTMdBjvtoXYhTl438yzHVrAIG9/cFJx64jIzkFVCKSKmqVV2mbAF3EAHcWwgmKsMU80pamTou8n5Z/hB4fojqfxDuYdjQicS9Qp7nBlSO7/eoAYwu/d7dMHOACWBs0B9s/PZN397IYqBQ4hjJHW+7+9FaU7P7+4ITD1xUNeYCdEygYnVjcwHkbl6EEJId4ATIPdgYoIfTANw9typMkGwAiXuRRz/60QC2+3t71MyKPM9VVQkWlrqrIyJ5jBjUTUGYBfYQvVMTx8hwmeVoVPs0BUjcq6xbt24hJkVEVERUVXF82UpA/R2IjCA0Se/lcZPneb4dPC/LQd34YdkGtWZQWPAzEexP/uRPxgB7wQtekAIyEvcod955pwGY2fVmZsHsDKDt7oY7LnGgUlEEYWRN8+uNvJgiJQk5bnJVKd0xETmcETBW/fU49yIZXBL3AmVZUr+HXWA2RA/VcugS6LgOM1iICDg9VS1JKwDHTd4YKb7q7sWgCgjQiOssC8Jg6I6Z5VqISKvT6Wwh2gJm7++LTzywqD1MDfiiOzcAitd+aO51XoqFhLQQR/6KNCAdN7mqljHgQhYMLcP11qUaQZxzodR2g/v7whMPPC6++OLhP3ukqsH3CbkqXzPzoqoG1wOWaTYjIlWWZduAsrLBtwQpi6LYLkIJ7CKpXInEA4JchAp8mO7LiJK3UtX97l6qyizQG2kWM0B12WWXJYNLIvEAQd7xjndoo1HQbK5Zj7vtuXWyA9Bo5ObuBB9UAO1227rdbuHum7Is17VrRwuQzm/8xq/vur9vIpFIHB/5b/7mb9pnP/tZqJ18fu2SF6zqUHHVVVdBXBFQkPozkUicqghALQD49re/rYPB4CwLVswfKM9xt7wK1Q/FhKB+lpm1qiqcD2JZnvdE5OZ1o+03AzOveMVv3XR/38zJwOs/+1kFtMgyzVWLvGuMzIYTPu7JRJ7D+OnQK7HvTmJrm6W94r99oQIQufK47UOf/exncyCfyjI9oKqD2YrQXT0+pXEgIwsKePfXfu0nTsgu9Vsf+CjARH9gOnXX4ExzyweDclMw1/3zVVtVdN3apgrQyDKqYBzolQaYqvQylbLVbMxkQuf0Zr7Hne4fv+p5q+bN/Gz9nnw7y/L9qnljLlB07n3T2oG5HBDOePigEq1H8IsvvpiLL76YwWAAi6P6Uot/cZifpAks4XABVQ9A7tHnfvxtJ8e535JzL7+ng39ylveHlX6W7SMnfkn3Ccsu8y1velsTeKW7rwN+exgfEOOwQ50cNEqpPM9x99LdZgW5YbS97vXA7Mtf/fLt9/dN3Z/8p9d8YCNwURnsR4LzS25m7lYB6ArBLavJfKl/bJXfV8PNlrhsC8Tw2ri/HHn/pT16IRHXQd/X/VTd3QyvcEycnqjMFSPFTtxvUQlfAKb+/q2/fvOR2ux5v/eR9QITe+468JzK/Klm1nQnF9xEsNWvWQpBdO1I/n+bjex24H//5RtecNTZqp9x1R+f7+7ambcXuHt+oN9/ijtqyHoAUS3iZ4yBE1lsHa9bx91jg5jVRTQoVaSjKtNFo7FDhO0jDfkXYOe1b7r0a8P9n3r5H50LnN8bDC4O7k/0WGMj/pyA8Bi+J0PskO+1EBHUBp8SsJXW8ytgIRZ7GCcwlM6LvgLLXg01swLIf/9tv68Av/3q3/6+XCpc2i7DDuSOimDuK4+YRxr3/Ni2r/M6RIcuEdFFv44TO5cs+d0dXbg3MAcVUPc4Ipp7AZL/3BV/pACfvOqSVd+HOielxmtfPC6C4cNS9Iey5Hpyc88F9NV/9EkEeOslP7fis3F3/vPvfDDHoQpW1OfMnXje4bmE5e/6Sp6yQ6ekZf4yi9ek9XOPbeEUF7/ifYW4W7scVINhf6q3o27DZY18HBy8+8GHkmGRH0cdX+7Q84hHPrwnIu+dmrxjbGbm7vOBJvDEpRrA8IZr56Eiz/P14E/ozB/4iIjc1G6tfR+xetD3pU1gf68sgAnLig2eNbY4FbUCsIyDO9aJIyBCbjYrUAWvSsAsa25GNCfcc3aIpa/7gqpbv1n9AeBu4lSZ8vm1BR8gZu+9frXj3XF39zwRuXje9D8OkPPMqlh0yuTwbaPRFj3o9n9J8fL0tc0v1krODCt7B+Z1sNGLEYq9+/qvdVDPi9H4amfLO/VCPpLAcgfEg57b0D05Oi4WiIwHl/EycCbB0QEvUXzHSMb1wD+J8H97ZTVqou0SXe8iW6Jm7VEMrNjW98x7InmOIHj/wBYO1gCG4ZYIRh1euSQri64oBRd/VxHyEELLofXGN76lEMF+53de833upnmEx+Z+TAJfAFaaYC50REp8wUV28TT1ue7pW1uWPnI4WrI4MgezJlC85F0fUQF7z2W/srD95z//bdzhTf/vc+ruudelwIbtcsRL9oX/aT2CF51ef9X8AFf/+T8WgJrTcuKoz4LGtORdXumk9U0dboD2papW/Vk71oOg7hSOFD2RlgjFwrTOl0wnDnfTsvRBH/cjW8YyAfCsZz0LYO6j11zTedDDf+BFd+zavX7fndMfBZpFMXK2mTEYLPoBuTtVVSEizSzLN4fgGzvd+SeKyE1Fs/FR4GbgH0/oik8xREUFFBV1VcwtKsfLt4q+7RC/dzvKzimgWgvqOOIvit8MEeGMtc0/W1dkt90yve8Hg3nTRZ+JSNvD6tncvN5/4RyrbugI9Zx3hW6w0HdFVbO8CGaPnT1Qnp2p/KXAbnx5DIk7hQhFCH5uWYWnGrIBBEI4urKTVgGC540JVOlV9uTvTs2cDXyMqAUs4wvbdl4K0pqr9HVAYdQDWrmK13E959e8AUC25DnG6ZTgZkSNxYnlDYbzLFtoExfFNNsatNiqHs6zzJ60piG7T281v3f7vk4+GNSyWmSF98Drfp+BKKLx53iRPEdEMJWcVWwAQwk2NErMgrTcvWTRErrCLvE1ivtSmNkozugbXnflmKqW7dNOLwH7rd96yQPaNiBDQw5UuJfDueSyLRa7ClKPXhyVRd2pjxufz7K558JbF/3ofdF+c6RD1q/1kTW1eDNHEQfii5pAHT/S7VfDSNIFbtw9mQNNh8Ihj31nZeFy2HPBsOPlZjRVRJfmD3jJOz+ei8B377i7Bb7WPd7xkVcdHBADL+NkxBfaSJBhdKKCD7WOldt7mYbhubs3zb01CKHlTjHUHORwlyMMRwo7OFfisSD48HJK8JUFwHN+7ucMmHnP298zd8bYxCXd3vyGbn/+ahFazZHm+WbGoBosswmEEA3dWZa13P2CQX9wAbAzU/0icCNwLVEqTx3vxZ8KrGloD2SyNPtuCOUNZsZyQ3YcN/CY9CLg6w3Wm0hcVj1MYlbA1G2Xiszh1hOhMpccEW1gswpVhn3ywWOtPTsmw39waJEfcUnKAGsX+Q6ATOjWNkSFRWOY14befsVmBw1oczVNAHc8VJhqU7K8WeFn3jY9/3iiRjg93Oxz2793piDnVciPVpKdZVbhdVMtv2Q5aHRcaRoqDAbhx0x8bs1I4y+BmWFHkbrozd3d8gXAWOVaRFG9il1EMsDJxErBu60G/4h7T53vEFcmSqCJ8pAq2Pq+8wRziop8LNouDu6fDmGAh4oKtpiyJdhgrj8Is2UVRqE2dq40s5Oo8Qk+pfhcVVU73ZnjeBP0VGWtQfqXZFUN4KBdiHECe4HROlZbgeYRbALUhR3a7pzem+9uANe3vOktvTzPe4/78ceVImKPf/zjj/keTm7EgK7ECrZT9Xh/8BthIuQS7SpNwcfEyZcu+a3AcIloTmC6rtNQIQuj6hyLz6o+1NGMpEObN9MCJtBZsBSzxObgHq9VaBFzQ2w48nEXLeIWNQcFuP7663F33vjJGwucUXeaRxiMF+xQLMQHLz1VLGTjeGF4U0SKN3zo2iZRG7JOv4zXjOSO6xLbwWrXbhKf0bQgHWAavAcyW29QAj13RkByEZ8WpI37KEfqlDJcHRI1J4/zjJUF27LdhB7QEZipE6aeaETuHEcSAC99+UsrYNfHP/7xPcAle26d3Lx/rvNGRMaKovgxs8XVgaFWMvQTiFJLNovoZjP7me6BzqWqekOzWXwWuEFEPl835AMquOgFP/ygvSLyuZun/bq75/nTRtFkTXsxuW3RrGifNrBNo6P5aLOZv/uTN/5yfxCe0yltSz/4RvHAMnkhAqJkWFehbI3kH9g4vvbz69qNybO2nt6d/N4BLXvGTz2W6mmPF4sj1LP50Ze+Q4mrOCsjCiJkFnpA+QMT7ctExF7+3CftMIO52cX3OIQ+Bzp79Ks77mzffNvshbP7e2fO7O+92UANKVbVBOqeau6tfhU2urOn/kJFROfm++eb+3MHrptsYfZ4KJnQU6UKwZsOeT2tWDyLBRCjD+eJwGmZPvbWO+9eD3wZ6N2xr/t0hNMtKyaAJuHwc/6G0hNh5uxNZ/wm0PmTlz/n71Zrxl9/z8fGQM7fvXf/hXft711pInnIR4pow1glxyZCBe3KaddLtatcj4DmiGY0MvvCSMO+jutf/8NbX7rjHnlZOXopEue0UaJO1p8z4DmxWvAhUs9jCifMbTgXVaBtZmdUVdjw5S9dv9nc5t72tt/tYJRZkFJV7WGPfJjBgkHyVGfVuZqImIjYscx2AfA4B3RbmAce9HmsVuJ4BcFCJbpg91npvIhQqUin1j5sqVa+6lmjLcBEpBcjT+Gvbrw1B5oILTea7p77YUc/6ahIx1XGzLzp0W6gy87r0RPBgWDenu8Pxoo8z6+99ju887rPrAGaC8Pvkvte6ZlJHGm7xPiYIyQbjRqfR81pVpBYZUtYxbC7xAbky7xuV3s0w1J9uTtFrlnxorf/eXNQDrBjMAVUdaKfZmPEaoFT/tHLn310AuDZz362AbMf//jH54CXfm/nLZvKfvkCYBPCMxXRLC8KM6MKi7akxequUqhq4e4XDQbhIvdqar7X35Nl2Q3NNSNfBbYT14pngc6JGDnub5797GfDoiFwVep20d/7y+tLFKuXXo9IMC+9GvT27SvLy576ywva0zsO2m7YMY5CwBi47dq/Z6+727kPfvCqL7yZdUXk8z/3hj/tNHKZDUZRhaGWcdCZRBn6LqrK7Olr12wnTiO5bXZ+A3CmkP1wZdW55lar9otNsFSgjK4p/u7Bp6396tRs5ycHwTZ3Kz8zOGNxDr+ofbg2VFSZLwdPHgwGs2esXXcDSNnp9s8DJiQr8rqyyIr3F639XjVzuw6YOdzIP+R9L/3FOeDLT3vtB+bGWiOP6AXf3As8Ifr1rfhITRBz98LxZvBoBF31BG5RbhkTFuQHmkVxJrV7viDHYAPw+t6Zq5/WNo7SBnDIDRA1gNvr33citNx9PdHRooCDPOJqD6yhzcDjDbSACQv2MHfvVcGqXHNUtUfUNk5ZIXA0SPQr1VUHisMQtz+Wh7/6gWpbOS1ttUHshe/8RNfdKasoW1Rj38yC8sK3f1w117FBFSbMPfdYWYoV/M3ij1AJ3gPmwDvU0735ftkExuJILktvavHSWFhRQaCbqc6qyFy0rUi12pTD3QjmbcTNxdpfunX70GalR/SFiHMQE5GjGPkPfp6UwO2ZiGbCDldhuNpwUMvEeufR9jHmMB7MVxEAQ/8Aw512MMbn+9WW2+/eX7hbcXAJz4P3XPZ7XfqvodUsYOeetfHmf929+9gMCbUmUBLzsL/7rW/9vTHg04N+/6xQVZeoyliej5xpZpjbggYAi7YBAFWdyLJsQuAcC/5fzcIuc9strh8SkU9xVKrXqY1Ho1reyFT7Fo5qqI6IGvmJp2Srl54cyQHaWfsiYofbXW8xPMfCFKPbK0dnuvM/0a/CxjL4xHCp75CLV0HyBhm2tyn2TRH/tzM22heplxrv3t/dDPxUQLaSN5RqsHzdP6b8RvBeJpR5rl/51Sc95tp3fPI6RHlEDzaLy0QYDLWGWgOoKhChL36hCIb4Y+/q7t+rKmPutM3CKk5US/Qlpxptrfkqx1gD493Pf9IuEXn/t3bd2bxz9sAYYqgeqgIUI5mtWVvYP3x1zwX7uuWP3jbbfUKnXz2BoSfgwYLQYq7OyuSiIEI56P/X2op/yACwzC568JfaiMVVsZ0iWGtNcZ1AeaIvUgXMici0CDcjEo0sQhNnlGjsyeP7tuIb3nP3nselwV3AbF0VdlnDfeQjH8kB7fWCxtJQXr7oRc9/QGsI9wn18p6A7u8Ntopg/bvmWuBqZsNlqeiQa2Lm1u5XtjFY7Pz1QVY6cinuXRGmRNgpwl7ACm/qq97/V8UNuybbwX3cXFuHW4tXkZ7GZcmYpUqkk4ncjVvpdpglSDx3sGA+3hsEE5Fh7YtF/4AVm8Nr2SPHm2h0aCurV2J8tW0suJWODxi+64dxMVxmtpCVlZgjxgAs3J8rjrkFyrI8saWEyy9/RQe44eMf//hNwOdu23P7lt5876lVVT3CzJ6oqm1VnTCzZWXH6+IOuNme4LYD+LTm8jnzatLMZlewAYwSpwx1MUjZQ6pSdIIsvCKFQ7Fvvnx9/LW0Wjk4aISpDZaiuS94ux36JqpmCD7d8MENmci//vDDN/4p0Hv7i57Re9X7/2oUYdzgvH5lP12ZtQw5ZK4sokiWUSh7mpnsrqqw5wkXnDX7wrd8/JsUTM4c2PuM6H6HIqIsdOr4WRktgDLYTx4oq06eadvU8/6RStvW97WmKGbBj0kD3bp161A7LjmKd/M5b/2zGWDW62jN1eXg0GlpMbDsuLyBw3C1IahAPuj3dG52Vu/J7L5VfeO7gUpExojlnbeISMvNx1iIlZY5YAaRHeDfRJis9y1hMSbh6qvf3nQnn7ztjq3AhJm3cc8H1WDsitdd2dEs68SqxVUHvNqwYUNv8+bNJiL25Cc/+R68tQc+y94/WYyMOwg9wsg/HKRiHQkouv3+giCZmptrARscOc2QHFxXffOjzWhWVaZYyBDs3bjuTkeELi4tDrPu3huE8WDeCuZNG3owHsVUy82P0jPzBFgIuzmSrcuX7SAi+HEkG1hwH65XHiTPkaK4Z9J7P/vZz66I1sU5YPsHP/jBFjA+e/fcWYNy8FODQXUO+BMEaYrSEpVv5kX+j5Jl//LIn33adUD1rHPPXaEhZIMIE/Pd+Re5+0VuYZyoBWxDZBa4AbiLGHk4B+wSkWFK6TRFOAac+g1Z6gG4fBNdMPgd2WrZFJhw99Pu7HSaDOf+B+a3AE8LyPmm+Zh7YNGSXyNSRwI6qo2bxsfW/oPHpWc++Jr/tgfgia94784G2cb5iq3mtAnLH/XQZX/2QP8iESEMfVOO4Bo9zJvgMbT9Xg1iG1ZCXjjn4a6rbhcRjTEfxxMLoDEGQAaDQsC03aY444x7Lb//0GdgBvh3YmdsSYyCaovItvrvMyzpqJ/4xCcA+N73bhkDWv1e92x33+zuG3HaQOHuuYiM4xS4b3UL60MIubt1b7/tjvV33H5nr6qq2Ste94aqkeddEUzIShCrvN8DbFhN5nGPe1yVZRkXX3xxEhZHM6oMO6fIqkIg+n+Qm+ioCBP7u4MtuerU9dffNnPFX17TDmYbzKQd82gsn8cvGetMcFOhUsEypXnpuz42WuRNy7TBN265tTL3HrgtHx+XYx49A47s8r/kKAL9KrSPtfme/pr3FcDogf6g6PSrURFHODQBjFucCk/f3dlSFPlDglnLl+j3KzT68P9dwUvcOphXfozzAJGARw+qadwtN7NGVR3XMuAReeELX1gSfb6nga9dddXvT2jOpjyXdp7LOLDjla/8rW0AXP6qpbsORdtZwFmhqp5tZo8V0VFVbdqi28w58V20xyKCBSvd3QZhEDUAZXutCXxbkJJoZDQWaxrsqavQzNbH+74vQiHZ8FVQYBVDmTtYdUjHXb6N4ZK1Q1acKW5VfzCY80y+BOweBN/SG4QnVi5j7rrCCx+XD0XoZUovV8pmQyqJxuU29WCxtjlSBrOp7mCwlSXJTw4muOX4Qgc6chvEiMi8Ww5+ANh3jE04BlwIrBfhh2sHoRW1CAGb3d/dmOf5ptLYjK8uUKUe+TNsj4pNhzDY5u4zvpiY96jwKobzq8hdImLj/V61ft++e0cArEBJVNEPayTZvn3nBDAuwnkCP6SqG4g+3IfEbC/zK6hVOxFpI1IIbARKC6YmVLg9DLBBVW1y3FSyScD+7fNfmgZ4w+uunHN3sxjnQF6M9ABGRqKm0Gi0eiIwMpJVIQT27dtXiYi12+1KRLjssstOXQ3C3RDIhMna/70E0WWe/IvbFiH4OLj64dyMh88Hz828Rcbotd/4xoQjY8FoG6ziKhtHQhfUnLw/CFtvu6tzwIyuO6VIBxFhEKqt7r7ezQ7jhrzkmEfdFHFcLUPYIFD86V99Jgfh+f/l4lWnAx+45jMKkn/qy98Zm+8Pzq3IziDLtsaovUOXAT2a481Exytjwp3WYQXqcElUZEZh0kT+3d2mcDlWY+BQWHRYXK24bwTAFVf89tA+cKQHcD5wkZs/TeCxWZaT50JZlst8Cg4WBkvrxdcGxK0iLMz9hm0bFiaDtldErCzLnSKCquypG2Vn/Xl7/TldN9RQg+gQ523DzzmOwuvvpCWutRtgpxXyGcCaRWPG3YmBKo4IMezYLS8rRucqe4JBESTbyLKsOUueYx0ObO5Nc9Yj8gN79+8/B/QRlcmGhZDfFUc9x4zChWK+rH6+Pwg/X492C1tY/RxXyrSw7PaOsTncDcfzfuUXAnsFGWodh3l3JQdGET27H7jEJGvTKDa4GfjqWZiCGZX7oTaQg55PnPNnZOrbm5nfCI1r/v5tL955oo/+unfGz5Oqxp+qzgFTbmEHTtPdW2behDoCTaRJtAHU7bP8EUePqeVOsMvztS3s1yT6p08MTy0iJjHC0SyEjQC9+cGcg813y7sAU6HrYCGErgidudDZSRQKp14i1GHbOYZQZfg36hwQw6SaBzsCqQijmUpbkPFgvnHVYzu4GYLnQCuYrb9z7sDZ5hY7/xFH7TpHnqOr6AmH96E/XsxAUDNGEaq//uq/XwSUP/f6P7o5z6Q6d8sZXRGhKAru2tfVW+7Y1/r0jTtHzfys+TKcG1zaMdZ/wGrCkSWej+K2PFPTwXaY2i7gZjiMVvgZZrbx8b/xrjJmBzmuu4wl1rGOyEkmANatG50ErHtgf9dC9fV+v3q4mU8gbBHVMQlhAyJtXciKE4VAqPPdHawhDL9f+LeKSjT0jNXFTsdrzQGArN63DmDCrM6DGFNsWe0gYhJLqu9192uJxsxTTwAg9fzSSqB8VMv+HLA/eN3zJ1fb4xlX/cloa83IzrluedZgfvCE2i9AD+nQCy+tN8lYH9xH57q9rVUIGw9ntDsoB4DGrLSH8dxbnn7sxPEAjgbJN+KM7++VvwnMrls78iFYqIs5pAls6g3C5vn+4BcqYyKgG9wMt/7h210V3IgeOUdICWcO6pj5xgBm5ncCGzhGG8CSZ5PXDb0LTjIBQBxNp+vrGiYPGVXV7SIyivtGdx8VkTERKdx9rF6yadUJTpuA6qrLJAdrDItpz5e3+UK0Vr3P4rpwnDJkCjTNrM0R5sInM0vD6qd6g5wjTGUylQqYFmFChdJBg8dAFjn4yHF0K4L5GHg1T+hV5qNHHv0PXudefZhbzEdxbCJgNSG0cJSoCeQD043A2L4D/Z8SofryzbffWp8Yc2+Wg/AQc8aDs9HM2147vK1+wQpQgVeZSicTmauwscp8fOU7jVkOMMOUicpQd3mMI48AUfzYNSDJckXAB/Nt7isbwNHyspf9jxlix182x/nYxz42CjT33LJnS1VVYw7ngjyo3+ud4zEJw2aQpoisB4osy+uXY/n7vJhzcVFTOHxaqDqffsyfhhBtDY28QQxgGowTvRRPWWJEmett81UTP7wA2NBulsDOzoF+u1A6wciDSx3IcrDB0HBomUkrmFGGYZqwI3SQ4aB2mGXJBVckrzfzKnaeo46qkuGOK+7jbuDkpWbn4o5aeCxQlQObWTy3F8CYI7hmcXnPDpN5WTSutHgo1a3TyLOd7WZj+75u/7xBGcYkpv459HrqaUIw2WqiWxG5cNX8AavqQ0uTlcfckeb+KU42AXAYhmGve1m0YraBW4GmavYwkKZ52Ej0QBv16Pk1RvRea9WfhYNi3gLwOEdF6oAYWcmktNJK1THnrTsCSzNhHPIMF65J6/x9Ryf1HXVZmrr6kBS+y25QRTjSnLKyoV0Fc6d2xV2lneprX2ipw8rZuPynIh1RupnqnKp06wvSQ09QuyXHTqhlKZvcrbkoPQ7/bDKVXtxdmjEgamFkWN6EdYBOLRUXVj5q0/NCJGQ0+B3Oiq8IYuJumciePNNtucq0mU+DbF3u2LP6pMZxxA93d37Ev0s95XCPYeCnhAD4pV/6paF339Aau23p93/8x/97A1DcefvkZjNrllX/LKApoj8oIkUVqg1Abm7jxI5Uz6Fox0S70SU6byw2x7LpgbPwkhwkfc1PcAWgTgum9SdSB6QsblC/QMNAjmM89tCDTBZGvSXfxqxNCq5ZduRDV8PATsdAShdUJK7nywqtcKiYlJWz34iCKpn4dJH51NqRbMe6NSNTsWCGrOQubCJi/SqMORR3zA5+pgoULBlFDzmLsJBzv6F0RMRKk+ZioI2zkNV3+Kd6RHep7Waqo8vUj/pTPBxyn0ufneY5YmbqVhWZ3vyQ09d8vNuvtFuG3NBzNFNdjIdYOjFbqU39hMYeG9pNPKY9OyUEwJFwp1vHY08S7Qe9+nOytg2MxiotElMwqTwUAJEoEGA8JovxFo66x2ASoveiultBrFiTg+dm1vQYLFLKCbiMLverH668H9xtlo8IsqCBHIFlwmKh3MUhDTf8xo5CsWjkEjeNmX3KpUbko61ucKhCFZ1vxc3yTHaONLIb8ky/Wz/LJTEJh6zmGMT8/gJbVaRy1fWOFHg49Hp8UXg3i3yHgIXSd4IT3M+LtkZpDdfdl/WzpatOQ0UqLqEutONCyv4lAsLdUfFOhs0gPqX4LhG+4rB9EGxDcN9IreH4ssQQRwoLPH6G6eiHIuYBIQAuueSXh5rBMBf8ilb5T3ziEwXA1NTUBkDLstzo7sx35rdEW6tvcFwt8BBA80a2oXYyGqPWGNwpzGw9MCcxeckJ5jR0ooPW6t9Hw9gwdbircmRNoD6eRgPmCmrl0KV3IVlGpkd6wdprMgOpVKhEKMXJNSaaPv53U4SYpt6rIs9ueuSG0/8K2Pnel/23o84e/RO/9Z4fz1QoycZEpLBV5uLDDLtja0duylQqn5u/zR2dr4jPXzQK/qyxZFa2VPAsH5/lkOPX0sGjPcBDMMVnC/Xtgt9QKH+LV3v+/LW/uuOJr3z/hcCZtePaEsXjaFryBCTBkhxuwgNEABwDcd4apxJLO9Ewa8xuYtBLO0ZexHyHItKqn36rbrPTgQMguzj+NOdGVEp3uft1bjbhxnhcG16qT2u9nmw9Fyp332VuQzvI6rh9FbjFzeZcvFhcf6+pVfc6/0JlvuDUdBhiLjnHp0X870BaFmwDGMeTxS2W0nKEupKR85U800mOPRvPl4DbcNvtJi0/KL3Y0nt2d/qDwbc0ajE3A+TCOkBNOBdEzW09oIa3a01AiTEFS4qu+oIwkGENDacS6GUic6h2HZsWlSkRviPIHvDdROcxNAaz7RS3f3XzLsPEukc0mJwYblHwi/uX/IEyBThanvWsZy0pdgKsUD3mYIa5+77zne/o17/+9Xxubk737t3bitPr9qr+3keBiUgVQrjZzLphMGjZwFqibktXdy1UGrN2SCmqZuo7Kivn/AjnlVB+EaE5GGQ3IZK7Vct6RJzfClktXQaMzB7Jin71i55lQO9Jr373VFHwF/1BKKp+GAdHjzKn4bJrwBBXBXqqUoaq2vGOF//Cbne3d/760R9npMiuA1q9bnmDOc2D73XxnqOd5c7ZA3slCt8v/PD6dYBsHxj5bT39aXPPewP7Ycdzwzc4YHXxjjpMOKYgWJyqmapaFKTezUTn1jaKW1TZ224V2zKVqY+95vk73B1VXbiutc18Bri5X87PWhW+6Zjdmx1/SChdBSHTsOekcwQ6GVlitBp2dmX5CHVcAmDJcWfrz5zF5JAHqQDxPHX/nCXOvw/f4YSp+piz9TFWyfYLdULS8qidZ2UhLZyy6Dl4PMbQhXurf2YPapujw5lFFvJJHM6fYak//NL+NtQIb6g/J+uvR+sGqkOl4zqRyiGLmcOBZRjrMsuiT0unvqeDr2n4DpUsDkT3hUv5sA3m4NjdpROJ70uuqDXBhwAvOui7FTr3KUPSABKJo6U2dNz7inoikUjcB6QpQOKU54orrhjWWbArr7zy/r6cU4p7N/FhInEfUHf+oyj3nTiYpAEkTlre//73j4lIc/rOmXPMwoYQbMKNVpZns5pp6W43gM2cdtppc2vXrq327J78j8BYnuU767yPN732ist711xzTQFw/ZdveKpD0ch0r4jwtKc/7QsA11zz/37M3dWCXQCQRaNemRXF10Sk/Pmf/8833XjjTc3Jyanzq6pq9rrdzTF1vS04gQmiWZYVDl0XmVbVmXXrxnZ15u7eWFWDc91dcc8dwV1Uows6lVW9YKErItse9KDTd3Y7vbOIJffGRGi5y6Qjc8D2N7zhtdPv+73fawrkd+zrXuQw4fXKkYh8TWI+jckrr/yd8i1vfMs5QLOswgU4hYWqjaONNcXNILZu3RmfybLi+8sPIHFqISItohfm+SA/CGxFGIOFNPKz1Mt+dUm5HwU2ERPIdFiMGRmGc/+4xO++Q1xy+3L9/bn1cZ5R/15BXX598Tht4Lz68zH1/sOlPGOx3N0s8F1ivP0MsBW4GMhjQptlNRe03n6WxZT6m4ELgIeCjAPfiPfrU8QS7k1ipz8feCROs87kPAvsdfe9xKXFzcRI1ScjtIGJervP1EVavwhUSQAkTjpe9aq3FYBO3nbHUxD/URUdAykQuUHgLtx/yKow7m4/604ZBvaeRz7ykbtuveU23F3LQflzQD46Onrdzp07e3/xib+4wN0LEZ7oTjvLR/5JRMprr/37pwBalYPnAJWI/i2QuTCOUISq+kURmf2nf/rctJvl4jaHBQuhmgXaInIuuLpTiPgsge0Oc+7MkWdmVo2r6lbV7PHAjOGTisypyIyIqIiomnbMqn1Zlnc3bNjAju/s3OLuP9ooio1Zno0NBoOJEKppohDaOTewMWC0URSPwf28ugoSVVX962BQVmNjY2e/613vLe++a+ZXwdeL6HZE9gI34G79Xv8JQJ7n+74HkgRA4qREgSKE8GgRfgaVvarSEdHvaabbvaoeDmx05wJiqvj/9fjHP776zD9+DmLY9/nAqKi0RCQPIWwGWiBni9DO8mJWs7w7Pz/3M+7ecPeLgJ4g7wAUZQvOabg/z92nq6o6090rwWdwUzPrAq0syzZ5DDZrubPHsJvcvedGL3r9eQuRB6vqWY7vVGRKRXp5lt9FTFzTMAv73bST53l52mmn4e7j7r5VRDaqZmPIoAk+S9SECNEdfVRVtwicPSwRXuFj7jYtwgbA3P3HgE2q8jURuTvg2xEqM3tevF7/YZHvM1fgxKlBq1UokPd7Bwo3byLewt1y1bzRyK0S+Wd3vlJozAI9UoxMAlVzzcg/ufnYgQPdC8Dbg7J6yl/8n0/u7fZ6T3Onmal+GUHdbTvQMwu/AKhoTGuQ50VLwBrN7Gs4Tcx+H5EDqnITTlktRpvelKluVdWtuBcWk9J8DfxPqLNea6atqqrGQlVZCAGEOYTtiN5qajtUNMdRFZ0jl47GGIjS3Ct3t1BVk+CTuFciYplmrfdc/Z6xufLAFvCNIdgc+I4qhHF3L4JbTFdXV+dWVa0zZxeCrGmPnjatIr1ur/M+nLzRKG4WkSQAEicfeZ4poP04uubEkN9CRMizjCxv7ES0WlM0mplqvqa1Zk5E7EET4zvcvXngwIEeMfT9UWb2EAt+juPNPM++KCLVYDA/fflrXt57/euvKtw9H6aQy2IJ7WrdurFJ3FU99ByvXH3S3cvf/K3fGFZO3vmG113ZBWbMvZAYyz/1pre8cWhT4M1vvnq9mY3ZQk4J76JypxGmPNa2zBXNNctmG2sac0Dn6U9/evXaV7/OEDGz0JFAz6GpqoWK5kBLYNxhvVnoAtMhhKa7m9c5Eur2Wqi/WWexyteubXcaRdFrlvIFANW1syKSPAETJyU9oBwZGfk4cGOw8Dhz39wvy5/tl+XTaiMW843i+izL7lpTlrs+/elP97IsmxkMBhRF8Sl3NphVP1aWVRO8iUNRFH+T5VmHOn6j1VrzIXd0vjs/Duhg0HsOwO2Te35FoBopil0iMnf62NhH5aAFszpMPMc9d3NF4LOfvUJBuPjiK01NIUYIRgEgnCnwC7jMVQOfMQ15UM8JbOuV/W8R4xC2xTwOrqL5VJbnU26h5e55lmXjAwnnBbOtZvYQV24C+iHYf3L3Daqai0hrMBhc32g0ulmmfwpMDKpqK04+NXX7eQCZyhQCp43lHxLRZANInHy89rWXVQDvfe8Hbwam7tw79TBzX+/uZwPjw1yAIYRph7wKoSjLUicmJrpPf/rT7W1v+d1/B+4aDAY/D0zg7BWwtWtbO04bG52lDrp55St/+6Zdu27RD33of9/s7jluz3N3dbP1Dr1g9gVguk4Zt6yvDIugLoQID7MX1XHICwJjMbZ7TJCziVOEXm07KHByh3nqPJjDPA4idLMsmwluXXcvRKWJsN7dT/cYrv4tMqbdfc7dx4FckKKz/8D05Ze/cubqt179dWCsHAzOB0bNbAuQ43KziJiZNVXTKkDiJOTP/uzPmiKS33bbZLuqqnaeZ38rkv+Dm405NN3sx4ENIOdh9mNlb/7b276xbQz4JtBd01rzRaB54M4D/8PdW5rrN0Uo+/3+lLvPDYN33njFW7cCWqzJ/xkg9MO/Eacb5zmsGwwGvyzQmb7rrucSi8XcfLjrvu228YV/BwkQcybWxVZlG/AZVb01zxs7RSQHUVXZm2fZdN7I95qZvu61r1dwNXMdVJUK3JGr9iyER8+H+fVuQd0MkWxaJd8ZBY43Y1ZFbKTZmLj66quboR+mgJnmyMjrEWF+fn6r4znGc929mL377sshBQMlTkJqz76iqgbFYDAo1q1bt3vLli2znU6naWb5HVN3jrt7GarwWGCzm683sWE6eTY8ZP1eIL9j6o4SqLJGNqMqve58t/u85z1voQ7kYDAYA1g3HutRPHT0oZOdspPf0b2jrKpqvKqqlzk0ze0s/Mjp3w8cWLLJkrRBdXjzrKh8K8uzHZt/4KHfnJ+vtNczHR1t9x772Ef32u22yUKGJlGrM69mIt1MZS6mV2erR9+CniC9TBpzODZMFFvP+5uAmVkXp/eoRz1yx0Me+pDqn//5n6fcPe/PD34FUDe7ANAkABInHdmaNU2gXQ3s2VbxhP1z3Z3bvvWd6WKk+Ndmc80ed2+6GVU1wMwtb+RdybKFjEazs7MQl8IgZnhS7NAiGnkzewZOPr135iKQcr4drgQ0y1XFNXe3mGRUdZaDyoNJTC5bIBREx5xlfUksdmYVjZkNhY2CXIzzQ7ffdscF7q7upvMHZnqf+ptbe3me37TpYRu3iciImeU4TQ/WGmm3JtefMbHjlltufUYIYYvH+pVd8LlGQ6ddyHFa5m4Eq/K8OEs1s+D9S9yZ2LFj5//63vd2ddasae0WoZo/cLc6aJ5l0yQBkDgZkWiWz4nebOfj3nL3aTP/jrvP1IleMXOLmZupEKm8nm+XZWksjXNZJdGuiGx2PHfnIvCe4xN10tjeYtZ0R1RiyrJDDkAszrGQr3H5l7VarvXI3hKRDSCFO/nQiOhuPVx7ZrY7hJDHWoMyvP88zxvdLVu3zOzatVvdvU30KAShHBnJyvpGFsq4iUg7JrLlfGCDu3/OzO/OVKd0WdpHKdMqQOJkZRboNBr5h7JM/xX0R0Vkc39+/he6nQ6NooGqUhTFNQKziHwe2CMSy7zneW5AlWX513Cmsky3i0jJQRl3iqzxdhy1RkwhNt/tvAigX1fOHRlpXiPCbFE0PsBBeQqzPOsC3xSL9Q8R+feHPexhC9+LSwXMOvI9hy+7e+UhFBLC+kE5GEeidiLQBenmWXZjr9fTLNPvAV9U1d2qeuegLKfWrl07be5fAVpZln850+z2XLK9azprqjzLbnY8zySfUslmi0axvdVu9ea73Ye7+0S/7J8HFJ0DB34S3EaKYgqgGGn+UfIETJyUPOeZz6yA6uqrr94NlGUZfhBHzX2DR21gFijzPLs9z7I9wMyrXvOqhZLzw3V9FZ1DaAqyfyUBcHrztJ3BgpahP+nueRWq8wHqWg+9RqPxeWDmtNPW7eIgDUBVK2AOLDfXCuiuWbNmyRYyTCHXA2aJRWgKc8vxxZiAuELomEhR55/sqcqsiuxXkW6oQu9HfuRHyms++f/miEFGd+R5vje3rNcoGyYqHUFmRbRU0Wptqz1zyQt/tfPmN7/1FkH2V1V1PtA2syZApnqTiFRjY+PbsjxPAiBxUrOHmHV5F/gwI7Oy2BlnictqB5fvHo7WV9f7dAEcX57C3RfyMf4ecU7/P+vthmm+hj4DMyuEGk8C76j/rcSOvlRIdMB31Nd/HUsrGi+fkgzTQM/U9/Ep4HP1fQ1LkxvwMfBrgI4Pg5Ridab/SQwQmmV5ENNf10uN17CQ+n1Z20yuUr44kUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBKJRCKRSCQSiUQikUgkEolEIpFIJBIPcP5//rGzEbrqh5AAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTQtMDEtMjNUMDM6Mjc6MDArMDg6MDDOAI47AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE0LTAxLTIzVDAzOjI3OjAwKzA4OjAwv102hwAAAABJRU5ErkJggg=='
    $iconBytes = [System.Convert]::FromBase64String($base64IconString)
    $iconStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList $iconBytes,0,$iconBytes.Length
    $iconStream.Write($iconBytes,0,$iconBytes.Length)
    $iconHandle = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $iconStream
    $ProgIcon = [System.Drawing.Icon]::FromHandle($iconHandle.GetHicon())
    $IPMatch = '([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]){1}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}'
    $CIDRMatch = "$IPMatch\/([8-9]|1[0-9]|2[0-9]|30)"
    $LoHiMatch = "$IPMatch\-$IPMatch"
    function Find-RemoteIPRange{
        $formFind = New-Object -TypeName System.Windows.Forms.Form
        $labelFind = New-Object -TypeName System.Windows.Forms.Label
        $textBoxFind = New-Object -TypeName System.Windows.Forms.TextBox
        $buttonFindNext = New-Object -TypeName System.Windows.Forms.Button
        $groupBoxDirection = New-Object -TypeName System.Windows.Forms.GroupBox
        $radioButtonUp = New-Object -TypeName System.Windows.Forms.RadioButton
        $radioButtonDown = New-Object -TypeName System.Windows.Forms.RadioButton
        $buttonFindCancel = New-Object -TypeName System.Windows.Forms.Button
        $buttonFindAll = New-Object -TypeName System.Windows.Forms.Button
        $buttonFindNext_Click = {
            if($Global:dataGridView.SelectedRows.Count -eq 0){
                if($radioButtonUp.Checked){$StartIndex = $Global:dataGridView.RowCount - 1}
                if($radioButtonDown.Checked){$StartIndex = 0}
            }
            else{
                $StartIndex = $Global:dataGridView.SelectedRows[0].Index
                if($radioButtonUp.Checked){$StartIndex--}
                if($radioButtonDown.Checked){$StartIndex++}
            }
            $Global:dataGridView.SuspendLayout()
            $Global:dataGridView.ClearSelection()
            $matchFound = $false
            $SearchString = [string]::Join([string]::Empty, @($textBoxFind.Text.ToCharArray() | %{[regex]::Escape($_)}))
            if($radioButtonUp.Checked){
                :RowSearchUp
                for($i = $StartIndex; $i -ge 0; $i--){
                    if([regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[0].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase) -or [regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[1].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)){
                        $Global:dataGridView.CurrentCell = $Global:dataGridView.Rows[$i].Cells[0]
                        $Global:dataGridView.FirstDisplayedScrollingRowIndex = $i
                        $Global:dataGridView.Rows[$i].Selected = $true
                        $matchFound = $true
                        break RowSearchUp
                    }
                }
            }
            if($radioButtonDown.Checked){
                :RowSearchDown
                for($i = $StartIndex; $i -lt $Global:dataGridView.RowCount; $i++){
                    if([regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[0].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase) -or [regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[1].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)){
                        $Global:dataGridView.CurrentCell = $Global:dataGridView.Rows[$i].Cells[0]
                        $Global:dataGridView.FirstDisplayedScrollingRowIndex = $i
                        $Global:dataGridView.Rows[$i].Selected = $true
                        $matchFound = $true
                        break RowSearchDown
                    }
                }
            }
            if(!$matchFound){[void][System.Windows.Forms.MessageBox]::Show($this,[string]::Format('Cannot find "{0}".',$textBoxFind.Text),'Find',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)}
            $Global:dataGridView.PerformLayout()
            $Global:dataGridView.ResumeLayout()
        }
        $textBoxFind_TextChanged = {
            $Global:dataGridView.SuspendLayout()
            $Global:dataGridView.ClearSelection()
            $Global:dataGridView.PerformLayout()
            $Global:dataGridView.ResumeLayout()
            $buttonFindNext.Enabled = $textBoxFind.TextLength -gt 0
            $buttonFindAll.Enabled = $textBoxFind.TextLength -gt 0
        }
        $buttonFindAll_Click = {
            $matchFound = $false
            $Global:dataGridView.SuspendLayout()
            $Global:dataGridView.ClearSelection()
            $SearchString = [string]::Join([string]::Empty, @($textBoxFind.Text.ToCharArray() | %{[regex]::Escape($_)}))
            for($i = 0; $i -lt $Global:dataGridView.RowCount; $i++){
                if([regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[0].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase) -or [regex]::IsMatch($Global:dataGridView.Rows[$i].Cells[1].Value,$SearchString,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)){
                    if(!$matchFound){
                        $Global:dataGridView.CurrentCell = $Global:dataGridView.Rows[$i].Cells[0]
                        $Global:dataGridView.FirstDisplayedScrollingRowIndex = $i
                        $matchFound = $true
                    }
                    $Global:dataGridView.Rows[$i].Selected = $true
                }
            }
            if(!$matchFound){[void][System.Windows.Forms.MessageBox]::Show($this,[string]::Format('Cannot find "{0}".',$textBoxFind.Text),'Find',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)}
            $Global:dataGridView.PerformLayout()
            $Global:dataGridView.ResumeLayout()
            $formFind.Close()
        }
        $formFind.AcceptButton = $buttonFindNext
        $formFind.CancelButton = $buttonFindCancel
        $formFind.ClientSize = New-Object -TypeName System.Drawing.Size (405,76)
        $formFind.Icon = $ProgIcon
        $formFind.MaximizeBox = $false
        $formFind.MaximumSize = New-Object -TypeName System.Drawing.Size (421,114)
        $formFind.MinimizeBox = $false
        $formFind.MinimumSize = New-Object -TypeName System.Drawing.Size (421,114)
        $formFind.ShowInTaskbar = $false
        $formFind.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
        $formFind.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $formFind.Text = 'Find'
        $labelFind.Location = New-Object -TypeName System.Drawing.Point (12,12)
        $labelFind.Size = New-Object -TypeName System.Drawing.Size (61,23)
        $labelFind.TabIndex = 0
        $labelFind.Text = 'Find what:'
        $labelFind.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $formFind.Controls.Add($labelFind)
        $textBoxFind.Location = New-Object -TypeName System.Drawing.Point (79,14)
        $textBoxFind.Size = New-Object -TypeName System.Drawing.Size (243,20)
        $textBoxFind.TabIndex = 1
        $textBoxFind.add_TextChanged($textBoxFind_TextChanged)
        $formFind.Controls.Add($textBoxFind)
        $buttonFindNext.Enabled = $false
        $buttonFindNext.Location = New-Object -TypeName System.Drawing.Point (328,12)
        $buttonFindNext.Size = New-Object -TypeName System.Drawing.Size (65,23)
        $buttonFindNext.TabIndex = 2
        $buttonFindNext.Text = 'Find Next'
        $buttonFindNext.UseVisualStyleBackColor = $true
        $buttonFindNext.add_Click($buttonFindNext_Click)
        $formFind.Controls.Add($buttonFindNext)
        $groupBoxDirection.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
        $groupBoxDirection.Location = New-Object -TypeName System.Drawing.Point (79,36)
        $groupBoxDirection.Size = New-Object -TypeName System.Drawing.Size (172,28)
        $groupBoxDirection.TabIndex = 4
        $groupBoxDirection.TabStop = $false
        $groupBoxDirection.Text = 'Direction'
        $formFind.Controls.Add($groupBoxDirection)
        $radioButtonUp.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
        $radioButtonUp.Location = New-Object -TypeName System.Drawing.Point (59,8)
        $radioButtonUp.Size = New-Object -TypeName System.Drawing.Size (39,17)
        $radioButtonUp.TabIndex = 0
        $radioButtonUp.Text = 'Up'
        $radioButtonUp.UseVisualStyleBackColor = $false
        $groupBoxDirection.Controls.Add($radioButtonUp)
        $radioButtonDown.BackColor = [System.Drawing.Color]::FromArgb(0,255,255,255)
        $radioButtonDown.Checked = $true
        $radioButtonDown.Location = New-Object -TypeName System.Drawing.Point (104,8)
        $radioButtonDown.Size = New-Object -TypeName System.Drawing.Size (53,17)
        $radioButtonDown.TabIndex = 1
        $radioButtonDown.TabStop = $true
        $radioButtonDown.Text = 'Down'
        $radioButtonDown.UseVisualStyleBackColor = $false
        $groupBoxDirection.Controls.Add($radioButtonDown)
        $buttonFindCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $buttonFindCancel.Location = New-Object -TypeName System.Drawing.Point (257,41)
        $buttonFindCancel.Size = New-Object -TypeName System.Drawing.Size (65,23)
        $buttonFindCancel.TabIndex = 5
        $buttonFindCancel.Text = 'Cancel'
        $buttonFindCancel.UseVisualStyleBackColor = $true
        $buttonFindCancel.add_Click($buttonFindCancel_OnClick)
        $formFind.Controls.Add($buttonFindCancel)
        $buttonFindAll.Enabled = $false
        $buttonFindAll.Location = New-Object -TypeName System.Drawing.Point (328,41)
        $buttonFindAll.Size = New-Object -TypeName System.Drawing.Size (65,23)
        $buttonFindAll.TabIndex = 3
        $buttonFindAll.Text = 'Find All'
        $buttonFindAll.UseVisualStyleBackColor = $true
        $buttonFindAll.add_Click($buttonFindAll_Click)
        $formFind.Controls.Add($buttonFindAll)
        [void]$formFind.ShowDialog()
    }
    function Get-CsvImport{
        param([string]$CsvFile,[string[]]$MandatoryHeaders)
        $CsvFileImport = $null
        $Delimiter = (Import-Csv -Path $CsvFile -WarningAction SilentlyContinue | Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue).Name
        if(@($MandatoryHeaders | %{[regex]::IsMatch($Delimiter,"\b$_\b",[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)}) -notcontains $false){
            if($Delimiter.Count -eq 1){
                if([regex]::IsMatch($Delimiter,'\t')){$CsvFileImport = Import-Csv -Delimiter `t -Path $CsvFile}
                elseif([regex]::IsMatch($Delimiter,'\,')){$CsvFileImport = Import-Csv -Delimiter ',' -Path $CsvFile}
                elseif([regex]::IsMatch($Delimiter,'\;')){$CsvFileImport = Import-Csv -Delimiter ';' -Path $CsvFile}
                elseif([regex]::IsMatch($Delimiter,'\|')){$CsvFileImport = Import-Csv -Delimiter '|' -Path $CsvFile}
                elseif([regex]::IsMatch($Delimiter,'\~')){$CsvFileImport = Import-Csv -Delimiter '~' -Path $CsvFile}
                else{$CsvFileImport = Import-Csv -Path $CsvFile}
            }
            else{$CsvFileImport = Import-Csv -Path $CsvFile}
        }
        else{[void][System.Windows.Forms.MessageBox]::Show($this,[string]::Format("Mandatory Header(s) missing.`r`n`r`n{0}",[string]::Join('; ',$MandatoryHeaders)),'Missing Headers',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)}
        return $CsvFileImport
    }
    function Get-FileName{
        param([string]$Start,[string]$Filter = 'Import Files|*.csv;*.txt|CSV Files (*.csv)|*.csv|TXT Files (*.txt)|*.txt')
        $OpenFileDialog = New-Object -TypeName System.Windows.Forms.OpenFileDialog
        if($Start.Length -gt 0){$OpenFileDialog.InitialDirectory = $Start}
        $OpenFileDialog.Filter = $Filter
        $OpenFileDialog.Multiselect = $false
        $OpenFileDialog.Title = 'Select file to import'
        switch($OpenFileDialog.ShowDialog()){
            'OK'{return $OpenFileDialog.FileName}
            default{return $null}
        }
    }
    function Get-RemoteIPRange{
        begin{$Script:RemoteIPRange = @()}
        process{
            $formAdd = New-Object -TypeName System.Windows.Forms.Form
            $buttonAddRemoteIPRange = New-Object -TypeName System.Windows.Forms.Button
            $textBoxAddRemoveIPRange = New-Object -TypeName System.Windows.Forms.TextBox
            $labelAddInfo = New-Object -TypeName System.Windows.Forms.Label
            $buttonAddRemoteIPRange_Click = {
                $Script:RemoteIPRange = @($textBoxAddRemoveIPRange.Text.Split(';,') | %{$_.Trim()} | ?{$_})
                $formAdd.Close()
            }
            $textBoxAddRemoveIPRange_TextChanged = {
                $buttonAddRemoteIPRange.Enabled = $textBoxAddRemoveIPRange.TextLength -gt 0 -and @($textBoxAddRemoveIPRange.Text.Split(';,') | %{[regex]::IsMatch($_.Trim(),"^($IPMatch|$CIDRMatch|$LoHiMatch)$")}) -notcontains $false
            }
            $formAdd.AcceptButton = $buttonAddRemoteIPRange
            $formAdd.ClientSize = New-Object -TypeName System.Drawing.Size (306,101)
            $formAdd.Icon = $ProgIcon
            $formAdd.MaximizeBox = $false
            $formAdd.MaximumSize = New-Object -TypeName System.Drawing.Size (322,139)
            $formAdd.MinimizeBox = $false
            $formAdd.MinimumSize = New-Object -TypeName System.Drawing.Size (322,139)
            $formAdd.ShowInTaskbar = $false
            $formAdd.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
            $formAdd.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
            $formAdd.Text = 'Add'
            $labelAddInfo.Dock = [System.Windows.Forms.DockStyle]::Top
            $labelAddInfo.Location = New-Object -TypeName System.Drawing.Point (0,0)
            $labelAddInfo.Size = New-Object -TypeName System.Drawing.Size (306,73)
            $labelAddInfo.TabIndex = 0
            $labelAddInfo.Text = "Enter one, or multiple comma delimited, RemoteIPRanges which match one of the following formats:`r`nCIDR: 10.200.0.0/24`r`nLoHi: 10.200.0.1-10.200.0.9`r`nSingleAddress: 10.200.0.10"
            $labelAddInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $formAdd.Controls.Add($labelAddInfo)
            $textBoxAddRemoveIPRange.Location = New-Object -TypeName System.Drawing.Point (4,76)
            $textBoxAddRemoveIPRange.Size = New-Object -TypeName System.Drawing.Size (260,20)
            $textBoxAddRemoveIPRange.TabIndex = 1
            $textBoxAddRemoveIPRange.add_TextChanged($textBoxAddRemoveIPRange_TextChanged)
            $formAdd.Controls.Add($textBoxAddRemoveIPRange)
            $buttonAddRemoteIPRange.Enabled = $false
            $buttonAddRemoteIPRange.Location = New-Object -TypeName System.Drawing.Point (267,74)
            $buttonAddRemoteIPRange.Size = New-Object -TypeName System.Drawing.Size (35,23)
            $buttonAddRemoteIPRange.TabIndex = 2
            $buttonAddRemoteIPRange.Text = 'Add'
            $buttonAddRemoteIPRange.UseVisualStyleBackColor = $true
            $buttonAddRemoteIPRange.add_Click($buttonAddRemoteIPRange_Click)
            $formAdd.Controls.Add($buttonAddRemoteIPRange)
            [void]$formAdd.ShowDialog()
            return $Script:RemoteIPRange
        }
        end{Remove-Variable -Name RemoteIPRange -Force -ErrorAction SilentlyContinue}
    }
    function Save-FileDialog{
	    param([string]$Start,[string]$Filter = 'CSV Files (*.csv)|*.csv')
	    $SaveFileDialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
	    if($Start.Length -gt 0){$SaveFileDialog.InitialDirectory = $Start}
	    $SaveFileDialog.Filter = $Filter
	    $SaveFileDialog.Title = 'Enter name to save file as'
        $SaveFileDialog.CreatePrompt = $false
        $SaveFileDialog.OverwritePrompt = $true
        if($PSVersionTable.PSVersion.Major -le 2){$SaveFileDialog.ShowHelp = $true}
        if($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
            if(Test-Path -LiteralPath $SaveFileDialog.FileName){Remove-Item -LiteralPath $SaveFileDialog.FileName -Force}
            return $SaveFileDialog.FileName
        }
        else{return $null}
    }
    function Show-DSRCUpdateProgressBar{
        param([ValidateSet('Hide','Show','Update')][string]$State,[int]$Value)
        switch($State){
            'Hide'{
                $Global:buttonImport.Enabled = $Global:ControlState.Import
                $Global:buttonExport.Enabled = $Global:ControlState.Export
                $Global:buttonAdd.Enabled = $Global:ControlState.Add
                $Global:buttonRemove.Enabled = $Global:dataGridView.SelectedRows.Count -gt 0
                $Global:buttonRefresh.Enabled = $Global:ControlState.Refresh
                $Global:buttonSave.Enabled = $Global:ControlState.Save
                $Global:dataGridView.Enabled = $Global:ControlState.DataGrid
                $Global:formDSRC.Text = 'Digital Sender Receive Connectors'
                $Global:formDSRC.ControlBox = $true
                $Global:progressBar.Value = 0
                $Global:progressBar.Visible = $false
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
            }
            'Show'{
                $Global:ControlState.Import = $Global:buttonImport.Enabled
                $Global:ControlState.Export = $Global:buttonExport.Enabled
                $Global:ControlState.Add = $Global:buttonAdd.Enabled
                $Global:ControlState.Refresh = $Global:buttonRefresh.Enabled
                $Global:ControlState.Save = $Global:buttonSave.Enabled
                $Global:ControlState.DataGrid = $Global:dataGridView.Enabled
                $Global:buttonExport.Enabled = $false
                $Global:buttonImport.Enabled = $false
                $Global:buttonAdd.Enabled = $false
                $Global:buttonRemove.Enabled = $false
                $Global:buttonRefresh.Enabled = $false
                $Global:buttonSave.Enabled = $false
                $Global:dataGridView.Enabled = $false
                $Global:formDSRC.Text = '0 % | Digital Sender Receive Connectors'
                $Global:formDSRC.ControlBox = $false
                $Global:progressBar.Value = 0
                $Global:progressBar.Visible = $true
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::AppStarting
            }
            'Update'{
                $Global:progressBar.Value = $Value
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::AppStarting
                $Global:formDSRC.Text = [string]::Format('{0:P0} | Digital Sender Receive Connectors',$($Value/100))
            }
        }
                $Global:progressBar.Width = $statusStrip.Width - $Global:progressBar.Margin.Size.Width - $statusStrip.GripMargin.Size.Width - $statusStrip.SizeGripBounds.Width - $toolStripStatusLabelTotal.Width - $toolStripStatusLabelSelected.Width - $toolStripStatusLabelAdd.Width - $toolStripStatusLabelRemove.Width
        [System.Windows.Forms.Application]::DoEvents()
    }
    function Show-ExchangeInConnector{
        $formRemoveExchange = New-Object -TypeName System.Windows.Forms.Form
        $panelRemoveExchangeInfo = New-Object -TypeName System.Windows.Forms.Panel
        $pictureBoxRemoveExchange = New-Object -TypeName System.Windows.Forms.PictureBox
        $labelRemoveExchange = New-Object -TypeName System.Windows.Forms.Label
        $dataGridViewRemoveExchange = New-Object -TypeName System.Windows.Forms.DataGridView
        $panelRemoveExchangeButtons = New-Object -TypeName System.Windows.Forms.Panel
        $buttonOKRemoteExchange = New-Object -TypeName System.Windows.Forms.Button
        $formRemoveExchange_Shown = {
            $dataGridViewRemoveExchange.SuspendLayout()
            foreach($RExchSrv in @($Global:ContainedExchangeIPs | Sort-Object -Property Name)){
                $dataGridViewRemoveExchange.Rows.Add($RExchSrv.Name,$RExchSrv.IPAddress)
            }
            $dataGridViewRemoveExchange.PerformLayout()
            $dataGridViewRemoveExchange.ResumeLayout()
            $buttonOKRemoteExchange.Focus()
        }
        $formRemoveExchange.AcceptButton = $buttonOKRemoteExchange
        $formRemoveExchange.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
        $formRemoveExchange.ClientSize = New-Object -TypeName System.Drawing.Size (384,162)
        $formRemoveExchange.Icon = $ProgIcon
        $formRemoveExchange.MaximizeBox = $false
        $formRemoveExchange.MaximumSize = New-Object -TypeName System.Drawing.Size (400,[int]::MaxValue)
        $formRemoveExchange.MinimizeBox = $false
        $formRemoveExchange.MinimumSize = New-Object -TypeName System.Drawing.Size (400,200)
        $formRemoveExchange.ShowInTaskbar = $false
        $formRemoveExchange.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
        $formRemoveExchange.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $formRemoveExchange.Text = 'Remove'
        $Column_ExchangeName = New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn
        $Column_ExchangeName.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::AllCells
        $Column_ExchangeName.HeaderText = 'Name'
        $Column_ExchangeName.ReadOnly = $true
        $Column_ExchangeName.Width = 60
        [void]$dataGridViewRemoveExchange.Columns.Add($Column_ExchangeName)
        $Column_ExchangeIPAddress = New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn
        $Column_ExchangeIPAddress.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::Fill
        $Column_ExchangeIPAddress.HeaderText = 'IPAddress'
        $Column_ExchangeIPAddress.ReadOnly = $true
        $Column_ExchangeIPAddress.Width = 321
        [void]$dataGridViewRemoveExchange.Columns.Add($Column_ExchangeIPAddress)
        $dataGridViewRemoveExchange.AllowUserToAddRows = $false
        $dataGridViewRemoveExchange.AllowUserToDeleteRows = $false
        $dataGridViewRemoveExchange.AllowUserToResizeColumns = $false
        $dataGridViewRemoveExchange.AllowUserToResizeRows = $false
        $dataGridViewRemoveExchange.BackgroundColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
        $dataGridViewRemoveExchange.ClipboardCopyMode = [System.Windows.Forms.DataGridViewClipboardCopyMode]::Disable
        $dataGridViewRemoveExchange.ColumnHeadersHeightSizeMode = [System.Windows.Forms.dataGridViewColumnHeadersHeightSizeMode]::DisableResizing
        $dataGridViewRemoveExchange.Dock = [System.Windows.Forms.DockStyle]::Fill
        $dataGridViewRemoveExchange.Location = New-Object -TypeName System.Drawing.Point (0,60)
        $dataGridViewRemoveExchange.ReadOnly = $true
        $dataGridViewRemoveExchange.RowHeadersVisible = $false
        $dataGridViewRemoveExchange.RowHeadersWidthSizeMode = [System.Windows.Forms.dataGridViewRowHeadersWidthSizeMode]::DisableResizing
        $dataGridViewRemoveExchange.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
        $dataGridViewRemoveExchange.Size = New-Object -TypeName System.Drawing.Size (384,57)
        $dataGridViewRemoveExchange.StandardTab = $true
        $dataGridViewRemoveExchange.TabIndex = 1
        $formRemoveExchange.Controls.Add($dataGridViewRemoveExchange)
        $panelRemoveExchangeInfo.Dock = [System.Windows.Forms.DockStyle]::Top
        $panelRemoveExchangeInfo.Location = New-Object -TypeName System.Drawing.Point (0,0)
        $panelRemoveExchangeInfo.Size = New-Object -TypeName System.Drawing.Size (384,60)
        $panelRemoveExchangeInfo.TabIndex = 0
        $formRemoveExchange.Controls.Add($panelRemoveExchangeInfo)
        $pictureBoxRemoveExchange.Image = [System.Drawing.SystemIcons]::Information
        $pictureBoxRemoveExchange.Location = New-Object -TypeName System.Drawing.Point (12,12)
        $pictureBoxRemoveExchange.Size = New-Object -TypeName System.Drawing.Size (42,42)
        $pictureBoxRemoveExchange.TabIndex = 0
        $pictureBoxRemoveExchange.TabStop = $false
        $panelRemoveExchangeInfo.Controls.Add($pictureBoxRemoveExchange)
        $labelRemoveExchange.Location = New-Object -TypeName System.Drawing.Point (60,12)
        $labelRemoveExchange.Size = New-Object -TypeName System.Drawing.Size (321,42)
        $labelRemoveExchange.TabIndex = 1
        $labelRemoveExchange.Text = 'The following exchange IPAddress(es) are in the receive connectors and removed from the data grid but you must save the form to remove them.'
        $labelRemoveExchange.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $panelRemoveExchangeInfo.Controls.Add($labelRemoveExchange)
        $panelRemoveExchangeButtons.BackColor = [System.Drawing.Color]::FromArgb(255,240,240,240)
        $panelRemoveExchangeButtons.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $panelRemoveExchangeButtons.Location = New-Object -TypeName System.Drawing.Point (0,117)
        $panelRemoveExchangeButtons.Size = New-Object -TypeName System.Drawing.Size (384,45)
        $panelRemoveExchangeButtons.TabIndex = 2
        $formRemoveExchange.Controls.Add($panelRemoveExchangeButtons)
        $buttonOKRemoteExchange.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $buttonOKRemoteExchange.Location = New-Object -TypeName System.Drawing.Point (297,10)
        $buttonOKRemoteExchange.Size = New-Object -TypeName System.Drawing.Size (75,23)
        $buttonOKRemoteExchange.TabIndex = 0
        $buttonOKRemoteExchange.Text = 'OK'
        $buttonOKRemoteExchange.UseVisualStyleBackColor = $true
        $panelRemoveExchangeButtons.Controls.Add($buttonOKRemoteExchange)
        $formRemoveExchange.add_Shown($formRemoveExchange_Shown)
        $formRemoveExchange.ShowDialog()
    }
    function Start-DSRCUpdate{
        $Global:ControlState = New-Object -TypeName psobject | Select-Object -Property Import,Export,Add,Refresh,Save,DataGrid
        $Global:formDSRC = New-Object -TypeName System.Windows.Forms.Form
        $groupBox = New-Object -TypeName System.Windows.Forms.GroupBox
        $labelInfo = New-Object -TypeName System.Windows.Forms.Label
        $Global:buttonImport = New-Object -TypeName System.Windows.Forms.Button
        $Global:buttonExport = New-Object -TypeName System.Windows.Forms.Button
        $Global:buttonAdd = New-Object -TypeName System.Windows.Forms.Button
        $Global:buttonRemove = New-Object -TypeName System.Windows.Forms.Button
        $Global:buttonRefresh = New-Object -TypeName System.Windows.Forms.Button
        $Global:buttonSave = New-Object -TypeName System.Windows.Forms.Button
        $Global:dataGridView = New-Object -TypeName System.Windows.Forms.dataGridView
        $Column_RangeFormat = New-Object -TypeName System.Windows.Forms.dataGridViewTextBoxColumn
        $Column_IPRange = New-Object -TypeName System.Windows.Forms.dataGridViewTextBoxColumn
        $statusStrip = New-Object -TypeName System.Windows.Forms.StatusStrip
        $toolStripStatusLabelTotal = New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel
        $toolStripStatusLabelSelected = New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel
        $toolStripStatusLabelAdd = New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel
        $toolStripStatusLabelRemove = New-Object -TypeName System.Windows.Forms.ToolStripStatusLabel
        $Global:progressBar = New-Object -TypeName System.Windows.Forms.ToolStripProgressBar
        $background_Refresh_Work = {
            $Global:formDSRC.TopMost = $true
            $Global:formDSRC.TopMost = $false
            $Global:dataGridView.Rows.Clear()
            $toolStripStatusLabelTotal.Text = [string]::Format('Total: {0}', $Global:dataGridView.RowCount)
            Show-DSRCUpdateProgressBar -State Show
            $backgroundRefreshJob = Start-Job -Name backgroundRefreshJob -InitializationScript {Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010} -ScriptBlock {
                $backgroundRefreshJob_Result = New-Object -TypeName psobject | Select-Object -Property ExchangeServers,ReceiveConnectors,TransportServers,RemoteIPRanges
                Write-Progress -Activity Progress -Status $(0/5*100) -PercentComplete $(0/5*100)
                $backgroundRefreshJob_Result.ExchangeServers = @(Get-ExchangeServer | Select-Object -ExpandProperty fqdn | ?{$_.EndsWith([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name)} | Sort-Object | Select-Object -Property @{n='Name';e={$_}},@{n='IPAddress';e={try{[System.Net.Dns]::GetHostAddresses($_) | ?{$_.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork} | Select-Object -ExpandProperty IPAddressToString}catch{$null}}} | ?{$_})
                if($backgroundRefreshJob_Result.ExchangeServers.Count -gt 0){
                    Write-Progress -Activity Progress -Status $(1/5*100) -PercentComplete $(1/5*100)
                    $backgroundRefreshJob_Result.TransportServers = @($backgroundRefreshJob_Result.ExchangeServers | %{Get-TransportServer -Identity $_.Name -ErrorAction SilentlyContinue} | ?{$_})
                    Write-Progress -Activity Progress -Status $(2/5*100) -PercentComplete $(2/5*100)
                    $backgroundRefreshJob_Result.ReceiveConnectors = @($backgroundRefreshJob_Result.TransportServers | %{Get-ReceiveConnector -Server $_.Name | ?{$_.Name -match '(AFGHAN|AFGN) Digital Senders'}})
                    if($backgroundRefreshJob_Result.ReceiveConnectors.Count -gt 0){
                        Write-Progress -Activity Progress -Status $(3/5*100) -PercentComplete $(3/5*100)
                        $backgroundRefreshJob_Result.RemoteIPRanges = @($backgroundRefreshJob_Result.ReceiveConnectors | Select-Object -ExpandProperty RemoteIPRanges | Sort-Object -Unique | ?{$_})
                        Write-Progress -Activity Progress -Status $(4/5*100) -PercentComplete $(4/5*100)
                    }
                }
                Write-Output -InputObject $backgroundRefreshJob_Result
            }
            while($backgroundRefreshJob.ChildJobs[0].State -ne 'Completed'){
                $percentComplete = $backgroundRefreshJob.ChildJobs[0].Progress.PercentComplete
                if($percentComplete.Count -gt 0){
                    $percentComplete = $percentComplete[$percentComplete.Count - 1]
                    if($percentComplete -gt 0){
                        Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                    }
                    else{[System.Windows.Forms.Application]::DoEvents()}
                }
            }
            $Global:RemoteIPRangeAdd = @()
            $Global:RemoteIPRangeRemove = @()
            $Global:RemoteIPRangeCurrent = @()
            $Global:ContainedExchangeIPs = @()
            $Global:ATransportSrvrs = $backgroundRefreshJob.ChildJobs[0].Output.TransportServers
            $Global:CRemoteIPRanges = $backgroundRefreshJob.ChildJobs[0].Output.RemoteIPRanges
            $Global:DSRcvConnectors = $backgroundRefreshJob.ChildJobs[0].Output.ReceiveConnectors
            $Global:ExchangeServers = $backgroundRefreshJob.ChildJobs[0].Output.ExchangeServers
            Remove-Job -Name backgroundRefreshJob -Force
            if($Global:ExchangeServers.Count -gt 0){
                $Loop2 = 0,$Global:CRemoteIPRanges.Count
                $Global:dataGridView.SuspendLayout()
                for($i = 0; $i -lt $Global:CRemoteIPRanges.Count; $i++){
                    $percentComplete = $($(4 / 5) + $($($i / $Global:CRemoteIPRanges.Count) / 5)) * 100
                    Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                    switch($Global:CRemoteIPRanges[$i].RangeFormat){
                        'SingleAddress'{
                            if($Global:ExchangeServers.IPAddress -contains $Global:CRemoteIPRanges[$i].LowerBound.ToString()){
                                $Global:ContainedExchangeIPs += $Global:ExchangeServers | ?{$_.IPAddress -eq $Global:CRemoteIPRanges[$i].LowerBound.ToString()}
                            }
                            else{
                                $Global:dataGridView.Rows.Add($Global:CRemoteIPRanges[$i].RangeFormat,$Global:CRemoteIPRanges[$i].LowerBound.ToString())
                                $Global:RemoteIPRangeCurrent += $Global:CRemoteIPRanges[$i].LowerBound.ToString()
                            }
                        }
                        'LoHi'{
                            $Global:dataGridView.Rows.Add($Global:CRemoteIPRanges[$i].RangeFormat,[string]::Format('{0}-{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].UpperBound.ToString()))
                            $Global:RemoteIPRangeCurrent += [string]::Format('{0}-{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].UpperBound.ToString())
                        }
                        'CIDR'{
                            $Global:dataGridView.Rows.Add($Global:CRemoteIPRanges[$i].RangeFormat,[string]::Format('{0}/{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].CIDRLength))
                            $Global:RemoteIPRangeCurrent += [string]::Format('{0}/{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].CIDRLength)
                        }
                    }
                }
                $Global:dataGridView.PerformLayout()
                $Global:dataGridView.ResumeLayout()
            }
            else{Show-DSRCUpdateProgressBar -State Update -Value 100}
            if($Global:ContainedExchangeIPs.Count -gt 0){
                Show-ExchangeInConnector | Out-Null
            }
            Show-DSRCUpdateProgressBar -State Hide
            $toolStripStatusLabelTotal.Text = [string]::Format('Total: {0}', $Global:RemoteIPRangeCurrent.Count)
            $Global:dataGridView.Focus()
        }
        $formDSRC_KeyDown = {
            $sender = [System.Windows.Forms.Form]$this
            $eventArgs = [System.Windows.Forms.KeyEventArgs]$_
            if($Global:dataGridView.RowCount -gt 0 -and $eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::F -and $eventArgs.Control){
                Find-RemoteIPRange
            }
        }
        $buttonImport_Click = {
            Show-DSRCUpdateProgressBar -State Show
            if($InFile = Get-FileName){
                if($InData = Get-CsvImport -CsvFile $InFile -MandatoryHeaders 'IPRange'){
                    $RemoteIPRanges = @($InData | %{$_.IPRange} | ?{$_})
                    if($RemoteIPRanges.Count -gt 0){
                        $Global:dataGridView.SuspendLayout()
                        for($i = 0; $i -lt $RemoteIPRanges.Count; $i++){
                            $percentComplete = $($i / $RemoteIPRanges.Count) * 100
                            Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                            if($Global:ExchangeServers.IPAddress -contains $RemoteIPRanges[$i]){
                                $Global:ExchangeServers | ?{$_.IPAddress -eq $RemoteIPRanges[$i]} | Select-Object -First 1 | %{
                                    [void][System.Windows.Forms.MessageBox]::Show($this,[string]::Format("This entry is associated with an exchange server. Skipping entry.`r`n`r`n{0} [{1}]", $_.Name, $_.IPAddress), 'Exchange IPAddress Entry', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                                }
                            }
                            elseif($Global:RemoteIPRangeRemove -contains $RemoteIPRanges[$i]){
                                $Global:RemoteIPRangeRemove = @($Global:RemoteIPRangeRemove | ?{$_ -ne $RemoteIPRanges[$i]})
                                switch($RemoteIPRanges[$i]){
                                    {[regex]::IsMatch($_,"^$IPMatch$")}{$Global:dataGridView.Rows.Add('SingleAddress',$_)}
                                    {[regex]::IsMatch($_,"^$LoHiMatch$")}{$Global:dataGridView.Rows.Add('LoHi',$_)}
                                    {[regex]::IsMatch($_,"^$CIDRMatch$")}{$Global:dataGridView.Rows.Add('CIDR',$_)}
                                }
                            }
                            elseif($Global:RemoteIPRangeCurrent -notcontains $RemoteIPRanges[$i]){
                                $Global:RemoteIPRangeAdd += $RemoteIPRanges[$i]
                                switch($RemoteIPRanges[$i]){
                                    {[regex]::IsMatch($_,"^$IPMatch$")}{$Global:dataGridView.Rows.Add('SingleAddress',$_)}
                                    {[regex]::IsMatch($_,"^$LoHiMatch$")}{$Global:dataGridView.Rows.Add('LoHi',$_)}
                                    {[regex]::IsMatch($_,"^$CIDRMatch$")}{$Global:dataGridView.Rows.Add('CIDR',$_)}
                                }
                            }
                        }
                        $Global:dataGridView.PerformLayout()
                        $Global:dataGridView.ResumeLayout()
                    }
                    Remove-Variable -Name InData,RemoteIPRanges
                }
                Remove-Variable -Name InFile -Force -ErrorAction SilentlyContinue
            }
            Show-DSRCUpdateProgressBar -State Hide
        }
        $buttonExport_OnClick = {
            if($OutFile = Save-FileDialog){
                Show-DSRCUpdateProgressBar -State Show
                $exportData = @()
                for($i = 0; $i -lt $Global:dataGridView.RowCount; $i++){
                    $percentComplete = $($i / $Global:dataGridView.RowCount) * 100
                    Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                    $exportData += New-Object -TypeName psobject | Select-Object -Property @{n='RangeFormat';e={$Global:dataGridView.Rows[$i].Cells[0].Value}},@{n='IPRange';e={$Global:dataGridView.Rows[$i].Cells[1].Value}}
                }
                $exportData | ConvertTo-Csv -Delimiter `t -NoTypeInformation | Out-File -LiteralPath $OutFile
                Invoke-Item -LiteralPath $OutFile
                Remove-Variable -Name exportData,OutFile -Force -ErrorAction SilentlyContinue
                Show-DSRCUpdateProgressBar -State Hide
            }
        }
        $buttonAdd_Click = {
            $RemoteIPRanges = @(Get-RemoteIPRange | ?{$_})
            if($RemoteIPRanges.Count -gt 0){
                Show-DSRCUpdateProgressBar -State Show
                $Global:dataGridView.SuspendLayout()
                for($i = 0; $i -lt $RemoteIPRanges.Count; $i++){
                    $percentComplete = $($i / $RemoteIPRanges.Count) * 100
                    Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                    if($Global:ExchangeServers.IPAddress -contains $RemoteIPRanges[$i]){
                        $Global:ExchangeServers | ?{$_.IPAddress -eq $RemoteIPRanges[$i]} | Select-Object -First 1 | %{
                            [void][System.Windows.Forms.MessageBox]::Show($this,[string]::Format("This entry is associated with an exchange server. Skipping entry.`r`n`r`n{0} [{1}]", $_.Name, $_.IPAddress), 'Exchange IPAddress Entry', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                        }
                    }
                    elseif($Global:RemoteIPRangeRemove -contains $RemoteIPRanges[$i]){
                        $Global:RemoteIPRangeRemove = @($Global:RemoteIPRangeRemove | ?{$_ -ne $RemoteIPRanges[$i]})
                        switch($RemoteIPRanges[$i]){
                            {[regex]::IsMatch($_,"^$IPMatch$")}{$Global:dataGridView.Rows.Add('SingleAddress',$_)}
                            {[regex]::IsMatch($_,"^$LoHiMatch$")}{$Global:dataGridView.Rows.Add('LoHi',$_)}
                            {[regex]::IsMatch($_,"^$CIDRMatch$")}{$Global:dataGridView.Rows.Add('CIDR',$_)}
                        }
                    }
                    elseif($Global:RemoteIPRangeCurrent -notcontains $RemoteIPRanges[$i]){
                        $Global:RemoteIPRangeAdd += $RemoteIPRanges[$i]
                        switch($RemoteIPRanges[$i]){
                            {[regex]::IsMatch($_,"^$IPMatch$")}{$Global:dataGridView.Rows.Add('SingleAddress',$_)}
                            {[regex]::IsMatch($_,"^$LoHiMatch$")}{$Global:dataGridView.Rows.Add('LoHi',$_)}
                            {[regex]::IsMatch($_,"^$CIDRMatch$")}{$Global:dataGridView.Rows.Add('CIDR',$_)}
                        }
                    }
                }
                $Global:dataGridView.PerformLayout()
                $Global:dataGridView.ResumeLayout()
                Show-DSRCUpdateProgressBar -State Hide
            }
        }
        $buttonRemove_Click = {
            $Global:RemoveInProcess = $true
            Show-DSRCUpdateProgressBar -State Show
            $RemoveRemoteRanges = @()
            foreach($IPRange in $Global:dataGridView.SelectedRows){
                $RemoveRemoteRanges += $IPRange.Cells[1].Value
            }
            if($(Verify-RemoveRemoteIPRange -RemoteRanges $RemoveRemoteRanges) -eq [System.Windows.Forms.DialogResult]::Yes){
                $Loop1 = 0,$Global:dataGridView.SelectedRows.Count
                foreach($IPRange in $Global:dataGridView.SelectedRows){
                    $percentComplete = $($Loop1[0]++ / $Loop1[1]) * 100
                    Show-DSRCUpdateProgressBar -State Update -Value $percentComplete
                    if($Global:RemoteIPRangeAdd -contains $IPRange.Cells[1].Value){
                        $Global:RemoteIPRangeAdd = @($Global:RemoteIPRangeAdd | ?{$_ -ne $IPRange.Cells[1].Value})
                    }
                    else{$Global:RemoteIPRangeRemove += $IPRange.Cells[1].Value}
                    $Global:dataGridView.Rows.Remove($IPRange)
                    $Global:dataGridView.PerformLayout()
                }
            }
            Show-DSRCUpdateProgressBar -State Hide
            $Global:RemoveInProcess = $false
        }
        $buttonSave_Click = {
            Show-DSRCUpdateProgressBar -State Show
            $ScriptBlock = {
                param([string]$Server,[string[]]$RemoteIPRanges)
                Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010
                $Iterations = [int][System.Convert]::ToString($RemoteIPRanges.Count/1000).Split('.')[0]
                $null = Get-ReceiveConnector -Server $Server | ?{$_.Name -match '(AFGHAN|AFGN) Digital Senders'} | Remove-ReceiveConnector -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                Start-Sleep -Milliseconds 500
                $BaseConnectorName = [string]::Format('{0} Digital Senders',[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name.ToUpper().Split('.')[0])
                for($i=0; $i -le $Iterations; $i++){
                    $ConnectorNumber = $i + 1
                    $ConnectorName = [string]::Format('{0} {1}',$BaseConnectorName,$ConnectorNumber)
                    $NumberToSkip = [int][string]::Format('{0}000',$i)
                    if($i -eq 0){$SetIPRange = @($RemoteIPRanges | Select-Object -First 1000)}
                    else{$SetIPRange = @($RemoteIPRanges | Select-Object -First 1000 -Skip $NumberToSkip)}
                    $null = New-ReceiveConnector -Name $ConnectorName -RemoteIPRanges $SetIPRange -Server $Server -Usage Custom -Bindings 0.0.0.0:25 -PermissionGroups ExchangeServers -AuthMechanism ExternalAuthoritative,Tls -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    Start-Sleep -Milliseconds 500
                }
                Start-Sleep -Seconds 1
                $ReceiveConnectors = @(Get-ReceiveConnector -Server $Server | ?{$_.Name -match '(AFGHAN|AFGN) Digital Senders'})
                return New-Object -TypeName psobject -Property @{ReceiveConnector = $ReceiveConnectors}
            }
            $SetRemoteIPRanges = @($Global:dataGridView.Rows | %{$_.Cells[1].Value} | Sort-Object {[regex]::Replace($_,'\d+',{$args[0].Value.PadLeft(3,'0')})} -Unique)
            $Jobs = @()
            $MinimumThreads = 1
            $MaximumThreads = 20
            $RunspacePool = [runspacefactory]::CreateRunspacePool($MinimumThreads, $MaximumThreads)
            $RunspacePool.Open()
            for($i = 0; $i -lt $Global:ATransportSrvrs.Count; $i++){
               $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($Global:ATransportSrvrs[$i].Name).AddArgument($SetRemoteIPRanges)
               $Job.RunspacePool = $RunspacePool
               $Jobs += New-Object -TypeName psobject -Property @{RunNum = $i; Pipe = $Job; Result = $Job.BeginInvoke()}
            }
            do{Show-DSRCUpdateProgressBar -State Update -Value $($(@($Jobs.Result | ?{$_.IsCompleted -eq $true}).Count / $Jobs.Count) * 100)}
            while($Jobs.Result.IsCompleted -contains $false)
            $Global:RemoteIPRangeCurrent = @()
            $Global:DSRcvConnectors = @($Jobs | %{$_.Pipe.EndInvoke($_.Result).ReceiveConnector;Show-DSRCUpdateProgressBar -State Update -Value 100} | ?{$_})
            $Global:CRemoteIPRanges = @($Global:DSRcvConnectors | Select-Object -ExpandProperty RemoteIPRanges | Sort-Object -Unique | ?{$_})
            for($i = 0; $i -lt $Global:CRemoteIPRanges.Count; $i++){
                Show-DSRCUpdateProgressBar -State Update -Value 100
                switch($Global:CRemoteIPRanges[$i].RangeFormat){
                    'SingleAddress'{$Global:RemoteIPRangeCurrent += $Global:CRemoteIPRanges[$i].LowerBound.ToString()}
                    'LoHi'{$Global:RemoteIPRangeCurrent += [string]::Format('{0}-{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].UpperBound.ToString())}
                    'CIDR'{$Global:RemoteIPRangeCurrent += [string]::Format('{0}/{1}',$Global:CRemoteIPRanges[$i].LowerBound.ToString(),$Global:CRemoteIPRanges[$i].CIDRLength)}
                }
            }
            $Global:RemoteIPRangeAdd = @($Global:RemoteIPRangeAdd | ?{$Global:RemoteIPRangeCurrent -notcontains $_;Show-DSRCUpdateProgressBar -State Update -Value 100})
            $Global:RemoteIPRangeRemove = @($Global:RemoteIPRangeRemove | ?{$Global:RemoteIPRangeCurrent -notcontains $_;Show-DSRCUpdateProgressBar -State Update -Value 100})
            $toolStripStatusLabelTotal.Text = [string]::Format('Total: {0}', $Global:RemoteIPRangeCurrent.Count)
            Show-DSRCUpdateProgressBar -State Hide
            $Global:dataGridView.Focus()
        }
        $validateExportSave = {
            $toolStripStatusLabelAdd.Text = [string]::Format('Add: {0}', $Global:RemoteIPRangeAdd.Count)
            $toolStripStatusLabelRemove.Text = [string]::Format('Remove: {0}', $Global:RemoteIPRangeRemove.Count + $Global:ContainedExchangeIPs.Count)
            $Global:buttonExport.Enabled = $Global:RemoteIPRangeAdd.Count -eq 0 -and $Global:RemoteIPRangeRemove.Count -eq 0
            $Global:buttonSave.Enabled = $Global:RemoteIPRangeAdd.Count -gt 0 -or $Global:RemoteIPRangeRemove.Count -gt 0 -or $Global:ContainedExchangeIPs.Count -gt 0
        }
        $dataGridView_SelectionChanged = {
            $toolStripStatusLabelSelected.Text = [string]::Format('Selected: {0}', $Global:dataGridView.SelectedRows.Count)
            $toolStripStatusLabelAdd.Text = [string]::Format('Add: {0}', $Global:RemoteIPRangeAdd.Count)
            if($Global:RemoveInProcess){
                $toolStripStatusLabelRemove.Text = [string]::Format('Remove: {0}', $Global:RemoteIPRangeRemove.Count + $Global:ContainedExchangeIPs.Count)
            }
            else{
                $Global:buttonRemove.Enabled = $Global:dataGridView.SelectedRows.Count -gt 0
            }
        }
        $statusStrip_SizeChanged = {
            $Global:progressBar.Width = $statusStrip.Width - $Global:progressBar.Margin.Size.Width - $statusStrip.GripMargin.Size.Width - $statusStrip.SizeGripBounds.Width - $toolStripStatusLabelTotal.Width - $toolStripStatusLabelSelected.Width - $toolStripStatusLabelAdd.Width - $toolStripStatusLabelRemove.Width
        }
        $Global:formDSRC.ClientSize = New-Object -TypeName System.Drawing.Size (484,362)
        $Global:formDSRC.Icon = $ProgIcon
        $Global:formDSRC.KeyPreview = $true
        $Global:formDSRC.MinimumSize = New-Object -TypeName System.Drawing.Size (500,400)
        $Global:formDSRC.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $Column_RangeFormat.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::AllCells
        $Column_RangeFormat.HeaderText = 'RangeFormat'
        $Column_RangeFormat.Name = 'RangeFormat'
        $Column_RangeFormat.ReadOnly = $true
        $Column_RangeFormat.Resizable = [System.Windows.Forms.dataGridViewTriState]::False
        $Column_RangeFormat.Width = 96
        [void]$Global:dataGridView.Columns.Add($Column_RangeFormat)
        $Column_IPRange.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::Fill
        $Column_IPRange.HeaderText = 'IPRange'
        $Column_IPRange.Name = 'IPRange'
        $Column_IPRange.ReadOnly = $true
        $Column_IPRange.Width = 361
        [void]$Global:dataGridView.Columns.Add($Column_IPRange)
        $Global:dataGridView.AllowUserToAddRows = $false
        $Global:dataGridView.AllowUserToDeleteRows = $false
        $Global:dataGridView.AllowUserToResizeColumns = $false
        $Global:dataGridView.AllowUserToResizeRows = $false
        $Global:dataGridView.ColumnHeadersHeightSizeMode = [System.Windows.Forms.dataGridViewColumnHeadersHeightSizeMode]::DisableResizing
        $Global:dataGridView.Dock = [System.Windows.Forms.DockStyle]::Fill
        $Global:dataGridView.EditMode = [System.Windows.Forms.dataGridViewEditMode]::EditProgrammatically
        $Global:dataGridView.Location = New-Object -TypeName System.Drawing.Point (0,55)
        $Global:dataGridView.ReadOnly = $true
        $Global:dataGridView.RowHeadersWidth = 25
        $Global:dataGridView.RowHeadersWidthSizeMode = [System.Windows.Forms.dataGridViewRowHeadersWidthSizeMode]::DisableResizing
        $Global:dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
        $Global:dataGridView.ShowCellErrors = $false
        $Global:dataGridView.ShowCellToolTips = $false
        $Global:dataGridView.ShowEditingIcon = $false
        $Global:dataGridView.ShowRowErrors = $false
        $Global:dataGridView.Size = New-Object -TypeName System.Drawing.Size (484,285)
        $Global:dataGridView.StandardTab = $true
        $Global:dataGridView.TabIndex = 1
        $Global:dataGridView.add_SelectionChanged($dataGridView_SelectionChanged)
        $Global:formDSRC.Controls.Add($Global:dataGridView)
        $groupBox.Dock = [System.Windows.Forms.DockStyle]::Top
        $groupBox.Location = New-Object -TypeName System.Drawing.Point (0,0)
        $groupBox.Size = New-Object -TypeName System.Drawing.Size (484,55)
        $groupBox.TabIndex = 0
        $groupBox.TabStop = $false
        $Global:formDSRC.Controls.Add($groupBox)
        $labelInfo.Anchor = 13
        $labelInfo.Location = New-Object -TypeName System.Drawing.Point (6,9)
        $labelInfo.Size = New-Object -TypeName System.Drawing.Size (299,43)
        $labelInfo.TabIndex = 0
        $labelInfo.Text = 'This tool will create and delete AFGHAN Digital Sender receive connectors as needed and only store up to 1000 RemoteIPRanges per connector.'
        $labelInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $groupBox.Controls.Add($labelInfo)
        $Global:buttonRefresh.Anchor = 9
        $Global:buttonRefresh.Location = New-Object -TypeName System.Drawing.Point (311,10)
        $Global:buttonRefresh.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonRefresh.TabIndex = 1
        $Global:buttonRefresh.Text = 'Refresh'
        $Global:buttonRefresh.UseVisualStyleBackColor = $true
        $Global:buttonRefresh.add_Click($background_Refresh_Work)
        $Global:buttonRefresh.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonRefresh)
        $Global:buttonAdd.Anchor = 9
        $Global:buttonAdd.Location = New-Object -TypeName System.Drawing.Point (368,10)
        $Global:buttonAdd.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonAdd.TabIndex = 2
        $Global:buttonAdd.Text = 'Add'
        $Global:buttonAdd.UseVisualStyleBackColor = $true
        $Global:buttonAdd.add_Click($buttonAdd_Click)
        $Global:buttonAdd.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonAdd)
        $Global:buttonRemove.Anchor = 9
        $Global:buttonRemove.Enabled = $false
        $Global:buttonRemove.Location = New-Object -TypeName System.Drawing.Point (425,10)
        $Global:buttonRemove.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonRemove.TabIndex = 3
        $Global:buttonRemove.Text = 'Remove'
        $Global:buttonRemove.UseVisualStyleBackColor = $true
        $Global:buttonRemove.add_Click($buttonRemove_Click)
        $Global:buttonRemove.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonRemove)
        $Global:buttonImport.Anchor = 9
        $Global:buttonImport.Location = New-Object -TypeName System.Drawing.Point (311,31)
        $Global:buttonImport.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonImport.TabIndex = 4
        $Global:buttonImport.Text = 'Import'
        $Global:buttonImport.UseVisualStyleBackColor = $true
        $Global:buttonImport.add_Click($buttonImport_Click)
        $Global:buttonImport.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonImport)
        $Global:buttonExport.Anchor = 9
        $Global:buttonExport.Location = New-Object -TypeName System.Drawing.Point (368,31)
        $Global:buttonExport.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonExport.TabIndex = 5
        $Global:buttonExport.Text = 'Export'
        $Global:buttonExport.UseVisualStyleBackColor = $true
        $Global:buttonExport.add_Click($buttonExport_OnClick)
        $Global:buttonExport.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonExport)
        $Global:buttonSave.Anchor = 9
        $Global:buttonSave.Enabled = $false
        $Global:buttonSave.Location = New-Object -TypeName System.Drawing.Point (425,31)
        $Global:buttonSave.Size = New-Object -TypeName System.Drawing.Size (55,20)
        $Global:buttonSave.TabIndex = 6
        $Global:buttonSave.Text = 'Save'
        $Global:buttonSave.UseVisualStyleBackColor = $true
        $Global:buttonSave.add_Click($buttonSave_Click)
        $Global:buttonSave.add_Click($validateExportSave)
        $groupBox.Controls.Add($Global:buttonSave)
        $statusStrip.Location = New-Object -TypeName System.Drawing.Point (0,340)
        $statusStrip.Size = New-Object -TypeName System.Drawing.Size (484,22)
        $statusStrip.TabIndex = 2
        $statusStrip.add_SizeChanged($statusStrip_SizeChanged)
        $Global:formDSRC.Controls.Add($statusStrip)
        $toolStripStatusLabelTotal.Text = 'Total: 0'
        [void]$statusStrip.Items.Add($toolStripStatusLabelTotal)
        $toolStripStatusLabelSelected.Text = 'Selected: 0'
        [void]$statusStrip.Items.Add($toolStripStatusLabelSelected)
        $toolStripStatusLabelAdd.Text = 'Add: 0'
        [void]$statusStrip.Items.Add($toolStripStatusLabelAdd)
        $toolStripStatusLabelRemove.Text = 'Remove: 0'
        [void]$statusStrip.Items.Add($toolStripStatusLabelRemove)
        $Global:progressBar.AutoSize = $false
        $Global:progressBar.Visible = $false
        $Global:progressBar.Width = 254
        [void]$statusStrip.Items.Add($Global:progressBar)
        $Global:formDSRC.add_Shown($background_Refresh_Work)
        $Global:formDSRC.add_Shown($validateExportSave)
        $Global:formDSRC.add_KeyDown($formDSRC_KeyDown)
        [void]$Global:formDSRC.ShowDialog()
        Remove-Variable -Name ATransportSrvrs,buttonAdd,buttonExport,buttonImport,buttonRemove,buttonRefresh,buttonSave,ContainedExchangeIPs,ControlState,CRemoteIPRanges,dataGridView,DSRcvConnectors,ExchangeServers,formDSRC,progressBar,RemoteIPRangeAdd,RemoteIPRangeCurrent,RemoteIPRangeRemove,RemoveInProcess -Scope Global -Force -ErrorAction SilentlyContinue
    }
    function Verify-RemoveRemoteIPRange{
        param($RemoteRanges)
        $formRemove = New-Object -TypeName System.Windows.Forms.Form
        $panelRemoveInfo = New-Object -TypeName System.Windows.Forms.Panel
        $pictureBoxRemoveQuestion = New-Object -TypeName System.Windows.Forms.PictureBox
        $labelRemoveIPRange = New-Object -TypeName System.Windows.Forms.Label
        $dataGridViewRemove = New-Object -TypeName System.Windows.Forms.DataGridView
        $panelRemoveButtons = New-Object -TypeName System.Windows.Forms.Panel
        $buttonYesRemoteIPRange = New-Object -TypeName System.Windows.Forms.Button
        $buttonNoRemoteIPRange = New-Object -TypeName System.Windows.Forms.Button
        $formRemove_Shown = {
            $dataGridViewRemove.SuspendLayout()
            foreach($IPRange in @($RemoteRanges | Sort-Object)){
                switch($IPRange){
                    {[regex]::IsMatch($_,"^$IPMatch$")}{$dataGridViewRemove.Rows.Add('SingleAddress',$_)}
                    {[regex]::IsMatch($_,"^$LoHiMatch$")}{$dataGridViewRemove.Rows.Add('LoHi',$_)}
                    {[regex]::IsMatch($_,"^$CIDRMatch$")}{$dataGridViewRemove.Rows.Add('CIDR',$_)}
                }
            }
            $dataGridViewRemove.PerformLayout()
            $dataGridViewRemove.ResumeLayout()
            $buttonNoRemoteIPRange.Focus()
        }
        $formRemove.AcceptButton = $buttonYesRemoteIPRange
        $formRemove.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
        $formRemove.CancelButton = $buttonNoRemoteIPRange
        $formRemove.ClientSize = New-Object -TypeName System.Drawing.Size (384,162)
        $formRemove.Icon = $ProgIcon
        $formRemove.MaximizeBox = $false
        $formRemove.MinimizeBox = $false
        $formRemove.MinimumSize = New-Object -TypeName System.Drawing.Size (400,200)
        $formRemove.MaximumSize = New-Object -TypeName System.Drawing.Size (400,[int]::MaxValue)
        $formRemove.ShowInTaskbar = $false
        $formRemove.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
        $formRemove.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
        $formRemove.Text = 'Remove'
        $Column_Remove_RangeFormat = New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn
        $Column_Remove_RangeFormat.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::AllCells
        $Column_Remove_RangeFormat.HeaderText = 'RangeFormat'
        $Column_Remove_RangeFormat.ReadOnly = $true
        $Column_Remove_RangeFormat.Resizable = [System.Windows.Forms.dataGridViewTriState]::False
        $Column_Remove_RangeFormat.Width = 96
        [void]$dataGridViewRemove.Columns.Add($Column_Remove_RangeFormat)
        $Column_Remove_IPRange = New-Object -TypeName System.Windows.Forms.DataGridViewTextBoxColumn
        $Column_Remove_IPRange.AutoSizeMode = [System.Windows.Forms.dataGridViewAutoSizeColumnMode]::Fill
        $Column_Remove_IPRange.HeaderText = 'IPRange'
        $Column_Remove_IPRange.ReadOnly = $true
        $Column_Remove_IPRange.Width = 285
        [void]$dataGridViewRemove.Columns.Add($Column_Remove_IPRange)
        $dataGridViewRemove.AllowUserToAddRows = $false
        $dataGridViewRemove.AllowUserToDeleteRows = $false
        $dataGridViewRemove.AllowUserToResizeColumns = $false
        $dataGridViewRemove.AllowUserToResizeRows = $false
        $dataGridViewRemove.BackgroundColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
        $dataGridViewRemove.ClipboardCopyMode = [System.Windows.Forms.DataGridViewClipboardCopyMode]::Disable
        $dataGridViewRemove.ColumnHeadersHeightSizeMode = [System.Windows.Forms.dataGridViewColumnHeadersHeightSizeMode]::DisableResizing
        $dataGridViewRemove.Dock = [System.Windows.Forms.DockStyle]::Fill
        $dataGridViewRemove.Location = New-Object -TypeName System.Drawing.Point (0,60)
        $dataGridViewRemove.ReadOnly = $true
        $dataGridViewRemove.RowHeadersVisible = $false
        $dataGridViewRemove.RowHeadersWidthSizeMode = [System.Windows.Forms.dataGridViewRowHeadersWidthSizeMode]::DisableResizing
        $dataGridViewRemove.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
        $dataGridViewRemove.Size = New-Object -TypeName System.Drawing.Size (384,57)
        $dataGridViewRemove.StandardTab = $true
        $dataGridViewRemove.TabIndex = 1
        $formRemove.Controls.Add($dataGridViewRemove)
        $panelRemoveInfo.Dock = [System.Windows.Forms.DockStyle]::Top
        $panelRemoveInfo.Location = New-Object -TypeName System.Drawing.Point (0,0)
        $panelRemoveInfo.Size = New-Object -TypeName System.Drawing.Size (384,60)
        $panelRemoveInfo.TabIndex = 0
        $formRemove.Controls.Add($panelRemoveInfo)
        $pictureBoxRemoveQuestion.Location = New-Object -TypeName System.Drawing.Point (12,12)
        $pictureBoxRemoveQuestion.Size = New-Object -TypeName System.Drawing.Size (42,42)
        $pictureBoxRemoveQuestion.TabIndex = 0
        $pictureBoxRemoveQuestion.TabStop = $false
        $pictureBoxRemoveQuestion.Image = [System.Drawing.SystemIcons]::Question
        $panelRemoveInfo.Controls.Add($pictureBoxRemoveQuestion)
        $labelRemoveIPRange.Location = New-Object -TypeName System.Drawing.Point (60,12)
        $labelRemoveIPRange.Size = New-Object -TypeName System.Drawing.Size (321,42)
        $labelRemoveIPRange.TabIndex = 1
        $labelRemoveIPRange.Text = 'Are you sure you want to remove the RemoteIPRanges below?'
        $labelRemoveIPRange.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $panelRemoveInfo.Controls.Add($labelRemoveIPRange)
        $panelRemoveButtons.BackColor = [System.Drawing.Color]::FromArgb(255,240,240,240)
        $panelRemoveButtons.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $panelRemoveButtons.Location = New-Object -TypeName System.Drawing.Point (0,117)
        $panelRemoveButtons.Size = New-Object -TypeName System.Drawing.Size (384,45)
        $panelRemoveButtons.TabIndex = 2
        $formRemove.Controls.Add($panelRemoveButtons)
        $buttonYesRemoteIPRange.DialogResult = [System.Windows.Forms.DialogResult]::Yes
        $buttonYesRemoteIPRange.Location = New-Object -TypeName System.Drawing.Point (216,10)
        $buttonYesRemoteIPRange.Size = New-Object -TypeName System.Drawing.Size (75,23)
        $buttonYesRemoteIPRange.TabIndex = 0
        $buttonYesRemoteIPRange.Text = 'Yes'
        $buttonYesRemoteIPRange.UseVisualStyleBackColor = $true
        $panelRemoveButtons.Controls.Add($buttonYesRemoteIPRange)
        $buttonNoRemoteIPRange.DialogResult = [System.Windows.Forms.DialogResult]::No
        $buttonNoRemoteIPRange.Location = New-Object -TypeName System.Drawing.Point (297,10)
        $buttonNoRemoteIPRange.Size = New-Object -TypeName System.Drawing.Size (75,23)
        $buttonNoRemoteIPRange.TabIndex = 1
        $buttonNoRemoteIPRange.Text = 'No'
        $buttonNoRemoteIPRange.UseVisualStyleBackColor = $true
        $panelRemoveButtons.Controls.Add($buttonNoRemoteIPRange)
        $formRemove.add_Shown($formRemove_Shown)
        $formRemove.ShowDialog()
    }
    Start-DSRCUpdate
    Remove-Variable -Name base64IconString,CIDRMatch,iconBytes,iconHandle,iconStream,IPMatch,LoHiMatch,ProgIcon,RemoteIPRange -Force -ErrorAction SilentlyContinue


}#End DigitalSenderReceiveConnector

function Disable-Mailbox {

    param ($Username)

    $ErrorActionPreference = "silentlycontinue"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }

    Write-Host -ForgroundColor Red "*** WARNING *** - You are about to delete the mailbox for the following user."	

    (Get-ADUser $Username).name

    $Delete_Confirmation = Read-Host "Do you wish to proceed? (Y/N)"

    If ($Delete_Confirmation -eq "Y") {Disable-Mailbox $Username -Confirm:$False}

    pause


}#End Disable-Mailbox

function Get-TestServiceHealth {

    #Get the list of Exchange servers in the organization
    $KDHRB1AFGN001 = Get-ExchangeServer

    #Loop through each server
    ForEach ($server in $servers)
    {
	    Write-Host -ForegroundColor White "---------- Testing" $server

	    #Initialize an array object for the Test-ServiceHealth results
	    [array]$servicehealth = @()

	    #Run Test-ServiceHealth
	    $servicehealth = Test-ServiceHealth $server

	    #Output the results
	    ForEach($serverrole in $servicehealth)
	    {
		    If ($serverrole.RequiredServicesRunning -eq $true)
		    {
			    Write-Host $serverrole.Role -NoNewline; Write-Host -ForegroundColor Green "Pass"
		    }
		    Else
		    {
			    Write-Host $serverrole.Role -nonewline; Write-Host -ForegroundColor Red "Fail"
			    [array]$notrunning = @()
			    $notrunning = $serverrole.ServicesNotRunning
			    ForEach ($svc in $notrunning)
			    {
				    $alertservices += $svc
			    }
			    Write-Host $serverrole.Role "Services not running:"
			    ForEach ($al in $alertservices)
				    {
					    Write-Host -ForegroundColor Red `t$al
				    }
		    }
	    }
    }

}#End Get-TestServiceHealth

function Get-ComputerImageVersion8 {

<#
.SYNOPSIS
Get Computer IP Address, Image Version, & OS Install date
.DESCRIPTION
Retrieves the information for Computer IP Address & Image Version Number with the OS Install Date.
Must be run With Elevated User Account.
version 8 by Michael Melonas / 7 MAR 2015
change OU & DC per enclave
.PARAMETER OutFile
Name of the Output File with the complete file path
.EXAMPLE
Get-ComputerImageVersion
This example retrieves the Computer IP Address, Image number and OS install date and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the folder where the script is. "ComputerImageVersion&DateList.Csv" is the default output file name
.EXAMPLE
Check-ElevatedExpDates -OutFile C:\ComputerImageVersion&DateList.Csv
This example retrieves the elevated account information and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the C:\ drive root
#>

    param(
        [string]$OutFile = "C:\temp\ComputerImageVersion&DateListARNA.Csv",
        [string]$DomainOU = "OU=Computers,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    )
    BEGIN{
        if (Test-Path $OutFile) {
            Remove-Item $OutFile
        }
        New-Item $OutFile -type file | Out-Null
    }
    PROCESS{
        $Computers = (Get-ADComputer -Filter * -Properties Name -SearchBase $DomainOU).Name
        foreach ($Computer in $Computers){
            $PingStatus = "null"
            $model = "null"
            $OSDate = "null"
            $ip = "null"

            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet){
                $PingStatus = "On line"

                $ip=Get-WMIObject win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer |
                    Foreach-Object {$_.IPAddress} |Foreach-Object { [IPAddress]$_ } |
                    Where-Object { $_.AddressFamily -eq 'Internetwork' } |
                    Foreach-Object { $_.IPAddressToString } 
 
                try {
                    $Reg1 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey1= $Reg1.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OEMInformation" )
                    $model1 = $objRegKey1.GetValue("Model")

                    $Reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey2= $Reg2.OpenSubKey("SOFTWARE\\DOD\\UGM\\ImageRev" )
                    $model2 = $objRegKey2.GetValue("CurrentBuild")


                } catch {
                    $model = "n/a"
                } Finally {
                    if ($model1 -ne $null) {
                        $model = $model1
                    } elseIf ($model2 -ne $null) {
                        $model = $model2
                    } else {
                        $model = "unk"
                    }
                }

                $os = gwmi win32_operatingsystem -ComputerName $Computer
                $OSDate = $os.ConvertToDateTime($os.installDate)
            }else{
                $PingStatus = "Off line"
                $model = "n/a"
                $OSDate = "n/a"
                $ip = "n/a"
            }

        $header = @()
        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "$Computer"
        $row | Add-Member -MemberType NoteProperty -Name "Status" -Value "$PingStatus"
        $row | Add-Member -MemberType NoteProperty -Name "IP Address" -Value "$ip"
        $row | Add-Member -MemberType NoteProperty -Name "Image" -Value "$model"
        $row | Add-Member -MemberType NoteProperty -Name "OS Installed Date" -Value "$OSDate"
        $header += $row
        $header | Export-Csv $OutFile -Append -NoTypeInformation
        }
    }
    END{}


}#End Get-ComputerImageVersion8

function Get-ComputerImageVersion9 {

<#
.SYNOPSIS
Get Computer IP Address, Image Version, & OS Install date
.DESCRIPTION
Retrieves the information for Computer IP Address & Image Version Number with the OS Install Date.
Must be run With Elevated User Account.
version 9 by Michael Melonas / 23 MAR 2015
change OU & DC per enclave
.PARAMETER OutFile
Name of the Output File with the complete file path
.EXAMPLE
Get-ComputerImageVersion
This example retrieves the Computer IP Address, Image number and OS install date and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the folder where the script is. "ComputerImageVersion&DateList.Csv" is the default output file name
.EXAMPLE
Check-ElevatedExpDates -OutFile C:\temp\ComputerImageVersion&DateList.Csv
This example retrieves the elevated account information and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the C:\ drive root
#>

    param(
        [string]$OutFile = "C:\temp\ComputerImageVersion&DateListKDHR.Csv",
        [string]$DomainOU = "OU=Computers,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil",
        [string]$Offline_OutFile = "C:\temp\Offline.Csv"
    )
    BEGIN{
        if (Test-Path $OutFile) {
            Remove-Item $OutFile
        }
        New-Item $OutFile -type file | Out-Null

        if (Test-Path $Offline_OutFile) {
            Remove-Item $OutFile
        }
        New-Item $Offline_OutFile -type file | Out-Null
    }
    PROCESS{
        $Computers = (Get-ADComputer -Filter * -Properties Name -SearchBase $DomainOU).Name
        foreach ($Computer in $Computers){
            $PingStatus = "null"
            $model = "null"
            $OSDate = "null"
            $ip = "null"

            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet){
                $PingStatus = "On line"

                $ip=Get-WMIObject win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer |
                    Foreach-Object {$_.IPAddress} |Foreach-Object { [IPAddress]$_ } |
                    Where-Object { $_.AddressFamily -eq 'Internetwork' } |
                    Foreach-Object { $_.IPAddressToString } 
 
                try {
                    $Reg1 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey1= $Reg1.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OEMInformation" )
                    $model1 = $objRegKey1.GetValue("Model")

                    $Reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey2= $Reg2.OpenSubKey("SOFTWARE\\DOD\\UGM\\ImageRev" )
                    $model2 = $objRegKey2.GetValue("CurrentBuild")


                } catch {
                    $model = "n/a"
                } Finally {
                    if ($model1 -ne $null) {
                        $model = $model1
                    } elseIf ($model2 -ne $null) {
                        $model = $model2
                    } else {
                        $model = "unk"
                    }
                }

                $os = gwmi win32_operatingsystem -ComputerName $Computer
                $OSDate = $os.ConvertToDateTime($os.installDate)
            }else{
            
                $PingStatus = "Off line"
                $model = "n/a"
                $OSDate = "n/a"
                $ip = "n/a"
            
                $header = @()
                $row = New-Object PSObject
                $row | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "$Computer"
                $row | Add-Member -MemberType NoteProperty -Name "Status" -Value "$PingStatus"
                $header += $row
                $header | Export-Csv $Offline_OutFile -Append -NoTypeInformation
            

            }

        $header = @()
        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "$Computer"
        $row | Add-Member -MemberType NoteProperty -Name "Status" -Value "$PingStatus"
        $row | Add-Member -MemberType NoteProperty -Name "IP Address" -Value "$ip"
        $row | Add-Member -MemberType NoteProperty -Name "Image" -Value "$model"
        $row | Add-Member -MemberType NoteProperty -Name "OS Installed Date" -Value "$OSDate"
        $header += $row
        $header | Export-Csv $OutFile -Append -NoTypeInformation
        }
    }
    END{}

}#End Get-ComputerImageVersion9

function Get-DHCPLeases {

    # Get-DHCPLeases

    # Author : Assaf Miron

    # Description : This Script is used to get all DHCP Scopes and Leases from a specific DHCP Server

    #

    # Input : 

    # Output: 3 Log Files - Scope Log, Client Lease Log, Reserved Clients Log


    $DHCP_SERVER = "kdhra5afgn04002" # The DHCP Server Name

    $LOG_FOLDER = "m:\dhcp" # A Folder to save all the Logs

    # Create Log File Paths

    $ScopeLog = $LOG_FOLDER+"\ScopeLog.csv"

    $LeaseLog = $LOG_FOLDER+"\LeaseLog.csv"

    $ReservedLog = $LOG_FOLDER+"\ReservedLog.csv"


    #region Create Scope Object

    # Create a New Object

    $Scope = New-Object psobject

    # Add new members to the Object

    $Scope | Add-Member noteproperty "Address" ""

    $Scope | Add-Member noteproperty "Mask" ""

    $Scope | Add-Member noteproperty "State" ""

    $Scope | Add-Member noteproperty "Name" ""

    $Scope | Add-Member noteproperty "LeaseDuration" ""

    # Create Each Member in the Object as an Array

    $Scope.Address = @()

    $Scope.Mask = @()

    $Scope.State = @()

    $Scope.Name = @()

    $Scope.LeaseDuration = @()

    #endregion


    #region Create Lease Object

    # Create a New Object

    $LeaseClients = New-Object psObject

    # Add new members to the Object

    $LeaseClients | Add-Member noteproperty "IP" ""

    $LeaseClients | Add-Member noteproperty "Name" ""

    $LeaseClients | Add-Member noteproperty "Mask" ""

    $LeaseClients | Add-Member noteproperty "MAC" ""

    $LeaseClients | Add-Member noteproperty "Expires" ""

    $LeaseClients | Add-Member noteproperty "Type" ""

    # Create Each Member in the Object as an Array

    $LeaseClients.IP = @()

    $LeaseClients.Name = @()

    $LeaseClients.MAC = @()

    $LeaseClients.Mask = @()

    $LeaseClients.Expires = @()

    $LeaseClients.Type = @()

    #endregion


    #region Create Reserved Object

    # Create a New Object

    $LeaseReserved = New-Object psObject

    # Add new members to the Object

    $LeaseReserved | Add-Member noteproperty "IP" ""

    $LeaseReserved | Add-Member noteproperty "MAC" ""

    # Create Each Member in the Object as an Array

    $LeaseReserved.IP = @()

    $LeaseReserved.MAC = @()

    #endregion


    #region Define Commands

    #Commad to Connect to DHCP Server

    $NetCommand = "netsh dhcp server \\$DHCP_SERVER"

    #Command to get all Scope details on the Server

    $ShowScopes = "$NetCommand show scope"

    #endregion


    function Get-LeaseType( $LeaseType )

    {

    # Input : The Lease type in one Char

    # Output : The Lease type description

    # Description : This function translates a Lease type Char to it's relevant Description


    Switch($LeaseType){

    "N" { return "None" }

    "D" { return "DHCP" }

    "B" { return "BOOTP" }

    "U" { return "UNSPECIFIED" }

    "R" { return "RESERVATION IP" }

    }

    }


    function Check-Empty( $Object ){

    # Input : An Object with values.

    # Output : A Trimmed String of the Object or '-' if it's Null.

    # Description : Check the object if its null or not and return it's value.

    If($Object -eq $null)

    {

    return "-"

    }

    else

    {

    return $Object.ToString().Trim()

    }

    }


    function out-CSV ( $LogFile, $Append = $false) {

    # Input : An Object with values, Boolean value if to append the file or not, a File path to a Log File

    # Output : Export of the object values to a CSV File

    # Description : This Function Exports all the Values and Headers of an object to a CSV File.

    #  The Object is recieved with the Input Const (Used with Pipelineing) or the $inputObject

    Foreach ($item in $input){

    # Get all the Object Properties

    $Properties = $item.PsObject.get_properties()

    # Create Empty Strings - Start Fresh

    $Headers = ""

    $Values = ""

    # Go over each Property and get it's Name and value

    $Properties | %{ 

    $Headers += $_.Name+"`t"

    $Values += $_.Value+"`t"

    }

    # Output the Object Values and Headers to the Log file

    If($Append -and (Test-Path $LogFile)) {

    $Values | Out-File -Append -FilePath $LogFile -Encoding Unicode

    }

    else {

    # Used to mark it as an Powershell Custum object - you can Import it later and use it

    # "#TYPE System.Management.Automation.PSCustomObject" | Out-File -FilePath $LogFile

    $Headers | Out-File -FilePath $LogFile -Encoding Unicode

    $Values | Out-File -Append -FilePath $LogFile -Encoding Unicode

    }

    }

    }


    #region Get all Scopes in the Server 

    # Run the Command in the Show Scopes var

    $AllScopes = Invoke-Expression $ShowScopes

    # Go over all the Results, start from index 5 and finish in last index -3

    for($i=5;$i -lt $AllScopes.Length-3;$i++)

    {

    # Split the line and get the strings

    $line = $AllScopes[$i].Split("-")

    $Scope.Address += Check-Empty $line[0]

    $Scope.Mask += Check-Empty $line[1]

    $Scope.State += Check-Empty $line[2]

    # Line 3 and 4 represent the Name and Comment of the Scope

    # If the name is empty, try taking the comment

    If (Check-Empty $line[3] -eq "-") {

    $Scope.Name += Check-Empty $line[4]

    }

    else { $Scope.Name += Check-Empty $line[3] }

    }

    # Get all the Active Scopes IP Address

    $ScopesIP = $Scope | Where { $_.State -eq "Active" } | Select Address

    # Go over all the Adresses to collect Scope Client Lease Details

    Foreach($ScopeAddress in $ScopesIP.Address){

    # Define some Commands to run later - these commands need to be here because we use the ScopeAddress var that changes every loop

    #Command to get all Lease Details from a specific Scope - when 1 is amitted the output includes the computer name

    $ShowLeases = "$NetCommand scope "+$ScopeAddress+" show clients 1"

    #Command to get all Reserved IP Details from a specific Scope

    $ShowReserved = "$NetCommand scope "+$ScopeAddress+" show reservedip"

    #Command to get all the Scopes Options (Including the Scope Lease Duration)

    $ShowScopeDuration = "$NetCommand scope "+$ScopeAddress+" show option"

    # Run the Commands and save the output in the accourding var

    $AllLeases = Invoke-Expression $ShowLeases 

    $AllReserved = Invoke-Expression $ShowReserved 

    $AllOptions = Invoke-Expression $ShowScopeDuration

    # Get the Lease Duration from Each Scope

    for($i=0; $i -lt $AllOptions.count;$i++) 

    { 

    # Find a Scope Option ID number 51 - this Option ID Represents  the Scope Lease Duration

    if($AllOptions[$i] -match "OptionId : 51")

    { 

    # Get the Lease Duration from the Specified line

    $tmpLease = $AllOptions[$i+4].Split("=")[1].Trim()

    # The Lease Duration is recieved in Ticks / 10000000

    $tmpLease = [int]$tmpLease * 10000000; # Need to Convert to Int and Multiply by 10000000 to get Ticks

    # Create a TimeSpan Object

    $TimeSpan = New-Object -TypeName TimeSpan -ArgumentList $tmpLease

    # Calculate the $tmpLease Ticks to Days and put it in the Scope Lease Duration

    $Scope.LeaseDuration += $TimeSpan.TotalDays

    # After you found one Exit the For

    break;

    } 

    }

    # Get all Client Leases from Each Scope

    for($i=8;$i -lt $AllLeases.Length-4;$i++)

    {

    # Split the line and get the strings

    $line = [regex]::split($AllLeases[$i],"\s{2,}")

    # Check if you recieve all the lines that you need

    $LeaseClients.IP += Check-Empty $line[0]

    $LeaseClients.Mask += Check-Empty $line[1].ToString().replace("-","").Trim()

    $LeaseClients.MAC += $line[2].ToString().substring($line[2].ToString().indexOf("-")+1,$line[2].toString().Length-1).Trim()

    $LeaseClients.Expires += $(Check-Empty $line[3]).replace("-","").Trim()

    $LeaseClients.Type += Get-LeaseType $(Check-Empty $line[4]).replace("-","").Trim()

    $LeaseClients.Name += Check-Empty $line[5]

    }

    # Get all Client Lease Reservations from Each Scope

    for($i=7;$i -lt $AllReserved.Length-5;$i++)

    {

    # Split the line and get the strings

    $line = [regex]::split($AllReserved[$i],"\s{2,}")

    $LeaseReserved.IP += Check-Empty $line[0]

    $LeaseReserved.MAC += Check-Empty $line[2]

    }

    }

    #endregion 


    #region Export all the Data to nice log files

    # Export all data to XML Files for  later review

    $LeaseClients | Export-Clixml -Path $LOG_FOLDER"\Clients.xml"

    $LeaseReserved | Export-Clixml -Path $LOG_FOLDER"\Reserved.xml"

    $Scope | Export-Clixml -Path $LOG_FOLDER"\Scope.xml"

    #region Create a Temp Scope Object

    # Create a New Object

    $tmpScope = New-Object psobject

    # Add new members to the Object

    $tmpScope | Add-Member noteproperty "Address" ""

    $tmpScope | Add-Member noteproperty "Mask" ""

    $tmpScope | Add-Member noteproperty "State" ""

    $tmpScope | Add-Member noteproperty "Name" ""

    $tmpScope | Add-Member noteproperty "LeaseDuration" ""

    #endregion

    #region Create a Temp Lease Object

    # Create a New Object

    $tmpLeaseClients = New-Object psObject

    # Add new members to the Object

    $tmpLeaseClients | Add-Member noteproperty "IP" ""

    $tmpLeaseClients | Add-Member noteproperty "Name" ""

    $tmpLeaseClients | Add-Member noteproperty "Mask" ""

    $tmpLeaseClients | Add-Member noteproperty "MAC" ""

    $tmpLeaseClients | Add-Member noteproperty "Expires" ""

    $tmpLeaseClients | Add-Member noteproperty "Type" ""

    #endregion

    #region Create a Temp Reserved Object

    # Create a New Object

    $tmpLeaseReserved = New-Object psObject

    # Add new members to the Object

    $tmpLeaseReserved | Add-Member noteproperty "IP" ""

    $tmpLeaseReserved | Add-Member noteproperty "MAC" ""

    #endregion

    # Go over all the scope addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $Scope.Address.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpScope.Address = $Scope.Address[$l]

    $tmpScope.Mask = $Scope.Mask[$l]

    $tmpScope.State = $Scope.State[$l]

    $tmpScope.Name = $Scope.Name[$l]

    if($Scope.LeaseDuration[$l] -ne $Null)

    {

    $tmpLease = $Scope.LeaseDuration[$l].ToString()

    $tmpScope.LeaseDuration = $Scope.LeaseDuration[$l].ToString()

    }

    else

    {

    $tmpScope.LeaseDuration = $tmpLease

    }

    # Export with the Out-CSV Function to the Log File

    $tmpScope | Out-csv $ScopeLog -append $True

    }

    # Go over all the Client Lease addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $LeaseClients.IP.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpLeaseClients.IP = $LeaseClients.IP[$l]

    $tmpLeaseClients.Name = $LeaseClients.Name[$l]

    $tmpLeaseClients.Mask =  $LeaseClients.Mask[$l]

    $tmpLeaseClients.MAC = $LeaseClients.MAC[$l]

    $tmpLeaseClients.Expires = $LeaseClients.Expires[$l]

    $tmpLeaseClients.Type = $LeaseClients.Type[$l]

    # Export with the Out-CSV Function to the Log File

    $tmpLeaseClients | out-csv $LeaseLog -append $true

    }

    # Go over all the Reserved Client Lease addresses and export each detail to a temporary var and out to the log file

    For($l=0; $l -lt $LeaseReserved.IP.Length;$l++)

    {

    # Get all Scope details to a temp var

    $tmpLeaseReserved.IP = $LeaseReserved.IP[$l]

    $tmpLeaseReserved.MAC = $LeaseReserved.MAC[$l]

    # Export with the Out-CSV Function to the Log File

    $tmpLeaseReserved | out-csv $ReservedLog -append $true

    }

    #endregion 

}#End Get-DHCPLeases

function Get-DigitalSenderList {

    Param(
        [string]$OutFile = "C:\temp\DigitalSenderList.csv"
    )
    BEGIN{}
    PROCESS{
        #$IpaddressS = Get-ReceiveConnector -id 'KDHRB1AFGN001\AFGHAN Digital Senders 2' | select -expand remoteipranges
        $IpaddressS = "10.206.48.19"
        foreach ($IpAddDS in $IpaddressS){
            $PingStatus = "null"
            $Title = "null"
            $ip = "null"

            if (Test-Connection -ComputerName $IPAddDS -Count 2 -Quiet){
                $PingStatus = "On line"
                $web = New-Object System.Net.WebClient
                Try {
                    #$web.DownloadString("https://$IpAddDS")
                    $web.DownloadString("https://10.206.48.19")
                    $regex = '[<title>]+.+[<\/title>]'
                    $Title = select-string -Path $web -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value }
                    #$Title.TrimStart("<title>")
                    #$Title.TrimEnd("<\/title>")
                } Catch {
                    $PingStatus = "no webpage found"
                }
            }else{
                $PingStatus = "Off line"
                $Title = "n/a"
                $ip = "n/a"
            }

        $header = @()
        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "DigitalSenderIP" -Value "$IpAddDS"
        $row | Add-Member -MemberType NoteProperty -Name "Status" -Value "$PingStatus"
        $row | Add-Member -MemberType NoteProperty -Name "Mfr/Model" -Value "$Title"
        $header += $row
        $header | Export-Csv $OutFile -Append -NoTypeInformation
        }
    }
    END{}

}#End Get-DigitalSenderList

function Get-DisconnectMailboxDB01 {

[array[]]$MSExchDBs = ('KDHRDB01','KDHRDB02','KDHRDB03','KDHRDB05','KDHRDB06','KDHRDB07','KDHRDBVIP')

    foreach ($MSExchDB in $MSExchDBs) {
    
        Get-MailboxStatistics -Database $MSExchDB | Where { $_.DisconnectReason -eq "Disabled" }

    }#End foreach

}#End Get-DisconnectMailboxDB01

function Get-LoggedOnUser {

    function global:Get-LoggedOnUser {
    #Requires -Version 2.0            
    [CmdletBinding()]            
     Param             
       (                       
        [Parameter(Mandatory=$true,
                   Position=0,                          
                   ValueFromPipeline=$true,            
                   ValueFromPipelineByPropertyName=$true)]            
        [String[]]$ComputerName
       )#End Paramexi

    Begin            
    {            
     Write-Host "`n Checking Users . . . "
     $i = 0            
    }#Begin          
    Process            
    {
        $ComputerName | Foreach-object {
        $Computer = $_
        try
            {
                $processinfo = @(Get-WmiObject -class win32_process -ComputerName $Computer -EA "Stop")
                    if ($processinfo)
                    {    
                        $processinfo | Foreach-Object {$_.GetOwner().User} | 
                        Where-Object {$_ -ne "NETWORK SERVICE" -and $_ -ne "LOCAL SERVICE" -and $_ -ne "SYSTEM"} |
                        Sort-Object -Unique |
                        ForEach-Object { New-Object psobject -Property @{Computer=$Computer;LoggedOn=$_} } | 
                        Select-Object Computer,LoggedOn
                    }#If
            }
        catch
            {
                "Cannot find any processes running on $computer" | Out-Host
            }
         }#Forech-object(ComputerName)       
            
    }#Process
    End
    {

    }#End

    }#Get-LoggedOnUser


}#End Get-LoggedOnUser

function Enable-Mailbox {

    param ($Username)

    KDHR-Set-DomainController

    $ErrorActionPreference = "silentlycontinue"

    $DatabasePrefix = "KDHRDB0"
    $DatabaseRandom = Get-Random -InputObject 1, 2, 3, 5

    $DatabaseName = "$DatabasePrefix$DatabaseRandom"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }
	

    Enable-Mailbox -Identity $Username -Database $DatabaseName -DomainController $DomainController

}#End Enable-Mailbox

function Get-ComputerInfo {


<#
.SYNOPSIS
UH, this gets the Computer Info?
.DESCRIPTION
Yeah. This gets computer information.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/06/2015 v.15
#>

    param ($Computer)
    
    . Var-Script-Variables
    . Get-LastLogon
    . Get-PendingReboot
    
    Import-Module .\Includes\Modules\PSRemoteRegistry\PSRemoteRegistry.psm1

    $ErrorActionPreference = "silentlycontinue"

    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName

    If ($Computer -eq $Null -or $ComputerCheck -eq $Null) 
	    {

	    Do 	{$Computer = Read-Host -Prompt "Please Enter Valid Computer Name" 
			    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName
		    }

	    Until ($Computer -ne $Null -and $ComputerCheck -ne $Null)
	    }

    Write-Host "
    Active Directory Information about Computer
    ---------------------------------------------"
    Get-ADComputer $Computer -Properties * | Select-Object Name, CanonicalName, DistinguishedName, SID, Enabled, IPv4Address, `
								    OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion, whenCreated, whenChanged, `
								    LastLogonDate, Description, Info

    If ((Get-ADComputer $Computer).Enabled -eq $False) 
	    {Write-Host -ForegroundColor Yellow "*** WARNING *** Computer is Disabled, if disabled for inactivity, submit for reimage.`n"}


    Write-Host "
    Remote Information from Computer
    ---------------------------------------------"

    $ComputerStatus = Test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -ErrorAction 0 -quiet

    if ($ComputerStatus -eq $False) 

	    {
		    Write-Host -ForegroundColor Red "`n*** WARNING *** - Computer is either offline or had bad DNS information.`n"
		    $Manufacturer = ""
		    $Model = ""
		    $RemoteDate = ""
		    $InstallDate = ""
		    $OSArchitecture = ""
		    $SCCMInfo = ""
		    $RebootPending = ""
		    $FileRenamePending = ""
		    $Hotfix = ""
		    $LastLogon = ""
	    }
	
    ElseIf ($ComputerStatus -eq $True) 
	
	    {
	
		    $Manufacturer = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Manufacturer).data
		    $Model = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Model).data
		    $RemoteInfo = Get-WmiObject win32_operatingsystem -ComputerName $Computer
		    $RebootDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.LastBootUpTime)
		    $InstallDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.InstallDate)
		    $OSArchitecture = $RemoteInfo.OSArchitecture
		    $SCCMInfo = Get-PendingReboot -ComputerName $Computer
		    $RebootPending = $SCCMInfo.RebootPending
		    $FileRenamePending = $SCCMInfo.PendFileRename
		    $Hotfix = (Get-HotFix -ComputerName $Computer) | Select-Object Description, HotFixID, InstalledOn
		    $LastLogon = Get-LastLogon -ComputerName $Computer
		    $SecGroupNames = Get-ADPrincipalGroupMembership $Computer$
		
	

    Write-Host "
       Registry Information
       -----------------------------------------
       Manufacturer          : $Manufacturer
       Model                 : $Model
   
       WMI Information
       -----------------------------------------
       Last Rebooted         : $RebootDate
       Install Date          : $InstallDate
       OSArchitecture        : $OSArchitecture
   
       SCCM Information
       -----------------------------------------
       File Rename Pending   : $FileRenamePending
       System Reboot Pending : $RebootPending"

    If (($ComputerStatus -eq $True) -and ($Manufacturer -ne $Current_UGM_Manufacturer -or $Model -ne $Current_UGM_Model)) {Write-Host -ForegroundColor Red "`n   *** WARNING *** - This is not the currently approved UGM image, please have system baselined"}

    Write-Host "`n   
    Most Recently Applied Patches
    ---------------------------------------------"
			    $Hotfix[1]
   

    Write-Host "`nLast User to Logon to this Computer
    ---------------------------------------------"
			    $LastLogon
			
	    }	
	
    Write-Host "
    Computer is a member of the following groups
    ----------------------------------------------
    "
		
			    $SecGroupNames.name

    If ((Get-ADPrincipalGroupMembership $Computer$).count -eq 2) {}
	    Else {Write-Host -ForegroundColor Yellow "`n`n*** WARNING *** Computer does not have 2 security groups, verify 802.1x VLAN Assignment`n`n"}
	
    $ElevatedUser = $env:username
    $ElevatedGroups = Get-ADPrincipalGroupMembership $ElevatedUser
    $8021x_VLAN = (Get-ADPrincipalGroupMembership $Computer$).name | findstr.exe "8021x"

    # ################################ #
    # 802.1x Creation and Modification #
    # ################################ #

    If ($ElevatedGroups.name -contains "8021x_Modify_Group_Members")

	    {
		    Write-Host -ForegroundColor Green "`nCongratulations, you are a member of the 8021x_Modify_Group_Members security group!"
		
		    If ($8021x_VLAN -eq $Null) 
		
			    {

				    $8021x_ModifyChoice = Read-Host "`nThere is currently no 802.1x VLAN assignment on this Computer object, do you wish to assign one? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to assign this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
				    }
	
			    }
			
		    Else
			
			    {
				    $8021x_ModifyChoice = Read-Host "`nComputer Object $Computer is currently assigned to group $8021x_VLAN, do you wish to change it? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to change this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    Remove-ADgroupMember -Identity $8021x_VLAN -Member $Computer$ -Confirm:$False
				    }
				
			    }
	    }

    pause

}#End Get-ComputerInfo

function KDHR-Get-ComputerInfo2 {

<#
.SYNOPSIS
UH, this gets the Computer Info?
.DESCRIPTION
Yeah. This gets computer information.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>


    param ($Computer)

    . Var-Script-Variables
    . Get-LastLogon
    . Get-PendingReboot
    
    Import-Module PSRemoteRegistry

    $ErrorActionPreference = "silentlycontinue"

    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName

    If ($Computer -eq $Null -or $ComputerCheck -eq $Null) 
	    {

	    Do 	{$Computer = Read-Host -Prompt "Please Enter Valid Computer Name" 
			    $ComputerCheck = (Get-ADComputer $Computer).SamAccountName
		    }

	    Until ($Computer -ne $Null -and $ComputerCheck -ne $Null)
	    }

    Write-Host "
    Active Directory Information about Computer
    ---------------------------------------------"
    Get-ADComputer $Computer -Properties * | Select-Object Name, CanonicalName, DistinguishedName, SID, Enabled, IPv4Address, `
								    OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion, whenCreated, whenChanged, `
								    LastLogonDate, Description, Info

    If ((Get-ADComputer $Computer).Enabled -eq $False) 
	    {Write-Host -ForegroundColor Yellow "*** WARNING *** Computer is Disabled, if disabled for inactivity, submit for reimage.`n"}


    Write-Host "
    Remote Information from Computer
    ---------------------------------------------"

    $ComputerStatus = Test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -ErrorAction 0 -quiet

    if ($ComputerStatus -eq $False) 

	    {
		    Write-Host -ForegroundColor Red "`n*** WARNING *** - Computer is either offline or had bad DNS information.`n"
		    $Manufacturer = ""
		    $Model = ""
		    $RemoteDate = ""
		    $InstallDate = ""
		    $OSArchitecture = ""
		    $SCCMInfo = ""
		    $RebootPending = ""
		    $FileRenamePending = ""
		    $Hotfix = ""
		    $LastLogon = ""
	    }
	
    ElseIf ($ComputerStatus -eq $True) 
	
	    {
	
		    $Manufacturer = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Manufacturer).data
		    $Model = (Get-RegValue -ComputerName $Computer -Key SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation -Value Model).data
		    $RemoteInfo = Get-WmiObject win32_operatingsystem -ComputerName $Computer
		    $RebootDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.LastBootUpTime)
		    $InstallDate = $RemoteInfo.ConvertToDateTime($RemoteInfo.InstallDate)
		    $OSArchitecture = $RemoteInfo.OSArchitecture
		    $SCCMInfo = Get-PendingReboot -ComputerName $Computer
		    $RebootPending = $SCCMInfo.RebootPending
		    $FileRenamePending = $SCCMInfo.PendFileRename
		    $Hotfix = (Get-HotFix -ComputerName $Computer) | Select-Object Description, HotFixID, InstalledOn
		    $LastLogon = Get-LastLogon -ComputerName $Computer
		    $SecGroupNames = Get-ADPrincipalGroupMembership $Computer$
		
	

    Write-Host "
       Registry Information
       -----------------------------------------
       Manufacturer          : $Manufacturer
       Model                 : $Model
   
       WMI Information
       -----------------------------------------
       Last Rebooted         : $RebootDate
       Install Date          : $InstallDate
       OSArchitecture        : $OSArchitecture
   
       SCCM Information
       -----------------------------------------
       File Rename Pending   : $FileRenamePending
       System Reboot Pending : $RebootPending"

    If (($ComputerStatus -eq $True) -and ($Manufacturer -ne $Current_UGM_Manufacturer -or $Model -ne $Current_UGM_Model)) {Write-Host -ForegroundColor Red "`n   *** WARNING *** - This is not the currently approved UGM image, please have system baselined"}

    Write-Host "`n   
    Most Recently Applied Patches
    ---------------------------------------------"
			    $Hotfix[1]
   

    Write-Host "`nLast User to Logon to this Computer
    ---------------------------------------------"
			    $LastLogon
			
	    }	
	
    Write-Host "
    Computer is a member of the following groups
    ----------------------------------------------
    "
		
			    $SecGroupNames.name

    If ((Get-ADPrincipalGroupMembership $Computer$).count -eq 2) {}
	    Else {Write-Host -ForegroundColor Yellow "`n`n*** WARNING *** Computer does not have 2 security groups, verify 802.1x VLAN Assignment`n`n"}
	
    $ElevatedUser = $env:username
    $ElevatedGroups = Get-ADPrincipalGroupMembership $ElevatedUser
    $8021x_VLAN = (Get-ADPrincipalGroupMembership $Computer$).name | findstr.exe "8021x"

    # ################################ #
    # 802.1x Creation and Modification #
    # ################################ #

    If ($ElevatedGroups.name -contains "8021x_Modify_Group_Members")

	    {
		    Write-Host -ForegroundColor Green "`nCongratulations, you are a member of the 8021x_Modify_Group_Members security group!"
		
		    If ($8021x_VLAN -eq $Null) 
		
			    {

				    $8021x_ModifyChoice = Read-Host "`nThere is currently no 802.1x VLAN assignment on this Computer object, do you wish to assign one? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to assign this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
				    }
	
			    }
			
		    Else
			
			    {
				    $8021x_ModifyChoice = Read-Host "`nComputer Object $Computer is currently assigned to group $8021x_VLAN, do you wish to change it? (Y/N)"
				
				    If ($8021x_ModifyChoice -eq "Y")
			
				    {
						    $8021x_NewVLAN = Read-Host "Please enter the VLAN you wish to change this Computer to (Number Only)"
						    $8021x_NewVLANName = "8021x_VLAN$8021x_NewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $8021x_NewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $8021x_NewVLANName -Member $Computer$
						    Set-ADComputer -Identity $Computer -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    Remove-ADgroupMember -Identity $8021x_VLAN -Member $Computer$ -Confirm:$False
				    }
				
			    }
	    }

    pause

}#End Get-ComputerInfo2

function Get-DatabaseSizeReport {

    Get-MailboxDatabase -Status -Identity KDHR* |
    select ServerName,Name,DatabaseSize | Sort-Object Name | Out-GridView -Title "Kandahar Exchange Database Sizes"

}#End Get-DatabaseSizeReport

function Get-DatabaseUserCount {
<#
.SYNOPSIS
Counts the Users in the MSExchange Database.
.DESCRIPTION
Counts the Users in the MSExchange Database.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $ExchangeDatabases = Get-MailboxDatabase -Identity KDHR*

    Foreach ($Database in $ExchangeDatabases.Name)

	    {

	    $DatabaseCount = (Get-Mailbox -ResultSize Unlimited -Database $Database).count
	    Write-Host "$Database - $DatabaseCount"
	    $UserCount = $UserCount + $DatabaseCount

	    }

    Write-Host "
    Total Users: $UserCount"

}#End Get-DatabaseUserCount

function Get-MacAddressInfo {

<#
.SYNOPSIS
Counts the Users in the MSExchange Database.
.DESCRIPTION
Counts the Users in the MSExchange Database.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Param ($EnteredMac)

    . Var-Script-Variables

    $Mac1 = "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"
    $Mac2 = "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]"
    $Mac3 = "[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]"


    Do 	{
	
	    If ($EnteredMac -eq $Null) {$EnteredMac = read-host "Enter a Mac Address"}
	
	    If ($EnteredMac -notlike $Mac1 -and $EnteredMac -notlike $Mac2 -and $EnteredMac -notlike $Mac3)
                
            {
    		    Write-Host "Error: The MAC Address Entered is NOT in the correct format, Please Enter the correct format."
			    $EnteredMac = read-host "Enter a Mac Address"
		    }
        

	    }


    until ($EnteredMac -like $Mac1 -or $EnteredMac -like $Mac2 -or  $EnteredMac -like $Mac3){}


    if ($EnteredMac -like $Mac1) 

	    {
		    $PlainMac = $EnteredMac
		    $EnteredMac = $EnteredMac.insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-') 
	    }

    elseif ($EnteredMac -like $Mac2) 
    
	    {
		    $PlainMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
    	    $EnteredMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1).insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        }
		
    elseif ($EnteredMac -like $Mac3)
	
	    {
		    $PlainMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
	    }
 
    $DHCPDump = netsh dhcp server $DHCPServer dump
    $searchMac = $DHCPDump | select-string -pattern $EnteredMac -OutVariable FoundMac


    Write-Host "
    Mac Filter Matches:
    ==================
    "


    if (-not $FoundMac) 

	    {
		    $MacFilterStatus = "None"
		    Write-Host -ForegroundColor Red "  NOTICE: No entries were found on either the Allow or Deny DHCP Filter.`n`n`n"
        } 

    else 
	    {
		    $FoundMacArray = $FoundMac.line.split(" ")
		    $FoundMacAddress = $FoundMacArray[7]
		    $MacFilterStatus = $FoundMacArray[6]
		    If ($FoundMacArray[6] -eq "Deny") {$FoundMacColor = "Red"} Else {$FoundMacColor = "Green"}
		    Write-Host -ForegroundColor $FoundMacColor " "$FoundMacArray[6]"         "$FoundMacArray[7] $FoundMacArray[8] $FoundMacArray[9] $FoundMacArray[10] $FoundMacArray[11] $FoundMacArray[12]"`n`n"
	    }

    $searchMac = $DHCPDump | select-string -pattern $PlainMac -OutVariable FoundReservation
	
    Write-Host "
    DHCP Reservation Matches:
    ========================
    "

    if (-not $FoundReservation) 

	    {
	    Write-Host -ForegroundColor Red "  NOTICE: No Reservation in any Scope was found for this MAC address."
    
            } 

    else 
	    {

	    $Result = ($DHCPDump | select-string -pattern $PlainMac).ToString().remove(0,53)
	    Write-Host -ForegroundColor Green $Result

	    }

    Write-Host "

    MAB Object Info:
    ===============
    "

    $PlainMac = $PlainMac.ToLower()
    $MABCheck = Get-ADUser -Filter {sAMAccountName -eq $PlainMac}

    If ($MABCheck -eq $Null) {Write-Host -ForegroundColor Yellow "  NOTICE: This Mac Address DOES NOT have a MAB Object, though they are not always needed.`n"}
    Else {
	    $MABInfo = Get-ADUser -Identity $PlainMac -Properties *
	    $MABLocation = $MABInfo.CanonicalName
	    $MABExpire = $MABInfo.AccountExpirationDate
	    $MABVLAN = (Get-ADPrincipalGroupMembership $PlainMac).name | findstr.exe "MAB"
	    if ($MABVLAN.count -eq 0) { $MABVLAN = (Get-ADPrincipalGroupMembership $PlainMac).name | findstr.exe "VOIP"}
	    $MABPassword = Validate-Account $PlainMac $PlainMac
	    $CurrentDate = (Get-Date)

	    Write-Host -ForegroundColor Green "   NOTICE: A MAB object exists for this MAC Address"

	    Write-Host -ForegroundColor Green "   MAB Location: $MABLocation"

	    If ($MABInfo.Enabled -eq $True) {Write-Host -ForegroundColor Green "   MAB Enabled: True"}
	    Else {Write-Host -ForegroundColor Red "   MAB Enabled: False"}

	    If ($MABInfo.accountExpires -eq 0 -or $MABInfo.accountExpires -eq 9223372036854775807) {Write-Host -ForegroundColor Green "   MAB Expiration: Never Expires"}
	    ElseIf ($MABInfo.AccountExpirationDate -gt $CurrentDate) {Write-Host -ForegroundColor Yellow "MAB Expiration: Not Expired ($MABExpire), should never expire"}
	    Else {Write-Host -ForegroundColor Red "MAB Expiration: Is Expired ($MABExpre)"}

	    If ($MABPassword -eq $True) {Write-Host -ForegroundColor Green "   MAB Password: Password Assignment is Correct`n"}
	    Else {Write-Host -ForegroundColor Red "   MAB Password: Password Assignment is either incorrect, account is disabled, or account is expired`n"}

	    If ($MABVLAN.count -gt 1) { Write-Host -ForegroundColor Red "   WARNING: There are multiple VLAN assignments on this MAB Object, please correct`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}
	    ElseIf ($MABVLAN.count -eq 0) {Write-Host -ForegroundColor Red "   WARNING: There are no VLAN assignments on this MAB Object, please correct`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}
	    Else {Write-Host -ForegroundColor Green "   NOTICE: MAB VLAN assignment appears to be valid but this does not guarantee it is a valid assignment`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}

        }
    $ElevatedUser = $env:username
    $ElevatedGroups = Get-ADPrincipalGroupMembership $ElevatedUser

    # ############################# #
    # MAB Creation and Modification #
    # ############################# #

    If ($ElevatedGroups.name -contains "8021x_Modify_Group_Members")

	    {
		    Write-Host -ForegroundColor Green "`nCongratulations, you are a member of the 8021x_Modify_Group_Members security group!"
		
		    If ($MABCheck -eq $Null -and $ElevatedGroups.name -contains $Elevated_SA_Group) 
		
			    {
				    Write-Host -ForegroundColor Green "`nWelcome Systems Administrator.  MAB Creation mode has been enabled."
				    $MABModifyChoice = Read-Host "`nThere is currently no MAB Object assigned to this MAC address, do you wish to create one? (Y/N)"
				
				    If ($MABModifyChoice -eq "Y")
			
				    {
						    Do
							    {
								    Write-Host -ForegroundColor Red "`n*** WARNING *** - Verify this MAC with HotPan to ensure it is not being added to the wrong network"
								    Write-Host ""
								    Write-Host "1) Computer"
								    Write-Host "2) Cisco Phone"
								    Write-Host "3) Printer"
								    Write-Host "4) Digital Sender"
								    Write-Host "5) Tandberg"
								    Write-Host "6) Temporary ReImage Authorization"
								    Write-Host "7) Other"
								    Write-Host ""
								    $MABType = Read-Host "Please enter the type of MAB you need created"
							    }
						    Until ($MABType -eq 1 -or $MABType -eq 2 -or $MABType -eq 3 -or $MABType -eq 4 -or $MABType -eq 5 -or $MABType -eq 6 -or $MABType -eq 7)
						
						    Switch ($MABType) 
							    {
								    "1" {$MABPath = $MAB_Other_OU; $MabTypeName = "Computer"; $MABPrefix = "MAB_VLAN"}
								    "2" {$MABPath = $MAB_Other_OU; $MabTypeName = "CiscoPhone"; $MABPrefix = "VoIP_VLAN"}
								    "3" {$MABPath = $MAB_Printers_OU; $MabTypeName = "Printer"; $MABPrefix = "MAB_VLAN"}
								    "4" {$MABPath = $MAB_DigitalSenders_OU; $MabTypeName = "Digital Sender"; $MABPrefix = "MAB_VLAN"}
								    "5" {$MABPath = $MAB_Tandbergs_OU; $MabTypeName = "Tandberg"; $MABPrefix = "MAB_VLAN"}
								    "6" {$MABPath = $MAB_Reimage_OU; $MabTypeName = "Computer_10.7_Reimage_Temp"; $MABPrefix = "MAB_VLAN"}
								    "7" {$MABPath = $MAB_Other_OU; $MabTypeName = "Other"; $MABPrefix = "MAB_VLAN"}
							    }
						
						    $MABNewVLAN = Read-Host "Please enter the VLAN you wish to assign this MAB to (Number Only)"
						    $MABName = Read-Host "Please enter the name of the object"
						    $SecurePassword = ConvertTo-SecureString -AsPlainText -String "!*Jf?d)wvS8Ggr@" -Force
						    $MABNewVLANName = "$MABPrefix$MABNewVLAN"
						    $MABDescription = "$MABTypeName, VLAN: $MABNEWVLAN, $MABName"
						    New-ADUser -Name $PlainMac -SamAccountName $PlainMac -UserPrincipalName $PlainMac@$DomainFQDN -AccountPassword $SecurePassword `
						               -AllowReversiblePasswordEncryption $True -PasswordNeverExpires $True -CannotChangePassword $True `
								       -Description $MABDescription -Enabled $True -Path $MABPath -OtherAttributes @{GivenName=$PlainMac;sn=$PlainMac} `
								       -Confirm:$False

						    $PrimaryGroupToken = (Get-ADGroup $MABNewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $MABNewVLANName -Member $PlainMac
						    Set-ADUser -Identity $PlainMac -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    $SecurePasswordNew = ConvertTo-SecureString -AsPlainText -String $PlainMac -Force
						    Set-ADAccountPassword -Identity $PlainMac -Reset -NewPassword $SecurePasswordNew
				    }
	
			    }
				
				
		    ElseIf ($MABCheck -ne $Null)

			    {
		
				    $MABModifyChoice = Read-Host "`nWould you like to change the MAB VLAN Assignment for this MAC Address? (Y/N)"
		
				    If ($MABModifyChoice -eq "Y")
			
					    {
						    Write-Host "`nCurrently $PlainMac is assigned to $MABVLAN"
						    $MABNewVLAN = Read-Host "Please enter the new VLAN you wish to change this to? (Number Only)"
						    $MABTypeSelection = Read-Host "What type of MAB object to you wish to change this to? (MAB/VoIP)"
						    If ($MABTypeSelection -eq "MAB") {$MABPrefix = "MAB_VLAN"}
						    ElseIf ($MABTypeSelection -eq "VoIP") {$MABPrefix = "VOIP_VLAN"}
						    $MABNewVLANName = "$MABPrefix$MABNewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $MABNewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $MABNewVLANName -Member $PlainMac
						    Set-ADUser -Identity $PlainMac -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    Remove-ADgroupMember -Identity $MABVLAN  -Member $PlainMac -Confirm:$False
						    Write-Host "Operation Completed"
					    }
			    }
	    }

    # ###################################### #
    # DHCP Allow / Deny Filter Modifications #
    # ###################################### #

    If ($ElevatedGroups.name -contains $Elevated_SA_Group -or $ElevatedGroups.name -contains $Elevated_IA_Group -or $ElevatedGroups.name -contains $Elevated_NA_Group -or $ElevatedGroups.name -contains $DHCP_Administrator_Group)
	
	    {
		    $MacFilterAddress = $PlainMac
		
		    Write-Host -ForegroundColor Green "`n***Welcome DHCP Administrator***`n"

		    If ($MacFilterStatus -eq "None") 
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was not found on any filter, would you like to add it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Which filter set would you like to add it to? (Allow/Deny)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM: #$FilterAddChoiceITSM"
					    }
				    pause
			    }
	
		    ElseIf ($MacFilterStatus -eq "Allow")
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was found on the Allow Filter, would you like to change it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Would you like to move it to the Deny filter, or remove it from the filter? (Deny/Remove)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						
						    if ($FilterAddChoiceType -eq "Deny")

						    {
							    netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress
							    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM #$FilterAddChoiceITSM"
						    }
						
						    elseif ($FilterAddChoiceType -eq "Remove") {netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress}
					    }
				    pause
			    }

		    ElseIf ($MacFilterStatus -eq "Deny")
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was found on the Deny Filter, would you like to change it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Would you like to move it to the Allow filter, or remove it from the filter? (Allow/Remove)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						
						    if ($FilterAddChoiceType -eq "Allow")

						    {
							    netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress
							    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM #$FilterAddChoiceITSM"
						    }
						
						    elseif ($FilterAddChoiceType -eq "Remove") {netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress}
					    }
				    pause
			    }


	
	    }

}#End Get-MacAddressInfo

function Get-MailboxInfo {

<#
.SYNOPSIS
Counts the Users in the MSExchange Database.
.DESCRIPTION
Counts the Users in the MSExchange Database.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($Username)

    $ErrorActionPreference = "silentlycontinue"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }
    
    `n
    Get-Mailbox $Username | Get-MailboxStatistics | Select DisplayName, Database, ServerName, DatabaseName, LastLoggedOnUserAccount, LastLogonTime, LastLogoffTime, ItemCount, DeletedItemCount, TotalItemSize, TotalDeletedItemSize, StorageLimitStatus, IsValid
    Get-Mailbox $Username | select  DisplayName, Database, OrganizationalUnit, PrimarySmtpAddress, EmailAddresses


    Write-Host "
    Server Side Mailbox Rules
    =========================================================
    "`n

    Get-InboxRule -Mailbox $Username | ft

    Write-Host ""

    Pause


}#End Get-MailboxInfo

function Get-MoveRequestList {

<#
.SYNOPSIS
Gets the move request for a user's mailbox on the Exchange Server.
.DESCRIPTION
Gets the move request for a user's mailbox on the Exchange Server.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Get-MoveRequest | where {$_.SourceDatabase -like "KDHR*" -or $_.TargetDatabase -like "KDHR*"} |
    Get-MoveRequestStatistics | select DisplayName, Alias, Status, SourceDatabase, TargetDatabase, PercentComplete, TotalMailboxSize
    

}#End Get-MoveRequestList

function Get-MoveRequestTable {

<#
.SYNOPSIS
Gets the move request for a user's mailbox on the Exchange Server with Out-GridView.
.DESCRIPTION
Gets the move request for a user's mailbox on the Exchange Server with Out-GridView.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Get-MoveRequest | where {$_.SourceDatabase -like "KDHR*" -or $_.TargetDatabase -like "KDHR*"} |
    Get-MoveRequestStatistics | select Alias, Status, SourceDatabase, TargetDatabase, PercentComplete, TotalMailboxSize |
    Out-GridView

}#End Get-MoveRequestTable

function New-MoveRequest {

<#
.SYNOPSIS
Creates the move request for a user's mailbox on the Exchange Server.
.DESCRIPTION
Creates the move request for a user's mailbox on the Exchange Server.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($Username)

    KDHR-Set-DomainController

    $ErrorActionPreference = "silentlycontinue"

    $DatabasePrefix = "KDHRDB0"
    $DatabaseRandom = Get-Random -InputObject 1, 2, 3, 4, 5

    $DatabaseName = "$DatabasePrefix$DatabaseRandom"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }

    Write-Host "
    ===================================
             User Information
    ===================================
    "

    Get-Mailbox $Username | Select DisplayName, SamAccountName, Database, RecipientTypeDetails | Format-List

    Do {$MoveConfirm = Read-Host -Prompt "Is this the user you want to move to Kandahar? [Y/N]"}
    Until ($MoveConfirm -eq "Y" -or $MoveConfirm -eq "N")

    If ($MoveConfirm -ne "Y") {exit} else {

	    New-MoveRequest -Identity $Username -TargetDatabase $DatabaseName -DomainController $DomainController -BatchName KDHRHD
    }

}#End New-MoveRequest

function Remove-MailboxRecovery {

<#
.SYNOPSIS
This deletes content from the users mailbox dumpster only.
.DESCRIPTION
This deletes content from the users mailbox dumpster only.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Param ($Username)

    Search-Mailbox -Identity $Username -SearchDumpsterOnly -estimateresultonly 

    Search-Mailbox -Identity $Username -SearchDumpsterOnly -DeleteContent

}#End Remove-MailboxRecovery

function Set-MailboxAutoReplyConfiguration {

<#
.SYNOPSIS
Sets the User's MSExchange Automatic Reply.
.DESCRIPTION
Sets the User's MSExchange Automatic Reply.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($Username)

    $ErrorActionPreference = "silentlycontinue"

    $UserCheck = (Get-ADUser $Username).SamAccountName

    If ($Username -eq $Null -or $UserCheck -eq $Null) 
	    {

	    Do 	{
			    $Username = Read-Host -Prompt "Please Enter Valid Username" 
			    $UserCheck = (Get-ADUser $Username).SamAccountName
		    }

	    Until ($Username -ne $Null -and $UserCheck -ne $Null)
	    }

    Get-MailboxAutoReplyConfiguration -Identity $Username

    Set-MailboxAutoReplyConfiguration -Identity $Username -AutoReplyState Disabled -Confirm

}#End Set-MailboxAutoReplyConfiguration

function Set-PSWindowSize {

<#
.SYNOPSIS
Sets the Powershell Window Size.
.DESCRIPTION
Sets the Powershell Window Size.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $pshost = get-host
    $pswindow = $pshost.ui.rawui

    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $newsize.width = 120
    $pswindow.buffersize = $newsize

    $newsize = $pswindow.windowsize
    $newsize.height = 50
    $newsize.width = 120
    $pswindow.windowsize = $newsize

}#End Set-PSWindowSize

function Get-UsageReport {

<#
.SYNOPSIS
Gets the MSExchange Database Overall Usage.
.DESCRIPTION
Gets the MSExchange Database Overall Usage.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>


    $ADUserAccountsKDHR = (Get-ADUser -SearchBase "OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil" -Filter *).count
    $ADUserAccountsKDHQ = (Get-ADUser -SearchBase "OU=HD_KDHQ,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil" -Filter *).count

    $ADUserAccounts = $ADUserAccountsKDHR + $ADUserAccountsKDHQ

    $KDHRDB01Accounts = (Get-Mailbox -Database KDHRDB01 -ResultSize Unlimited).count
    $KDHRDB02Accounts = (Get-Mailbox -Database KDHRDB02 -ResultSize Unlimited).count
    $KDHRDB03Accounts = (Get-Mailbox -Database KDHRDB03 -ResultSize Unlimited).count
    $KDHRDB04Accounts = (Get-Mailbox -Database KDHRDB04 -ResultSize Unlimited).count
    $KDHRDB05Accounts = (Get-Mailbox -Database KDHRDB05 -ResultSize Unlimited).count
    $KDHRVIP01Accounts = (Get-Mailbox -Database KDHRVIP01 -ResultSize Unlimited).count


    $KDHQDB01Accounts = (Get-Mailbox -Database KDHQDB01 -ResultSize Unlimited).count
    $KDHQVIP01Accounts = (Get-Mailbox -Database KDHQVIP01 -ResultSize Unlimited).count


    $ExchangeTotalKDHR = $KDHRDB01Accounts + $KDHRDB02Accounts + $KDHRDB03Accounts + $KDHRDB04Accounts + `
                         $KDHRDB05Accounts + $KDHRVIP01Accounts

    $ExchangeTotalKDHQ = $KDHQDB01Accounts + $KDHQVIP01Accounts

    $ExchangeTotal = $ExchangeTotalKDHR + $ExchangeTotalKDHQ

    Write-Host "

    Total AD User Accounts in KDHR/HD_DSST: $ADUserAccountsKDHR
    Total AD User Accounts in KDHQ/HD_DSST: $ADUserAccountsKDHQ

                    TOTAL AD User Accounts: $ADUserAccounts

    Total Exchange Mailboxes in Use

       -- KDHRDB01             $KDHRDB01Accounts
       -- KDHRDB02             $KDHRDB02Accounts
       -- KDHRDB03             $KDHRDB03Accounts
       -- KDHRDB04             $KDHRDB04Accounts
       -- KDHRDB05             $KDHRDB05Accounts
       -- KDHRVIP01            $KDHRVIP01Accounts

       TOTAL Exchange Mailboxes: $ExchangeTotalKDHR


       -- KDHQDB01             $KDHQDB01Accounts
       -- KDHQVIP01            $KDHQVIP01Accounts

       TOTAL Exchange Mailboxes: $ExchangeTotalKDHQ


       GRAND TOTAL: $ExchangeTotal
    "
}#End Get-UsageReport

function macchecktest {

<#
.SYNOPSIS
Searches Devices by MAC, and can assigns, Security Group, DHCP Allow/Deny/Remove Filter, and MAB Creation.
.DESCRIPTION
Searches Devices by MAC, and can assigns, Security Group, DHCP Allow/Deny/Remove Filter, and MAB Creation.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Param ($EnteredMac)

    . Var-Script-Variables

    $Mac1 = "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"
    $Mac2 = "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]"
    $Mac3 = "[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]"


    Do 	{
	
	    If ($EnteredMac -eq $Null) {$EnteredMac = read-host "Enter a Mac Address"}
	
	    If ($EnteredMac -notlike $Mac1 -and $EnteredMac -notlike $Mac2 -and $EnteredMac -notlike $Mac3)
                
            {
    		    Write-Host "Error: The MAC Address Entered is NOT in the correct format, Please Enter the correct format."
			    $EnteredMac = read-host "Enter a Mac Address"
		    }
        

	    }


    until ($EnteredMac -like $Mac1 -or $EnteredMac -like $Mac2 -or  $EnteredMac -like $Mac3){}


    if ($EnteredMac -like $Mac1) 

	    {
		    $PlainMac = $EnteredMac
		    $EnteredMac = $EnteredMac.insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-') 
	    }

    elseif ($EnteredMac -like $Mac2) 
    
	    {
		    $PlainMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
    	    $EnteredMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1).insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        }
		
    elseif ($EnteredMac -like $Mac3)
	
	    {
		    $PlainMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
	    }
 
    $DHCPDump = netsh dhcp server $DHCPServer dump
    $searchMac = $DHCPDump | select-string -pattern $EnteredMac -OutVariable FoundMac


    Write-Host "
    Mac Filter Matches:
    ==================
    "


    if (-not $FoundMac) 

	    {
		    $MacFilterStatus = "None"
		    Write-Host -ForegroundColor Red "NOTICE: No entries were found on either the Allow or Deny DHCP Filter.`n`n`n"
        } 

    else 
	    {
		    $FoundMacArray = $FoundMac.line.split(" ")
		    $FoundMacAddress = $FoundMacArray[7]
		    $MacFilterStatus = $FoundMacArray[6]
		    If ($FoundMacArray[6] -eq "Deny") {$FoundMacColor = "Red"} Else {$FoundMacColor = "Green"}
		    Write-Host -ForegroundColor $FoundMacColor " "$FoundMacArray[6]"         "$FoundMacArray[7] $FoundMacArray[8] $FoundMacArray[9] $FoundMacArray[10] $FoundMacArray[11] $FoundMacArray[12]"`n`n"
	    }

    $searchMac = $DHCPDump | select-string -pattern $PlainMac -OutVariable FoundReservation
	
    Write-Host "
    DHCP Reservation Matches:
    ========================
    "

    if (-not $FoundReservation) 

	    {
	    Write-Host -ForegroundColor Red "  NOTICE: No Reservation in any Scope was found for this MAC address."
    
            } 

    else 
	    {

	    $Result = ($DHCPDump | select-string -pattern $PlainMac).ToString().remove(0,53)
	    Write-Host -ForegroundColor Green $Result

	    }

    Write-Host "

    MAB Object Info:
    ===============
    "

    $PlainMac = $PlainMac.ToLower()
    $MABCheck = Get-ADUser -Filter {sAMAccountName -eq $PlainMac}

    If ($MABCheck -eq $Null) {Write-Host -ForegroundColor Yellow "  NOTICE: This Mac Address DOES NOT have a MAB Object, though they are not always needed.`n"}
    Else {
	    $MABInfo = Get-ADUser -Identity $PlainMac -Properties *
	    $MABLocation = $MABInfo.CanonicalName
	    $MABExpire = $MABInfo.AccountExpirationDate
	    $MABVLAN = (Get-ADPrincipalGroupMembership $PlainMac).name | findstr.exe "MAB"
	    $MABPassword = Validate-Account $PlainMac $PlainMac
	    $CurrentDate = (Get-Date)

	    Write-Host -ForegroundColor Green "   NOTICE: A MAB object exists for this MAC Address"

	    Write-Host -ForegroundColor Green "   MAB Location: $MABLocation"

	    If ($MABInfo.Enabled -eq $True) {Write-Host -ForegroundColor Green "   MAB Enabled: True"}
	    Else {Write-Host -ForegroundColor Red "   MAB Enabled: False"}

	    If ($MABInfo.accountExpires -eq 0 -or $MABInfo.accountExpires -eq 9223372036854775807) {Write-Host -ForegroundColor Green "   MAB Expiration: Never Expires"}
	    ElseIf ($MABInfo.AccountExpirationDate -gt $CurrentDate) {Write-Host -ForegroundColor Yellow "MAB Expiration: Not Expired ($MABExpire), should never expire"}
	    Else {Write-Host -ForegroundColor Red "MAB Expiration: Is Expired ($MABExpre)"}

	    If ($MABPassword -eq $True) {Write-Host -ForegroundColor Green "   MAB Password: Password Assignment is Correct`n"}
	    Else {Write-Host -ForegroundColor Red "   MAB Password: Password Assignment is either incorrect, account is disabled, or account is expired`n"}

	    If ($MABVLAN.count -gt 1) { Write-Host -ForegroundColor Red "   WARNING: There are multiple VLAN assignments on this MAB Object, please correct`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}
	    ElseIf ($MABVLAN.count -eq 0) {Write-Host -ForegroundColor Red "   WARNING: There are no VLAN assignments on this MAB Object, please correct`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}
	    Else {Write-Host -ForegroundColor Green "   NOTICE: MAB VLAN assignment appears to be valid but this does not guarantee it is a valid assignment`n      MAB VLAN Assignments`n      --------------------`n      $MABVLAN `n"}

        }
    $ElevatedUser = $env:username
    $ElevatedGroups = Get-ADPrincipalGroupMembership $ElevatedUser

    # ############################# #
    # MAB Creation and Modification #
    # ############################# #

    If ($ElevatedGroups.name -contains "8021x_Modify_Group_Members")

	    {
		    Write-Host -ForegroundColor Green "`nCongratulations, you are a member of the 8021x_Modify_Group_Members security group!"
		
		    If ($MABCheck -eq $Null -and $ElevatedGroups.name -contains $Elevated_SA_Group) 
		
			    {
				    Write-Host -ForegroundColor Green "`nWelcome Systems Administrator.  MAB Creation mode has been enabled."
				    $MABModifyChoice = Read-Host "`nThere is currently no MAB Object assigned to this MAC address, do you wish to create one? (Y/N)"
				
				    If ($MABModifyChoice -eq "Y")
			
				    {
						    Do
							    {
								    Write-Host -ForegroundColor Red "`n*** WARNING *** - Verify this MAC with HotPan to ensure it is not being added to the wrong network"
								    Write-Host ""
								    Write-Host "1) Computer"
								    Write-Host "2) Cisco Phone"
								    Write-Host "3) Printer"
								    Write-Host "4) Digital Sender"
								    Write-Host "5) Tandberg"
								    Write-Host "6) Temporary ReImage Authorization"
								    Write-Host "7) Other"
								    Write-Host ""
								    $MABType = Read-Host "Please enter the type of MAB you need created"
							    }
						    Until ($MABType -eq 1 -or $MABType -eq 2 -or $MABType -eq 3 -or $MABType -eq 4 -or $MABType -eq 5 -or $MABType -eq 6 -or $MABType -eq 7)
						
						    Switch ($MABType) 
							    {
								    "1" {$MABPath = $MAB_Other_OU; $MabTypeName = "Computer"}
								    "2" {$MABPath = $MAB_Other_OU; $MabTypeName = "CiscoPhone"}
								    "3" {$MABPath = $MAB_Printers_OU; $MabTypeName = "Printer"}
								    "4" {$MABPath = $MAB_DigitalSenders_OU; $MabTypeName = "Digital Sender"}
								    "5" {$MABPath = $MAB_Tandbergs_OU; $MabTypeName = "Tandberg"}
								    "6" {$MABPath = $MAB_Reimage_OU; $MabTypeName = "Computer_10.7_Reimage_Temp"}
								    "7" {$MABPath = $MAB_Other_OU; $MabTypeName = "Other"}
							    }
						
						    $MABNewVLAN = Read-Host "Please enter the VLAN you wish to assign this MAB to (Number Only)"
						    $MABName = Read-Host "Please enter the name of the object"
						    $SecurePassword = ConvertTo-SecureString -AsPlainText -String "!*Jf?d)wvS8Ggr@" -Force
						    $MABNewVLANName = "MAB_VLAN$MABNewVLAN"
						    $MABDescription = "$MABTypeName, VLAN: $MABNEWVLAN, $MABName"
						    New-ADUser -Name $PlainMac -SamAccountName $PlainMac -UserPrincipalName $PlainMac@$DomainFQDN -AccountPassword $SecurePassword `
						               -AllowReversiblePasswordEncryption $True -PasswordNeverExpires $True -CannotChangePassword $True `
								       -Description $MABDescription -Enabled $True -Path $MABPath -OtherAttributes @{GivenName=$PlainMac;sn=$PlainMac} `
								       -Confirm:$False

						    $PrimaryGroupToken = (Get-ADGroup $MABNewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $MABNewVLANName -Member $PlainMac
						    Set-ADUser -Identity $PlainMac -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    $SecurePasswordNew = ConvertTo-SecureString -AsPlainText -String $PlainMac -Force
						    Set-ADAccountPassword -Identity $PlainMac -Reset -NewPassword $SecurePasswordNew
				    }
	
			    }
				
				
		    Else

			    {
		
				    $MABModifyChoice = Read-Host "`nWould you like to change the MAB VLAN Assignment for this MAC Address? (Y/N)"
		
				    If ($MABModifyChoice -eq "Y")
			
					    {
						    Write-Host "`nCurrently $PlainMac is assigned to $MABVLAN"
						    $MABNewVLAN = Read-Host "Please enter the new VLAN you wish to change this to (Number Only)"
						    $MABNewVLANName = "MAB_VLAN$MABNewVLAN"
						    $PrimaryGroupToken = (Get-ADGroup $MABNewVLANName -Properties primarygrouptoken).primarygrouptoken
						    Add-ADGroupMember -Identity $MABNewVLANName -Member $PlainMac
						    Set-ADUser -Identity $PlainMac -Replace @{primaryGroupID=$PrimaryGroupToken} -Confirm:$False
						    Remove-ADgroupMember -Identity $MABVLAN  -Member $PlainMac -Confirm:$False
						    Write-Host "Operation Completed"
					    }
			    }
	    }

    # ###################################### #
    # DHCP Allow / Deny Filter Modifications #
    # ###################################### #

    If ($ElevatedGroups.name -contains $Elevated_SA_Group -or $ElevatedGroups.name -contains $Elevated_IA_Group -or $ElevatedGroups.name -contains $Elevated_NA_Group -or $ElevatedGroups.name -contains $DHCP_Administrator_Group)
	
	    {
		    $MacFilterAddress = $PlainMac
		
		    Write-Host -ForegroundColor Green "`n***Welcome DHCP Administrator***`n"

		    If ($MacFilterStatus -eq "None") 
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was not found on any filter, would you like to add it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Which filter set would you like to add it to? (Allow/Deny)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM: #$FilterAddChoiceITSM"
					    }
				    pause
			    }
	
		    ElseIf ($MacFilterStatus -eq "Allow")
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was found on the Allow Filter, would you like to change it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Would you like to move it to the Deny filter, or remove it from the filter? (Deny/Remove)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						
						    if ($FilterAddChoiceType -eq "Deny")

						    {
							    netsh dhcp server $DHCPServer v4 delete filter$MacFilterAddress
							    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM #$FilterAddChoiceITSM"
						    }
						
						    elseif ($FilterAddChoiceType -eq "Remove") {netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress}
					    }
				    pause
			    }

		    ElseIf ($MacFilterStatus -eq "Deny")
			
			    {
				    $FilterAddChoice = Read-Host "The MAC Address $MacFilterAddress was found on the Deny Filter, would you like to change it? (Y/N)"
				
				    if ($FilterAddChoice -eq "Y") 
				
					    {
						    $FilterAddChoiceType = Read-Host "Would you like to move it to the Allow filter, or remove it from the filter? (Allow/Remove)"
						    $FilterAddChoiceITSM = Read-Host "Please enter your ITSM ticket number for this transaction"
						
						    if ($FilterAddChoiceType -eq "Allow")

						    {
							    netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress
							    netsh dhcp server $DHCPServer v4 add filter $FilterAddChoiceType $MacFilterAddress "ITSM #$FilterAddChoiceITSM"
						    }
						
						    elseif ($FilterAddChoiceType -eq "Remove") {netsh dhcp server $DHCPServer v4 delete filter $MacFilterAddress}
					    }
				    pause
			    }


	
	    }

}#End macchecktest

function ExchShell {

powershell.exe -noexit -command `
". 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto"

}#ExchShell

function menu {

<#
.SYNOPSIS
This is a Version 1 menu.
.DESCRIPTION
This is a Version 1 menu.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>
    
    cls

    $CurrentUser = (whoami)
    $DomainControllerName = (Get-ADDomainController).Name
    $InfoWhiteSpace = 64 - ($DomainControllerName).length
    $CurrentUserPadded = $CurrentUser.PadLeft($InfoWhiteSpace)
    $Host.UI.RawUI.WindowTitle = "Exch 2010 Management Tool"

    Do 	{
    Write-Host -ForegroundColor Cyan "
    ==================================================================
                   Kandahhar Helpdesk Service Menu               
                                                                          
     Domain Controller                         Currently Logged On As
     $DomainControllerName $CurrentUserPadded
    ==================================================================

    Please select desired operation

    1. Add Exchange Mailbox To New User
    2. Move User Mailbox to Kandahar
    3. Change Users Email Address
    4. Check Kandahar Mailbox Move Queue
    5. Get Information About User Mailbox
    6. Disable User's Mailbox Auto Reply (Out of Office) 
    7. Get Exchange 2010 Database Size Report
    8. Launch Active Directory Users and Computers Console 
    9. Exit to Exchange Powershell Session

    Extree Options

    E. Goto New Extended Menu System (In Development)
    C. Get Computer Object Information
       -- Checks Enabled/Disabled, 802.1x assignment, and Last Used
    D. Gets the Exchange Database statuses and all Exchange Servers
    M. Check Whitelist/Blacklist for MAC Address
    K. Reboot KDHR Workstations
    "
    
    Write-host -ForegroundColor Gray `n"     To exit this menu hold down the Ctrl key and press c" `n
    

    $MainMenuChoice = read-host -prompt "Please Select Desired Option and Press Enter"
	    }until ($MainMenuChoice -eq "1" -or $MainMenuChoice -eq "2" -or $MainMenuChoice -eq "3" -or $MainMenuChoice -eq "4" `
	        -or $MainMenuChoice -eq "5" -or $MainMenuChoice -eq "6" -or $MainMenuChoice -eq "7" -or $MainMenuChoice -eq "8" `
	        -or $MainMenuChoice -eq "9" -or $MainMenuChoice -eq "C" -or $MainMenuChoice -eq "M" -or $MainMenuChoice -eq "E" `
            -or $MainMenuChoice -eq "D" -or $MainMenuChoice -eq "K")

    Switch ($MainMenuChoice) {
    "1" {Enable-Mailbox}
    "2" {New-MoveRequest}
    "3" {Change-EmailAddress}
    "4" {Get-MoveRequestTable}
    "5" {Get-MailboxInfo}
    "6" {Set-MailboxAutoReplyConfiguration}
    "7" {Get-DatabaseSizeReport}
    "8" {dsa.msc /server=$DomainControllerName}
    "9" {Write-Host "";Write-Host -ForegroundColor Magenta `n`n "     Creating new seperate MS Exchange shell" `n`n;
         Write-Host -ForegroundColor Green "Type exit to leave this shell and return to the Main Menu." `n`n;
         ExchShell}
    "C" {Get-ComputerInfo}
    "D" {Get-ExchangeDBHealth}
    "M" {Get-MacAddressInfo}
    "E" {MenuV2}
    "K" {Reboot_Workstations}
    }

    menu

}#End menu

function MenuV2 {

<#
.SYNOPSIS
This is a Version 2 menu.
.DESCRIPTION
This is a Version 2 menu.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>
    
    cls

    $WindowWidth = (get-host).ui.rawui.window.width
    $WindowHeight = (get-host).ui.rawui.window.height
    $BufferWidth = (get-host).ui.rawui.buffersize.width
    $BufferHeight = (get-host).ui.rawui.buffersize.height

    $pshost = get-host
    $PSWindowSize = $pshost.ui.rawui.windowsize
    $PSWindowBuffer = $pshost.ui.rawui.buffersize

    if ($WindowHeight -lt 50) { $pshost.ui.rawui.windowsize.height = 50 }

    if ($WindowWidth -lt 120) { $pshost.ui.rawui.windowsize.width = 120 }

    if ($BufferHeight -lt 3000) { $pshost.ui.rawui.buffersize.height = 3000 }

    $CurrentUser = (whoami)
    $DomainControllerName = (Get-ADDomainController).Name
    $InfoWhiteSpace = 64 - ($DomainControllerName).length
    $CurrentUserPadded = $CurrentUser.PadLeft($InfoWhiteSpace)
    $Host.UI.RawUI.WindowTitle = "Kandahar Extended Helpdesk Operations Menu"
 

    Do 	{
    Write-Host -ForegroundColor Magenta "
    ==================================================================
                    Kandahhar Helpdesk Operations Menu               
                                                                          
     Domain Controller                         Currently Logged On As
     $DomainControllerName$CurrentUserPadded
    ==================================================================
                        Exchange Server Operations
    ==================================================================

     1. Add Exchange Mailbox to New User                         
     2. Move User Mailbox to Kandahar
     3. Change / Correct Users Email Address
     4. Check Kandahar Mailbox Move Queue
     5. Get Information About User Mailbox
     6. Disable User's Mailbox Out of Office Reply
     7. Get List of Allowed Receive Connector IP Addresses
     8. Clear User's Exchange Dumpster
     9. Resolve User List for a Dynamic Distribution Group
    10. Remove Mailbox from a User's Account
    11. Create a Distribution Group
    12. Create Dynamic Distribution Group
    13. Create a Group Mailbox
    ==================================================================
                     Active Directory (AD) Management
    ==================================================================

    21. Launch Active Directory Users and Computers Console
    22. Get Computer Object Information
    23. Get MAC Address Info (White List / MAB Object)

    ==================================================================
                            Other Menu Options
    ==================================================================

    R. Return to the Old Menu
    X. Exit to Powershell

    ==================================================================

    "

    $MainMenuChoice = read-host -prompt "Please Select Desired Option and Press Enter"
	    }until ($MainMenuChoice -eq "1"  -or $MainMenuChoice -eq "2"  -or $MainMenuChoice -eq "3"  -or $MainMenuChoice -eq "4" `
	        -or $MainMenuChoice -eq "5"  -or $MainMenuChoice -eq "6"  -or $MainMenuChoice -eq "7"  -or $MainMenuChoice -eq "8" `
	        -or $MainMenuChoice -eq "9"  -or $MainMenuChoice -eq "10" -or $MainMenuChoice -eq "11" -or $MainMenuChoice -eq "12" `
		    -or $MainMenuChoice -eq "13" -or $MainMenuChoice -eq "21" -or $MainMenuChoice -eq "22" `
		    -or $MainMenuChoice -eq "23" -or $MainMenuChoice -eq "X"  -or $MainMenuChoice -eq "R")

    Switch ($MainMenuChoice) {
    "1" {Enable-Mailbox}
    "2" {New-MoveRequest}
    "3" {Change-EmailAddress}
    "4" {Get-MoveRequestTable}
    "5" {Get-MailboxInfo}
    "6" {Set-MailboxAutoReplyConfiguration}
    "7" {SMTP-AllowList-Connectors}
    "8" {Clear-Dumpster}
    "9" {Resolve-DynamicDistro}
    "10" {Disable-Mailbox}
    "11" {Create-Distribution}
    "12" {Create-DynamicDistribution}
    "13" {Create-OrgBox}
    "21" {dsa.msc /server=$DomainControllerName}
    "22" {Get-ComputerInfo}
    "23" {Get-MacAddressInfo}
    "X" {Write-Host "";Write-Host "Type "menu" to return to this menu.";exit}
    "R" {menu}

    }

    MenuV2

}#End MenuV2

function MenuV3 {

<#
.SYNOPSIS
This is a Version 3 menu.
.DESCRIPTION
This is a Version 3 menu.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $WindowWidth = (get-host).ui.rawui.window.width
    $WindowHeight = (get-host).ui.rawui.window.height
    $BufferWidth = (get-host).ui.rawui.buffersize.width
    $BufferHeight = (get-host).ui.rawui.buffersize.height

    $pshost = get-host
    $PSWindowSize = $pshost.ui.rawui.windowsize
    $PSWindowBuffer = $pshost.ui.rawui.buffersize

    if ($WindowHeight -lt 50) { $pshost.ui.rawui.windowsize.height = 50 }
    if ($WindowWidth -lt 120) { $pshost.ui.rawui.windowsize.width = 120 }
    if ($BufferHeight -lt 3000) { $pshost.ui.rawui.buffersize.height = 3000 }

    $CurrentUser = (whoami)
    $DomainControllerName = (Get-ADDomainController).Name
    $InfoWhiteSpace = 64 - ($DomainControllerName).length
    $CurrentUserPadded = $CurrentUser.PadLeft($InfoWhiteSpace)
    $Host.UI.RawUI.WindowTitle = "Kandahar Extended Helpdesk Operations Menu"

    $message = ""
    $continue = $true

    Do 	{
        Write-Host "
        ==================================================================
                        Kandahhar Helpdesk Operations Menu               
                                                                          
         Domain Controller                         Currently Logged On As
         $DomainControllerName $CurrentUserPadded
        ==================================================================
                            Exchange Server Operations
        ==================================================================

         1. Add Exchange Mailbox to New User                         
         2. Move User Mailbox to Kandahar
         3. Change / Correct Users Email Address
         4. Check Kandahar Mailbox Move Queue
         5. Get Information About User Mailbox
         6. Disable User's Mailbox Out of Office Reply
         7. Get List of Allowed Receive Connector IP Addresses
         8. Clear User's Exchange Dumpster
         9. Resolve User List for a Dynamic Distribution Group
        10. Remove Mailbox from a User's Account
        11. Create a Distribution Group
        12. Create Dynamic Distribution Group
        13. Create a Group Mailbox
        ==================================================================
                         Active Directory (AD) Management
        ==================================================================

        21. Launch Active Directory Users and Computers Console
        22. Get Computer Object Information
        23. Get MAC Address Info (White List / MAB Object)

        ==================================================================
                                Other Menu Options
        ==================================================================

        P. Exit to Powershell
        X. Exit Powershell

        ==================================================================

        "

        $MainMenuChoice = read-host "Please Select Desired Option and Press Enter"

        Switch ($MainMenuChoice) {
            1 {KDHR-Enable-Mailbox}
            2 {KDHR-New-MoveRequest}
            3 {Change-EmailAddress}
            4 {Get-MoveRequestTable}
            5 {Get-MailboxInfo}
            6 {Set-MailboxAutoReplyConfiguration}
            7 {SMTP-AllowList-Connectors}
            8 {ClearDumpster}
            9 {Resolve-DynamicDistro}
            10 {DisableMailbox}
            11 {CreateDistribution}
            12 {CreateDynamicDistribution}
            13 {CreateOrgBox}
            21 {dsa.msc /server=$DomainControllerName}
            22 {KDHR-Get-ComputerInfo}
            23 {KDHR-Get-MacAddressInfo}
            'X' {Write-Host "";Write-Host "Type "menu" to return to this menu.";exit}
            'P' {menuV3}
            default { $message = "Unknown choice, try again!"}
        }
        if ($message -ne "") {
            Write-Warning $message
            Write-Host ""
            $message = ""
        }
    } while ($continue)
    Write-Host "Menu Exit."


}#End MenuV3

function NPSCheck {

<#
.SYNOPSIS
This Checks the NPS Servers.
.DESCRIPTION
This Checks the NPS Servers.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $NPSServers = Get-ADComputer -Filter 'Name -like "*NPSAFGN*"' | Sort-Object Name

    $NPSServers | ForEach-Object { 

	    $ServerName = $_.Name

	    Write-Host ""
	    Write-Host -ForegroundColor White "Querying Server: $ServerName"

	    If (Test-Connection -Computername $ServerName -BufferSize 16 -Count 1 -Quiet) 

		    { 	

		    try

			    {			
	
			    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$ServerName\My","LocalMachine")
			    $store.Open("ReadOnly")
			    $store.Certificates | Select-Object FriendlyName, NotBefore, NotAfter | ft
			
			    }

		    catch [System.Management.Automation.MethodInvocationException]
			
			    {
			
			    Write-Host ""
			    Write-Host -ForegroundColor Yellow "While pingable, access to $ServerName appears to be blocked by a firewall"
			    Write-Host ""
			    Write-Host ""

			    }			

		    }

	    Else

		    {

		    Write-Host ""
		    Write-Host -ForegroundColor Red "$ServerName appears to be Offline (No Ping Response)"
		    Write-Host ""
		    Write-Host ""

		    }
	    }

}#End NPSCheck

function Reset-MABPassword {

<#
.SYNOPSIS
Resets the password for a MAB Object.
.DESCRIPTION
Resets the password for a MAB Object.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($PlainMac)

    $SecurePasswordNew = ConvertTo-SecureString -AsPlainText -String $PlainMac -Force
    Set-ADAccountPassword -Identity $PlainMac -Reset -NewPassword $SecurePasswordNew

}#End Reset-MABPassword

function Resolve-DynamicDistro {

<#
.SYNOPSIS
This tool is supposed to help with finding Distribution Groups. 
.DESCRIPTION
This tool is supposed to help with finding Distribution Groups.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($DistroName)

    $DistroCheck = (Get-DynamicDistributionGroup "$DistroName" -ErrorAction SilentlyContinue).Alias

    If ($DistroName -eq $Null -or $DistroCheck -eq $Null) 

	    {

	    Do 	{
			    $DistroName = Read-Host -Prompt "Please Enter Valid Dynamic Distribution Group Name"
 
			    $DistroCheck = (Get-DynamicDistributionGroup "$DistroName" -ErrorAction SilentlyContinue).Alias
		    }

	    Until ($DistroName -ne $Null -and $DistroCheck -ne $Null)

	    }

    $DistroArray = Get-DynamicDistributionGroup -Identity "$DistroName"

    Get-Recipient -OrganizationalUnit $DistroArray.RecipientContainer -RecipientPreviewFilter $DistroArray.RecipientFilter | select Displayname,PrimarySmtpAddress | out-gridview

}#End Resolve-DynamicDistro

function SAmacQuery {

<#
.SYNOPSIS
This is a MAC only query.
.DESCRIPTION
This is a MAC only query.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>


    $server = "10.206.117.162"

    $uisettings = (Get-Host).UI.RawUI

    $b = $uisettings.WindowSize
    $b.Width = 120
    $b.Height = 40
    $uisettings.WindowSize = $b

    $s = $uisettings.BufferSize
    $s.Width = 120
    $s.Height = 3000
    $uisettings.BufferSize = $s


    #ErrorActionPreference = "silentlycontinue"


    Function MainMenu {

    $testdir = (Test-Path C:\Temp)
    if($testdir -eq $False){mkdir c:\Temp}          
    $results = "C:\temp\FullScopeList.txt"
    $results2 = "C:\temp\TrimmedScopeList.txt"
    $ScopeLeases = "C:\temp\ScopeLeasesdump.txt"


    cls
    #<#
    Write-Host "         
             MAIN MENU
            |--------------------------------------------------------------------------------------------------------|

                          See Available Options Listed Below:
 

                           1: Dump All Scope Leases from DHCP.

                               (Note: Do this once per shift, or if a lot of new hosts pulled new leases from DHCP.)
                               (      Dumping the DHCP Leases is NOT required to search the MAC Filter.            )

      
                           2: Search DHCP Filters by MAC Address.
             |------------------------------------------------------------------------------------------------------|"`n`n`n

 

    Do{
    $choice = read-host "----->   Please type 1 or 2 then press Enter" 
    } until (($choice -like "1") -or ($choice -like "2")){}
    Write-Host ""


    switch ($choice)
        {
            1 {
              $testfile = (Test-Path C:\Temp\ScopeLeasesdump.txt)
              if ($testfile -eq $True){" " | Out-File -Encoding ascii -force -filePath $ScopeLeases}
             #cls
              Write-Host ""`n
              Write-Host "  Please wait while DHCP Scope Information is dumped ...."                 
              netsh dhcp server \\$server show scope | Out-File -Encoding ascii -force -filePath $results
              (Get-Content $results | Select-Object -Skip 5) | Set-Content $results
              (Get-Content $results | Select-Object -skip 3 -last 10000) | Set-Content $results
              Get-Content $results  | foreach-object {$_.Remove(15).trim()} | Out-File -Encoding ascii -force -filePath $results2
              Get-Content $results2 | foreach-object {netsh dhcp server \\$server scope $_ show clients 1 | Out-File -Encoding ascii -append -filePath $ScopeLeases}
	      cls
              . MAC-CompSearch 
              }

            2 {
                cls
                . MAC-CompSearch
              }
        }
        }
    #>

    Function MAC-CompSearch {
    $Mac1 = "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"
    $Mac2 = "[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]"
    $Mac3 = "[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]-[0-9a-fA-F][0-9a-fA-F]"
    $Mac4 = "[0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F]"
    $Mac5 = "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F].[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"
    Do {
    Write-Host ""
    $EnteredMac = read-host "Enter a Mac Address"
    cls
    if ($EnteredMac -notlike $Mac1, $Mac2, $Mac3, $Mac4, $Mac5)
    {
        Write-Host "Error: 'The MAC Address Entered is NOT in the correct format, Please Enter the correct format.'" `n`n`n`n
        }
    }
    until (($EnteredMac -like $Mac1) -or ($EnteredMac -like $Mac2) -or  ($EnteredMac -like $Mac3)-or  ($EnteredMac -like $Mac4)-or  ($EnteredMac -like $Mac5) -or ($EnteredMac -like "cancel"))
          {}
          cls

     $EnteredComp = read-host "       You May Press Enter to continue with provided MAC, but no 802.1x Sec Groups will be shown for the computer.
       
           Enter the Computer Name"

    cls 
    Write-Host "" 
    Write-Host " Please wait while Mac Filters are search for the provided Mac of  '$EnteredMac'  ............." `n`n
        if ($EnteredMac -like $Mac1) {
        $MacForADSearch = $EnteredMac
        $EnteredMac = $EnteredMac.insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        #write-host $EnteredMac
        }
        elseif ($EnteredMac -like $Mac2) 
        {
        $EnteredMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1).insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        $MacForADSearch = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
        #write-host $EnteredMac
        }
        elseif ($EnteredMac -like $Mac3)
        {
        $MacForADSearch = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
        }
        elseif ($EnteredMac -like $Mac4) 
        {
        $EnteredMac = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1).insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        $MacForADSearch = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
        #write-host $EnteredMac
        }
        elseif ($EnteredMac -like $Mac5) 
        {
        $EnteredMac = $EnteredMac.remove(4,1).remove(8,1).insert(2,'-').insert(5,'-').insert(8,'-').insert(11,'-').insert(14,'-')
        $MacForADSearch = $EnteredMac.remove(2,1).remove(4,1).remove(6,1).remove(8,1).remove(10,1)
        #write-host $EnteredMac
        }
    
 
    $searchMac = netsh dhcp server \\$server dump | select-string -pattern $EnteredMac -OutVariable FoundMac
    $searchLeases = get-content $ScopeLeases  | select-string -pattern $EnteredMac -OutVariable FoundLease
    $SearchMAB = get-aduser -Identity $MacForADSearch -outvariable MABResult
    #$SearchComp = get-adcomputer -Identity $EnteredComp

    if ($FoundMac -ne $False){
    cls
    Write-Host " 
          ......................................................................................................
                   ***   NOTE: 'NEVER EXPIRE' and 'INACTIVE' Lease Expirations are RESERVED IP's   ***         
          ======================================================================================================
          | IP Address        Subnet Mask            MAC               Lease Expires      Type       Name      |
          =============      =============   ===================   =====================  ====  ================"
    if (-not $FoundLease){Write-Host "---> No Leases/Reservation Found or DHCP Leases need to be Dumped from Main Menu with Option 1."} 
    else {
    Write-host "--->  $FoundLease"}
                      $FoundLease = ""
          if (-not $MABResult)
         { 

          Write-Host `n " 
    --->  No MAB Object Found!"`n
         }
          else
              { $GetMABInfo = (Get-ADPrincipalGroupMembership $MacForADSearch).name
                Write-host "
    
    --->  MAB Object Found, see below Sec Group Memberships:
                "
                $GetMABInfo
                $GetMABInfo = ""
               }
    if ($EnteredComp -notlike $null) {
    Write-Host "
    --->  802.1x Membership for Computer $EnteredComp :"`n
    $Get1xInfo = (Get-ADPrincipalGroupMembership $EnteredComp$).name
    $Get1xInfo
    $EnteredComp = ""
    }else {}
               
    Write-Host ""
    Write-Host "
           .....................................................................................................
           |  'Filter Info'     'MAC'             'Filter Description'                                         |
           ----------------     ----------------   -------------------------------------------------------------"

    Write-Host "---> $FoundMac".remove(5,42).insert(5,"       ").insert(18,"         ")
          Do {
          Write-Host ""`n 
          $DeleteMac = Read-Host "Type  D  to 'DELETE' the MAC from current Filter and add to another, or type  N  for 'NEW' to start new search"
                       }
                       until(($DeleteMac -like "D") -or ($DeleteMac -like "d") -or ($DeleteMac -like "delete") -or ($DeleteMac -like "N") -or ($DeleteMac -like "n")){}
             
          Switch($DeleteMac)
                     {
                       D {
                          netsh dhcp server \\$Server v4 delete filter $EnteredMac | out-null
                          cls
                          Write-Host "       The Following MAC '$EnteredMac' has been deleted from the DHCP Mac Filter."`n`n`n
                          . AlloworDeny
                         }
                       N {. MainMenu}
                     } 
                 
               
     
    }
         else
         {
            cls
            Write-Host " Mac   '$EnteredMac'   NOT Found in ALLOW or DENY Filters!" `n`n`n
            . AlloworDeny
          } 
    }


 


    Function AlloworDeny {

    Do {
          
              $AddDenyorAllow = read-host "---->  Type 'Allow' or 'Deny' to add  '$EnteredMac'  to the desired Filter, or Type N to start new search"
              cls
              if ($AddDenyorAllow -notlike "Allow", "allow", "Deny", "deny", "N", "n"){
                Write-Host "Error: 'You Must type 'Allow' or 'Deny'. Other entries are invalid.'" `n`n`n`n`
                 }
                }
        until(($AddDenyorAllow -eq "Allow") -or ($AddDenyorAllow -like "allow") -or ($AddDenyorAllow -like "Deny") -or ($AddDenyorAllow -like "deny") -or ($AddDenyorAllow -like "N") -or ($AddDenyorAllow -like "n")){}
        cls
        Switch($AddDenyorAllow){
        Allow {
                  Write-Host "" `n
                  $AllowDesc = read-host "Type a Description for $EnteredMac"
                  cls
                  Do {
                  Write-Host " You are about to add  '$EnteredMac'  with description  '$AllowDesc'  to the  'ALLOW'  Filter."`n`n`n
                  $AllowConfirm = read-host "---> Please Type Y or N"
                  cls
                  if ($AllowConfirm -notlike "Y", "N"){
                    Write-Host ""`n
                    Write-Host "Error: 'You Must type 'Y' or 'N''. Other Characters are invalid.'"
                      }
                    }
                  until(($AllowConfirm -like "Y") -or ($AllowConfirm -like "y") -or ($AllowConfirm -like "N") -or ($AllowConfirm -like "n")){}
                  cls
                  Switch($AllowConfirm){
                        Y {netsh dhcp server \\$Server v4 add filter Allow $EnteredMac "$AllowDesc"
                           start-sleep -Seconds 3
                           . MainMenu
                          }
                        N {. MainMenu}
                        }
                }
        
        Deny  {   Write-Host "" `n
                  $DenyDesc = read-host "Type a Description for $EnteredMac"
                  cls
                  Do {
                    Write-Host "You are about to add  '$EnteredMac'  with description  '$DenyDesc'  to the  'DENY'  Filter" `n`n`n
                   $DenyConfirm = read-host "---> Please Type Y or N"
                    cls
                    if ($DenyConfirm -notlike "Y", "N"){
                    Write-Host ""`n 
                    Write-Host "Error: 'You Must type 'Y' or 'N'. Other Characters are invalid.'"
                     }
                    }
                  until(($DenyConfirm -like "Y") -or ($DenyConfirm -like "y") -or ($DenyConfirm -like "N") -or ($DenyConfirm -like "n")){}
                  cls
                  Switch($DenyConfirm){
                        Y {netsh dhcp server \\$Server v4 add filter Deny $EnteredMac "$AllowDesc"
                           start-sleep -Seconds 3
                           . MainMenu
                          }
                        N {. MainMenu}
                        }
                }
            N   {. MainMenu}
            }
    }
    . MainMenu

}#End SAmacQuery

function SMTP-AllowList-Connectors-001 {

<#
.SYNOPSIS
Gets a list of authorized devices to use SMTP.
.DESCRIPTION
Gets a list of authorized devices to use SMTP.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

Get-ReceiveConnector -id 'KDHRB1AFGN001\AFGHAN Digital Senders*' | select -expand remoteipranges | out-gridview

}#End SMTP-AllowList-Connectors-001

function Validate-Account {

<#
.SYNOPSIS
Validates an account.
.DESCRIPTION
Validates an account.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param ($Username,$Password)
    $Domain = $env:USERDOMAIN

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$Domain
    $pc.ValidateCredentials($UserName,$Password)

}#End Validate-Account

function VerifyAndRepair-SCCMClient {

<#
.SYNOPSIS
Get Computer IP Address, Image Version, & OS Install date, Verify and Repair SCCM Client.
.DESCRIPTION
Retrieves the information for Computer IP Address & Image Version Number with the OS Install Date, Verify and Repair SCCM Client.
Must be run With Elevated User Account.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
.PARAMETER OutFile
Name of the Output File with the complete file path
.EXAMPLE
Get-ComputerImageVersion
This example retrieves the Computer IP Address, Image number and OS install date and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the folder where the script is. "ComputerImageVersion&DateList.Csv" is the default output file name
.EXAMPLE
Check-ElevatedExpDates -OutFile C:\ComputerImageVersion&DateList.Csv
This example retrieves the elevated account information and creates a csv file named "ComputerImageVersion&DateList.Csv"
in the C:\ drive root
#>

    param(
        [string]$OutFile = "c:\temp\Verify SCCM Client.Csv",
        [string]$DomainOU = "OU=Computers,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    )
    BEGIN{
        # delete the old data file and make a new blank file (fails if file is open)
        if (Test-Path $OutFile) {
            Remove-Item $OutFile
        }
        New-Item $OutFile -type file | Out-Null
    }
    PROCESS{
        # get a list of the workstations from Active Directory
        $Computers = (Get-ADComputer -Filter * -Properties Name -SearchBase $DomainOU).Name

        # Begin processing each workstation
        foreach ($Computer in $Computers){

            # Set ALL the varables to "NULL" so they in a known state at the start of working with the workstation
            $PingStatus = "null"
            $model = "null"
            #$OSDate = "null"
            $ip = "null"
            $schedstatus = "null"
            $sccmstatus = "null"
            $sccmstatus = "null"

            # Ping the computer
            if (Test-Connection -ComputerName $Computer -Count 2 -Quiet){
                # Pinging the computer is successful
                $PingStatus = "On line"
                # check the Task Scheduler status
                $schservice = (Get-Service -Name Schedule -ComputerName $Computer)
                $schedstatus = $schservice.Status

                if ($schedstatus -ne "running") {

                    # Try to start the Task Scheduler if not running (DO NOT USE A RESTART HERE)
                    $serviceObj = Get-Service -Name Schedule -ComputerName $Computer
                    Start-Service -InputObject $serviceObj

                    # check if the Task Scheduler restart worked
                    $schservice = (Get-Service -Name Schedule -ComputerName $Computer)
                    if ($schservice.status -eq "running") {
                        $schedstatus = "Restart SUCCESS"
                    }else{
                        $schedstatus = "Restart FAILED!"
                    } # if
                } # if
            
                # see if the WMI is running
                $wmiservice = (Get-Service -Name Winmgmt -ComputerName $Computer)
                $wmistatus = $wmiservice.Status

                if ($wmistatus -ne "running") {

                    # Try to restart the WMI if not running (DO NOT USE A RESTART HERE)
                    $serviceObj = Get-Service -Name winmgmt -ComputerName $Computer 
                    Start-Service -InputObject $serviceObj

                    # check if the WMI restart worked
                    $wmiservice = (Get-Service -Name winmgmt -ComputerName $Computer)
                    if ($wmiservice.status -eq "running") {
                        $wmistatus = "Restart SUCCESS"
                    }else{
                        $wmistatus = "Restart FAILED!"
                    } # if
                } # if

                # see if the SCCM client is installed and running
                $sccmservice = (Get-Service -Name ccmexec -ComputerName $Computer)
                $sccmstatus = $sccmservice.Status
                if ($sccmstatus -ne "running") {

                    # Try to restart the SCCM client if not running
                    $serviceObj = Get-Service -Name ccmexec -ComputerName $Computer 
                    Start-Service -InputObject $serviceObj

                    # check if the SCCM restart worked
                    $sccmservice = (Get-Service -Name ccmexec -ComputerName $Computer)
                    if ($sccmservice.status -eq "running") {
                        $sccmstatus = "Restart SUCCESS"
                    }else{
                        $sccmstatus = "Restart FAILED!"
                    } # if
                } # if

                # get the IP of the computer from the computer
                $ip=Get-WMIObject win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer |
                    Foreach-Object {$_.IPAddress} |Foreach-Object { [IPAddress]$_ } |
                    Where-Object { $_.AddressFamily -eq 'Internetwork' } |
                    Foreach-Object { $_.IPAddressToString } 
 
                try { # read the two reg keys to get the model version
                    $Reg1 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey1= $Reg1.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OEMInformation" )
                    $model1 = $objRegKey1.GetValue("Model")

                    $Reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                    $objRegKey2= $Reg2.OpenSubKey("SOFTWARE\\DOD\\UGM\\ImageRev" )
                    $model2 = $objRegKey2.GetValue("CurrentBuild")

                } catch { # error getting model version
                    $model = "n/a"
                } Finally { # get model version from one of the two reg keys used
                    if ($model1 -ne $null) {
                        $model = $model1
                    } elseIf ($model2 -ne $null) {
                        $model = $model2
                    } else {
                        $model = "unk"
                    }
                } # try

                # In most cases the OS Date is not usefull
                # get OS installed date
                #$os = gwmi win32_operatingsystem -ComputerName $Computer
                #$OSDate = $os.ConvertToDateTime($os.installDate)

            }else{ #if ping not successfull
                $PingStatus = "Off line"
                $model = "n/a"
                #$OSDate = "n/a"
                $ip = "n/a"
                $schedstatus = "n/a"
                $sccmstatus = "n/a"
                $wmistatus = "n/a"
            } # ping

        # output information to CSV file
        $header = @()
        $row = New-Object PSObject
        $row | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value "$Computer"
        $row | Add-Member -MemberType NoteProperty -Name "Status" -Value "$PingStatus"
        $row | Add-Member -MemberType NoteProperty -Name "Task Scheduler" -Value "$schedstatus"
        $row | Add-Member -MemberType NoteProperty -Name "WMI" -Value "$wmistatus"
        $row | Add-Member -MemberType NoteProperty -Name "SCCM Agent" -Value "$sccmstatus"
        $row | Add-Member -MemberType NoteProperty -Name "IP Address" -Value "$ip"
        $row | Add-Member -MemberType NoteProperty -Name "Image" -Value "$model"
        #$row | Add-Member -MemberType NoteProperty -Name "OS Installed Date" -Value "$OSDate"
        $header += $row
        $header | Export-Csv $OutFile -Append -NoTypeInformation
        } # foreach
    } # Process
    END{}

}#End VerifyAndRepair-SCCMClient

function GPUpdate-Computers {

<#
.SYNOPSIS
Utilizes gpupdate for only computer policies
Ensure you have PSEXEC in one of the $env:Path locales.
.DESCRIPTION
Utilizes gpupdate for only computer policies.
Ensure you have PSEXEC in one of the $env:Path locales.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    param (
        [Parameter(Mandatory=$true,
                   Position=0,                          
                   ValueFromPipeline=$true,            
                   ValueFromPipelineByPropertyName=$true)]            
        [String[]]$ComputerNames
    )

    foreach ($ComputerName in $ComputerNames) {

        psexec -accepteula \\$ComputerName -accepteula gpupdate /target:computer

    }#End foreach

}#End GPUpdate-Computers

function Enable-PSRemotingWithPsExec {

<#
.SYNOPSIS
Enables PowerShell Remoting using PSEXEC
Ensure you have PSEXEC in one of the $env:Path locales.
.DESCRIPTION
Enables PowerShell Remoting using PSEXEC
Ensure you have PSEXEC in one of the $env:Path locales.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>
    param (
        [Parameter(Mandatory=$true,
                   Position=0,                          
                   ValueFromPipeline=$true,            
                   ValueFromPipelineByPropertyName=$true)]            
        [String[]]$ComputerNames
    )

    foreach ($ComputerName in $ComputerNames) {

        psexec -accepteula \\$ComputerName "Enable-PSRemoting -Force"

    }#End foreach

}#End Enable-PSRemotingWithPsExec

function Get-MailBoxOverage {

<#
.SYNOPSIS
Gets the statistics of all users' mailboxes.
Must have MS Exchange tools installed to use.
.DESCRIPTION
Gets the statistics of all users' mailboxes.
Must have MS Exchange tools installed to use.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    Get-MailboxStatistics -Database KDHR_OVERSIZED_TEMP | where {$_.ObjectClass –eq “Mailbox”} |
    where {$_.TotalItemSize -lt 250MB} |  Sort-Object TotalItemSize –Descending |
    ft @{label=”User”;expression={$_.DisplayName}},
    @{label=”Total Size (MB)”;expression={$_.TotalItemSize.Value.ToMB()}},
    @{label=”Items”;expression={$_.ItemCount}},@{label=”Storage Limit”;expression={$_.StorageLimitStatus}} -auto

    <#
    Get-MailboxStatistics -Database KDHR_OVERSIZED_TEMP | 
    where {$_.ObjectClass –eq “Mailbox”} | 
    where {$_.TotalItemSize -lt 250MB} | 
    where {$_.disconnectdate -eq $null} | 
    Sort-Object TotalItemSize –Descending 
    #>

}#End Get-MailBoxOverage

function ExchangeRemote {


    #. \\kdhra7afgn005\Exchange2010$\Includes\KDHR-Set-DomainController.ps1
    KDHR-Set-DomainController

    $ExchangServerPrefix = "KDHRB1AFGN00"
    $ExchangeServerID = Get-Random -InputObject 1, 2, 3, 5, 6, 7

    $ExchangeServer = "$ExchangServerPrefix$ExchangeServerID"

    $DSAInvoke = "c:\windows\system32\dsa.msc /server=$DomainController"

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/PowerShell/
    Import-PSSession $Session -AllowClobber

    Write-Host -BackgroundColor DarkGreen -ForegroundColor Yellow `n`n"Your Domain Controller is: $DomainController"`n`n

    <#
    If (Test-Path M:) {Remove-PSDrive -Name "M"}

    New-PSDrive -Name "M" -PSProvider FileSystem -Root "\\kdhra7afgn005\Exchange2010$" -Description "Exchange 2010 Scripts" -Persist

    Set-Location M:

    $env:Path = ".\;" + $env:Path
    
    This scripts $env:Path is set to:

    C:\ProgramData\Oracle\Java\javapath;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPow
    erShell\v1.0\;C:\Program Files\ActivIdentity\ActivClient\;C:\Program Files (x86)\ActivIdentity\ActivClient\;C:\WINDOWS\Sys
    tem32\WindowsPowerShell\v1.0\;C:\Program Files\Tumbleweed\Desktop Validator\;C:\Program Files (x86)\ApproveIt\;C:\Program 
    Files (x86)\ApproveIt\ThirdParty\Bin\;C:\windows\CCM;C:\WINDOWS\System32\Windows System Resource Manager\bin;C:\WINDOWS\Sy
    stem32\Windows System Resource Manager\bin;C:\Program Files\Microsoft\Exchange Server\V14\bin;C:\Program Files\Tumbleweed\
    Desktop Validator\x86

    To find out how to add these to the $env:Path GIMF!
    #>

    menu

}# End ExchangeRemote

function Get-LastLogon {

<#

.SYNOPSIS
This function will list the last user logged on or logged in.
.DESCRIPTION
This function will list the last user logged on or logged in.  It will detect if the user is currently logged on
via WMI or the Registry, depending on what version of Windows is running on the target.  There is some "guess" work
to determine what Domain the user truly belongs to if run against Vista NON SP1 and below, since the function
is using the profile name initially to detect the user name.  It then compares the profile name and the Security
Entries (ACE-SDDL) to see if they are equal to determine Domain and if the profile is loaded via the Registry.
.PARAMETER ComputerName
A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).
.PARAMETER FilterSID
Filters a single SID from the results.  For use if there is a service account commonly used.
.PARAMETER WQLFilter
Default WQLFilter defined for the Win32_UserProfile query, it is best to leave this alone, unless you know what
you are doing.
Default Value = "NOT SID = 'S-1-5-18' AND NOT SID = 'S-1-5-19' AND NOT SID = 'S-1-5-20'"
.EXAMPLE
$Servers = Get-Content "C:\ServerList.txt"
Get-LastLogon -ComputerName $Servers
This example will return the last logon information from all the servers in the C:\ServerList.txt file.
Computer          : SVR01
User              : WILHITE\BRIAN
SID               : S-1-5-21-012345678-0123456789-012345678-012345
Time              : 9/20/2012 1:07:58 PM
CurrentlyLoggedOn : False
Computer          : SVR02
User              : WILIHTE\BRIAN
SID               : S-1-5-21-012345678-0123456789-012345678-012345
Time              : 9/20/2012 12:46:48 PM
CurrentlyLoggedOn : True
.EXAMPLE
Get-LastLogon -ComputerName svr01, svr02 -FilterSID S-1-5-21-012345678-0123456789-012345678-012345
This example will return the last logon information from all the servers in the C:\ServerList.txt file.
Computer          : SVR01
User              : WILHITE\ADMIN
SID               : S-1-5-21-012345678-0123456789-012345678-543210
Time              : 9/20/2012 1:07:58 PM
CurrentlyLoggedOn : False
Computer          : SVR02
User              : WILIHTE\ADMIN
SID               : S-1-5-21-012345678-0123456789-012345678-543210
Time              : 9/20/2012 12:46:48 PM
CurrentlyLoggedOn : True
.LINK
http://msdn.microsoft.com/en-us/library/windows/desktop/ee886409(v=vs.85).aspx
http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx
.NOTES
Author:	 Michael Melonas
Date: 	 "09/20/2015"
Updates: Added FilterSID Parameter
         Cleaned Up Code, defined fewer variables when creating PSObjects
ToDo:    Clean up the UserSID Translation, to continue even if the SID is local
#>

    [CmdletBinding()]
    param(
	    [Parameter(Position=0,ValueFromPipeline=$true)]
	    [Alias("CN","Computer")]
	    [String[]]$ComputerName="$env:COMPUTERNAME",
	    [String]$FilterSID,
	    [String]$WQLFilter="NOT SID = 'S-1-5-18' AND NOT SID = 'S-1-5-19' AND NOT SID = 'S-1-5-20'"
	    )

    Begin
	    {
		    #Adjusting ErrorActionPreference to stop on all errors
		    $TempErrAct = $ErrorActionPreference
		    $ErrorActionPreference = "Stop"
		    #Exclude Local System, Local Service & Network Service
	    }#End Begin Script Block

    Process
	    {
		    Foreach ($Computer in $ComputerName)
			    {
				    $Computer = $Computer.ToUpper().Trim()
				    Try
					    {
						    #Querying Windows version to determine how to proceed.
						    $Win32OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
						    $Build = $Win32OS.BuildNumber
						
						    #Win32_UserProfile exist on Windows Vista and above
						    If ($Build -ge 6001)
							    {
								    If ($FilterSID)
									    {
										    $WQLFilter = $WQLFilter + " AND NOT SID = `'$FilterSID`'"
									    }#End If ($FilterSID)
								    $Win32User = Get-WmiObject -Class Win32_UserProfile -Filter $WQLFilter -ComputerName $Computer
								    $LastUser = $Win32User | Sort-Object -Property LastUseTime -Descending | Select-Object -First 1
								    $Loaded = $LastUser.Loaded
								    $Script:Time = ([WMI]'').ConvertToDateTime($LastUser.LastUseTime)
								
								    #Convert SID to Account for friendly display
								    $Script:UserSID = New-Object System.Security.Principal.SecurityIdentifier($LastUser.SID)
								    $User = $Script:UserSID.Translate([System.Security.Principal.NTAccount])
							    }#End If ($Build -ge 6001)
							
						    If ($Build -le 6000)
							    {
								    If ($Build -eq 2195)
									    {
										    $SysDrv = $Win32OS.SystemDirectory.ToCharArray()[0] + ":"
									    }#End If ($Build -eq 2195)
								    Else
									    {
										    $SysDrv = $Win32OS.SystemDrive
									    }#End Else
								    $SysDrv = $SysDrv.Replace(":","$")
								    $Script:ProfLoc = "\\$Computer\$SysDrv\Documents and Settings"
								    $Profiles = Get-ChildItem -Path $Script:ProfLoc
								    $Script:NTUserDatLog = $Profiles | ForEach-Object -Process {$_.GetFiles("ntuser.dat.LOG")}
								
								    #Function to grab last profile data, used for allowing -FilterSID to function properly.
								    function GetLastProfData ($InstanceNumber)
									    {
										    $Script:LastProf = ($Script:NTUserDatLog | Sort-Object -Property LastWriteTime -Descending)[$InstanceNumber]							
										    $Script:UserName = $Script:LastProf.DirectoryName.Replace("$Script:ProfLoc","").Trim("\").ToUpper()
										    $Script:Time = $Script:LastProf.LastAccessTime
										
										    #Getting the SID of the user from the file ACE to compare
										    $Script:Sddl = $Script:LastProf.GetAccessControl().Sddl
										    $Script:Sddl = $Script:Sddl.split("(") | Select-String -Pattern "[0-9]\)$" | Select-Object -First 1
										    #Formatting SID, assuming the 6th entry will be the users SID.
										    $Script:Sddl = $Script:Sddl.ToString().Split(";")[5].Trim(")")
										
										    #Convert Account to SID to detect if profile is loaded via the remote registry
										    $Script:TranSID = New-Object System.Security.Principal.NTAccount($Script:UserName)
										    $Script:UserSID = $Script:TranSID.Translate([System.Security.Principal.SecurityIdentifier])
									    }#End function GetLastProfData
								    GetLastProfData -InstanceNumber 0
								
								    #If the FilterSID equals the UserSID, rerun GetLastProfData and select the next instance
								    If ($Script:UserSID -eq $FilterSID)
									    {
										    GetLastProfData -InstanceNumber 1
									    }#End If ($Script:UserSID -eq $FilterSID)
								
								    #If the detected SID via Sddl matches the UserSID, then connect to the registry to detect currently loggedon.
								    If ($Script:Sddl -eq $Script:UserSID)
									    {
										    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"Users",$Computer)
										    $Loaded = $Reg.GetSubKeyNames() -contains $Script:UserSID.Value
										    #Convert SID to Account for friendly display
										    $Script:UserSID = New-Object System.Security.Principal.SecurityIdentifier($Script:UserSID)
										    $User = $Script:UserSID.Translate([System.Security.Principal.NTAccount])
									    }#End If ($Script:Sddl -eq $Script:UserSID)
								    Else
									    {
										    $User = $Script:UserName
										    $Loaded = "Unknown"
									    }#End Else

							    }#End If ($Build -le 6000)
						
						    #Creating Custom PSObject For Output
						    New-Object -TypeName PSObject -Property @{
							    Computer=$Computer
							    User=$User
							    SID=$Script:UserSID
							    Time=$Script:Time
							    CurrentlyLoggedOn=$Loaded
							    } | Select-Object Computer, User, SID, Time, CurrentlyLoggedOn
							
					    }#End Try
					
				    Catch
					    {
						    If ($_.Exception.Message -Like "*Some or all identity references could not be translated*")
							    {
								    Write-Warning "Unable to Translate $Script:UserSID, try filtering the SID `nby using the -FilterSID parameter."	
								    Write-Warning "It may be that $Script:UserSID is local to $Computer, Unable to translate remote SID"
							    }
						    Else
							    {
								    Write-Warning $_
							    }
					    }#End Catch
					
			    }#End Foreach ($Computer in $ComputerName)
			
	    }#End Process
	
    End
	    {
		    #Resetting ErrorActionPref
		    $ErrorActionPreference = $TempErrAct
	    }#End End

    

}#End Get-LastLogon

function Get-PendingReboot {

{
<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from either Microsoft Patching or a Software Installation.
    For Windows 2008+ the function will query the CBS registry key as another factor in determining
    pending reboot state.  "PendingFileRenameOperations" and "Auto Update\RebootRequired" are observed
    as being consistant across Windows Server 2003 & 2008.
	
    CBServicing = Component Based Servicing (Windows 2008)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003 / 2008)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendFileRename = PendingFileRenameOperations (Windows 2003 / 2008)

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize
	
    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot
	
    Computer       : WKS01
    CBServicing    : False
    WindowsUpdate  : True
    CCMClient      : False
    PendFileRename : False
    PendFileRenVal : 
    RebootPending  : True
	
    This example will query the local machine for pending reboot information.
	
.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation
	
    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx
	
    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Michael Melonas
    Date:    08/29/2015
    PSVer:   2.0/3.0
    Updated: 05/30/2013
    UpdNote: Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
#>

    [CmdletBinding()]
    param(
	    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	    [Alias("CN","Computer")]
	    [String[]]$ComputerName="$env:COMPUTERNAME",
	    [String]$ErrorLog
	    )

    Begin
	    {
		    # Adjusting ErrorActionPreference to stop on all errors, since using [Microsoft.Win32.RegistryKey]
            # does not have a native ErrorAction Parameter, this may need to be changed if used within another
            # function.
		    $TempErrAct = $ErrorActionPreference
		    $ErrorActionPreference = "Stop"
	    }#End Begin Script Block
    Process
	    {
		    Foreach ($Computer in $ComputerName)
			    {
				    Try
					    {
						    # Setting pending values to false to cut down on the number of else statements
						    $PendFileRename,$Pending,$SCCM = $false,$false,$false
                        
                            # Setting CBSRebootPend to null since not all versions of Windows has this value
                            $CBSRebootPend = $null
						
						    # Querying WMI for build version
						    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer

						    # Making registry connection to the local/remote computer
						    $RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$Computer)
						
						    # If Vista/2008 & Above query the CBS Reg Key
						    If ($WMI_OS.BuildNumber -ge 6001)
							    {
								    $RegSubKeysCBS = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames()
								    $CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"
									
							    }#End If ($WMI_OS.BuildNumber -ge 6001)
							
						    # Query WUAU from the registry
						    $RegWUAU = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
						    $RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
						    $WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
						
						    # Query PendingFileRenameOperations from the registry
						    $RegSubKeySM = $RegCon.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
						    $RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)
						
						    # Closing registry connection
						    $RegCon.Close()
						
						    # If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
						    If ($RegValuePFRO)
							    {
								    $PendFileRename = $true

							    }#End If ($RegValuePFRO)

						    # Determine SCCM 2012 Client Reboot Pending Status
						    # To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
						    $CCMClientSDK = $null
                            $CCMSplat = @{
                                NameSpace='ROOT\ccm\ClientSDK'
                                Class='CCM_ClientUtilities'
                                Name='DetermineIfRebootPending'
                                ComputerName=$Computer
                                ErrorAction='SilentlyContinue'
                                }
                            $CCMClientSDK = Invoke-WmiMethod @CCMSplat
						    If ($CCMClientSDK)
                                {
                                    If ($CCMClientSDK.ReturnValue -ne 0)
							            {
								            Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
                            
							            }#End If ($CCMClientSDK -and $CCMClientSDK.ReturnValue -ne 0)

						            If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
							            {
								            $SCCM = $true

							            }#End If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)

                                }#End If ($CCMClientSDK)
                            Else
                                {
                                    $SCCM = $null

                                }                        
                        
                            # If any of the variables are true, set $Pending variable to $true
						    If ($CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
							    {
								    $Pending = $true

							    }#End If ($CBS -or $WUAU -or $PendFileRename)
							
						    # Creating Custom PSObject and Select-Object Splat
                            $SelectSplat = @{
                                Property=('Computer','CBServicing','WindowsUpdate','CCMClientSDK','PendFileRename','PendFileRenVal','RebootPending')
                                }
						    New-Object -TypeName PSObject -Property @{
								    Computer=$WMI_OS.CSName
								    CBServicing=$CBSRebootPend
								    WindowsUpdate=$WUAURebootReq
								    CCMClientSDK=$SCCM
								    PendFileRename=$PendFileRename
                                    PendFileRenVal=$RegValuePFRO
								    RebootPending=$Pending
								    } | Select-Object @SelectSplat

					    }#End Try

				    Catch
					    {
						    Write-Warning "$Computer`: $_"
						
						    # If $ErrorLog, log the file to a user specified location/path
						    If ($ErrorLog)
							    {
								    Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append

							    }#End If ($ErrorLog)
							
					    }#End Catch
					
			    }#End Foreach ($Computer in $ComputerName)
			
	    }#End Process
	
    End
	    {
		    # Resetting ErrorActionPref
		    $ErrorActionPreference = $TempErrAct
	    }#End End
	
    }#End Function

}#End Get-PendingReboot

function Get-RemoteProgram {

<#
.Synopsis
Generates a list of installed programs on a computer

.DESCRIPTION
This script generates a list by querying the registry and returning the installed programs of a local or remote computer.

.NOTES   
Name: Get-RemoteProgram
Author: Jaap Brasser
Version: 1.0
DateCreated: 2013-08-23
DateUpdated: 2013-08-23
Blog: http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.PARAMETER ComputerName
The computer to which connectivity will be checked

.EXAMPLE
Get-RemoteProgram

Description:
Will generate a list of installed programs on local machine

.EXAMPLE
Get-RemoteProgram -ComputerName server01,server02

Description:
Will generate a list of installed programs on server01 and server02
#>
    #Function Get-RemoteProgram {
        param(
            [CmdletBinding()]
            [string[]]$ComputerName = $env:COMPUTERNAME
        )
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            $RegUninstall = $RegBase.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
            $RegUninstall.GetSubKeyNames() | 
            ForEach-Object {
                $DisplayName = ($RegBase.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_")).GetValue('DisplayName')
                if ($DisplayName) {
                    New-Object -TypeName PSCustomObject -Property @{
                        ComputerName = $Computer
                        ProgramName = $DisplayName
                    }
                }
            }
        }
    

}#End Get-RemoteProgram

function KDHR-Set-DomainController {

<#
.SYNOPSIS
This sets the domain controller. 
.DESCRIPTION
This sets the domain controller.
You will need to change this when you move site to site.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $DomainController = "KDHRA1AFGN010.afghan.swa.ds.army.mil"

}#End KDHR-Set-DomainController

function Start-ExchangeRemoteSession {

<#
.SYNOPSIS
This command executes the ExchangeRemote cmd-let.
.DESCRIPTION
This command executes the ExchangeRemote cmd-let built into this module.
This establishes the MSExchange capability by connecting to an Exchange server,
so that you can execute Exchange cmd-lets.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

# $Credentials = Get-Credential -Message "Enter your ELEVATED username (AFGHAN\username) and password"

Start-Process powershell.exe -ArgumentList `
"-noexit ExchangeRemote" -verb RunAs

}#End Start-ExchangeRemoteSession

function Var-DHCP-Server {

<#
.SYNOPSIS
This sets the DHCP Server.
.DESCRIPTION
This sets the DHCP Server, and you will need to change it from site to site.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $DHCPServer = "\\KDHRA5AFGN04002"

}#End Var-DHCP-Server

function Var-Domain-FQDN {

<#
.SYNOPSIS
This sets the Domain.
.DESCRIPTION
This sets the Domain, and you will need to change it from site to site.
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $DomainFQDN = "afghan.swa.ds.army.mil"

}#End Var-Domain-FQDN

function Var-MAB-OU-Locations {

<#
.SYNOPSIS
This sets the MAB locations for MAB Objects.
.DESCRIPTION
This sets the MAB locations for MAB Objects.
You will need to change it from site to site.
.NOTES
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $KDHR_MAB_Reimage_OU = "OU=MAB_10DOT7_IMAGE,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $KDHR_MAB_DigitalSenders_OU = "OU=MAB_Digital_Senders,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $KDHR_MAB_Other_OU = "OU=MAB_Other,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $KDHR_MAB_Printers_OU = "OU=MAB_Printers,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $KDHR_MAB_Tandbergs_OU = "OU=MAB_Tandberg,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"

}#End Var-MAB-OU-Locations

function Var-Script-Variables {

<#
.SYNOPSIS
This sets all variables for the module's environment.
.DESCRIPTION
This sets all variables including MAB locations, DHCP, Domain FQDN, Security Groups, and OS versions.
.NOTES
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    # ################# #
    # Site OU Locations #
    # ################# #

    $MAB_Reimage_OU = "OU=MAB_10DOT7_IMAGE,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $MAB_DigitalSenders_OU = "OU=MAB_Digital_Senders,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $MAB_Other_OU = "OU=MAB_Other,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $MAB_Printers_OU = "OU=MAB_Printers,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    $MAB_Tandbergs_OU = "OU=MAB_Tandbergs,OU=MAB_Devices,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"

    # ########### #
    # Domain FQDN #
    # ########### #

    $DomainFQDN = "afghan.swa.ds.army.mil"

    # ################### #
    # DHCP Server Address #
    # ################### #

    $DHCPServer = "\\KDHRA5AFGN04002"

    # ############################# #
    # Site Specific Security Groups #
    # ############################# #

    $Elevated_SA_Group = "Site Admin Rights KDHR"
    $Elevated_NA_Group = "KDHR NA Security Group"
    $Elevated_IA_Group = "Site IA Rights KDHR"
    $Elevated_HA_Group = "Helpdesk Admin Rights KDHR"

    $DHCP_Administrator_Group = "KDHR DHCP Administrators"

    # ################################# #
    # Current Image Version Information #
    # ################################# #

    $Current_UGM_Manufacturer = "Unified Golden Master"
    $Current_UGM_Model = "v10.7"

}#End Var-Script-Variables

function Reboot-ExchangeServers {

<#
.SYNOPSIS
This command Reboots Exchange servers individually.
.DESCRIPTION
This command Reboots Exchange servers, and moves the databases safely without corruption.
You will need to edit the Array from site to site.
.NOTES
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $ErrorActionPreference = 'SilentlyContinue'

    [array[]]$list = ('KDHRB1AFGN001','KDHRB1AFGN002','KDHRB1AFGN003','KDHRB1AFGN005','KDHRB1AFGN006','KDHRB1AFGN007')


    $CompListCount = ($list).count

    $MyCurrDir = $PSScriptRoot
    $TimeStamp = (get-date -f g).replace("/","-").replace(":","")
    $ResultsDir = "$MyCurrDir\Results"
    If (!(Get-Item -path $ResultsDir)) {New-Item -Path $ResultsDir -ItemType Directory -Force | out-null}

    $SummaryOutput = @()
    $iprogress = 0


    function ProgressBar 
    {
        if($iprogress -lt $CompListCount) 
        {
         $iprogress++
         $percentage = ($iprogress/$CompListCount*100).ToString('0.00')
         write-progress -activity "Current Operation On $c ...." -status "$percentage %" -percentcomplete ($iprogress/$CompListCount*100)
        }
    } # End of ProgressBar Function


    # Set Datanbase Copy Activation to Policy to unrestrticted so database can be activated
    Write-Host `n`n`n`n`n""
    Write-Host `n`n`n`n"Setting Database Copy Activation Policy to Unrestricted, please wait ..."`n`n`n`n
    Foreach ($c in $list) 
    {
        if($CompListCount -gt 1)
        {
        . ProgressBar
        }
     Set-MailboxServer -Identity $c -DatabaseCopyAutoActivationPolicy Unrestricted | out-Null
    }


    # Start Main Loop
    $iprogress = 0
    foreach ($c in $list) 
    {
    $DatabaseMovedFailed = ""
    $SkipThisComp = ""
    $RestartSuccess = ""
    $PingStatus = ""
    $ExchServices = ""
    $DataBaseCopyHealth = ""
    $DatabaseUnhealthy = ""
    $SecondaryDatabasePreferenceServers = ""
    $RestartAction = ""

        if($CompListCount -gt 1)
        {
        . ProgressBar
        }
           $NewOutPut = New-Object System.Object
           Write-Host -ForegroundColor DarkGreen -BackgroundColor White "$c - Current Server"
	       Move-ActiveMailboxDatabase -Server $c -Confirm:$False
	       Start-sleep -seconds 15
           $DBInformation = Get-MailboxDatabaseCopyStatus -Server $c | ?{$_.Status -eq "Mounted"} | Select DatabaseName,Status
	       $i = 0

		    If ($DBInformation)
		    {
		        Do {
			             $i++
	                     foreach($datab in $DBInformation) 
                         {                    
				          $DBName = ($datab).DatabaseName
                          $DBMounted = ($datab).Status
	                      Write-Host "$c - $DBName  is Still Active, will sleep for 15 seconds, and check again, up to 3 times."
				          Move-ActiveMailboxDatabase -Server $c -Confirm:$False
			              start-sleep -seconds 15
			                  If ($i -gt 2)
                                {
			                      Write-Host "$c - Failed to move active copy of $datab off of Server $c" -ForegroundColor "DarkRed"
						          $DatabaseMovedFailed = $DBName
                                  $SkipThisComp = "Yes"
			                     } 
				         }


	               } until ($i -eq 2)
		     }

             # Goes to the next computer in the outer most foreach loop, acting like a break
             If($SkipThisComp -eq "Yes"){Continue}

            $GetSecondary = Get-MailboxDatabase -Server $c | select -ExpandProperty ActivationPreference | ?{$_.Value -eq 2} | select -ExpandProperty Key | select -ExpandProperty Name    
            if($GetSecondary | foreach {Test-Connection -ComputerName $_ -count 1})
            {
            Write-host "$c -  Starting Reboot, the script will pause up to 5 minutes to allow time to boot."
            Restart-Computer -ComputerName $c -Wait -For WMI -Timeout 300 -Delay 5 -Force

                    $i = 0

                    Do {
                        $i++
                        if ($i -gt 6) {
                                        Write-Host "Server $c never came back online !!!!!"
                                        $PingStatus = "Failing"
                                      }

	                    If (Test-Connection -ComputerName $c -count 1 -buffersize 16 -Quiet) 
                        {
                         Write-Host "$c -  is Back Online ! Will wait for 60 seconds before checking services."
                         $RestartSuccess = "Yes"
                         $PingStatus = "Success"
					     Start-Sleep -Seconds 60
                         $MovingOn = $True				
				 	    } Else { 
						         Write-Host "$c -  is Offline :( , will wait 30 seconds and ping again" -ForegroundColor "Red"
                                 $MovingOn = $False
						         Start-Sleep -Seconds 30	
					            }
	                    } Until ($MovingOn = $True)



                    Write-Host "$c -  Checking Exchange Services, please wait ....."
                    $i = 0
                    Do {
                            $i++
                            $TestHealth = Test-ServiceHealth $c | Select-Object -Expand ServicesNotRunning | select -unique
	                        If ($TestHealth) 
                            {
	                              If ($i -lt 3) 
                                  {
                                       Foreach ($FailedService in $TestHealth)
	                                    {
		                                 Get-Service -ComputerName $c -Name $FailedService | Stop-Service
                                         Start-Sleep -Seconds 10
			                             Get-Service -ComputerName $c -Name $FailedService | Start-Service
	                                    } 
                                   } Else {$ExchServices = $TestHealth}

                            } Else {
                                    $ExchServices = "AllRunning"
                                   }
                    
                        } Until ($i -eq 3)
                        Start-Sleep -Seconds 10


                        Write-Host "$c -  Checking Database Health, please wait ....." 
                        $i = 0
                    Do {
                            $CheckDBs = ""
                            $GetDBNames = Get-MailboxDatabaseCopyStatus -server $c | ?{$_.Status -notmatch "Healthy|Mounted" -or $_.ContentIndexState -ne "Healthy"}
                            $i++
		                    if($GetDBNames)
                            {
                                $GetDBNames = ($GetDBNames).DatabaseName
    		                    Foreach ($DataBs in $GetDBNames)
		                        { 
                                    $CheckDBs = Get-MailboxDatabaseCopyStatus -DatabaseName $DataBs | select-object -expand Status
                                    
		                                    Write-Host "$c - Database $DataBs is Unhealthy, will suspend and resume database copy..."          
                                            If ($i -lt 3) 
                                            {
                                            Suspend-MailboxDatabaseCopy -Identity $DataBs\$c -Confirm:$False
			                                Start-Sleep -Seconds 60
			                                Resume-MailboxDatabaseCopy -Identity $DataBs\$c -Confirm:$False
			                                Start-Sleep -Seconds 30
			                                } Else
                                                   {
                                                    Write-Host "One or More Databases are in a failed state, check the ExchangeRestartResults.csv log." -ForegroundColor "Red"
				                                    $DatabaseUnhealthy = $DbStatus
                                                   }

		                         }
                            } Else {
                                    $DataBaseCopyHealth = "AllHealthy"
                                   }

                        } Until ($i -eq 3)


             } Else  {
                      $SecondaryDatabasePreferenceServers = "Offline"
                      $RestartAction = "Skipped"
                     }
            $NewOutPut | Add-Member -type NoteProperty -name Computer -Value $c
            $NewOutPut | Add-Member -type NoteProperty -name DatabaseMovedFailed -Value $DatabaseMovedFailed
            $NewOutPut | Add-Member -type NoteProperty -name RestartSkipped -Value $SkipThisComp
            $NewOutPut | Add-Member -type NoteProperty -name RestartSuccess -Value $RestartSuccess
            $NewOutPut | Add-Member -type NoteProperty -name PingStatus -Value $PingStatus
            $NewOutPut | Add-Member -type NoteProperty -name ExchServices -Value $ExchServices
            $NewOutPut | Add-Member -type NoteProperty -name DataBaseCopyHealth -Value $DataBaseCopyHealth
		    $NewOutPut | Add-Member -type NoteProperty -name DatabaseUnhealthy -Value $DatabaseUnhealthy
            $NewOutPut | Add-Member -type NoteProperty -name SecondaryDatabasePreferenceServers -Value $SecondaryDatabasePreferenceServers
            $NewOutPut | Add-Member -type NoteProperty -name RestartAction -Value $RestartAction
   		    $SummaryOutput += $NewOutPut
            Write-Host -ForegroundColor DarkGreen -BackgroundColor White "$c -  Completed Reboot Operation."`n`n`n`n
        
    } # End of Main Loop


    # Create Output CSV of Restart Results
    Start-Sleep -Seconds 5
    $SummaryOutput | sort Computer | export-csv -NoTypeInformation -Append -Path "$ResultsDir\ExchangeRestartResults_$TimeStamp.csv"


    # Get DAG Info and Re-Distribute Databases for those DAGs.
    $DagList = @()
    $DatabaseList = @()
    Foreach ($cmp in $list)
    {
    $GetDag = Get-MailboxServer -Identity $cmp | select -expand DatabaseAvailabilityGroup | select -expand Name
    $DagList += $GetDag
    $GetDBList = Get-Mailboxdatabase -server $cmp | Select -expand Name
    $DatabaseList += $GetDBList
    }
    $DagList = $DagList | select -unique
    $DatabaseList = $DatabaseList | select -Unique

    Write-Host "Activating/Moving Databases back to Preferred Servers :"
    Foreach ($data_base in $DatabaseList) {
    $GetPrimary = Get-MailboxDatabase -identity $data_base | select -ExpandProperty ActivationPreference | ?{$_.Value -eq 1} | select -ExpandProperty Key | select -ExpandProperty Name
    if((Get-MailboxDatabase -identity $data_base).ServerName -NotMatch "$GetPrimary") {Move-ActiveMailboxDatabase -Identity $data_base -ActivateOnServer $GetPrimary -mountdialoverride:none -SkipActiveCopyChecks:$true -SkipHealthChecks:$true -skiplagchecks:$true -skipclientExperiencechecks:$true -Confirm:$False}
    }
    # End Get DAG and Re-Distribute Databases


    # Final Database Copy Status Health Check
    $DBHealth = @()
    Write-Host -ForegroundColor Red -BackgroundColor White `n`n`n`n"Final Database Check for all servers :"
    foreach ($computer in $list) 
    {
     $GetDBHealth = Get-MailboxDatabaseCopyStatus -server $computer | Select Name,Status,CopyQueueLength,LastInspectedLogTime,ContentIndexState
     $DBHealth += $GetDBHealth
    }
    
    $DBHealth | FT -AutoSize

    pause

}#End Reboot-ExchangeServers

function Get-ExchangeDBHealth {

<#
.SYNOPSIS
This command checks the Exchange servers current status.
.DESCRIPTION
This command checks the Exchange servers current status.
You will need to edit the Array from site to site.
.NOTES
Script written and modified by Michael Melonas
For assistance, please don't email me.
Last Updated: 06/19/2015 v.2
#>

    $list = ("KDHRB1AFGN001","KDHRB1AFGN002","KDHRB1AFGN003",
    "KDHRB1AFGN005","KDHRB1AFGN006","KDHRB1AFGN007")
    $CompListCount = ($list).count

    #Database Copy Status Health Check
    $DBHealth = @()
    
    Write-Host -ForegroundColor Blue -BackgroundColor Cyan `n`n`n`n"Database Check for all servers :"
    
    foreach ($computer in $list) 
    
    {
     $GetDBHealth = Get-MailboxDatabaseCopyStatus -server $computer |
     Select Name,Status,CopyQueueLength,LastInspectedLogTime,ContentIndexState
     $DBHealth += $GetDBHealth
    }#End foreach

    $DBHealth | FT -AutoSize

    pause

    #menu

}#End Get-ExchangeDBHealth

function E2K10_Architecture_CMD_V2.02 {

####################################################################
# Exchange 2010 Architecture Report
#
# File : E2K10_Architecture_CMD.ps1
# Version : 2.0
# Author : Pascal Theil & Franck Nerot
# Author Mail : skall_21@hotmail.com & fnerot66@hotmail.com
# Creation date : 12/09/2011
# Modification date : 26/10/2011
#
# Exchange 2010
# 
####################################################################

#Argument control
$OK = $null
if ($args.count -eq 1)
    {
        if (($args[0] -ge 2) -and ($args[0] -le 15))
	{
		$OK =$TRUE
		$Threads = $args[0]
		Write-Host "Number of simultaneous jobs: " $Threads
	}
	else
	{
		Write-host -foregroundcolor "red" -backgroundcolor "black" "BAD ARGUMENT.`nUSAGE: <JOBSMAX> value must be between 2 and 15"
	}
    }
else
    {
        Write-host -foregroundcolor "red" -backgroundcolor "black" "ARGUMENT ERROR.`nUSAGE: E2K10_Architecture_V2_CMD <JOBSMAX> where <JOBSMAX> is the maximum simultaneous jobs you want to launch. The value of <JOBSMAX> must be between 2 and 15"
    }

$Snaps = Get-PSSnapin -Registered
	foreach ($Snap in $Snaps)
		{
			if ($Snap.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010")
				{
					$OKSnap = $True
				}
		}
if ($OKSnap -ne $TRUE)
	{
		Write-host -foregroundcolor "red" -backgroundcolor "black" "SNAPIN ERROR.`nExchange 2010 Management Tools not installed on the Local Machine"
	}


if (($OK -eq $TRUE) -and ($OKSnap -eq $TRUE))
    {
        ##########################
		# Initializing variables #
		##########################
		$Mess=""
		$Cancelled = $null

		$labelElapsedTime = ""
		$Begin = $null
		$Stop = $null
		$Filename = $null
		$HTMLFile = $null
		$Final = $null
		$ALLTABLEJOBS = $null
		$ALLTABLEJOBS = @()
		$jobs = $null
		$job = $null
		
		###############	
		# MAIN REGION #
		###############
			
		$begin = Get-Date
		
        $LIST = get-content "$PSScriptRoot\scripts\JobsListCMD.txt"
 
			
				#Removing all current Jobs if needed
				$jobs = Get-Job
				if ($jobs -ne $null)
				{
					$a = 0
				Write-Host  "Clearing old jobs"
					foreach ($job in $jobs)
					{
						$a++
						Write-Progress -Activity "Clearing old jobs" -Status "Progress:" -PercentComplete ($a/$jobs.count*100)
						if ($job.state -eq "Running")
							{
								Stop-Job $job.id
								Remove-Job $job.id
							}
						else
							{
								Remove-Job $job.id
							}						
					}				
				}			
				
				#Generating Report Filename
				$UpOneFolder = "$PSScriptRoot\.."
				$Filename = "$UpOneFolder\Results\Exchange_ArchitectureReport_" + $Begin.Hour + $Begin.Minute + "_" + $Begin.Day + "-" + $Begin.Month + "-" + $Begin.Year + ".htm"
				$jobs = @() 
			
				#Generating HTML Header
				Write-Progress -Activity "Creating Report Header" -Status "Progress:" -PercentComplete (0/1*100)
				Start-Job -Name "Header" -FilePath "$PSScriptRoot\scripts\Header.ps1" | Out-Null
				wait-Job -Name "Header"	| Out-Null
				Write-Progress -Activity "Creating Report Header" -Status "Progress:" -PercentComplete (100)
				$HTMLFile = Receive-Job -Name "Header"
				Remove-Job -Name "Header"
			
				#Creating list of jobs that have been selected
				$a = 0
				foreach ($item in $LIST)
					{
						$a++
						$CurrentTime = Get-Date
								Write-Host $item.ToString()	
								Write-Progress -Activity "Creating list of jobs" -Status "Progress:" -PercentComplete ($a/$LIST.count*100)
								if ($item.ToString() -eq "Active Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Active Directory"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\ActiveDirectory.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
						if ($item.ToString() -eq "Viewing SPN")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Viewing SPN"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\SetSPNView.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Duplicated SPN")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Duplicated SPN"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\SetSPNDupl.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}																		
								if ($item.ToString() -eq "Hardware Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Hardware Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\HardwareInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Disk Report Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Disk Report Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DiskInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Exchange Servers Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Servers Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\ExchangeServersInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}	
								if ($item.ToString() -eq "Exchange Services")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Services"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\ExchangeServices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0	
										$ALLTABLEJOBS += $TABLE		
									}
								if ($item.ToString() -eq "Exchange Rollup (E2K7 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Rollup (E2K7 Only)"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\ExchangeRollupE2K7.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}									
								if ($item.ToString() -eq "Exchange Rollup (E2K10 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Exchange Rollup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\ExchangeRollup.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
										
									}
								if ($item.ToString() -eq "Client Access Server Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASServerInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - OWA Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS OWA"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASOWA.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - WebServices Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS WebServices"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASWebservices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Client Access Server - Autodiscover Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Autodiscover"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASAutodiscover.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Client Access Server - OAB Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS OAB"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASOAB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Client Access Server - ECP Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS ECP"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASECP.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Client Access Server - ActiveSync Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS ActiveSync"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASActiveSync.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}	
								if ($item.ToString() -eq "Client Access Server - Powershell Virtual Directory")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "PowershellVD"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\PowershellVD.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}									
								if ($item.ToString() -eq "Client Access Server - Exchange Certificates")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "CAS Certificates"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\CASCertificates.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "HUB Transport - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "HUB Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\HUBInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "HUB Transport - Back Pressure (E2K10 Only)")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "HUB BackPressure"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\HUBBackPressure.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Network")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Network"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGNetwork.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Replication")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Replication"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGReplication.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
										
									}
								if ($item.ToString() -eq "Database Availability Group - DatabaseCopy")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG DBCopy"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGDBCopy.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE
									}
								if ($item.ToString() -eq "Database Availability Group - Backup")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG Backup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGBackup.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - Database Size and Availability")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG DBSize"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGDBSize.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Database Availability Group - RPCClientAccessServer")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "DAG RPCClientAccessSRV"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\DAGRPCClientAccessServer.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Mailbox Server - Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXInformation.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Database Size and Availability")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX DBSize"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXDBSIZE.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Backup")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Backup"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXBACKUP.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}	
								if ($item.ToString() -eq "Mailbox Server - RPCClientAccessServer")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX RPCClientAccessServer"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXRPCClientAccessServer.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}										
								if ($item.ToString() -eq "Mailbox Server - Offline Address Book")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX OAB"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXOAB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}
								if ($item.ToString() -eq "Mailbox Server - Calendar Repair Assistant")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "MBX Calendar RA"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\MBXCalRepairAssistant.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE											
									}											
								if ($item.ToString() -eq "Public Folder Databases")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "Public Folder Databases"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\PublicFolderDB.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}
								if ($item.ToString() -eq "RPCClientAccess Information")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "RPCClientAccess Information"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\RPCClientAccess.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE		
									}									
								if ($item.ToString() -eq "Test Mailflow")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestMailflow"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestMailflow.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE										
									}
								if ($item.ToString() -eq "Test OWA Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOWAConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestOWAConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test Web Services Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestWSConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\WEBServicesConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test ActiveSync Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestASConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestASConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test ECP Connectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestECPConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestECPConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test MAPI Connectivity - Mailbox and Public Folder Databases")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestMAPIConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestMAPIConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test OutlookConnectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOLConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestOLConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}
								if ($item.ToString() -eq "Test OutlookWebServices")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestOutlookWebServices"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestOutlookWebServices.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}	
								if ($item.ToString() -eq "Test PowershellConnectivity")
									{
										$Text = "Creating job for " + $item.ToString()
										$TABLE = New-Object system.Object
										$TABLE | add-member -membertype NoteProperty -name CheckName -value $item.ToString()
										$TABLE | add-member -membertype NoteProperty -name StatusBar -value $Text
										$TABLE | add-member -membertype NoteProperty -name JobName -value "TestPowershellConnectivity"								
										$TABLE | add-member -membertype NoteProperty -name Filepath -value "$PSScriptRoot\scripts\TestPowershellConnectivity.ps1"
										$TABLE | add-member -membertype NoteProperty -name JOBLoaded -Value 0
										$ALLTABLEJOBS += $TABLE									
									}					
					}
				#Variables initialization for next loop
				$i = 0
				$StillJobsToRun = (@($ALLTABLEJOBS | Where-Object {$_.JOBLoaded -eq 0})).count
				$CurrentThreads = 0
				$jobs = @()
				#Looping While Cancel button is not clicked and all jobs have not been created. At the same time we check for not going beyond the number of maximum defined threads
				while ($StillJobsToRun -gt 0)
					{	
						$Inc = $Threads - $CurrentThreads					
						if ($CurrentThreads -lt $Threads)
							{
								$Max = $i +$Inc
								for ($j = $i ; $j -lt $Max ; $j++)
									{									
										if ($StillJobsToRun -eq 0)
										{										
											break;
										}
										else
										{
											$i++
											$jobs += Start-Job -Name $ALLTABLEJOBS[$j].JobName -FilePath $ALLTABLEJOBS[$j].Filepath
											$ALLTABLEJOBS[$j].JOBLoaded = 1		
											#Next "if" needed to complete the last job because $CompletedJobs is null for the last object
											if ($CompletedJobs -eq $null)
												{
													$CompletedJobs =0
												}
											$StillJobsToRun = (@($ALLTABLEJOBS | Where-Object {$_.JOBLoaded -eq 0})).count
										}
									
									}
								
							}
						$CurrentThreads = (@(Get-Job | Where-Object {$_.state -eq "Running"})).count
						$CompletedJobs = (@(Get-Job | Where-Object {$_.state -eq "Completed"})).count
						Write-Progress -Activity "Work in Progress" -Status "Waiting for running jobs. Jobs still to execute: $StillJobsToRun" -PercentComplete ($CompletedJobs/$LIST.count*100)
						Start-Sleep -Seconds 1
						
					} 
			
			#Waiting for last jobs to finish			
				$jobs = Get-Job| Where-Object{$_.state -eq "Running"}
				while ($jobs -ne $null)
					{
						$CurrentTime = Get-Date		
						$jobs = Get-Job| Where-Object{$_.state -eq "Running"}
						$CompletedJobs = (@(Get-Job | Where-Object {$_.state -eq "Completed"})).count
						$Still = $ALLTABLEJOBS.count - $CompletedJobs
						Start-Sleep 1
						Write-Progress -Activity "Waiting for last jobs to finish" -Status "Jobs still in Running state: $Still" -PercentComplete ($CompletedJobs/$LIST.count*100)
					}
				
				#Retrieving finished jobs
				$jobs = Get-Job | sort ID
				$a = 0
				foreach ($job in $jobs)
					{	
						Write-Progress -Activity "Merging Data" -Status $job.Name -PercentComplete ($a/$LIST.count*100)
						$CurrentTime = Get-Date				
						$Final = receive-job $job.ID
						$HTMLFile += $Final
						Remove-Job $job.ID
					}				
				#Compiling data returned by jobs
				$HTMLFile += Get-Content "$PSScriptRoot\scripts\footer.txt"
				$HTMLFile | out-file -encoding ASCII -filepath $Filename
			
		}

}#End E2K10_Architecture_CMD_V2.02

function ServerHealthCheck {

    mode con:cols=100 lines=40

    $pshost = get-host
    $pswindow = $pshost.ui.rawui
    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $pswindow.buffersize = $newsize

    $GLOBAL:priority="normal"
    $FreePercent = 10

    $ServerList = "$PSScriptRoot\Servers.txt"
    [array[]]$GetServerList = ('KDHRA7AFGNTCF01','KDHRA5AFGN04002','KDHRA4AFGNAWRD1','KDHRA4AFGNAWRD2','KDHRPSAFGNACF01',
    'KDHRA7AFGNCCC01','KDHRA7AFGN007','KDHRA7AFGN302','KDHRA7AFGN004','KDHRA7AFGN005','KDHRVCAFGN006','KDHRVCAFGN007',
    'KDHRPSAFGN550','KDHRNPSAFGN002','KDHRNPSAFGN001','KDHRA7AFGN020','KDHRNMAFGN001','KDHRA4AFGN001','KDHRA7ROLE302',
    'KDHRB1AFGN001','KDHRB1AFGN002','KDHRB1AFGN003','KDHRB1AFGN005','KDHRB1AFGN006','KDHRB1AFGN007','ARNAA5AFGN002',
    'ARNAB1AFGN003','ARNAB1AFGN006','ARNAB1AFGN007','ARNAA7AFGN002','ARNAA7AFGN003','ARNANPSAFGN002','ARNANPSAFGN003',
    'ARNAPSAFGN001','ARNAB6AFGN010','ARNAB6AFGN020')

    
    #Get-Content -path $ServerList
    $results = "$PsScriptRoot\..\Results\Services-DiskSpace.csv"
    $UnPingable = "$PsScriptRoot\..\Results\UnPingable.csv"
    $date | Out-File -FilePath $results



    $ErrorActionPreference = "silentlycontinue"


    $inAry = @($GetServerList)
    if($inAry.count -gt 0)
    {$server = $inAry}


        function checkSystems()
        {   Write-Host "Checking Provided List`n"
            for($i = 0; $i -lt @($Server).count; $i++ ) 
            { $srv = @($Server)[$i]

            write-progress "Checking Server: $srv " -PercentComplete ($i * (100/@($Server).count))
            $status += "`n***$srv***"
            $errcnt = 0
            $error.clear()

            #$srv = "KDHRWKAFGN550BJ"

          (ping -n 1 "$srv").protocoladdress
          if($LASTEXITCODE -eq "1")
                 {
                  $Srv | out-file -Encoding ascii -force -filePath $UnPingable
                  #break
                 }

          else {

                   foreach($drive in(gwmi win32_logicaldisk -computername $srv | where{$_.Drivetype -like "3"}))
                     { if((($drive.freespace/1gb)/($drive.size/1gb) * 100 ) -lt $FreePercent)
                        { $status += "`n`t! Drive: " + $drive.deviceid + " Free Space: " + ($drive.freespace/ 1GB) + " GB" + "  -Less Than 10% Free Space!!"
                          $priority = "high"
                          $errcnt += 1   
                        }
                     }

                    foreach($svc in(gwmi win32_service -computername $srv | where{$_.StartMode -like "Auto" -and $_.name -ne "SysmonLog"}))
                     { if($svc.state -ne "Running")
                         { 
                          $status += "`n`t  Service: " + $svc.DisplayName + " is " + $svc.state
                          $errcnt += 1 
                         }
                     }
                 } 
       
            if($error[0])
                { 
                  foreach($err in $error)
                  { $status += "`n`t`~ " + $err }
                } 
            elseif($errCnt -eq 0)
                { $status += "`tAll Services Running" }
            else {}
            $status | ForEach { "{0}{1}{2}" -f $_,($null),($null) | Out-File -FilePath $results -Append}
            $status
            $status = ""
            }
 
         }

  
    checkSystems
    write-host `n`n
    Write-Host 
    "
    Online Server Results can be found at:

      -->  $results

    Un-reachable Server Results can be found at:

      -->  $UnPingable


    "
    pause

}#End ServerHealthCheck

function StartsAllChecks {


$ScriptPath = "$PSScriptRoot"

$MyPath = "$ScriptPath\Scriptz"

$fileEntries = Get-ChildItem -Force "$MyPath" -Recurse | select-object -ExpandProperty Name
 
foreach ($filesName in $fileEntries) 
 { 

	if ($filesName -like "E2K10_Architecture_CMD_V2.02.ps1")
     		{
      		.$MyPath\$filesName 5
     		}

	elseif ($filesName -like "*.ps1")
     		{
      		.$MyPath\$filesName
     		}
	else {}
 }
 
pause

}#End StartsAllChecks

function ActiveDirectory {

#===================================================================
# Active Directory Information
#===================================================================
#Write-Host "..Active Directory Information"
#start-Transcript -path .\ActiveDirectory.log -append
#$error.clear()
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    $SRVSettings = Get-ADServerSettings
    if ($SRVSettings.ViewEntireForest -eq "False")
	    {
		    Set-ADServerSettings -ViewEntireForest $true
	    }
    #if ($error[0])
    #    {
    #        write-host "Unable to load Exchange 2010 Snap-in"
    #    }
    $adsiteall = Get-ADSite
    $ClassHeaderADS = "heading1"
    foreach($ADSite in $ADSiteAll){
	    $ADsiteName = $adsite.Name
	    $ADSiteHub = $adsite.HubSiteEnabled
	    $ADSitePI = $adsite.PartnerID
	    $ADSiteMPI = $adsite.MinorPartnerID

        $Detailads+=  "					<tr>"
        $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteName)</b></font></td>"
        $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteHub)</b></font></td>"
        $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitePI)</b></font></td>"
        $Detailads+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSiteMPI)</b></font></td>"
        $Detailads+=  "					</tr>"
    }

    $adsitelinkall = Get-ADSitelink
    $ClassHeaderADSlink = "heading1"
    foreach($ADSitelink in $ADSitelinkAll){
	    $ADSitelinkName = $adsitelink.Name
	    $ADsitelinkcost = $adsitelink.ADCost
	    $adsitelinkMMS = $adsitelink.MaxMessageSize
	    $adsitelinkSite = $adsitelink.Sites

        $Detailadslink+=  "					<tr>"
        $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkName)</b></font></td>"
        $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkcost)</b></font></td>"
        $Detailadslink+=  "						<td width='20%'><font color='#0000FF'><b>$($ADSitelinkMMS)</b></font></td>"
        $Detailadslink+=  "						<td width='40%'><font color='#0000FF'><b>$($ADSitelinksite)</b></font></td>"
        $Detailadslink+=  "					</tr>"
    }
	
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderads)'>
            <SPAN class=sectionTitle tabIndex=0>Active Directory Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>ADSite Name</b></font></th>
	  						<th width='20%'><b>HubSiteEnabled</b></font></th>
	  						<th width='20%'><b>PartnerID</b></font></th>
	  						<th width='20%'><b>MinorPartnerID</b></font></th>
	  				</tr>
                    $($Detailads)
                </table>
                <table>
	  				<tr><tr>
	  						<th width='20%'><b>ADSiteLink Name</b></font></th>
	  						<th width='20%'><b>ADCost</b></font></th>
	  						<th width='20%'><b>MaxMessageSize</b></font></th>
	  						<th width='40%'><b>Sites</b></font></th>
					</tr>

                    $($Detailadslink)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>
"@
    Return $Report

}#End ActiveDirectory

function CASActiveSync {

#===================================================================
# Client Access Server - ActiveSync Virtual Directory
#===================================================================
#write-Output "..Client Access Server - ActiveSync Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderASyncVD = "heading1"
$CasSrv = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"}
Foreach ($ASyncVDS in $CasSrv){
$ASyncVDS = Get-ActiveSyncVirtualDirectory -server $ASyncVDS
foreach ($ASyncVD in $ASyncVDS){
		$ASSrv = $ASyncVD.server
		$ASName = $ASyncVD.name
		$ASIURL = $ASyncVD.InternalURL
		$ASIAM = $ASyncVD.InternalAuthenticationMethods		
		$ASEURL = $ASyncVD.ExternalURL
		$ASEAM = $ASyncVD.ExternalAuthenticationMethods			
		
    $DetailASyncVD+=  "					<tr>"
    $DetailASyncVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($ASSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($ASName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($ASIURL)</b></font></td></th>"
    $DetailASyncVD+=  "					</tr>"
    $DetailASyncVD+=  "					<tr>"
    $DetailASyncVD+=  "					<th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($ASIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($ASEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($ASEAM)</b></font></td></th>"
    $DetailASyncVD+=  "					</tr>"
    $DetailASyncVD+=  "					<tr>"
	$DetailASyncVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailASyncVD+=  "					</tr>"	
	}
	}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderASyncVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - ActiveSync Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
						
 		   		</tr>
                $($DetailASyncVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASActiveSync

function CASAutodiscover {

#===================================================================
# Client Access Server - Autodiscover Virtual Directory
#===================================================================
#write-Output "..Client Access Server - Autodiscover Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$AUTOVDS = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"} | Get-AutodiscoverVirtualDirectory
$ClassHeaderAUTOVD = "heading1"
foreach ($AUTOVD in $AUTOVDS){
		$ATDSrv = $AUTOVD.server
		$ATDName = $AUTOVD.name
		$ATDIURL = $AUTOVD.InternalURL
		$ATDIAM = $AUTOVD.InternalAuthenticationMethods		
		$ATDEURL = $AUTOVD.ExternalURL
		$ATDEAM = $AUTOVD.ExternalAuthenticationMethods			
		
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($ATDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($ATDName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($ATDIURL)</b></font></td></th>"
    $DetailAUTOVD+=  "					</tr>"
    $DetailAUTOVD+=  "					<tr>"
    $DetailAUTOVD+=  "				    <th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($ATDIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($ATDEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($ATDEAM)</b></font></td></th>"
    $DetailAUTOVD+=  "					</tr>"
    $DetailAUTOVD+=  "					<tr>"
	$DetailAUTOVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailAUTOVD+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderAUTOVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Autodiscover Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailAUTOVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASAutodiscover

function CASCertificates {

#===================================================================
# Client Access Server - Exchange Certificates
#===================================================================
#write-Output "..Client Access Server - Exchange Certificates"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$Allsrvs = Get-ExchangeServer | where{($_.Name -like "KDHR*") -AND ($_.AdminDisplayVersion.Major -gt "8") -AND ($_.ServerRole -ne "Edge")}
$ClassHeadercert = "heading1"
foreach ($allsrv in $allsrvs){
	$certs = Get-ExchangeCertificate -Server $allsrv
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>SERVER NAME : </b></font><font color='#000080'>$($allsrv)</font></td></th>"
	$DetailCert+=  "					</tr>"
		if($certs -eq $null)
	{
	$ClassHeadercert = "heading10"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"
	$DetailCert+=  "					</tr>"
	}
	else
	{
		foreach ($cert in $certs) {
		$certthumb = $cert.Thumbprint
		$CertDom = $cert.CertificateDomains
		$certserv = $cert.services
		$certAR = $cert.AccessRules
		$certPK = $cert.HasPrivatekey
		$certSSigned = $cert.IsSelfSigned
		$certIss = $cert.Issuer
		$certNA = $cert.NotAfter
		$certNB = $cert.NotBefore
		$certPKS = $cert.PublicKeySize
		$certRoot = $cert.RootCAType
		$certSN = $cert.SerialNumber
		$certstatus = $cert.status
		$certsubj = $cert.subject
    $DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>AccessRules : </b></font><font color='#0000FF'>$($certAR)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"
	$DetailCert+=  "					<th width='20%'><b>Certificate Domains : </b></font><font color='#0000FF'>$($certdom) </font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>HasPrivateKey : </b></font><font color='#0000FF'>$($certPK)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>IsSelfSigned : </b></font><font color='#0000FF'>$($certssigned)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Issuer : </b></font><font color='#0000FF'>$($certIss)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>NotAfter : </b></font><font color='#0000FF'>$($certNA)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>NotBefore : </b></font><font color='#0000FF'>$($certNB)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>PublicKeySize : </b></font><font color='#0000FF'>$($certPKS)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"
	$DetailCert+=  "					<th width='20%'><b>RootCAType : </b></font><font color='#0000FF'>$($certRoot) </font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>SerialNumber : </b></font><font color='#0000FF'>$($certSN)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Services : </b></font><font color='#0000FF'>$($certserv)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Status : </b></font><font color='#0000FF'>$($certstatus)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Subject : </b></font><font color='#0000FF'>$($certsubj)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<tr>"	
	$DetailCert+=  "					<th width='20%'><b>Thumbprint : </b></font><font color='#0000FF'>$($certthumb)</font></td></th>"
	$DetailCert+=  "					</tr>"
	$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$DetailCert+=  "					<tr>"	
	}
	}
	$DetailCert+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$DetailCert+=  "					<tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeadercert)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Exchange Certificates</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                    $($Detailcert)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report

}#End CASCertificates

function CASECP {

#===================================================================
# Client Access Server - ECP Virtual Directory
#===================================================================
#write-Output "..Client Access Server - ECP Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ECPVDS = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"} | Get-ECPVirtualDirectory
$ClassHeaderECPVD = "heading1"
foreach ($ECPVD in $ECPVDS){
		$EPSrv = $ECPVD.server
		$EPName = $ECPVD.name
		$EPIURL = $ECPVD.InternalURL
		$EPIAM = $ECPVD.InternalAuthenticationMethods		
		$EPEURL = $ECPVD.ExternalURL
		$EPEAM = $ECPVD.ExternalAuthenticationMethods			
		
    $DetailECPVD+=  "					<tr>"
    $DetailECPVD+=  "						</b><th width='10%'>Server Name : <font color='#0000FF'>$($EPSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($EPName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($EPIURL)</font></td></th>"
    $DetailECPVD+=  "					</tr>"
    $DetailECPVD+=  "					<tr>"
    $DetailECPVD+=  "						</b><th width='10%'>InternalAuthenticationMethods : <font color='#0000FF'>$($EPIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($EPEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($EPEAM)</font></td></th>"
    $DetailECPVD+=  "					</tr>"
    $DetailECPVD+=  "					<tr>"
	$DetailECPVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailECPVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderECPVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - ECP Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailECPVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASECP

function CASOAB {



#===================================================================
# Client Access Server - OAB Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OAB Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OABVDS = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"} | Get-OABVirtualDirectory
$ClassHeaderOABVD = "heading1"
foreach ($OABVD in $OABVDS){
		$OBSrv = $OABVD.server
		$OBName = $OABVD.name
		$OBIURL = $OABVD.InternalURL
		$OBIAM = $OABVD.InternalAuthenticationMethods		
		$OBEURL = $OABVD.ExternalURL
		$OBEAM = $OABVD.ExternalAuthenticationMethods			
		
    $DetailOABVD+=  "					<tr>"
    $DetailOABVD+=  "					<th width='10%'><b>Server Name : <font color='#0000FF'>$($OBSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OBName)</font><th width='10%'>InternalURL : <font color='#0000FF'>$($OBIURL)</b></font></td></th>"
    $DetailOABVD+=  "					</tr>"
    $DetailOABVD+=  "					<tr>"
    $DetailOABVD+=  "					<th width='10%'><b>InternalAuthenticationMethods : <font color='#0000FF'>$($OBIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($OBEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($OBEAM)</b></font></td></th>"
    $DetailOABVD+=  "					</tr>"
    $DetailOABVD+=  "					<tr>"
	$DetailOABVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOABVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOABVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OAB Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailOABVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASOAB

function CASOWA {



#===================================================================
# Client Access Server - OWA Virtual Directory
#===================================================================
#write-Output "..Client Access Server - OWA Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OWAVDS = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"} | Get-OWAVirtualDirectory 
$ClassHeaderOWAVD = "heading1"
foreach ($OWAVD in $OWAVDS){
		$OVDSrv = $OWAVD.Server
		$OVDName = $OWAVD.name
		$OVDE2K3 = $OWAVD.Exchange2003URL
		$OVDFailb = $OWAVD.FailbackURL
		$OVDInt = $OWAVD.InternalUrl
		$OVDExt = $OWAVD.ExternalUrl
		
    $DetailOWAVD+=  "					<tr>"
    $DetailOWAVD+=  "					</b><th width='10%'>Server Name : <font color='#0000FF'>$($OVDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OVDName)</font><th width='10%'>Exchange2003URL : <font color='#0000FF'>$($OVDE2K3)</font></td></th>"
    $DetailOWAVD+=  "					</tr>"
    $DetailOWAVD+=  "					<tr>"
    $DetailOWAVD+=  "					</b><th width='10%'>FailbackURL : <font color='#0000FF'>$($OVDFailb)</font><th width='10%'>InternalUrl : <font color='#0000FF'>$($OVDInt)</font><th width='10%'>ExternalUrl : <font color='#0000FF'>$($OVDExt)</font></td></th>"
    $DetailOWAVD+=  "					</tr>"
    $DetailOWAVD+=  "					<tr>"
	$DetailOWAVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOWAVD+=  "					</tr>"		
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOWAVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - OWA Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
						
 		   		</tr>
                    $($DetailOWAVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASOWA

function CASServerInformation {

#===================================================================
# Client Access Server Information
#===================================================================
#write-Output "..Client Access Server Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$CASarrays = Get-ClientAccessArray
$ClassHeaderCASarray = "heading1"
foreach($CASarray in $CASarrays) 
{
		$name = $CASArray.name
		$site = $CASArray.site
		$fqdn = $CASArray.fqdn
		$memb = $CASArray.members
    $DetailCASArray+=  "					<tr>"
    $DetailCASArray+=  "						<td width='15%'><font color='#0000FF'><b>$($name)</b></font></td>"
    $DetailCASArray+=  "						<td width='25%'><font color='#0000FF'><b>$($site)</b></font></td>"
    $DetailCASArray+=  "						<td width='20%'><font color='#0000FF'><b>$($fqdn)</b></font></td>"
    $DetailCASArray+=  "						<td width='20%'><font color='#0000FF'><b>$($memb)</b></font></td>"	
    $DetailCASArray+=  "					</tr>"
}
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCASArray)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Client Access Array</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Name</b></font></th>
							<th width='25%'><b>Site</b></font></th>
	  						<th width='20%'><b>FQDN</b></font></th>
	  						<th width='20%'><b>Members</b></font></th>							
	  				</tr>
                    $($DetailCASArray)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
<#
$casuri = Get-ClientAccessServer
$ClassHeaderCASauto = "heading1"
		Foreach ($cas in $casuri)
		{
    $DetailCASAuto+=  "					<tr>"
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'><b>$($cas.name)</b></font></td>"
    $DetailCASAuto+=  "						<td width='40%'><font color='#0000FF'><b>$($cas.AutoDiscoverServiceInternalUri)</b></font></td>"
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'><b>$($cas.AutoDiscoverSiteScope)</b></font></td>"	
    $DetailCASAuto+=  "						<td width='20%'><font color='#0000FF'></font></td>"    
    $DetailCASAuto+=  "					</tr>"
		}
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCASauto)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Autodiscover</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
	  					<th width='40%'><b>AutoDiscoverServiceInternalUri</b></font></th>
						<th width='20%'><b>AutoDiscoverSiteScope</b></font></th>
                        <td width='20%'><font color='#0000FF'></font></td>						
	  				</tr>
                    $($DetailCASauto)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              

"@
#>
Return $Report

}#End CASServerInformation

function CASWebServices {

#===================================================================
# Client Access Server - WebServices Virtual Directory
#===================================================================
#write-Output "..Client Access Server - WebServices Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$WEBSVDS = Get-ClientAccessServer | where-object {$_.Name -like "KDHR*"} | Get-WebServicesVirtualDirectory
$ClassHeaderWEBSVD = "heading1"
foreach ($WEBSVD in $WEBSVDS){
		$WVDSrv = $WEBSVD.server
		$WVDName = $WEBSVD.name
		$WVDIURL = $WEBSVD.InternalURL
		$WVDIAM = $WEBSVD.InternalAuthenticationMethods		
		$WVDEURL = $WEBSVD.ExternalURL
		$WVDEAM = $WEBSVD.ExternalAuthenticationMethods		
		$WVDINLB = $WEBSVD.InternalNLBBypassURL
		
    $DetailWEBSVD+=  "					<tr>"
    $DetailWEBSVD+=  "					</b><th width='10%'>Server Name : <font color='#0000FF'>$($WVDSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($WVDName)</font><th width='10%'>InternalUrl : <font color='#0000FF'>$($WVDIURL)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"
    $DetailWEBSVD+=  "					<tr>"
    $DetailWEBSVD+=  "					</b><th width='10%'>InternalAuthenticationMethods : <font color='#0000FF'>$($WVDIAM)</font><th width='10%'>ExternalURL : <font color='#0000FF'>$($WVDEURL)</font><th width='10%'>ExternalAuthenticationMethods : <font color='#0000FF'>$($WVDEAM)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"	
    $DetailWEBSVD+=  "					<tr>"	
    $DetailWEBSVD+=  "					</b><th width='10%'>InternalNLBBypassURL : <font color='#0000FF'>$($WVDINLB)</font></td></th>"
    $DetailWEBSVD+=  "					</tr>"
	$DetailWEBSVD+=  "					<tr>"	
	$DetailWEBSVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailWEBSVD+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderWEBSVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - WebServices Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                    $($DetailWEBSVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End CASWebServices

function DAGBackup {

#===================================================================
# Database Availability Group - Backup
#===================================================================
#write-Output "..Database Availability Group - Backup"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderDb = "heading1"
$DbList = Get-MailboxDatabase -Status | where {($_.Name -like "KDHR*") -AND $_.Recovery -eq $False -AND $_.ReplicationType -eq "Remote"} | sort Server
foreach ($Db in $DbList)
        {
            $DbServer = $Db.Server
            $DbLastFullBackup = $Db.LastFullBackup
            $DbIdentity  = $Db.Identity
			$DbLastIB = $Db.LastIncrementalBackup
			$DbLastDB = $Db.LastDifferentialBackup
			$DbLastCB = $Db.LastCopyBackup
 #           $FreeSpaceinDB = "{0:N2}" -f ($DB.AvailableNewMailboxSpace.ToBytes() / 1MB)
 #           $DbSize = "{0:N2}" -f ($DB.DatabaseSize.ToBytes() / 1GB)
    $DetailDb+=  "					<tr>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbServer)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbIdentity)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastIB)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastDB)</b></font></td>"
    $DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastCB)</b></font></td>"	
    if($DbLastFullBackup -eq $null)
    {
    $ClassHeaderDb = "heading10"       
	$DetailDb+=  "					<td width='15%'><font color='#FF0000'><b>Never Backuped</b></font></td>"
    $Global:Valid = 0
    }
    else
    {
	$DetailDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbLastFullBackup)</b></font></td>"
	
              if($DbLastFullBackup -gt (Get-Date).adddays(-1))
               {
			   $DetailDb+=  "			<td width='10%'><font color='#0000FF'><b>Valid</b></font></td>"
			   }
               else
               {
                    if($DbLastFullBackup -gt (Get-Date).adddays(-2))
                    {
					$ClassHeaderDb = "heading10" 					 
					$DetailDb+=  "						<td width='10%'><font color='#FF9900'><b>One Day Old</b></font></td>"                       
                    $Global:Valid = 0
                    }
                    else
                    {
					$ClassHeaderDb = "heading10"  
					$DetailDb+=  "						<td width='10%'><font color='#FF0000'><b>More Than 2 Days</b></font></td>"                          
                    $Global:Valid = 0
                    }
                }
    }
				$DetailDb+=  "					</tr>"  
	}

foreach ($Db in $DbList)
        {
            $DbServer = $Db.Server
            $DbSLastFB = $Db.SnapshotLastFullBackup
            $DbIdentity  = $Db.Identity
			$DbSLastIB = $Db.SnapshotLastIncrementalBackup
			$DbSLastDB = $Db.SnapshotLastDifferentialBackup
			$DbSLastCB = $Db.SnapshotLastCopyBackup

    $DetailSDb+=  "					<tr>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbServer)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbIdentity)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastIB)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastDB)</b></font></td>"
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastCB)</b></font></td>"	
    $DetailSDb+=  "						<td width='15%'><font color='#0000FF'><b>$($DbSLastFB)</b></font></td>"	
    $DetailSDb+=  "						<td width='10%'><font color='#0000FF'><b> </b></font></td>"		
	$DetailSDb+=  "					</tr>" 	
}	
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderDb)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Databases Backup Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>LastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>LastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>LastCopyBackup</b></font></th>							
	  						<th width='15%'><b>LastFullBackup</b></font></th>							
	  						<th width='10%'><b>Backup Validity</b></font></th>					
	  				</tr>
                    $($DetailDb)
                </table>
               <table>
	  				<tr>
	  						<br><th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>SnapshotLastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastCopyBackup</b></font></th>							
	  						<th width='15%'><b>SnapshotLastFullBackup</b></font></th>	
	  						<th width='10%'><b> </b></font></th>								
	  				</tr>
                    $($DetailSDb)
                </table>				
            </div>
        </div>
        <div class='filler'></div>
    </div>                     
"@
Return $Report

}#End DAGBackup

function DAGDBCopy {

#===================================================================
# Database Availability Group - DatabaseCopy
#===================================================================
#write-Output "..Database Availability Group - DatabaseCopy"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderDatabase = "heading1"

$MDCSCSS = get-mailboxserver | where-object{($_.Name -like "KDHR*") -AND $_.AdminDisplayVersion.major -eq "14" -AND $_.DatabaseAvailabilityGroup -ne $null} | Get-MailboxDatabaseCopyStatus -ConnectionStatus | ?{$_.activecopy -eq "True"}
$ClassHeaderConstatus = "heading1"
foreach($MDCSCS in $MDCSCSS)
{
		$MDCSN = $MDCSCS.Name
		$MDCSStatus = $MDCSCS.Status
		$MDCSDC = $MDCSCS.ActiveDatabaseCopy
		$MDCSAS = $MDCSCS.ActivationSuspended
		$MDCSOC = $MDCSCS.OutgoingConnections
	$DetailConstatus+=  "						<tr>"
    $DetailConstatus+=  "						<td width='25%'><font color='#0000FF'><b>$($MDCSN)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSStatus)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSDC)</b></font></td>"	
    $DetailConstatus+=  "						<td width='15%'><font color='#0000FF'><b>$($MDCSAS)</b></font></td>"	
    $DetailConstatus+=  "						<td width='30%'><font color='#0000FF'><b>$($MDCSOC)</b></font></td>"	
    $DetailConstatus+=  "						</tr>"
}
$MailboxDatabasesList = (Get-MailboxDatabase -status | where-object{($_.Name -like "KDHR*") -AND $_.ReplicationType -eq "Remote"} | sort Name | Get-MailboxDatabaseCopyStatus)
 foreach($Database in $MailboxDatabasesList)
               {
                $Server = $Database.MailboxServer
                $DBName = $Database.DatabaseName
				$index = $Database.ContentIndexState
                $CopyQueueLength = $Database.CopyQueueLength
                $ReplayQueueLength = $Database.ReplayQueueLength
                $ActiveCopy = $Database.ActiveCopy.ToString()
                $ResultStatus = $Database.Status.ToString()
                if($CopyQueueLength -lt 10)
                           {
                       $Color2 = "#0000FF"
                           }
                else
                           {
                       $ClassHeaderDatabase = "heading10"
		       $Color2 = "#FF9900"
                           }
 
                if($ReplayQueueLength -lt 1)
                           {
                       $Color3 = "#0000FF"
                           }
                else
                           {
                       $ClassHeaderDatabase = "heading10"
		       $Color3 = "#FF9900"
                           }
    
                if(($ResultStatus -eq "Mounted") -or ($ResultStatus -eq "Healthy"))
                   {
                      $Color1 = "#0000FF"
                           }
                else
                           {
                      $ClassHeaderDatabase = "heading10"
		      $Global:Valid = 0
                      $Color1 = "#FF0000"
                           } 
             if($index -eq "Healthy")
                   {
                      $Color4 = "#0000FF"
                           }
                else
                           {
                      $ClassHeaderDatabase = "heading10"
					  $Global:Valid = 0
                      $Color4 = "#FF0000"
                           }      						   
 
            #$Error = $Database.Error
	$DetailDatabase+=" 					<tr>"
	$DetailDatabase+="  				<td width='20%'><font color='#0000FF'><b>$($server)</b></font></td>"
	$DetailDatabase+="					<td width='20%'><font color='#0000FF'><b>$($DBName)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color='#0000FF'><b>$($ActiveCopy)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color1)><b>$($ResultStatus)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color2)><b>$($CopyQueueLength)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color3)><b>$($ReplayQueueLength)</b></font></td>"
	$DetailDatabase+="					<td width='15%'><font color=$($Color4)><b>$($index)</b></font></td>"
	$DetailDatabase+=" 					</tr>"
								}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderDatabase)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Mailbox Database Copy Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
			<table>
	  				<tr>
	  						<th width='25%'><b>Name</b></font></th>
							<th width='15%'><b>Status</b></font></th>
							<th width='15%'><b>ActiveDatabaseCopy</b></font></th>
							<th width='15%'><b>ActivationSuspended</b></font></th>
							<th width='30%'><b>OutgoingConnections</b></font></th>
					</tr>
             $($DetailConStatus)
             </table>
             <table>
	  				<tr>
	  						<br><th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>Active Copy</b></font></th>
	  						<th width='15%'><b>State</b></font></th>
							<th width='10%'><b>Copy Queue Length</b></font></th>
	  						<th width='10%'><b>Replay Queue Length</b></font></th>	
	  						<th width='10%'><b>Content Index State</b></font></th>						
	  				</tr>
                    $($DetailDatabase)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report

}#End DAGDBCopy

function DAGDBSize {

#===================================================================
# Database Availability Group - Database Size and Availability
#===================================================================
#write-Output "..Database Availability Group - Database Size and Availability"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DBsizes = Get-MailboxDatabase -status | where-object{$_.Name -like "KDHR*" -AND $_.ReplicationType -eq "Remote"} | sort Name
$ClassHeaderDBsize = "heading1"
foreach ($DBsize in $DBsizes){
		$DBname = $DBsize.Name
		$DBSrv = $DBsize.Server
		$DataBSize = $DBsize.DatabaseSize
		$DbANMS = $DBsize.AvailableNewMailboxSpace
		$DbDMRC = $DBsize.DataMoveReplicationConstraint
    $DetailDBsize+=  "					<tr>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBSrv)</b></font></td>"	
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DataBsize)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBANMS)</b></font></td>"
    $DetailDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DbDMRC)</b></font></td>"	
    $DetailDBsize+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDBsize)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Database Size and Availability</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='20%'><b>Server Name</b></font></th>							
							<th width='20%'><b>Database Size</b></font></th>
							<th width='20%'><b>AvailableNewMailboxSpace</b></font></th>
							<th width='20%'><b>DataMoveReplicationConstraint</b></font></th>							
 		   		</tr>
                    $($DetailDBsize)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
"@
Return $Report

}#End DAGDBSize

function DAGInformation {

#===================================================================
# Database Availability Group - Information
#===================================================================
#write-Output "..Database Availability Group - Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DAGS = Get-DatabaseAvailabilityGroup -Status | where-object {$_.Name -like "KDHR*"}
$ClassHeaderDAG = "heading1"
Foreach($DAG in $DAGS){
		$DAGname = $DAG.Name
		$DAGServer = $DAG.Servers
		$DAGpam = $DAG.PrimaryActiveManager
		$DAGdac = $DAG.DatacenterActivationMode
		$DAGNet = $DAG.DatabaseAvailabilityGroupIpAddresses
		$DAGRPort = $DAG.ReplicationPort
    $DetailDAG+=  "					<tr>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGName)</b></font></td>"
    $DetailDAG+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGServer)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGpam)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGdac)</b></font></td>"
    $DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNet)</b></font></td>"	
	$DetailDAG+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGRPort)</b></font></td>"	
    $DetailDAG+=  "					</tr>"
		$DAGWS = $DAG.WitnessServer
		$DAGWD = $DAG.WitnessDirectory
		$DAGAWS = $DAG.AlternateWitnessServer
		$DAGAWD = $DAG.AlternateWitnessDirectory		
    $DetailDAG2+=  "					<tr>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGWS)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGWD)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGAWS)</b></font></td>"
    $DetailDAG2+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGAWD)</b></font></td>"
    $DetailDAG2+=  "					</tr>"
		$DAGNC = $DAG.NetworkCompression
		$DAGNE = $DAG.NetworkEncryption
		$DAGNetName = $DAG.NetworkNames	
    $DetailDAG3+=  "					<tr>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNC)</b></font></td>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNE)</b></font></td>"
    $DetailDAG3+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNetName)</b></font></td>"
    $DetailDAG3+=  "					</tr>"
}
$DAGMBXS = Get-MailboxServer -Status | where-object{($_.Name -like "KDHR*") -AND $_.DatabaseAvailabilityGroup -ne $null}
$ClassHeaderADM = "heading1"
foreach($DAGMBX in $DAGMBXS){
		$DAGMBXN = $DAGMBX.Name
		$DAGMBXADM = $DAGMBX.AutoDatabaseMountDial
		$DAGMBXDAG = $DAGMBX.DatabaseAvailabilityGroup
		$DAGMBXDCAP = $DAGMBX.DatabaseCopyAutoActivationPolicy
		$DAGMBXMAD = $DAGMBX.MaximumActiveDatabases
    $DetailADM+=  "					<tr>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXN)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXADM)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXDAG)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXDCAP)</b></font></td>"
    $DetailADM+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGMBXAD)</b></font></td>"	
    $DetailADM+=  "					</tr>"
}	
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDAG)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>DAG Name</b></font></th>
							<th width='20%'><b>Servers</b></font></th>
							<th width='10%'><b>P.A.M.</b></font></th>
							<th width='10%'><b>DAC Mode</b></font></th>
							<th width='10%'><b>Network IP</b></font></th>
							<th width='10%'><b>Replication Port</b></font></th>
					</tr>
                    $($DetailDAG)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>Witness Server</b></font></th>
							<th width='20%'><b>Witness Directory</b></font></th>
							<th width='20%'><b>Alternate Witness Server</b></font></th>
							<th width='20%'><b>Alternate Directory</b></font></th>
 		   		</tr>
                    $($DetailDAG2)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>NetworkCompression</b></font></th>
							<th width='20%'><b>NetworkEncryption</b></font></th>
							<th width='20%'><b>NetworkNames</b></font></th>
 		   		</tr>
                    $($DetailDAG3)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>AutoDatabaseMountDial</b></font></th>
							<th width='20%'><b>DatabaseAvailabilityGroup</b></font></th>
							<th width='20%'><b>DatabaseCopyAutoActivationPolicy</b></font></th>
							<th width='20%'><b>MaximumActiveDatabases</b></font></th>
					</tr>
                    $($DetailADM)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report

}#End DAGInformation

function DAGNetwork {

#===================================================================
# Database Availability Group - Network
#===================================================================
#write-Output "..Database Availability Group - Network"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DAGNWKS = Get-DatabaseAvailabilityGroupNetwork | where-object {$_.Name -like "KDHR*"}
$ClassHeaderDAGNetworks = "heading1"
foreach($DAGNetwork in $DAGNWKS)
{
    	$DAGNWN = $DAGNetwork.Identity
		$DAGNWSub = $DAGNetwork.Subnets
		$DAGNWMAPI = $DAGNetwork.MapiAccessEnabled
		$DAGNWRE = $DAGNetwork.ReplicationEnabled	
		$DAGNWIN = $DAGNetwork.IgnoreNetwork
		$DAGNWInterf = $DAGNetwork.Interfaces
	$DetailDAGNetworks+=  "					<tr>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWN)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='15%'><font color='#0000FF'><b>$($DAGNWSub)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWMAPI)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWRE)</b></font></td>"
    $DetailDAGNetworks+=  "						<td width='10%'><font color='#0000FF'><b>$($DAGNWIN)</b></font></td>"	
	$DetailDAGNetworks+=  "						<td width='20%'><font color='#0000FF'><b>$($DAGNWInterf)</b></font></td>"	
    $DetailDAGNetworks+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderDAGNetworks)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Network</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>Identity</b></font></th>
							<th width='15%'><b>Subnets</b></font></th>
							<th width='10%'><b>MapiAccessEnabled</b></font></th>
							<th width='10%'><b>ReplicationEnabled</b></font></th>
							<th width='10%'><b>IgnoreNetwork</b></font></th>
							<th width='20%'><b>Interfaces</b></font></th>
					</tr>
                    $($DetailDAGNetworks)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
 
"@
Return $Report

}#End DAGNetwork

function DAGReplication {

#===================================================================
# Database Availability Group - Replication
#===================================================================
#write-Output "..Database Availability Group - Replication"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRepl = "heading1"
$DBReplication = (Get-MailboxServer | where{($_.Name -like "KDHR*") -AND $_.AdminDisplayVersion.Major -ge 14 -AND $_.DatabaseAvailabilityGroup -ne $null} | sort server | Test-ReplicationHealth)
Foreach($Repl in $DBReplication)
 {
              $server = $Repl.Server
			  $check = $Repl.check
              $result = $Repl.result
              $err = $Repl.error
    $DetailRepl+=  "					<tr>"
    $DetailRepl+=  "						<td width='20%'><font color='#0000FF'><b>$($server)</b></font></td>"
    $DetailRepl+=  "						<td width='20%'><font color='#0000FF'><b>$($check)</b></font></td>"
	if ($result -like "Passed")
	{
        $DetailRepl+=  "					<td width='20%'><font color='#0000FF'><b>$($result)</b></font></td>"
    }
    else
    {
    $ClassHeaderRepl = "heading10"
    $DetailRepl+=  "						<td width='20%'><font color='#FF0000'><b>$($result)</b></font></td>"
	$DetailRepl+=  "						<td width='20%'><font color='#FF0000'><b>$($err)</b></font></td>"
	$DetailRepl+=  "					</tr>"
	}
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderRepl)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - Replication Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
						<th width='20%'><b>Check</b></font></th>
	  					<th width='20%'><b>Result</b></font></th>
	  					<th width='20%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailRepl)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End DAGReplication

function DAGRPCClientAccessServer {

#===================================================================
# Database Availability Group - RPCClientAccessServer
#===================================================================
#write-Output "..Database Availability Group - RPCClientAccessServer"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRPCCAS = "heading1"
$DBrpcs = Get-MailboxDatabase -status | Where{($_.Name -like "KDHR*") -AND $_.ReplicationType -eq "Remote"} | sort Name
$Sites = ((Get-ClientAccessArray).site).name
$Carrays = Get-ClientAccessArray
foreach ($Site in $Sites)
{
    $DetailRPCCAS+=  "					<tr>"
    $DetailRPCCAS+=  "						<td width='20%'><font color='#000080'><b>$($Site)</b></font></td><tr>"
foreach ($DBRPC in $DBRpcs){
		$DBname = $DBrpc.Name
		$DBSrv = $DBrpc.Server
		$DBRPC = $DBrpc.RpcClientAccessServer
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBSrv)</b></font></td>"		
		$DetailRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($DBRPC)</b></font></td>"
	    $DetailRPCCAS+=  "						<td width='40%'><font color='#0000FF'></font></td>"	
        $DetailRPCCAS+=  "					</tr>"
}
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRPCCAS)'>
            <SPAN class=sectionTitle tabIndex=0>Database Availability Group - RPCClientAccessServer</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>RPC Client Access Server</b></font></th>
							<th width='40%'><b></b></font></th>                            
 		   		</tr>
                    $($DetailRPCCAS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
"@
Return $Report

}#End DAGRPCClientAccessServer

function DiskInformation {

#===================================================================
# Disk Report Information
#===================================================================
#Write-Output "..Logical Disk & MountPoint Report Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ALLSRVLIST = get-exchangeserver | Where-Object{$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge"}
$ClassHeaderObjDisk = "heading1"
foreach ($SRVLIST in $allSRVLIST){
   $query = "Select * from Win32_pingstatus where address = '$SRVLIST'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
foreach ($SRV in $SRVLIST)
 {
     $DetailObjDisk+=  "					<tr>"
     $DetailObjDisk+=  "					<th width='20%'><b>SERVER NAME : <font color='#0000FF'>$($srv)</b></font></th>"
 $colDisks = Get-WmiObject -computer $srv win32_volume | Where-object {$_.DriveLetter -ne $null -OR $_.Capacity -ne $null -AND $_.FileSystem -like "NTFS"} | sort-object Caption
Foreach ($objDisk in $colDisks)
	{

    $DetailObjDisk+=  "					<tr>"
    $DetailObjDisk+=  "						<td width='20%'><font color='#0000FF'><b>$($objDisk.Label)</b></font></td>"
    $DetailObjDisk+=  "						<td width='10%'><font color='#0000FF'><b>$($objDisk.Caption)</b></font></td>"
	$DetailObjDisk+=  "						<td width='20%'><font color='#0000FF'><b>$($objDisk.FileSystem)</b></font></td>"
	$disksize = [math]::round(($objDisk.Capacity/ 1073741824),2) 
	$DetailObjDisk+=  "						<td width='15%'><font color='#0000FF'><b>$disksize GB</b></font></td>"
	$freespace = [math]::round(($objDisk.FreeSpace / 1073741824),2)	
	$DetailObjDisk+=  " 						<td width='15%'><font color='#0000FF'><b>$Freespace GB</b></font></td>"
	if ($disksize -eq 0){
		$ClassHeaderObjDisk = "heading10"
		$percFreespace = "0"
			}
	Else{
		$percFreespace=[math]::round(((($objDisk.FreeSpace / 1073741824)/($objdisk.Capacity / 1073741824)) * 100),0)		
		}
		if ($percFreespace -lt "20")
		{
		$ClassHeaderObjDisk = "heading10"
		$DetailObjDisk+=  "						<td width='15%'><font color='#FF0000'><b>$percFreespace%</b></font></td>"
		}
		else {
		$DetailObjDisk+=  "						<td width='15%'><font color='#0000FF'><b>$percFreespace%</b></font></td>"
		}

	}
    $DetailObjDisk+=  "					<td width='15%'><font color='#FF0000'> </font></td>"
    $DetailObjDisk+=  "					</tr>"
}
}
   else
    {
    $ClassHeaderObjDisk = "heading10"
    $DetailObjDisk+=  "					<tr>"
    $DetailObjDisk+=  "					<th width='20%'><b>SERVER NAME : <font color='#FF0000'>$($SRVLIST)</b></font></td></th>"
    $DetailObjDisk+=  "					</tr>"
    }	
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderObjDisk)'>
            <SPAN class=sectionTitle tabIndex=0>Logical Disk & MountPoint Report</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
					<tr>
							<th width='20%'><b>Label</b></font></th>
	  						<th width='10%'><b>Drive Letter</b></font></th>
	  						<th width='20%'><b>File System</b></font></th>
	  						<th width='15%'><b>Disk Size</b></font></th>
	  						<th width='15%'><b>Disk Free Space</b></font></th>
	  						<th width='15%'><b>% Free Space</b></font></th>						
	  				</tr>
                    $($DetailObjDisk)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>    

"@
Return $Report

}#End DiskInformation

function ExchangeRollup {

#===================================================================
# Exchange Rollup (Edge server excluded)
#===================================================================
#write-Output "..Exchange Servers Rollup (E2K10 Only)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MsxServers = Get-ExchangeServer | where {$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge" -AND $_.AdminDisplayVersion.major -eq "14"} | sort Name
$ClassHeaderRollup = "heading1"
#Loop through each Exchange server that is found
ForEach ($MsxServer in $MsxServers)
{
   
   	#Get Exchange server version
	$MsxVersion = $MsxServer.ExchangeVersion

	#Create "header" string for output
	$Srv = $MsxServer.Name
 
    $DetailRollup+=  "					<tr>"
    $DetailRollup+=  "					<th width='10%'><b>SERVER NAME : <font color='#0000FF'>$($Srv)</b></font></td>"

   
	$key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\AE1D439464EB1B8488741FFA028E291C\Patches\"
	$type = [Microsoft.Win32.RegistryHive]::LocalMachine
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
	$regKey = $regKey.OpenSubKey($key)

     if ($regKey.SubKeyCount -eq 0)
    {
               $DetailRollup+=  "						<tr><td width='10%'><b><font color='#FF0000'>NO ROLLUP INSTALLED</b></font></td><tr>"
    }
    else
    {
	#Loop each of the subkeys (Patches) and gather the Installed date and Displayname of the Exchange 2010 patch
	$ErrorActionPreference = "SilentlyContinue"

	ForEach($sub in $regKey.GetSubKeyNames())
	{
		$SUBkey = $key + $Sub
		$SUBregKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
		$SUBregKey = $SUBregKey.OpenSubKey($SUBkey)

		ForEach($SubX in $SUBRegkey.GetValueNames())
		{
			# Display Installed date and Displayname of the Exchange 2007 patch
			IF ($Subx -eq "Installed")   {
				$d = $SUBRegkey.GetValue($SubX)
				$d = $d.substring(4,2) + "/" + $d.substring(6,2) + "/" + $d.substring(0,4)
			}
			IF ($Subx -eq "DisplayName") {
            $cd = $SUBRegkey.GetValue($SubX)
            $DetailRollup+=  "						<tr><td width='10%'><b>Rollup Version : <font color='#0000FF'>$($d) - $($cd)</b></font></td><tr>"
            }
		}
	}
           $DetailRollup+=  "					<tr>"
}
    $DetailRollup+=  "					</tr>"
}
	
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRollup)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Rollup (E2K10 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                         
	  				</tr>
                    $($DetailRollup)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
Return $Report

}#End ExchangeRollup

function ExchangeRollupE2K7 {

#===================================================================
# Exchange Rollup (Edge server excluded)
#===================================================================
#write-Output "..Exchange Servers Rollup (E2K7 Only)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MsxServers = Get-ExchangeServer | where {$_.ServerRole -ne "Edge" -AND $_.AdminDisplayVersion.major -eq "8"} | sort Name
$ClassHeaderRollup = "heading1"
#Loop through each Exchange server that is found

if ($MsxServers -ne $NULL)
{
ForEach ($MsxServer in $MsxServers)
{
   
   	#Get Exchange server version
	$MsxVersion = $MsxServer.ExchangeVersion

	#Create "header" string for output
	$Srv = $MsxServer.Name
 
    $DetailRollup+=  "					<tr>"
    $DetailRollup+=  "					<th width='10%'><b>SERVER NAME : </b><font color='#0000FF'>$($Srv)</font></td>"

 
    
	$key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\461C2B4266EDEF444B864AD6D9E5B613\Patches\"
	$type = [Microsoft.Win32.RegistryHive]::LocalMachine
	$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
	$regKey = $regKey.OpenSubKey($key)

     if ($regKey.SubKeyCount -eq 0)
    {
               $DetailRollup+=  "						<tr><td width='10%'><font color='#FF0000'><b>NO ROLLUP INSTALLED</b></font></td><tr>"
    }
    else
    {
	#Loop each of the subkeys (Patches) and gather the Installed date and Displayname of the Exchange 2007 patch
	$ErrorActionPreference = "SilentlyContinue"

	ForEach($sub in $regKey.GetSubKeyNames())
	{
		$SUBkey = $key + $Sub
		$SUBregKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
		$SUBregKey = $SUBregKey.OpenSubKey($SUBkey)

		ForEach($SubX in $SUBRegkey.GetValueNames())
		{
			# Display Installed date and Displayname of the Exchange 2007 patch
			IF ($Subx -eq "Installed")   {
				$d = $SUBRegkey.GetValue($SubX)
				$d = $d.substring(4,2) + "/" + $d.substring(6,2) + "/" + $d.substring(0,4)
			}
			IF ($Subx -eq "DisplayName") {
            $cd = $SUBRegkey.GetValue($SubX)
            $DetailRollup+=  "						<tr><td width='10%'><b>Rollup Version : <font color='#0000FF'>$($d) - $($cd)</b></font></td><tr>"
            }
		}
	}
           $DetailRollup+=  "					<tr>"
}
    $DetailRollup+=  "					</tr>"
}
	
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRollup)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Rollup (E2K7 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                         
	  				</tr>
                    $($DetailRollup)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
}
else
{
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderRollup)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Rollup (E2K7 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                         
	  				</tr>
                    No Exchange 2007 Servers Found in this Organization
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
}
Return $Report

}#End ExchangeRollupE2K7

function ExchangeServersInformation {

#===================================================================
# Exchange Servers Information
#===================================================================
#write-Output "..Exchange Servers Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$E2K = Get-ExchangeServer | Where-Object{$_.Name -like "KDHR*"}
$E2KEdge = Get-ExchangeServer | Where-Object{$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge"}
$E2K3 = Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 6.*"} | Measure-Object
$E2K7 = Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*"} | Measure-Object
$E2K10 = Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*"} | Measure-Object
$ClassHeadersrvVersion = "heading1"
		$E2KNB = $E2K.count
		$E2K7NB = $E2K7.count
		$E2K10NB = $E2K10.count
		$E2K3NB = $E2K3.count
		
		$E2K7MCH = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7CH = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7M = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7H = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7C = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7E = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -eq "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K7UM = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 8.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -eq "UnifiedMessaging"} | Measure-Object).count		
		
		$E2K10MCH = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10CH = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10M = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -eq "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10H = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -eq "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10C = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -eq "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10E = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -eq "EDGE" -AND $_.IsUnifiedMessagingServer -ne "UnifiedMessaging"} | Measure-Object).count
		$E2K10UM = (Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsMailboxServer -ne "Mailbox" -AND $_.IsClientAccessServer -ne "ClientAccess" -AND $_.IsHubTransportServer -ne "HUBTransport" -AND $_.IsEdgeServer -ne "EDGE" -AND $_.IsUnifiedMessagingServer -eq "UnifiedMessaging"} | Measure-Object).count		
		
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr><tr>"	
    $DetailsrvVersion+=  "				<td width='20%'><b>Total Exchange Servers : </b><font color='#FF0000'>$($E2KNB)</font></td><tr><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2003 Number(s) : </b><font color='#FF0000'>$($E2K3NB) </b></font></th>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"						
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2007 Number(s) : </b><font color='#FF0000'>$($E2K7NB)</b></font></th><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>--------------------------------</b></font><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox & ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K7MCH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K7CH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox number(s) : </b><font color='#0000FF'>$($E2K7M) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- HubTransport number(s) : </b><font color='#0000FF'>$($E2K7H) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess number(s) : </b><font color='#0000FF'>$($E2K7C) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Edge number(s) : </b><font color='#0000FF'>$($E2K7E) </font>(The Edge servers information collects are not included in this report)</b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Unified Messaging number(s) : </b><font color='#0000FF'>$($E2K7UM) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"						
	$DetailsrvVersion+=  "				<th width='10%'><b>- Exchange 2010 Number(s) : </b><font color='#FF0000'>$($E2K10NB)</b></font></th><tr>"
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>--------------------------------</b></font><tr>"		
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox & ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K10MCH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess & HubTransport number(s) : </b><font color='#0000FF'>$($E2K10CH) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Mailbox number(s) : </b><font color='#0000FF'>$($E2K10M) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- HubTransport number(s) : </b><font color='#0000FF'>$($E2K10H) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- ClientAccess number(s) : </b><font color='#0000FF'>$($E2K10C) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Edge number(s) : </b><font color='#0000FF'>$($E2K10E) </font>(The Edge servers information collects are not included in this report)</b></font></th><tr>"	
	$DetailsrvVersion+=  "				<th width='10%'><b>  ---- Unified Messaging number(s) : </b><font color='#0000FF'>$($E2K10UM) </b></font></th><tr>"	
	$DetailsrvVersion+=  "				<tr><th width='10%'><b>================================</b></font><tr>"	
    $DetailsrvVersion+=  "				</tr>"
	
$ClassHeaderEXCOSW = "heading1"
foreach($EXCOS in $E2KEdge){
    $query = "Select * from Win32_pingstatus where address = '$EXCOS'"
    $result = Get-WmiObject -query $query
    if ($result.protocoladdress){ 
	$XCOS = (Get-WmiObject -Class Win32_OperatingSystem -Namespace root/cimv2 -computername $EXCOS)
	$XCOSN = $XCOS.CSName
    $XCOSOS = $XCOS.Caption
	$XCOSSP = $XCOS.CSDVersion
	$XCOSArch = $XCOS.OSArchitecture
    $XCOSLB = $XCOS.ConvertToDateTime($XCOS.LastBootUpTime)
    $DetailEXCOSW+=  "					<tr>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCOSN)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='50%'><font color='#0000FF'><b>$($XCOSOS)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSSP)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSArch)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCOSLB)</b></font></td>"
    $DetailEXCOSW+=  "					</tr>"
    }
    else
    {
    $ClassHeaderEXCOSW = "heading10"
    $DetailEXCOSW+=  "					<tr>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#FF0000'><b>$($EXCOS)</b></font></td>"
    $DetailEXCOSW+=  "						<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"  
    $DetailEXCOSW+=  "						<td width='60%'><b></b></font></td>"      
    $DetailEXCOSW+=  "					</tr>"
    }
}
$ClassHeaderEXIPSW = "heading1"
foreach($EXCIP in $E2KEdge){
   $query = "Select * from Win32_pingstatus where address = '$EXCIP'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
    $XCIPNIC = (Get-WmiObject Win32_NetworkAdapterConfiguration -computer $EXCIP | where-object {$_.IPEnabled -eq $true} )
    foreach ($XCIP in $XCIPNIC){
    $XCIPN = $EXCIP.Name
    $XCIPIP = $XCIP.IPAddress
	$XCIPDG = $XCIP.DefaultIPGateway
	$XCIPDesc = $XCIP.Description
    $XCIPSN = $XCIP.ServiceName
    $DetailEXIPSW+=  "					<tr>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCIPN)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#0000FF'><b>$($XCIPIP)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCIPDG)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='30%'><font color='#0000FF'><b>$($XCIPDesc)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'><font color='#0000FF'><b>$($XCIPSN)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='10%'></font></td>"    
    $DetailEXIPSW+=  "					</tr>"
    }
    }
    else
    {
    $ClassHeaderEXIPSW = "heading10"
    $DetailEXIPSW+=  "					<tr>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#FF0000'><b>$($EXCIP)</b></font></td>"
    $DetailEXIPSW+=  "						<td width='20%'><font color='#FF0000'><b>SERVER CANNOT BE CONTACTED</b></font></td>"  
    $DetailEXIPSW+=  "						<td width='60%'><b></b></font></td>"      
    $DetailEXIPSW+=  "					</tr>"
    }
    }
	
$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderEXCOSW)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Servers Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						
	  				</tr>
                    $($DetailsrvVersion)
                </table>
                <table>
	  				<tr>
	  						
	  				</tr>
                    $($Detailmbxnumb)
                </table>
                <table>
	  			<tr>
	  				<br><th width='20%'><b>Name</b></font></th>                    
	  				<th width='50%'><b>Operating System</b></font></th>
					<th width='10%'><b>Service Pack</b></font></th>
					<th width='10%'><b>OS Version</b></font></th> 
					<th width='10%'><b>LastBootUpTime</b></font></th>  
  	  				</tr>
                    $($DetailEXCOSW)
                </table>
                <table>
	  			<tr>
	  				<br><th width='20%'><b>Server Name</b></font></th>                    
	  				<th width='20%'><b>IPAddress</b></font></th>
					<th width='10%'><b>DefaultIPGateway</b></font></th>
					<th width='30%'><b>Description</b></font></th> 
					<th width='10%'><b>ServiceName</b></font></th>  
 					<th width='10%'><b></b></font></th>                                                        
  	  				</tr>
                    $($DetailEXIPSW)
                </table>                             
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report

}#End ExchangeServersInformation

function ExchangeServices {

#===================================================================
# Exchange Services
#===================================================================
#Write-Output "..Exchange Services"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ExchangeServerList = Get-ExchangeServer | where {$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge"} 
$ClassHeaderExch = "heading1"
foreach($Exch in $ExchangeServerList)
    {
    $ServiceHealth = Test-ServiceHealth -Server $Exch | where {$_.Name -like "KDHR*" -AND $_.RequiredServicesRunning -eq $False}
    $ServerVer = $Exch.AdminDisplayVersion
    $ServerRole = $Exch.ServerRole
	$SvcRun = "All Services are Running"
    $DetailExch+=  "					<tr>"
    $DetailExch+=  "						<td width='20%'><font color='#0000FF'><b>$($Exch)</b></font></td>"
    $DetailExch+=  "						<td width='20%'><font color='#0000FF'><b>$($ServerRole)</b></font></td>" 
    $DetailExch+=  "						<td width='30%'><font color='#0000FF'><b>$($Serverver)</b></font></td>"			
foreach($Items in $ServiceHealth)
		{
	   		If($Items.ServicesNotRunning.Count -gt 0)
       		{
       		$Global:Valid = 0
                foreach($Service in $Items.ServicesNotRunning)
                {
		$ClassHeaderExch = "heading10"		
        $DetailExch+=  "						<td width='25%'><font color='#FF0000'><b>$($Service)</b></font></td><tr><td width='20%'><td width='20%'><td width='30%'>"
				}
			}
			Else
			{
        $DetailExch+=  "						<td width='25%'><font color='#0000FF'><b>$($SvcRun)</b></font></td>"
			}

		}
		$DetailExch+=  "					</tr>"
	}
$Report += @"
	</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderExch)'>
            <SPAN class=sectionTitle tabIndex=0>Exchange Services - All Exchange Versions</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
					<th width='20%'><b>Server Name</b></font></th>
					<th width='20%'><b>Server Role</b></font></th>
					<th width='30%'><b>Exchange Version</b></font></th>
					<th width='25%'><b>Exchange Services Status</b></font></th>						
	  				</tr>
                    $($DetailExch)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report

}#End ExchangeServices

function HardwareInformation {

#===================================================================
# Hardware information
#===================================================================
#write-Output "..Hardware Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$Allsrvs = Get-ExchangeServer | Where-Object{$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge"}
$ClassHeadercs = "heading1"
foreach ($allsrv in $allsrvs){
   $query = "Select * from Win32_pingstatus where address = '$allsrv'"
   $result = Get-WmiObject -query $query
   if ($result.protocoladdress){ 
	$Csall = Get-WmiObject -ComputerName $allsrv Win32_ComputerSystem -NameSpace "ROOT/CIMV2"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SERVER NAME : <font color='#000080'>$($allsrv)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
		foreach ($cs in $Csall) {
		$csdom = $cs.domain
		$csManu = $cs.manufacturer
		$csModel = $cs.Model
		$csST = $cs.SystemType
		$csRole = $cs.Roles
		$csPON = $cs.PrimaryOwnerName
		$csTPM = [math]::round(($cs.TotalPhysicalMemory/ 1073741824),2)
		$csCTZ = $cs.CurrentTimeZone
		$csEDST = $cs.EnableDayLightSavingsTime
		
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Domain : </font><font color='#0000FF'>$($csdom)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Manufacturer : </font><font color='#0000FF'>$($csmanu)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Model : </font><font color='#0000FF'>$($csModel)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SystemType : </font><font color='#0000FF'>$($csST)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Roles : </font><font color='#0000FF'>$($csRole)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>PrimaryOnwerName : </font><font color='#0000FF'>$($csPON)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>TotalPhysicalMemory : </font><font color='#0000FF'>$($csTPM) GB</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>CurrentTimeZone : </font><font color='#0000FF'>$($csCTZ)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>EnableDayLightSavingTime : </font><font color='#0000FF'>$($csEDST)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	}
	$Procall = Get-WmiObject -ComputerName $allsrv Win32_Processor -NameSpace "ROOT/CIMV2"
		foreach ($Proc in $Procall) {
		$Procver = $Proc.caption
		$ProcName = $Proc.Name
		$ProcNOC = $Proc.NumberOfCores
		$ProcNOLP = $Proc.NumberOfLogicalProcessors
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Caption : </font><font color='#0000FF'>$($Procver)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Name : </font><font color='#0000FF'>$($Procname)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>NumberOfCores : </font><font color='#0000FF'>$($ProcNOC)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>NumberOfLogicalProcessors : </font><font color='#0000FF'>$($ProcNOLP)</b></font></td></th>"
}
	$Biosall = Get-WmiObject -ComputerName $allsrv Win32_Bios -NameSpace "ROOT/CIMV2"
		foreach ($Bios in $Biosall) {
		$biosver = $bios.Version
		$biosdesc = $bios.Description
		$biosManu = $bios.manufacturer
		$biosName = $bios.Name
		$biosSN = $bios.SerialNumber
		$biosLang = $bios.listofLanguages
    $Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>BIOS Version : </font><font color='#0000FF'>$($biosver)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Description : </font><font color='#0000FF'>$($biosdesc)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"
	$Detailcs+=  "					<th width='20%'><b>Manufacturer : </font><font color='#0000FF'>$($biosmanu)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>Name : </font><font color='#0000FF'>$($biosName)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>SerialNumber : </font><font color='#0000FF'>$($biosSN)</b></font></td></th>"
	$Detailcs+=  "					</tr>"
	$Detailcs+=  "					<tr>"	
	$Detailcs+=  "					<th width='20%'><b>ListOfLanguages : </font><font color='#0000FF'>$($biosLang)</b></font></td></th>"
}

	$Detailcs+=  "					</tr>"	
	$Detailcs+=  "					<th width='20%'><b>______________________________________________________________________</b></font></th>"
	$Detailcs+=  "					<tr>"
}
   else
    {
    $ClassHeadercs = "heading10"
    $Detailcs+=  "					<tr>"
    $Detailcs+=  "					<th width='20%'><b>SERVER NAME : <font color='#FF0000'>$($allsrv)</b></font></td></th>"
    $Detailcs+=  "					</tr>"
    }

}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeadercs)'>
            <SPAN class=sectionTitle tabIndex=0>Hardware Informations (Bios, System, Processor)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>

 		   		</tr>
                $($Detailcs)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>
"@
Return $Report

}#End HardwareInformation

function Header {

####################################################################
# MICROSOFT - Exchange 2010 Architecture Report
#
# File : E2K10_Architecture.ps1
# Version : 2.0
# Author : Pascal Theil & Franck Nerot
# Author Company : MICROSOFT
# Author Mail : ptheil@microsoft.com & franckn@microsoft.com
# Creation date : 12/09/2011
# Modification date : 19/09/2011
#
# Exchange 2010
# 
####################################################################

#===================================================================
# Settings
#===================================================================
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$AD = Get-AcceptedDomain | ?{$_.Default -eq "True"} 
$ADDN = $AD.DomainName
$Date = Get-Date
#===================================================================
# HTML Report Structure
#===================================================================

	$Report = @"
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
	<html ES_auditInitialized='false'><head><title>Audit</title>
	<META http-equiv=Content-Type content='text/html; charset=windows-1252'>
	<STYLE type=text/css>	
		DIV .expando {DISPLAY: block; FONT-WEIGHT: normal; FONT-SIZE: 8pt; RIGHT: 10px; COLOR: #ffffff; FONT-FAMILY: Arial; POSITION: absolute; TEXT-DECORATION: underline}
		TABLE {TABLE-LAYOUT: fixed; FONT-SIZE: 100%; WIDTH: 100%}
		#objshowhide {PADDING-RIGHT: 10px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; Z-INDEX: 2; CURSOR: hand; COLOR: #405774; MARGIN-RIGHT: 0px; FONT-FAMILY: Arial; TEXT-ALIGN: right; TEXT-DECORATION: underline; WORD-WRAP: normal}
		.heading0_expanded {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 8px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 0px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #999999}
		.heading1 {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #CCCCCC}
		.heading10 {BORDER-RIGHT: #bbbbbb 1px solid; PADDING-RIGHT: 5em; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-WEIGHT: bold; FONT-SIZE: 8pt; MARGIN-BOTTOM: -1px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; CURSOR: hand; COLOR: #000000; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; HEIGHT: 2.25em; BACKGROUND-COLOR: #FF0000}
		.tableDetail {BORDER-RIGHT: #bbbbbb 1px solid; BORDER-TOP: #bbbbbb 1px solid; DISPLAY: block; PADDING-LEFT: 16px; FONT-SIZE: 8pt;MARGIN-BOTTOM: -1px; PADDING-BOTTOM: 5px; MARGIN-LEFT: 5px; BORDER-LEFT: #bbbbbb 1px solid; WIDTH: 100%; COLOR: #405774; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: #bbbbbb 1px solid; FONT-FAMILY: Arial; POSITION: relative; BACKGROUND-COLOR: #f9f9f9}
		.filler {BORDER-RIGHT: medium none; BORDER-TOP: medium none; DISPLAY: block; BACKGROUND: none transparent scroll repeat 0% 0%; MARGIN-BOTTOM: -1px; FONT: 100%/8px Arial; MARGIN-LEFT: 43px; BORDER-LEFT: medium none; COLOR: #ffffff; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: medium none; POSITION: relative}
		.Solidfiller {BORDER-RIGHT: medium none; BORDER-TOP: medium none; DISPLAY: block; BACKGROUND: none transparent scroll repeat 0% 0%; MARGIN-BOTTOM: -1px; FONT: 100%/8px Arial; MARGIN-LEFT: 0px; BORDER-LEFT: medium none; COLOR: #405774; MARGIN-RIGHT: 0px; PADDING-TOP: 4px; BORDER-BOTTOM: medium none; POSITION: relative; BACKGROUND-COLOR: #405774}
		td {VERTICAL-ALIGN: TOP; FONT-FAMILY: Arial}
		th {VERTICAL-ALIGN: TOP; COLOR: #000000; TEXT-ALIGN: left}
	</STYLE>
	<SCRIPT language=vbscript>
		strShowHide = 1
		strShow = "show"
		strHide = "hide"
		strShowAll = "show all"
		strHideAll = "hide all"
	
	Function window_onload()
		If UCase(document.documentElement.getAttribute("ES_auditInitialized")) <> "TRUE" Then
			Set objBody = document.body.all
			For Each obji in objBody
				If IsSectionHeader(obji) Then
					If IsSectionExpandedByDefault(obji) Then
						ShowSection obji
					Else
						HideSection obji
					End If
				End If
			Next
			objshowhide.innerText = strShowAll
			document.documentElement.setAttribute "ES_auditInitialized", "true"
		End If
	End Function
	
	Function IsSectionExpandedByDefault(objHeader)
		IsSectionExpandedByDefault = (Right(objHeader.className, Len("_expanded")) = "_expanded")
	End Function
	
	Function document_onclick()
		Set strsrc = window.event.srcElement
		While (strsrc.className = "sectionTitle" or strsrc.className = "expando")
			Set strsrc = strsrc.parentElement
		Wend
		If Not IsSectionHeader(strsrc) Then Exit Function
		ToggleSection strsrc
		window.event.returnValue = False
	End Function
	
	Sub ToggleSection(objHeader)
		SetSectionState objHeader, "toggle"
	End Sub
	
	Sub SetSectionState(objHeader, strState)
		i = objHeader.sourceIndex
		Set all = objHeader.parentElement.document.all
		While (all(i).className <> "container")
			i = i + 1
		Wend
		Set objContainer = all(i)
		If strState = "toggle" Then
			If objContainer.style.display = "none" Then
				SetSectionState objHeader, "show" 
			Else
				SetSectionState objHeader, "hide" 
			End If
		Else
			Set objExpando = objHeader.children.item(1)
			If strState = "show" Then
				objContainer.style.display = "block" 
				objExpando.innerText = strHide
	
			ElseIf strState = "hide" Then
				objContainer.style.display = "none" 
				objExpando.innerText = strShow
			End If
		End If
	End Sub
	
	Function objshowhide_onClick()
		Set objBody = document.body.all
		Select Case strShowHide
			Case 0
				strShowHide = 1
				objshowhide.innerText = strShowAll
				For Each obji In objBody
					If IsSectionHeader(obji) Then
						HideSection obji
					End If
				Next
			Case 1
				strShowHide = 0
				objshowhide.innerText = strHideAll
				For Each obji In objBody
					If IsSectionHeader(obji) Then
						ShowSection obji
					End If
				Next
		End Select
	End Function
	
	Function IsSectionHeader(obj) : IsSectionHeader = (obj.className = "heading1_expanded") Or (obj.className = "heading10_expanded") Or (obj.className = "heading1") Or (obj.className = "heading10") Or (obj.className = "heading2"): End Function
	Sub HideSection(objHeader) : SetSectionState objHeader, "hide" : End Sub
	Sub ShowSection(objHeader) : SetSectionState objHeader, "show": End Sub
	</SCRIPT>
	</HEAD>
	<BODY>
	<p><b><hr size="4" color="#FF0000"><font face="Arial" size="3">EXCHANGE 2010 ARCHITECTURE REPORT</font></b><br>
	<p><b><font face="Arial" size="1"color="#000000">Report generated on $Date <hr size="2" color="#FF00000"></font></p>
	<TABLE cellSpacing=0 cellPadding=0>
		<TBODY>
			<TR>
				<TD>
					<DIV id=objshowhide tabIndex=0><FONT face=Arial></FONT></DIV>
				</TD>
			</TR>
		</TBODY>
	</TABLE>
	<DIV class=heading0_expanded>
	<br><SPAN class=sectionTitle tabIndex=0><font face="Arial" size="2">Exchange Domaine Name : <font color='#0000FF'>$($ADDN)</font></SPAN><br><br>
	<A class=expando href='#'></A>
	</DIV>
	<DIV class=filler></DIV>

"@

Return $Report

}#End Header

function HUBBackPressure {

#===================================================================
# HUB Transport - Back Pressure (E2K10 Only)
#===================================================================
#write-Output "..HUB Transport - Back Pressure Events (E2K10 Only)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$E2K10HT = Get-ExchangeServer | ?{$_.Name -like "KDHR*" -AND $_.AdminDisplayVersion -like "Version 14.*" -AND $_.IsHubTransportServer -eq "True"}
$ClassHeaderHUBBP = "heading1"
foreach($HTBP in $E2K10HT){
	$HBPevt = get-eventlog -LogName Application -computername $HTBP -newest 100 | ?{$_.Source -like "MSExchange Transport" -AND $_.EventId -eq "15004" -OR $_.EventId -eq "15005" -OR $_.EventId -eq "15006" -OR $_.EventId -eq "15007"}
	foreach($HBP in $HBPevt){
	$HBPInst = $HBP.EventId
	$HBPTW = $HBP.TimeWritten
	$HBPEType = $HBP.EntryType
	$HBPSource = $HBP.Source
	$HBPMsg = $HBP.Message
	$DetailHUBBP+=  "					<tr>"
	$DetailHUBBP+=  "					    <td width='10%'><font color='#000080'><b>$($HTBP)</b></font></td>"
    $DetailHUBBP+=  "						<td width='5%'><font color='#0000FF'><b>$($HBPInst)</b></font></td>"
    $DetailHUBBP+=  "						<td width='10%'><font color='#0000FF'><b>$($HBPTW)</b></font></td>"
    $DetailHUBBP+=  "						<td width='10%'><font color='#0000FF'><b>$($HBPEType)</b></font></td>"
    $DetailHUBBP+=  "						<td width='15%'><font color='#0000FF'><b>$($HBPSource)</b></font></td>"
    $DetailHUBBP+=  "						<td width='50%'><font color='#0000FF'><b>$($HBPMsg)</b></font></td>"
    $DetailHUBBP+=  "					</tr>"
}
}
	
$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderHUBBP)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Back Pressure (E2K10 Only)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='10%'><b>Server Name</b></font></th>					
	  						<th width='5%'><b>EventId</b></font></th>
							<th width='10%'><b>TimeWritten</b></font></th>
							<th width='10%'><b>EntryType</b></font></th>
							<th width='15%'><b>Source</b></font></th>
	  						<th width='50%'><b>Message</b></font></th>
	  				</tr>
                    $($DetailHUBBP)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>	
"@
Return $Report

}#End HUBBackPressure

function HUBInformation {

#===================================================================
# HUB Transport Information
#===================================================================
#Write-Output "..Hub Transport Information"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ExchangeserverList = Get-transportServer | Get-ExchangeServer | where{($_.Name -like "KDHR*") -AND ($_.AdminDisplayVersion.Major -gt "8") -AND ($_.ServerRole -ne "Edge")}
$ClassHeaderQueue = "heading1"       
		foreach($ExchangeServer in $ExchangeServerList)
               {
                $QueueList = $ExchangeServer | Get-Queue
                foreach($Queue in $QueueList)
                {
				if ($Queue.identity -eq $null)
				{
	$ClassHeaderQueue = "heading10"    			
    $DetailQueue+=  "					<tr>"
    $DetailQueue+=  "					<td width='20%'><font color='#FF0000'><b>$($ExchangeServer)</b></font></td>"
    $DetailQueue+=  "					</tr>"
				}
				else
				{
				
                                  $Color = "#0000FF"
                                 if ($Queue.MessageCount -ge 250)
                                  {
                                  $ClassHeaderQueue = "heading10"
								  $Global:Valid = 0
                                  $Color = "FF0000"
                                  }
                    $QueueIdentity = $Queue.Identity
                    $QueueMessageCount = $Queue.MessageCount
                    $QueueNextHopDomain = $Queue.NextHopDomain   
    $DetailQueue+=  "					<tr>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($ExchangeServer)</b></font></td>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueIdentity)</b></font></td>" 
	$DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueMessageCount)</b></font></td>"
    $DetailQueue+=  "						<td width='20%'><font color=$($color)><b>$($QueueNextHopDomain)</b></font></td>"	
    $DetailQueue+=  "					</tr>"
				}
				}
				}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderQueue)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Transport Queue Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>Queue Name</b></font></th>
	  						<th width='20%'><b>Messages Count</b></font></th>
	  						<th width='20%'><b>NextHopDomain</b></font></th>							
	  				</tr>
                    $($DetailQueue)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

$ClassHeaderTC = "heading1"
$HUBTC = Get-TransportConfig
        $HUBSRE = $hubtc.ShadowRedundancyEnabled
        $HUBSHTI = $hubtc.ShadowHeartbeatTimeoutInterval
        $HUBSHRC = $hubtc.ShadowHeartbeatRetryCount
        $HUBSMADI = $hubtc.ShadowMessageAutoDiscardInterval     
        
    $DetailTC+=  "					<tr>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSRE)</b></font></td>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSHTI)</b></font></td>" 
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSHRC)</b></font></td>"
    $DetailTC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSMADI)</b></font></td>"      
	$DetailTC+=  "					</tr>"
        $HUBMDSD = $hubtc.MaxDumpsterSizePerDatabase
        $HUBMDT = $hubtc.MaxDumpsterTime
        $HUBMRS = $hubtc.MaxReceiveSize
        $HUBMREL = $hubtc.MaxRecipientEnvelopeLimit
        $HUBMSS = $hubtc.MaxSendSize            
        
    $DetailTCD+=  "					<tr>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMDSD)</b></font></td>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMDT)</b></font></td>" 
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMRS)</b></font></td>"
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMREL)</b></font></td>"   
    $DetailTCD+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBMSS)</b></font></td>"    
	$DetailTCD+=  "					</tr>"

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderTC)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Transport Config</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>ShadowRedundancyEnabled</b></font></th>
	  					<th width='20%'><b>ShadowHeartbeatTimeoutInterval</b></font></th>
	  					<th width='20%'><b>ShadowHeartbeatRetryCount</b></font></th>
	  					<th width='20%'><b>ShadowMessageAutoDiscardInterval </b></font></th>							
	  				</tr>
                    $($DetailTC)
                </table>
                <table>
	  				<tr>
	  						<br><th width='20%'><b>MaxDumpsterSizePerDatabase</b></font></th>
							<th width='20%'><b>MaxDumpsterTime</b></font></th>
							<th width='20%'><b>MaxReceiveSize</b></font></th>
							<th width='20%'><b>MaxRecipientEnvelopeLimit</b></font></th>
							<th width='20%'><b>MaxSendSize</b></font></th>
 		   		</tr>
                    $($DetailTCD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@

$ClassHeaderSC = "heading1"
$HUBSends = Get-SendConnector
foreach($HUBSend in $HUBSends){
        $HUBI = $hubsend.Identity
        $HUBAS = $hubsend.AddressSpaces
        $HUBHMSI = $hubsend.HomeMtaServerId
        $HUBSTS = $hubsend.SourceTransportServers
        $HUBMMS = $hubsend.MaxMessageSize     
        $HUBP = $hubsend.Port
        $HUBEnab = $hubsend.Enabled       
    $DetailSC+=  "					<tr>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBI)</b></font></td>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBAS)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBHMSI)</b></font></td>"
    $DetailSC+=  "						<td width='20%'><font color='#0000FF'><b>$($HUBSTS)</b></font></td>"      
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBMMS)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBP)</b></font></td>" 
    $DetailSC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBEnab)</b></font></td>"     
	$DetailSC+=  "					</tr>"
    }
$HUBReces = get-ReceiveConnector | where {$_.Name -like "KDHR*"}
foreach($HUBRece in $HUBReces){    
        $HUBRI = $hubRece.Identity
        $HUBRBind = $hubRece.Bindings
        $HUBMRS = $hubRece.Server
        $HUBRMMS = $hubRece.MaxMessageSize
        $HUBREnab = $hubRece.Enabled         
    $Detail+=  "					<tr>"
    $DetailRC+=  "						<td width='45%'><font color='#0000FF'><b>$($HUBRI)</b></font></td>"
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBRBind)</b></font></td>" 
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBMRS)</b></font></td>"
    $DetailRC+=  "						<td width='15%'><font color='#0000FF'><b>$($HUBRMMS)</b></font></td>"   
    $DetailRC+=  "						<td width='10%'><font color='#0000FF'><b>$($HUBREnab)</b></font></td>"    
	$DetailRC+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderSC)'>
            <SPAN class=sectionTitle tabIndex=0>HUB Transport - Connectors settings</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
                        <td width='20%'><b>SEND CONNECTORS</b></font></td><tr>                   
	  					<th width='20%'><b>Identity</b></font></th>
	  					<th width='20%'><b>AddressSpaces</b></font></th>
	  					<th width='10%'><b>HomeMtaServerId</b></font></th>
	  					<th width='20%'><b>SourceTransportServers</b></font></th>
	  					<th width='10%'><b>MaxMessageSize</b></font></th>	
	  					<th width='10%'><b>Port</b></font></th>	
	  					<th width='10%'><b>Enabled</b></font></th>	                                                							
	  				</tr>
                    $($DetailSC)
                </table>
                <table>
	  				<tr>
                        <td width='45%'><b>RECEIVE CONNECTORS</b></font></td><tr>
               		   <br><th width='45%'><b>Identity</b></font></th>
					   <th width='15%'><b>Binding</b></font></th>
					   <th width='15%'><b>Server</b></font></th>
					   <th width='15%'><b>MaxMessageSize</b></font></th>
					   <th width='10%'><b>Enabled</b></font></th>
 		   		</tr>
                    $($DetailRC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report

}#End HUBInformation

function MBXBackup {

#===================================================================
# Mailbox Server - Backup
#===================================================================
# write-Output "..Mailbox Server - Backup"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderMBXBK = "heading1"
$MBXBKList = Get-MailboxDatabase -Status | where {$_.Name -like "KDHR*" -AND $_.Recovery -eq $False -AND $_.ReplicationType -ne "Remote"} | sort Server
foreach ($MBXBK in $MBXBKList)
        {
            $MBXBKServer = $MBXBK.Server
            $MBXBKLastFullBackup = $MBXBK.LastFullBackup
            $MBXBKIdentity  = $MBXBK.Identity
			$MBXBKLastIB = $MBXBK.LastIncrementalBackup
			$MBXBKLastDB = $MBXBK.LastDifferentialBackup
			$MBXBKLastCB = $MBXBK.LastCopyBackup
    $DetailMBXBK+=  "					<tr>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKServer)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKIdentity)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastIB)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastDB)</b></font></td>"
    $DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastCB)</b></font></td>"	
    if($MBXBKLastFullBackup -eq $null)
    {
    $ClassHeaderMBXBK = "heading10"       
	$DetailMBXBK+=  "					<td width='15%'><font color='#FF0000'><b>Never Backuped</b></font></td>"
    $Global:Valid = 0
    }
    else
    {
	$DetailMBXBK+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKLastFullBackup)</b></font></td>"
	
              if($MBXBKLastFullBackup -gt (Get-Date).adddays(-1))
               {
			   $DetailMBXBK+=  "			<td width='10%'><font color='#0000FF'><b>Valid</b></font></td>"
			   }
               else
               {
                    if($MBXBKLastFullBackup -gt (Get-Date).adddays(-2))
                    {
					$ClassHeaderMBXBK = "heading10" 					 
					$DetailMBXBK+=  "						<td width='10%'><font color='#FF9900'><b>One Day Old</b></font></td>"                       
                    $Global:Valid = 0
                    }
                    else
                    {
					$ClassHeaderMBXBK = "heading10"  
					$DetailMBXBK+=  "						<td width='10%'><font color='#FF0000'><b>More Than 2 Days</b></font></td>"                          
                    $Global:Valid = 0
                    }
                }
    }
				$DetailMBXBK+=  "					</tr>"  
	}

foreach ($MBXBK in $MBXBKList)
        {
            $MBXBKServer = $MBXBK.Server
            $MBXBKSLastFB = $MBXBK.SnapshotLastFullBackup
            $MBXBKIdentity  = $MBXBK.Identity
			$MBXBKSLastIB = $MBXBK.SnapshotLastIncrementalBackup
			$MBXBKSLastDB = $MBXBK.SnapshotLastDifferentialBackup
			$MBXBKSLastCB = $MBXBK.SnapshotLastCopyBackup
    $DetailMBXBKS+=  "					<tr>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKServer)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKIdentity)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastIB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastDB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastCB)</b></font></td>"
    $DetailMBXBKS+=  "						<td width='15%'><font color='#0000FF'><b>$($MBXBKSLastFB)</b></font></td>"
	$DetailMBXBKS+=  "					</tr>"  	
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMBXBK)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Databases Backup Status</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>LastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>LastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>LastCopyBackup</b></font></th>							
	  						<th width='15%'><b>LastFullBackup</b></font></th>							
	  						<th width='10%'><b>Backup Validity</b></font></th>					
	  				</tr>
                    $($DetailMBXBK)
                </table>
               <table>
	  				<tr>
	  						<br><th width='15%'><b>Server Name</b></font></th>
							<th width='15%'><b>Database Name</b></font></th>
	  						<th width='15%'><b>SnapshotLastIncrementalBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastDifferentialBackup</b></font></th>
	  						<th width='15%'><b>SnapshotLastCopyBackup</b></font></th>							
	  						<th width='15%'><b>SnapshotLastFullBackup</b></font></th>							
	  				</tr>
                    $($DetailMBXBKS)
                </table>				
            </div>
        </div>
        <div class='filler'></div>
    </div>                     
"@
Return $Report

}#End MBXBackup

function MBXCalRepairAssistant {

#===================================================================
# Mailbox Server - Calendar Repair Assistant
#===================================================================
#Write-Output "..Mailbox Server - Calendar Repair Assistant"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderCRA = "heading1"
$MBXCRAall = Get-MailboxServer | ?{($_.Name -like "KDHR*") -AND $_.AdminDisplayVersion -like "Version 14.*"}
Foreach($MBXCRA in $MBXCRAall)
 {
        $SRVCRA = $MBXCRA.Name
		$CRWC = $MBXCRA.CalendarRepairWorkCycle
		$CRWCC = $MBXCRA.CalendarRepairWorkCycleCheckpoint
		$CRLE = $MBXCRA.CalendarRepairLogEnabled
		$CRLSLE = $MBXCRA.CalendarRepairLogSubjectLoggingEnabled		
		$CRLFAL = $MBXCRA.CalendarRepairLogFileAgeLimit
		$CRLDSL = $MBXCRA.CalendarRepairLogDirectorySizeLimit
		$CRLP = $MBXCRA.CalendarRepairLogPath
    $DetailCRA+=  "					<tr>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($SRVCRA)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRWC)</b></font></td>"
    $DetailCRA+=  "						<td width='15%'><font color='#0000FF'><b>$($CRWCC)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLE)</b></font></td>"
    $DetailCRA+=  "						<td width='15%'><font color='#0000FF'><b>$($CRLSLE)</b></font></td>"	
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLFAL)</b></font></td>"
    $DetailCRA+=  "						<td width='10%'><font color='#0000FF'><b>$($CRLDSL)</b></font></td>"
    $DetailCRA+=  "						<td width='20%'><font color='#0000FF'><b>$($CRLP)</b></font></td>"
	$DetailCRA+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderCRA)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Calendar Repair Assistant</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='10%'><b>Server Name</b></font></th>
						<th width='10%'><b>WorkCycle</b></font></th>
	  					<th width='15%'><b>WorkCycleCheckpoint</b></font></th>
	  					<th width='10%'><b>LogEnabled</b></font></th>
	  					<th width='15%'><b>LogSubjectLoggingEnabled</b></font></th>
	  					<th width='10%'><b>LogFileAgeLimit</b></font></th>
	  					<th width='10%'><b>LogDirectorySizeLimit</b></font></th>
	  					<th width='20%'><b>LogPath</b></font></th>							
	  				</tr>
                    $($DetailCRA)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report

}#End MBXCalRepairAssistant

function MBXDBSize {

#===================================================================
# Mailbox Server - Database Size and Availability
#===================================================================
#write-Output "..Mailbox Server - Database Size and Availability"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MBXDBsizes = Get-MailboxDatabase -status | where-object{$_.Name -like "KDHR*" -AND $_.ReplicationType -ne "Remote"} | sort Name
$ClassHeaderMBXDBsize = "heading1"
foreach ($MBXDBsize in $MBXDBsizes){
		$DBname = $MBXDBsize.Name
		$DataBSize = $MBXDBsize.DatabaseSize
		$DbANMS = $MBXDBsize.AvailableNewMailboxSpace
    $DetailMBXDBsize+=  "					<tr>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBname)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DataBsize)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='20%'><font color='#0000FF'><b>$($DBANMS)</b></font></td>"
    $DetailMBXDBsize+=  "						<td width='40%'><font color='#0000FF'><b> </b></font></td>"	
    $DetailMBXDBsize+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXDBsize)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Database Size and Availability</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
							<th width='20%'><b>Database Size</b></font></th>
							<th width='20%'><b>AvailableNewMailboxSpace</b></font></th>
							<th width='40%'><b> </b></font></th>							
 		   		</tr>
                    $($DetailMBXDBsize)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>                
"@
Return $Report

}#End MBXDBSize

function MBXInformation {

#===================================================================
# Mailbox Server - Information
#===================================================================
#write-Output "..Mailbox Server - Information (Out of DAG servers)"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MBXInfos = Get-MailboxServer -Status | where-object{$_.Name -like "KDHR*" -AND $_.DatabaseAvailabilityGroup -eq $null}
$ClassHeaderMBXI = "heading1"
foreach($MBXInfo in $MBXInfos){
		$MBXInfoN = $MBXInfo.Name
		$MBXInfoADM = $MBXInfo.AutoDatabaseMountDial
		$MBXInfoADV = $MBXInfo.AdminDisplayVersion
    $DetailMBXI+=  "					<tr>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoN)</b></font></td>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoADM)</b></font></td>"
    $DetailMBXI+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXInfoADV)</b></font></td>"
    $DetailMBXI+=  "						<td width='40%'><font color='#0000FF'><b> </b></font></td>"	
    $DetailMBXI+=  "					</tr>"
}	
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXI)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - Information (Out of DAG servers)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                 </table>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>AutoDatabaseMountDial</b></font></th>
							<th width='20%'><b>AdminDisplayVersion</b></font></th>
							<th width='40%'><b> </b></font></th>
					</tr>
                    $($DetailMBXI)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@
Return $Report

}#End MBXInformation

function MBXOAB {

#===================================================================
# Mailbox Server - OfflineAddressBook
#===================================================================
#write-Output "..OfflineAddressBook"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OABS = Get-OfflineAddressBook
$ClassHeaderOAB = "heading1"
foreach ($OAB in $OABS){
		$OBSrv = $OAB.server
		$OBName = $OAB.Name		
		$OBAL = $OAB.AddressLists
		$OBVer = $OAB.Versions
		$OBID = $OAB.IsDefault		
		$OBPFD = $OAB.PublicFolderDatabase
		$OBPFDE = $OAB.PublicFolderDistributionEnabled
		$OBVD = $OAB.VirtualDirectories		
		
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>Server Name : <font color='#0000FF'>$($OBSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($OBName)</font><th width='10%'>AddressLists : <font color='#0000FF'>$($OBAL)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>Versions : <font color='#0000FF'>$($OBVer)</font><th width='10%'>IsDefaut : <font color='#0000FF'>$($OBID)</font><th width='10%'>PublicFolderDatabase : <font color='#0000FF'>$($OBPFD)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
    $DetailOAB+=  "					<th width='10%'>PublicFolderDistributionEnabled : <font color='#0000FF'>$($OBPFDE)</font><th width='10%'>VirtualDirectories : <font color='#0000FF'>$($OBVD)</font></td></th>"
    $DetailOAB+=  "					</tr>"
    $DetailOAB+=  "					<tr>"
	$DetailOAB+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"	
    $DetailOAB+=  "					</tr>"	
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOAB)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox server - Offline Address Book</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailOAB)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End MBXOAB

function MBXRPCClientAccessServer {

#===================================================================
# Mailbox Server - RPCClientAccessServer
#===================================================================
# write-Output "..Mailbox Server - RPCClientAccessServer"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderMBXRPCCAS = "heading1"
$MBXInfos = Get-MailboxServer -Status | where-object{$_.Name -like "KDHR*" -AND $_.DatabaseAvailabilityGroup -eq $null}
foreach ($MBXInfo in $MBXInfos)
{
    $DetailMBXRPCCAS+=  "					<tr>"
    $DetailMBXRPCCAS+=  "						<tr><td width='20%'><font color='#000080'><b>$($MBXInfo)</b></font></td><tr>"
$MBXDBrpcs = Get-MailboxDatabase -status | Where{$_.Name -like "KDHR*" -AND $_.ReplicationType -ne "Remote"} | sort Name
foreach ($MBXDBrpc in $MBXDBrpcs){
		$MBXDB = $MBXDBrpc.Name
		$MBXSrv = $MBXDBrpc.Server
		$MBXDBrpc = $MBXDBrpc.RpcClientAccessServer
		
    $DetailMBXRPCCAS+=  "					<tr>"
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXDB)</b></font></td>"
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXSrv)</b></font></td>"	
    $DetailMBXRPCCAS+=  "						<td width='20%'><font color='#0000FF'><b>$($MBXDBrpc)</b></font></td>"
	$DetailMBXRPCCAS+=  "						<td width='40%'><font color='#0000FF'></font></td>"	
    $DetailMBXRPCCAS+=  "					</tr>"
}
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderMBXRPCCAS)'>
            <SPAN class=sectionTitle tabIndex=0>Mailbox Server - RPCClientAccessServer (Out of DAG servers)</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='20%'><b>Server Name</b></font></th>							
							<th width='20%'><b>RPC Client Access Server</b></font></th>
							<th width='40%'><b></b></font></th>                            
 		   		</tr>
                    $($DetailMBXRPCCAS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>         
"@
Return $Report

}#End MBXRPCClientAccessServer

function PowershellVD {

#===================================================================
# Client Access Server - Powershell Virtual Directory
#===================================================================
#write-Output "..Powershell Virtual Directory"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PWSVDS = Get-ClientAccessServer | Get-PowershellVirtualDirectory
$ClassHeaderPWSVD = "heading1"
foreach ($PWSVD in $PWSVDS){
		$PWSrv = $PWSVD.server
		$PWName = $PWSVD.name
		$PWCE = $PWSVD.CertificateAuthentication
		$PWSSL = $PWSVD.RequireSSL	
		$PWM = $PWSVD.MetabasePath
		$PWP = $PWSVD.Path		
		$PWIURL = $PWSVD.InternalURL		
		$PWEURL = $PWSVD.ExternalURL
		
    $DetailPWSVD+=  "					<tr>"
    $DetailPWSVD+=  "					<th width='10%'><b>Server : <font color='#0000FF'>$($PWSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($PWName)</font><th width='10%'>CertificateAuthentication : <font color='#0000FF'>$($PWCE)</b></font></td></th>"
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
    $DetailPWSVD+=  "					<th width='10%'><b>RequireSSL : <font color='#0000FF'>$($PWSSL)</font><th width='10%'>MetabasePath : <font color='#0000FF'>$($PWM)</font><th width='10%'>Path : <font color='#0000FF'>$($PWP)</b></font></td></th>"	
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
    $DetailPWSVD+=  "					<th width='10%'><b>InternalUrl : <font color='#0000FF'>$($PWIURL)</b><th width='10%'>ExternalUrl : <font color='#0000FF'>$($PWEURL)</font></td></th>"	
    $DetailPWSVD+=  "					</tr>"
	$DetailPWSVD+=  "					<tr>"	
	$DetailPWSVD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailPWSVD+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPWSVD)'>
            <SPAN class=sectionTitle tabIndex=0>Client Access Server - Powershell Virtual Directory</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  			<tr>
							
 		   		</tr>
                    $($DetailPWSVD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End PowershellVD

function PublicFolderDB {

#===================================================================
# Public Folder Database
#===================================================================
#write-Output "..Public Folder Database"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PFDall = Get-ExchangeServer |where-object{$_.serverrole -eq "none" -OR $_.serverrole -like "*mailbox*"} | Get-PublicFolderDatabase -Status | where-Object{$_.PublicFolderHierarchy -eq "Public Folders"}

$ClassHeaderPFD = "heading1"
foreach ($PFD in $PFDall){
		$PFSrv = $PFD.server
		$PFName = $PFD.name
		$PFMIS = $PFD.MaxItemSize
		$PFPPQ = $PFD.ProhibitPostQuota
		$PFRMS = $PFD.ReplicationMessageSize
		$PFUCRSL = $PFD.UseCustomReferralServerList		
		$PFCRSL = $PFD.CustomReferralServerList
		$PFAG = $PFD.AdministrativeGroup
		$PFAP = $PFD.ActivationPreference
		$PFDBS = $PFD.DatabaseSize
		$PFANMS = $PFD.AvailableNewMailboxSpace
		$PFLFB = $PFD.LastFullBackup
		$PFDIR = $PFD.DeletedItemRetention
		
    $DetailPFD+=  "					<tr>"
    $DetailPFD+=  "					<th width='10%'><b>Server : <font color='#0000FF'>$($PFSrv)</font><th width='10%'>Name : <font color='#0000FF'>$($PFName)</font><th width='10%'>MaxItemSize : <font color='#0000FF'>$($PFMIS)</b></font></td></th>"
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>ProhibitPostQuota : <font color='#0000FF'>$($PFPPQ)</font><th width='10%'>ReplicationMessageSize : <font color='#0000FF'>$($PFRMS)</font><th width='10%'>UseCustomReferralServerList : <font color='#0000FF'>$($PFUCRSL)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>CustomReferralServerList : <font color='#0000FF'>$($PFCRSL)</font><th width='10%'>DeletedItemRetention : <font color='#0000FF'>$($PFDIR)</font><th width='10%'>ActivationPreference : <font color='#0000FF'>$($PFAP)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='10%'><b>DatabaseSize : <font color='#0000FF'>$($PFDBS)</font><th width='10%'>AvailableNewMailboxSpace : <font color='#0000FF'>$($PFANMS)</font><th width='10%'>LastFullBackup : <font color='#0000FF'>$($PFLFB)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"
	$DetailPFD+=  "					<tr>"	
    $DetailPFD+=  "					<th width='30%'><b>AdministrativeGroup : <font color='#0000FF'>$($PFAG)</b></font></td></th>"	
    $DetailPFD+=  "					</tr>"	
	$DetailPFD+=  "					<tr>"	
	$DetailPFD+=  "					<th width='10%'><b>______________________________________________________________________</b></font></th>"
	$DetailPFD+=  "					</tr>"
}
$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPFD)'>
            <SPAN class=sectionTitle tabIndex=0>Public Folder Databases</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

 		   		    </tr>
                    $($DetailPFD)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  

"@
Return $Report

}#End PublicFolderDB

function RPCClientAccess {

#===================================================================
# RPCClientAccess
#===================================================================
#Write-Output "..RPCClientAccess"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderRPC = "heading1"
$RPCall = Get-RPCClientAccess
Foreach($RPC in $RPCall)
 {
        $RPCSrv = $RPC.Server
		$RPCResp = $RPC.Responsibility
		$RPCMC = $RPC.MaximumConnections
		$RPCER = $RPC.EncryptionRequired
		$RPCBCV = $RPC.BlockedClientVersions		

    $DetailRPC+=  "					<tr>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCSrv)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCResp)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCMC)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCER)</b></font></td>"
    $DetailRPC+=  "						<td width='20%'><font color='#0000FF'><b>$($RPCBCV)</b></font></td>"	
	$DetailRPC+=  "					</tr>"
}
$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderRPC)'>
            <SPAN class=sectionTitle tabIndex=0>RPCClientAccess Information</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Server Name</b></font></th>
						<th width='20%'><b>Responsibility</b></font></th>
	  					<th width='20%'><b>MaximumConnections</b></font></th>
	  					<th width='20%'><b>EncryptionRequired</b></font></th>
	  					<th width='20%'><b>BlockedClientVersions</b></font></th>
	  				</tr>
                    $($DetailRPC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div> 
"@
Return $Report

}#End RPCClientAccess

function SetSPNDupl {

#===================================================================
# SetSPN - Duplicate
#===================================================================
#write-Output "..SetSPN - Duplicate"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderSetSPND = "heading1"
$SetSPNDs = SetSPN -X
	Foreach ($SetSPND in $SetSPNDs){
    $DetailSetSPND+=  "					<tr>"
    $DetailSetSPND+=  "						<td width='15%'><b><font color='#0000FF'>$($SetSPND)</b></font></td>"
    $DetailSetSPND+=  "					</tr>"
}

$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderSetSPND)'>
            <SPAN class=sectionTitle tabIndex=0>SPN - Duplicated SPNs</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

	  				</tr>
                    $($DetailSetSPND)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@

Return $Report

}#End SetSPNDupl

function SetSPNView {

#===================================================================
# SetSPN - Viewing
#===================================================================
#write-Output "..SetSPN - Viewing"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderSetSPN = "heading1"
$AllSrvs = Get-Exchangeserver | Where-Object{$_.Name -like "KDHR*" -AND $_.ServerRole -ne "Edge"}
foreach ($AllSrv in $AllSrvs){
    $DetailSetSPN+=  "					<tr>"
	$DetailSetSPN+=  "				    <th width='15%'><b>__________________________________<font color='#000080'>$($AllSrv)____________________________________</b></font></th>"
	$SetSPNs = SetSPN -l $AllSrv
	Foreach ($SetSPN in $SetSPNs){
	if ($SetSPN -ne $null)
	{
	$ClassHeaderSetSPN = "heading1"
    $DetailSetSPN+=  "					<tr>"
    $DetailSetSPN+=  "						<td width='15%'><b><font color='#0000FF'>$($SetSPN)</b></font></td>"
    $DetailSetSPN+=  "					</tr>"
	}
	else
	{
	$ClassHeaderSetSPN = "heading10"
	$DetailSetSPN+=  "					<tr>"
    $DetailSetSPN+=  "						<td width='15%'><b><font color='#FF0000'>Could not find account $($AllSrv)</b></font></td>"
    $DetailSetSPN+=  "					</tr>"
	}
}	
}

$Report += @"
	</TABLE>
	    <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderSetSPN)'>
            <SPAN class=sectionTitle tabIndex=0>SPN - Viewing SPNs</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>

	  				</tr>
                    $($DetailSetSPN)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>  
"@

Return $Report

}#End SetSPNView

function TestASConnectivity {

#===================================================================
# Test ActiveSync Connectivity
#===================================================================
#Write-Output "..Test ActiveSync Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ASC = (Get-ClientAccessServer | Test-activesyncconnectivity -trustanySSLCertificate)
$ClassHeaderASC = "heading1"
foreach($Sync in $ASC)
               {
			    $SyncCAS = $sync.ClientAccessServer
				$syncSite = $sync.LocalSite
				$syncSC = $sync.scenario
				$syncRes = $sync.Result
				$syncLatency = $sync.Latency
				$syncError = $sync.Error
    $DetailASC+=  "					<tr>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncCAS)</b></font></td>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncSite)</b></font></td>"
    $DetailASC+=  "						<td width='20%'><font color='#0000FF'><b>$($syncSC)</b></font></td>"			
    if ($syncRes -like "Success")
    {
    $ClassHeaderASC = "heading1"	
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncRes)</b></font></td>"
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncLatency)</b></font></td>"				
    $DetailASC+=  "						<td width='10%'><font color='#0000FF'><b>$($syncError)</b></font></td>" 
    }
    else
    {
    $ClassHeaderASC = "heading10"
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncRes)</b></font></td>"
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncLatency)</b></font></td>"			
    $DetailASC+=  "						<td width='10%'><font color='#FF0000'><b>$($syncError)</b></font></td>" 
    }
    $DetailASC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderASC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test ActiveSyncConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Client Access Server</b></font></th>
						<th width='20%'><b>LocalSite</b></font></th>
	  					<th width='20%'><b>Scenario</b></font></th>
	  					<th width='10%'><b>Result</b></font></th>
	  					<th width='10%'><b>Latency (ms)</b></font></th>
	  					<th width='10%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailASC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End TestASConnectivity

function TestECPConnectivity {

#===================================================================
# Test ECP Connectivity
#===================================================================	 
#Write-Output "..Test ECP Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ECPC = (Get-ClientAccessServer | Test-ecpconnectivity)
$ClassHeaderECP = "heading1"
foreach($ECP in $ECPC)
{
    $ECPCAS = $ECP.ClientAccessServer
    $ECPSite = $ECP.LocalSite
    $ECPSC = $ECP.scenario
    $ECPRes = $ECP.Result
    $ECPLatency = $ECP.Latency
    $ECPError = $ECP.Error
    $DetailECP+=  "					<tr>"
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPCAS)</b></font></td>"
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPSite)</b></font></td>" 
    $DetailECP+=  "						<td width='20%'><font color='#0000FF'><b>$($ECPSC)</b></font></td>"			
    if ($ECPRes -like "Success")
    {
        $ClassHeaderECP = "heading1"	
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPRes)</b></font></td>"
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPLatency)</b></font></td>"			
        $DetailECP+=  "						<td width='10%'><font color='#0000FF'><b>$($ECPError)</b></font></td>" 
    }
    else
    {
        $ClassHeaderECP = "heading10"
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPRes)</b></font></td>"
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPLatency)</b></font></td>"			
        $DetailECP+=  "						<td width='10%'><font color='#FF0000'><b>$($ECPError)</b></font></td>" 
    }
    $DetailECP+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderECP)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test ECPConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Client Access Server</b></font></th>
						<th width='20%'><b>LocalSite</b></font></th>
	  					<th width='20%'><b>Scenario</b></font></th>
	  					<th width='10%'><b>Result</b></font></th>
	  					<th width='10%'><b>Latency (ms)</b></font></th>
	  					<th width='10%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailECP)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report

}#End TestECPConnectivity

function TestMailflow {

#===================================================================
# Test Mailflow
#===================================================================
#Write-Output "..Test Mailflow"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$DB = (Get-MailboxDatabase -Status | Foreach{$_.MountedOnServer})
$ClassHeaderflow = "heading1"
 foreach($DBFlow in $DB)
             {
			    $Flow = $DBFlow | test-Mailflow
                $TMFR = $flow.TestMailflowresult
				$MLT = $flow.MessageLatencyTime
				$IRT = $flow.IsRemoteTest
				$IV = $flow.IsValid
            $Detailflow+=  "					<tr>"
			if ($TMFR -like "Success")
			{
			$ClassHeaderflow = "heading1"			
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($DbFlow)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($TMFR)</b></font></td>" 
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($MLT)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#0000FF'><b>$($IRT)</b></font></td>" 
			$Detailflow+=  "						<td width='15%'><font color='#0000FF'><b>$($IV)</b></font></td>"
			}
			else
			{
			$ClassHeaderflow = "heading10"
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($DbFlow)</b></font></td>"			
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($TMFR)</b></font></td>" 
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($MLT)</b></font></td>"
			$Detailflow+=  "						<td width='20%'><font color='#FF0000'><b>$($IRT)</b></font></td>" 
			$Detailflow+=  "						<td width='15%'><font color='#FF0000'><b>$($IV)</b></font></td>"		
			}

    $Detailflow+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderflow)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Mailflow</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Server Name</b></font></th>
							<th width='20%'><b>TestMailflowResult</b></font></th>
	  						<th width='20%'><b>MessageLatencyTime</b></font></th>
	  						<th width='20%'><b>IsRemoteTest</b></font></th>
	  						<th width='15%'><b>IsValid</b></font></th>					
	  				</tr>
                    $($Detailflow)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report

}#End TestMailflow

function TestMAPIConnectivity {

#===================================================================
# Test MAPI Connectivity - Mailbox and Public Folder Databases
#===================================================================
#Write-Output "..Test MAPI Connectivity - Mailbox and Public Folder Databases"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$MAPIMBX = (Get-MAilboxDatabase | Test-MAPIConnectivity)
$ClassHeaderMC = "heading1"
foreach($MC in $MAPIMBX)
               {
			    $MCMBX = $MC.Server
				$MCDB = $MC.Database
				$MCRes = $MC.Result
				$MCLatency = $MC.Latency
				$MCError = $MC.Error
    $DetailMC+=  "					<tr>"
    $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCMBX)</b></font></td>"
    $DetailMC+=  "						<td width='30%'><font color='#0000FF'><b>$($MCDB)</b></font></td>"  
	if ($MCRes -like "Success")
	{
        $ClassHeaderMC = "heading1"	
        $DetailMC+=  "						<td width='10%'><font color='#0000FF'><b>$($MCRes)</b></font></td>"
        $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCLatency)</b></font></td>" 			
        $DetailMC+=  "						<td width='20%'><font color='#0000FF'><b>$($MCError)</b></font></td>"
    }
    else
    {
        $ClassHeaderMC = "heading10"
        $DetailMC+=  "						<td width='10%'><font color='#FF0000'><b>$($MCRes)</b></font></td>"
        $DetailMC+=  "						<td width='20%'><font color='#FF0000'><b>$($MCLatency)</b></font></td>" 			
        $DetailMC+=  "						<td width='20%'><font color='#FF0000'><b>$($MCError)</b></font></td>" 
    }
    $DetailMC+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test MAPIConnectivity - Mailbox Database</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='30%'><b>Database Name</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='20%'><b>Latency (ms)</b></font></th>							
	  						<th width='20%'><b>Error</b></font></th>								
	  				</tr>
                    $($DetailMC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
 
$MAPIPF = (Get-PublicFolderDatabase | Test-MAPIConnectivity)
$ClassHeaderMCPF = "heading1"
foreach($MCPF in $MAPIPF)
               {
			    $MCPFS = $MCPF.Server
				$MCDBPF = $MCPF.Database
				$MCPFRes = $MCPF.Result
				$MCPFLatency = $MCPF.Latency
				$MCPFError = $MCPF.Error
    $DetailMCPF+=  "					<tr>"
    $DetailMCPF+=  "						<td width='20%'><font color='#0000FF'><b>$($MCPFS)</b></font></td>"
    $DetailMCPF+=  "						<td width='20%'><font color='#0000FF'><b>$($MCDBPF)</b></font></td>"  
	if ($MCPFRes -like "Success")
	{
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFRes)</b></font></td>"
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFLatency)</b></font></td>"			
        $DetailMCPF+=  "						<td width='10%'><font color='#0000FF'><b>$($MCPFError)</b></font></td>"
    }
    else
    {
        $ClassHeaderMCPF = "heading10"
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFRes)</b></font></td>"
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFLatency)</b></font></td>"			
        $DetailMCPF+=  "						<td width='10%'><font color='#FF0000'><b>$($MCPFError)</b></font></td>" 
    }
    $DetailMCPF+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderMCPF)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test MAPIConnectivity - Public Folder Database</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='20%'><b>Database Name</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency (ms)</b></font></th>							
	  						<th width='10%'><b>Error</b></font></th>								
	  				</tr>
                    $($DetailMCPF)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@
Return $Report

}#End TestMAPIConnectivity

function TestOLConnectivity {

#===================================================================
# Test OutlookConnectivity
#===================================================================
#write-Output "..Test OutlookConnectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$TOCs = get-clientAccessServer | Test-OutlookConnectivity -RPCTestType:Server
foreach ($TOC in $TOCs){
$ClassHeaderCasOC = "heading1"
			   	$TOCCas = $TOC.ClientAccessServer
                $TOCEP = $TOC.ServiceEndpoint
				$TOCS = $TOC.Scenario
				$TOCRes = $TOC.Result
				$TOCLatency = $TOC.Latency
    $DetailCasOC+=  "					<tr>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCCas)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCEP)</b></font></td>"
    $DetailCasOC+=  "						<td width='30%'><font color='#0000FF'><b>$($TOCS)</b></font></td>"
	if ($TOCRes -like "Success")
	{
    $ClassHeaderCasOC = "heading1"	
    $DetailCasOC+=  "						<td width='10%'><font color='#0000FF'><b>$($TOCRes)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#0000FF'><b>$($TOCLatency)</b></font></td>"
	}
	else
	{
    $ClassHeaderCasOC = "heading10"
    $DetailCasOC+=  "						<td width='10%'><font color='#FF0000'><b>$($TOCRes)</b></font></td>"
    $DetailCasOC+=  "						<td width='20%'><font color='#FF0000'><b>$($TOCLatency)</b></font></td>"
	}
    $DetailCasOC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderCasOC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Outlook Connectivity Protocol HTTP</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Service Endpoint</b></font></th>
	  						<th width='30%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='20%'><b>Latency</b></font></th>						
	  				</tr>
                    $($DetailCasOC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report

}#End TestOLConnectivity

function TestOutlookWebServices {

#===================================================================
# Test Outlook Web Services
#===================================================================
#Write-Output "..Outlook Web Services"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderows = "heading1"
$OWSCAS = (Get-ExchangeServer | where{$_.adminDisplayversion.major -eq "14" -AND $_.ServerRole -like "ClientAccess*"})
foreach($TOWS in $OWSCAS)
               {
			    $OWSSrv = $TOWS.name
				$TOWS = Test-OutlookWebServices -ClientAccessServer $OWSSrv
				foreach($OWebS in $TOWS)
				{
				$OWebsID = $OWebs.ID
				$OWebsType = $OWebs.Type
				$OWebsMSG = $OWebs.Message
				if($OWebsType -eq "Error")
				{
			$ClassHeaderows = "heading10"	
			$Detailows+=  "					<tr>"
			$Detailows+=  "				        <td width='15%'><font color='#FF0000'><b>$($OWSSrv)</b></font></td>"			
			$Detailows+=  "						<td width='5%'><font color='#FF0000'><b>$($OWebsID)</b></font></td>"
			$Detailows+=  "						<td width='10%'><font color='#FF0000'><b>$($OWebsType)</b></font></td>" 
			$Detailows+=  "						<td width='70%'><font color='#FF0000'><b>$($OWebsMSG)</b></font></td>"
				}
				else
				{
			$ClassHeaderows = "heading1"					
            $Detailows+=  "					<tr>"
			$Detailows+=  "				        <td width='15%'><font color='#0000FF'><b>$($OWSSrv)</b></font></td>"			
			$Detailows+=  "						<td width='5%'><font color='#0000FF'><b>$($OWebsID)</b></font></td>"
			$Detailows+=  "						<td width='10%'><font color='#0000FF'><b>$($OWebsType)</b></font></td>" 
			$Detailows+=  "						<td width='70%'><font color='#0000FF'><b>$($OWebsMSG)</b></font></td>"
				}
			
			}
            $Detailows+=  "					<tr>"				
			$Detailows+=  "					<th width='100%'><b>____________________________________________________________________________________________________________________________________________</b></font></th>"				
			$Detailows+=  "					</tr>"
}


$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderows)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test Outlook WebServices</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>					
	  						<th width='5%'><b>ID</b></font></th>
							<th width='10%'><b>Type</b></font></th>
	  						<th width='70%'><b>Message</b></font></th>
	  				</tr>
                    $($Detailows)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End TestOutlookWebServices

function TestOWAConnectivity {

#===================================================================
# Test OWA Connectivity
#===================================================================
#Write-Output "..Test OWA Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderowa = "heading1"
$OC = (Get-ClientAccessServer | test-owaconnectivity -AllowUnsecureAccess)
foreach($SOC in $OC)
               {
			    $SOCCAS = $SOC.ClientAccessServer
				$SOCMBX = $SOC.MailboxServer
				$SOCURL = $SOC.URL
				$SOCSC = $SOC.scenario
				$SOCRes = $SOC.Result
				$SOCLatency = $SOC.Latency
				$SOCError = $SOC.Error
            $Detailowa+=  "					<tr>"
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCCAS)</b></font></td>"
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCMBX)</b></font></td>" 
			$Detailowa+=  "						<td width='20%'><font color='#0000FF'><b>$($SOCURL)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCSC)</b></font></td>"
			if ($SOCRes -like "Success")
			{
 			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCRes)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCLatency)</b></font></td>" 
			$Detailowa+=  "						<td width='10%'><font color='#0000FF'><b>$($SOCError)</b></font></td>" 
			}
			else
			{
			$ClassHeaderowa = "heading10"
 			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCRes)</b></font></td>"
			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCLatency)</b></font></td>" 
			$Detailowa+=  "						<td width='10%'><font color='#FF0000'><b>$($SOCError)</b></font></td>" 			
			}
			$Detailowa+=  "					</tr>"
}

$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderowa)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test OWAConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Mailbox Server</b></font></th>
	  						<th width='20%'><b>URL</b></font></th>
	  						<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency (ms)</b></font></th>
	  						<th width='10%'><b>Error</b></font></th>						
	  				</tr>
                    $($Detailowa)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End TestOWAConnectivity

function TestOWServices {

#===================================================================
# Test OutlookWebServices
#===================================================================
#write-Output "..Test OutlookWebServices"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$OWSs = Test-OutlookWebServices
$ClassHeaderOWebS = "heading1"
foreach ($OWS in $OWSs)#$OWS.RunspacID
{
			   	$OWSID = $OWS.ID
				$OWST = $OWS.Type
				$OWSMsg = $OWS.Message

    $DetailOWebS+=  "					<tr>"
    $DetailOWebS+=  "						<td width='20%'><font color='#0000FF'><b>$($OWSID)</b></font></td>"
	if ($OWST -like "Success")
	{
    $ClassHeaderOWebS = "heading1"	
    $DetailOWebS+=  "						<td width='20%'><font color='#0000FF'><b>$($OWST)</b></font></td>"
    $DetailOWebS+=  "						<td width='60%'><font color='#0000FF'><b>$($OWSMsg)</b></font></td>"
	}
	else
	{
    $ClassHeaderOWebS = "heading10"
    $DetailOWebS+=  "						<td width='20%'><font color='#FF0000'><b>$($OWST)</b></font></td>"
    $DetailOWebS+=  "						<td width='60%'><font color='#FF0000'><b>$($OWSMsg)</b></font></td>"
	}
    $DetailOWebS+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderOWebS)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test OutlookWebServices</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>ID</b></font></th>
							<th width='20%'><b>Type</b></font></th>
	  						<th width='60%'><b>Message</b></font></th>
	  				</tr>
                    $($DetailOWebS)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report


}#End TestOWServices

function TestPowershellConnectivity {

#===================================================================
# Test Powershell Connectivity
#===================================================================
#Write-Output "..Powershell Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$ClassHeaderpwc = "heading1"
$PWCCAS = (Get-ExchangeServer | where-object{$_.adminDisplayversion.major -eq "14" -AND $_.ServerRole -like "ClientAccess*"})
foreach($TPWC in $PWCCAS)
               {
			    $PWCSrv = $TPWC.name
				$TPWC = Test-PowershellConnectivity -ClientAccessServer $PWCSrv
				foreach($PWCY in $TPWC)
				{
				$PWCYCS = $PWCY.ClientAccessServerShortName
				$PWCYLS = $PWCY.LocalSite
				$PWCYS = $PWCY.Scenario
				$PWCYR = $PWCY.Result
				$PWCYL = $PWCY.LatencyInMillisecondsString
				$PWCYE = $PWCY.Error				
				if($PWCYR -like "Success")
				{
			$ClassHeaderpwc = "heading1"				
			$Detailpwc+=  "					<tr>"
			$Detailpwc+=  "				        <td width='15%'><font color='#0000FF'><b>$($PWCYCS)</b></font></td>"			
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYLS)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYS)</b></font></td>" 
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYR)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#0000FF'><b>$($PWCYL)</b></font></td>"
			$Detailpwc+=  "						<td width='45%'><font color='#0000FF'><b>$($PWCYE)</b></font></td>"					
				}
				else
				{
			$ClassHeaderpwc = "heading10"	
			$Detailpwc+=  "					<tr>"
			$Detailpwc+=  "				        <td width='15%'><font color='#FF0000'><b>$($PWCYCS)</b></font></td>"			
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYLS)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYS)</b></font></td>" 
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYR)</b></font></td>"
			$Detailpwc+=  "						<td width='10%'><font color='#FF0000'><b>$($PWCYL)</b></font></td>"
			$Detailpwc+=  "						<td width='45%'><font color='#FF0000'><b>$($PWCYE)</b></font></td>"	
				}
			
			}
			
			$Detailpwc+=  "					</tr>"
}


$Report += @"
					</TABLE>
				</div>
			</DIV>
    <div class='container'>
        <div class='$($ClassHeaderpwc)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test PowershellConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='15%'><b>Server Name</b></font></th>					
	  						<th width='10%'><b>Local Site</b></font></th>
							<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
							<th width='10%'><b>Latency(MS)</b></font></th>
	  						<th width='450%'><b>Error</b></font></th>
					</tr>
                    $($Detailpwc)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End TestPowershellConnectivity

function TestPWSConnectivity {

#===================================================================
# Test PowershellConnectivity
#===================================================================
#write-Output "..Test PowershellConnectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$PWSs = get-clientAccessServer | Test-PowershellConnectivity
foreach ($PWS in $PWSs){
$ClassHeaderPWSH = "heading1"
			   	$PWSCas = $PWS.ClientAccessServer
                $PWSLS = $PWS.LocalSite
				$PWSS = $PWS.Scenario
				$PWSRes = $PWS.Result
				$PWSLatency = $PWS.Latency
				$PWSErr = $PWS.Error
				
    $DetailPWSH+=  "					<tr>"
    $DetailPWSH+=  "						<td width='20%'><font color='#0000FF'><b>$($PWSCAS)</b></font></td>"
    $DetailPWSH+=  "						<td width='20%'><font color='#0000FF'><b>$($PWSLS)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSS)</b></font></td>"
	if ($PWSRes -like "Success")
	{
    $ClassHeaderPWSH = "heading1"	
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSRes)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#0000FF'><b>$($PWSLatency)</b></font></td>"
    $DetailPWSH+=  "						<td width='30%'><font color='#0000FF'><b>$($PWSErr)</b></font></td>"	
	}
	else
	{
    $ClassHeaderPWSH = "heading10"
    $DetailPWSH+=  "						<td width='10%'><font color='#FF0000'><b>$($PWSRes)</b></font></td>"
    $DetailPWSH+=  "						<td width='10%'><font color='#FF0000'><b>$($PWSLatency)</b></font></td>"
    $DetailPWSH+=  "						<td width='30%'><font color='#FF0000'><b>$($PWSErr)</b></font></td>"	
	}
    $DetailPWSH+=  "					</tr>"
}

$Report += @"
	</TABLE>
	            <div>
        <div>
    <div class='container'>
        <div class='$($ClassHeaderPWSH)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test PowershellConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  						<th width='20%'><b>Client Access Server</b></font></th>
							<th width='20%'><b>Service Endpoint</b></font></th>
	  						<th width='10%'><b>Scenario</b></font></th>
	  						<th width='10%'><b>Result</b></font></th>
	  						<th width='10%'><b>Latency</b></font></th>	
	  						<th width='30%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailPWSH)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>               
   
"@
Return $Report

}#End TestPWSConnectivity

function WEBServicesConnectivity {

#===================================================================
# Test Web Services Connectivity
#===================================================================
#Write-Output "..Test Web Services Connectivity"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
$SRVSettings = Get-ADServerSettings
if ($SRVSettings.ViewEntireForest -eq "False")
	{
		Set-ADServerSettings -ViewEntireForest $true
	}
$WSC = (Get-ClientAccessServer | test-webservicesconnectivity -AllowUnsecureAccess)
$ClassHeaderWSC = "heading1"
foreach($WebS in $WSC)
               {
			    $WebSCAS = $WebS.ClientAccessServer
				$WebSSite = $WebS.LocalSite
				$WebSSC = $WebS.scenario
				$WebSRes = $WebS.Result
				$WebSLatency = $WebS.Latency
				$WebSError = $WebS.Error
    $DetailWSC+=  "					<tr>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSCAS)</b></font></td>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSSite)</b></font></td>"
    $DetailWSC+=  "						<td width='20%'><font color='#0000FF'><b>$($WEBSSC)</b></font></td>"			
			if ($webSRes -like "Success")
    {
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSRes)</b></font></td>"
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSLatency)</b></font></td>"				
    $DetailWSC+=  "						<td width='10%'><font color='#0000FF'><b>$($WEBSError)</b></font></td>" 
    }
    else
    {
    $ClassHeaderWSC = "heading10"
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSRes)</b></font></td>"
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSLatency)</b></font></td>"			
    $DetailWSC+=  "						<td width='10%'><font color='#FF0000'><b>$($WEBSError)</b></font></td>" 
    }
    $DetailWSC+=  "					</tr>"
}

$Report += @"
	</TABLE>
	</div>
	</DIV>
    <div class='container'>
        <div class='$($ClassHeaderWSC)'>
            <SPAN class=sectionTitle tabIndex=0>Tests - Test WebServicesConnectivity</SPAN>
            <a class='expando' href='#'></a>
        </div>
        <div class='container'>
            <div class='tableDetail'>
                <table>
	  				<tr>
	  					<th width='20%'><b>Client Access Server</b></font></th>
						<th width='20%'><b>LocalSite</b></font></th>
	  					<th width='20%'><b>Scenario</b></font></th>
	  					<th width='10%'><b>Result</b></font></th>
	  					<th width='10%'><b>Latency (ms)</b></font></th>
	  					<th width='10%'><b>Error</b></font></th>							
	  				</tr>
                    $($DetailWSC)
                </table>
            </div>
        </div>
        <div class='filler'></div>
    </div>              
"@

Return $Report

}#End WEBServicesConnectivity

function ServerSCCM2012_ClientRepair {


$SCCMMgmtPoint='BGRMB7AFGN201.afghan.swa.ds.army.mil'
$SMSSiteCode='RC1'


$ErrorActionPreference = "SilentlyContinue" 

        #kill existing/hung instances of ccmsetup.exe 
           $ccm = (Get-Process ccmsetup -ErrorAction SilentlyContinue) 
            if($ccm -ne $null) 
            { 
                    $ccm.kill(); 
            }

        #stop the sms/sccm agent service and BITS, wuauserv
            stop-service 'ccmexec' -ErrorAction SilentlyContinue
            stop-service 'bits' -ErrorAction SilentlyContinue
            stop-service 'wuauserv' -ErrorAction SilentlyContinue
	    stop-process ccmexec.exe -force -ErrorAction SilentlyContinue
	    stop-process smscliui.exe -force -ErrorAction SilentlyContinue

        #Un-Install current Client
        if(test-path "C:\Windows\ccmsetup\ccmsetup.exe") 
        {
         Start-Process -FilePath 'C:\Windows\ccmsetup\ccmsetup.exe' -PassThru -ArgumentList "/Uninstall"
         Sleep(10)
        }

        
        Do {
		$ccm = (Get-Process ccmsetup -ErrorAction SilentlyContinue) 
		sleep -seconds 60
           } Until ($ccm -eq $null)


        #Cleanup CCM files and RegKeys 
            Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCM\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCMSetup\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCMSetup\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS\Mobile Client\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\CCM' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\SysWoW64\CCM' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\Windows\ccmsetup' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\ccmcache' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\Windows\SoftwareDistribution' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\windows\SMSCFG.ini' -ErrorAction SilentlyContinue


	#BITS RESET
        start-service 'bits' -ErrorAction SilentlyContinue
        start-service 'wuauserv' -ErrorAction SilentlyContinue
	bitsadmin.exe /reset /allusers

 
	#Make Sure C:\Windows\ccmsetup exist for download of ccmsetup.exe
	If(!(test-path "C:\Windows\ccmsetup")){New-Item C:\Windows\ccmsetup -Type Directory -ErrorAction SilentlyContinue | out-null}


        #download ccmsetup.exe from Mgmt Point to C:\Windows\ccmsetup
            $webclient = New-Object System.Net.WebClient 
            $url = "http://$($SCCMMgmtPoint)/CCM_Client/ccmsetup.exe" 
            $file = "C:\Windows\ccmsetup\ccmsetup.exe" 
            $webclient.DownloadFile($url,$file) 


        #run ccmsetup
        try {
                Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -PassThru -ArgumentList "SMSSITECODE=$SMSSiteCode"
            }

        catch 
	        { 
                  #$error[0]
	        }

	Remove-Item -Path 'C:\tempp\*.ps1' -ErrorAction SilentlyContinue

}#End Server_SCCM2012_ClientRepair

function Workstation_SCCM2012_ClientRepair {


$SCCMMgmtPoint='BGRMB7AFGN201.afghan.swa.ds.army.mil'
$SMSSiteCode='RC1'


$ErrorActionPreference = "SilentlyContinue" 

        #kill existing/hung instances of ccmsetup.exe 
           $ccm = (Get-Process ccmsetup -ErrorAction SilentlyContinue) 
            if($ccm -ne $null) 
            { 
                    $ccm.kill(); 
            }

        #stop the sms/sccm agent service and BITS, wuauserv
            stop-service 'ccmexec' -ErrorAction SilentlyContinue
            stop-service 'bits' -ErrorAction SilentlyContinue
            stop-service 'wuauserv' -ErrorAction SilentlyContinue
            stop-service 'winmgmt' -ErrorAction SilentlyContinue
	    stop-process ccmexec.exe -force -ErrorAction SilentlyContinue
	    stop-process smscliui.exe -force -ErrorAction SilentlyContinue

        #Un-Install current Client
        if(test-path "C:\Windows\ccmsetup\ccmsetup.exe") 
        {
         Start-Process -FilePath 'C:\Windows\ccmsetup\ccmsetup.exe' -PassThru -ArgumentList "/Uninstall"
         Sleep(10)
        }

        
        Do {
		$ccm = (Get-Process ccmsetup -ErrorAction SilentlyContinue) 
		sleep -seconds 60
           } Until ($ccm -eq $null)


        #Cleanup CCM files and RegKeys 
            Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCM\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\CCMSetup\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCM\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\CCMSetup\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS\Mobile Client\*' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\CCM' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\SysWoW64\CCM' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\Windows\ccmsetup' -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\ccmcache' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\Windows\SoftwareDistribution' -Recurse -ErrorAction SilentlyContinue
	    Remove-Item -Path 'C:\windows\SMSCFG.ini' -ErrorAction SilentlyContinue

	#Reset WMI
	winmgmt.exe /resetrepository
	wmiadap.exe /RegServer
	wmiapsrv.exe /RegServer
	wmic.exe /RegServer
	wmiprvse.exe /RegServer
	Start-sleep -Seconds 5

	#Windows Update Repair
	regsvr32.exe /s C:\Windows\System32\atl.dll
	regsvr32.exe /s C:\Windows\System32\urlmon.dll
	regsvr32.exe /s C:\Windows\System32\mshtml.dll
	regsvr32.exe /s C:\Windows\System32\shdocvw.dll
	regsvr32.exe /s C:\Windows\System32\browseui.dll
	regsvr32.exe /s C:\Windows\System32\jscript.dll
	regsvr32.exe /s C:\Windows\System32\vbscript.dll
	regsvr32.exe /s C:\Windows\System32\scrrun.dll
	regsvr32.exe /s C:\Windows\System32\msxml.dll
	regsvr32.exe /s C:\Windows\System32\msxml3.dll
	regsvr32.exe /s C:\Windows\System32\msxml6.dll
	regsvr32.exe /s C:\Windows\System32\actxprxy.dll
	regsvr32.exe /s C:\Windows\System32\softpub.dll
	regsvr32.exe /s C:\Windows\System32\wintrust.dll
	regsvr32.exe /s C:\Windows\System32\dssenh.dll
	regsvr32.exe /s C:\Windows\System32\rsaenh.dll
	regsvr32.exe /s C:\Windows\System32\gpkcsp.dll
	regsvr32.exe /s C:\Windows\System32\sccbase.dll
	regsvr32.exe /s C:\Windows\System32\slbcsp.dll
	regsvr32.exe /s C:\Windows\System32\cryptdlg.dll
	regsvr32.exe /s C:\Windows\System32\oleaut32.dll
	regsvr32.exe /s C:\Windows\System32\ole32.dll
	regsvr32.exe /s C:\Windows\System32\shell32.dll
	regsvr32.exe /s C:\Windows\System32\initpki.dll
	regsvr32.exe /s C:\Windows\System32\wuapi.dll
	regsvr32.exe /s C:\Windows\System32\wuaueng.dll
	regsvr32.exe /s C:\Windows\System32\wuaueng1.dll
	regsvr32.exe /s C:\Windows\System32\wucltui.dll
	regsvr32.exe /s C:\Windows\System32\wups.dll
	regsvr32.exe /s C:\Windows\System32\wups2.dll
	regsvr32.exe /s C:\Windows\System32\wuweb.dll
	regsvr32.exe /s C:\Windows\System32\qmgr.dll
	regsvr32.exe /s C:\Windows\System32\qmgrprxy.dll
	regsvr32.exe /s C:\Windows\System32\wucltux.dll
	regsvr32.exe /s C:\Windows\System32\muweb.dll
	regsvr32.exe /s C:\Windows\System32\wuwebv.dll
	regsvr32.exe /s C:\Windows\System32\wudriver.dll
        start-service 'bits' -ErrorAction SilentlyContinue
        start-service 'wuauserv' -ErrorAction SilentlyContinue
	bitsadmin.exe /RESET /ALLUSERS

 
	#Make Sure C:\Windows\ccmsetup exist for download of ccmsetup.exe
	If(!(test-path "C:\Windows\ccmsetup")){New-Item C:\Windows\ccmsetup -Type Directory -ErrorAction SilentlyContinue | out-null}


        #download ccmsetup.exe from Mgmt Point to C:\Windows\ccmsetup
            $webclient = New-Object System.Net.WebClient 
            $url = "http://$($SCCMMgmtPoint)/CCM_Client/ccmsetup.exe" 
            $file = "C:\Windows\ccmsetup\ccmsetup.exe" 
            $webclient.DownloadFile($url,$file) 


        #run ccmsetup
        try {
                Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -PassThru -ArgumentList "SMSSITECODE=$SMSSiteCode"
            }

        catch 
	        { 
                  #$error[0]
	        }

	Remove-Item -Path 'C:\tempp\*.ps1' -ErrorAction SilentlyContinue

}#End Workstation_SCCM2012_ClientRepair

function RebootEasy-Workstations {

$list = Get-Content C:\Scripts\Reboot\Reboot.txt
$rebooterror = "C:\Scripts\Reboot\rebooterror.csv"

echo "IP_Address,Status,Path" | Out-File -Encoding ascii -FilePath $rebooterror

$list | ForEach-Object {

echo "Current computer $_"

# Test if system is online
Invoke-Expression  "ping -n 1 -w 500 $_" | out-Null
$ping = $LASTEXITCODE


### IF pingable and have admin access C$, begin!!!
if (!$ping){

Invoke-Expression 'shutdown /f /r /t 900 /m \\$_ /c "This computer requires an emergency restart to apply reecently deployed critical Network changes/modifications. You can restart now or the computer will restart automatically in 15 Minutes. If you cannot logon to the computer and need to utilize it, you may hard reboot the machine by turning off the power and restarting the machine manually. Contact Networks at 841-1009, SIPR, if you have any questions." ' 
echo "Reboot set for $_"

#Invoke-Expression 'shutdown /a /m \\$_'
$shutcode= $LASTEXITCODE

if ($shutcode -eq 5){
echo "$_ is denied access"
echo "$_,`"Access Denied`",$path" | Out-File -Append -Encoding ascii -FilePath $rebooterror

}


}
else {

$strName = "$_"
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$strFilter = "(&(objectCategory=computer)(name=" + $strName + "))"
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = $strFilter
$strPath = $objSearcher.FindOne().Path 

$path = ""
if ($strPath){
$cleanPathArr = ""
$strPathArr = $strPath.Split(',')
[array]::Reverse($strPathArr)   # Reverse that craps CN/OU/OU/DC > DC/OU/OU/CN
$strPathArr | ForEach-Object {
$split = $_.Split('=')
[array]$cleanPathArr += $split[1]}
$cleanPathArr[5..15] | ForEach-Object {[string]$path = $path + $_  + '/'}
}
#echo $path




echo "$_ is offline"
echo "$_,`"System is offline`",$path" | Out-File -Append -Encoding ascii -FilePath $rebooterror


}


}

}#End RebootEasy-Workstations

function Create-WorkstationList {

<#
.SYNOPSIS
Creates Workstations Reboot List in a Csv file
.DESCRIPTION
Creates Workstations Reboot List in a Csv file
.PARAMETER OutFile
Name of the Output File with the complete file path
Default file: C:\Temp\ARNARebootList.csv
.EXAMPLE
Create Computer List for Reboot
This example retrieves the Computer Names from Active Directory and writes to File
.NOTES
version 2.0 by Michael Melonas / 8 APR 2015
Reboot Arena Workstations
change OU & DC per enclave
#>
    param(
        [string]$OutFile = "C:\temp\ARNARebootList.Csv",
        [string]$DomainOU = "OU=Computers,OU=HD_ARNA,OU=ARNA,OU=RC West,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"
    )
    BEGIN{
        if (Test-Path $OutFile) {
            Remove-Item $OutFile
        }
        New-Item $OutFile -type file | Out-Null
    }
    PROCESS{
        (Get-ADComputer -Filter * -Properties Name -SearchBase $DomainOU) | Select Name | Export-Csv $OutFile -Append -NoTypeInformation
    }
    END{}


}#End Create-WorkstationList

function RemotingSCCM-InitiationOfCoreFunction {

# Created by Jamie Culwell 2-7-2013
# Modified 2-1-2014


    $pshost = get-host
    $pswindow = $pshost.ui.rawui

    $newsize = $pswindow.buffersize
    $newsize.height = 3000
    $newsize.width = 100
    $pswindow.buffersize = $newsize

    $newsize = $pswindow.windowsize
    $newsize.height = 40
    $newsize.width = 100
    $pswindow.windowsize = $newsize
    $Host.UI.RawUI.WindowTitle = "SCCM-Query"



## Prompt for Credentials, and set file paths/file for import and export ##
    echo ""
    echo "           Example: AFGHAN\joe.smoe.sa"
    echo ""
    $user = Read-Host "Enter Elevated Acct Name "
    echo ""
    $p = Read-Host "Enter Elevated password " -AsSecureString
    cls 
    $mycreds = New-object -typename System.Management.Automation.PSCredential($user,$p)
    $list = Import-csv "$PSScriptRoot\NameList.csv"
    $ScriptLoc = "$PSScriptRoot\SCCM-Qry-CoreFunction.ps1"
    $results = "$PSScriptRoot\SCCMUpdateResults.csv"

    echo "" | Out-File -Encoding ascii -force -filePath $results
    echo "ServerName" | Out-File -Encoding ascii -force -filePath $results
    echo "" | Out-File -Encoding ascii -append -force -filePath $results


## Start Main Loop to check SCCM Client Status ##

$list | foreach-object{

            $currentIP = $_.ServerName
            (ping -n 1 "$currentIP").protocoladdress
            if($LASTEXITCODE -eq "0"){

                    ## Creates temp folder ##

                    $temp = Test-Path \\$currentIP\c`$\temp\
                    if($temp -eq 0){Invoke-Expression "mkdir \\$currentIP\c`$\temp\" > $null}
                    copy-item $ScriptLoc -Destination \\$currentIP\c$\Temp
                    echo "~ $currentIP ~" | Out-File -append $results

                    ## Test Target system for 32 or 64 bit ##

                    $32or64 = Test-Path \\$currentIP\"c`$\Program Files (x86)\"

                    ## Create Remote Session, load Function into memory (dot source) on remote system ##
                    if($32or64 -eq 0){
                                     $mysession = New-PSSession -computername $currentIP -credential $mycreds
                                     }
                                     elseif($32or64 -eq 1){
                                     $mysession = New-PSSession -computername $currentIP -ConfigurationName Microsoft.PowerShell32 -credential $mycreds
                                     }
                    $mycommand = invoke-command -Session $mysession -ScriptBlock {
                                 Set-ExecutionPolicy Unrestricted -force
                                 $LoadFunc = . C:\Temp\SCCM-Qry-CoreFunction.ps1
                                 $RunFunc = Get-SCCMClientUpdate -ShowHidden | Format-List Name,KB,BulletinID,EnforcementDeadline,UpdateStatus
                                 $LoadFunc
                                 $RunFunc
                                 }
                                 echo ""
                                 echo ""
                                 echo ""
                                 echo $currentIP
                                 $mycommand | Tee-Object -Variable myanswer

                    ## Now that results have been Tee'ed to the screen and to a variable we output them to the results file. ##

                                 echo $myanswer | Out-File -Encoding ascii -append -force -filePath $results
                                 echo "" | Out-File -append $results
                                 echo "" | Out-File -append $results
                                 remove-pssession -ComputerName $currentIP
                      }else{}

}

## End of Main Loop ##
Echo ""
Echo ""
Echo "SCCM Query Completed"
Echo ""
Echo ""
pause

}#End RemotingSCCM-InitiationOfCoreFunction

function SCCM-QryCoreFunction {


Function Get-SCCMClientUpdate {

<#
    .SYNOPSIS
        Allows you to query for updates via the SCCM Client Agent
    
    .DESCRIPTION
        Allows you to query for updates via the SCCM Client Agent
    
    .PARAMETER ShowHidden
        If in Quiet mode, use ShowHidden to view updates.
    
    .PARAMETER UpdateAction
        Define the type of action to query for.
    
        The following values are allowed:
        Install - This setting retrieves all updates that are available to be installed or in the process of being installed.
        Uninstall - This setting retrieves updates that are already installed and are available to be uninstalled. 
    
    
    .EXAMPLE
        Get-SCCMClientUpdate -ShowHidden | Format-Table Name,KB,BulletinID,EnforcementDeadline,UpdateStatus 

        Name                    KB                      BulletinID              EnforcementDeadline     UpdateStatus
        ----                    --                      ----------              -------------------     ------------
        Security Update for ... 2709162                 {MS12-041}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Service Pack 3 for V... 2526301                 {}                      6/4/2012 8:00:00 PM     JobStateDownloading
        Security Update for ... 2656374                 {MS12-025}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Security Update for ... 2656351                 {MS11-100}              6/3/2012 11:00:00 PM    JobStateStateError
        Security Update for ... 2686833                 {MS12-038}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Cumulative Security ... 2699988                 {MS12-037}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Security Update for ... 2656368                 {MS12-025}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Security Update for ... 2686827                 {MS12-038}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Update for Windows V... 2677070                 {}                      6/26/2012 1:00:00 AM    JobStateWaitInstall
        Update for Windows V... 2718704                 {}                      6/26/2012 1:00:00 AM    JobStateWaitInstall
        Security Update for ... 2685939                 {MS12-036}              6/26/2012 1:00:00 AM    JobStateWaitInstall
        Windows Malicious So... 890830                  {}                      6/26/2012 1:00:00 AM    JobStateWaitInstall     
        
        Description
        -----------
        This command will show all updates waiting to be installed on SCCM Client.
#>

    [cmdletbinding()]
    Param(
        [parameter()]
        [switch]$ShowHidden,
        [parameter()]
        [ValidateSet('Install','Uninstall')]
        [string]$UpdateAction = 'Install'
    )
    Begin {
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose ("{0}" -f $_)
        }
        
        $Action = [hashtable]@{
            Install = 2
            Uninstall = 3
        }
        $statusHash = [hashtable]@{
            0 = 'JobStateNone'
            1 = 'JobStateAvailable'
            2 = 'JobStateSubmitted'
            3 = 'JobStateDetecting'
            4 = 'JobStateDownloadingCIDef'
            5 = 'JobStateDownloadingSdmPkg'
            6 = 'JobStatePreDownload'
            7 = 'JobStateDownloading'
            8 = 'JobStateWaitInstall'
            9 = 'JobStateInstalling'
            10 = 'JobStatePendingSoftReboot'
            11 = 'JobStatePendingHardReboot'
            12 = 'JobStateWaitReboot'
            13 = 'JobStateVerifying'
            14 = 'JobStateInstallComplete'
            15 = 'JobStateStateError'
            16 = 'JobStateWaitServiceWindow'
        }   
        [ref]$progress = $Null            
    }
    Process {
        Write-Verbose ("UpdateAction: {0}" -f $UpdateAction)
        Try {
            $SCCMUpdate = New-Object -ComObject UDA.CCMUpdatesDeployment
            $updates = $SCCMUpdate.EnumerateUpdates(
                                                    $Action[$UpdateAction],
                                                    $PSBoundParameters['ShowHidden'],
                                                    $Progress
            )
            $Count = $updates.GetCount()
        } Catch {
            Write-Warning ("{0}" -f $_.Exception.Message)      
        }
        
        If ($Count -gt 0) {
            Write-Verbose ("Found {0} updates!" -f $Count)
            Try {
                For ($i=0;$i -lt $Count;$i++) {
                    [ref]$status = $Null
                    [ref]$Complete = $Null
                    [ref]$Errors = $Null                 
                    $update = $updates.GetUpdate($i)
                    $UpdateObject = New-Object PSObject -Property @{
                        KB = $update.GetArticleID()
                        BulletinID = {Try {$update.GetBulletinID()} Catch {}}.invoke()
                        DownloadSize = $update.GetDownloadSize()
                        EnforcementDeadline = $update.GetEnforcementDeadline()
                        ExclusiveUpdateOption = $update.GetExclusiveUpdateOption()
                        ID = $update.GetID()
                        InfoLink = $update.GetInfoLink(1033)
                        Manufacture = $update.GetManufacturer(1033)
                        Name = $update.GetName(1033)
                        NotificationOption = $update.GetNotificationOption()
                        Progress = $update.GetProgress($status,$Complete,$Errors)
                        UpdateStatus = $statusHash[$status.value]
                        ErrorCode = $Errors.Value                        
                        RebootDeadling = $update.GetRebootDeadline()
                        State = $update.GetState()
                        Summary = $update.GetSummary(1033)
                    }
                    $UpdateObject.PSTypeNames.Insert(0,'SCCMUpdate.Update')
                    $UpdateObject
                    
                }
            } Catch {
                Write-Warning ("{0}" -f $_.Exception.Message)
            }
        } Else {
            Write-Verbose 'No updates found!'
            echo "No updates found!"
        }
    }
  }

}#End SCCM-QryCoreFunction

function Get-SysInfo {

    param(
        [string[]]$ComputerName
    )

    foreach ($comp in $ComputerName) {
    $os = gwmi -Class win32_operatingsystem -ComputerName $comp
    $cs = gwmi -Class win32_computersystem -ComputerName $Comp
    $bios = gwmi -Class win32_bios -ComputerName $Comp

    $props = [ordered]@{'Computer Name' = $Comp;
               'OSVersion' = $os.version;
               'SPVersion' = $os.servicepackmajorversion;
               'MFGR' = $cs.manufacturer;
               'Model' = $cs.model;
               'RAM' = $cs.totalphysicalmemory;
               'BIOSSerial' = $bios.serialnumber
               }
    
    $obj = New-Object -TypeName PSObject -Property $props

    Write-Output $obj

    }#End foreach

}#End Get-SysInfo

function Get-LastBootUp {
    
    param(
        [string[]]$Computername
    )
    
    foreach ($comp in $Computername) {
    
        $Booter = gwmi win32_operatingsystem | 
                  select csname,@{n='Last Boot Time';e={$_.converttodatetime($_.lastbootuptime)}}
    
    }#End foreach

}#End Get-LastBootUp

function List-MassiveModule {

    Write-Host -BackgroundColor Cyan -ForegroundColor DarkBlue "Here is the list of commands for the MassiveModule"

    Get-Command -Module MyMassiveModule | Out-GridView -Title "Massive Module's Massive List of Commands"

}#End List-MassiveModule

function Reboot-Workstations {


    [string]$DomainOU = "OU=Computers,OU=HD_DSST,OU=KDHR,OU=RC South,DC=afghan,DC=swa,DC=ds,DC=army,DC=mil"

    $CurrentCompList = (Get-ADComputer -Filter * -Properties Name -SearchBase $DomainOU) | Select Name 

    Write-host -ForegroundColor Magenta `n`n "   Please enter your FULL username:"`n`n

    $CurrentUser = [Environment]::UserName

    Write-Host -ForegroundColor Magenta "`n`n
                     Problem machines will be revealed in rebooterror.csv, 
                     which will be located on your desktop.


                     micPlease press enter when you are ready to start the reboot process. `n`n"

    pause

    #$list = Get-Content C:\Scripts\Reboot\Reboot.txt

    $rebooterror = "C:\Users\$CurrentUser\Desktop\rebooterror.csv"

    echo "IP_Address,Status,Path" | Out-File -Encoding ascii -FilePath $rebooterror

    $CurrentCompList.name | ForEach-Object {

    echo "Current computer $_"

    # Test if system is online
    Invoke-Expression  "ping -n 1 -w 500 $_" | out-Null
    $ping = $LASTEXITCODE


    ### IF pingable and have admin access C$, begin!!!
    if (!$ping){

    Invoke-Expression `
    'shutdown /f /r /t 900 /m \\$_ /c "This computer requires an emergency restart to apply reecently deployed critical Network changes/modifications. You can restart now or the computer will restart automatically in 15 Minutes. If you cannot logon to the computer and need to utilize it, you may hard reboot the machine by turning off the power and restarting the machine manually. Contact Networks at 841-1009, SIPR, if you have any questions." ' 

    echo "Reboot set for $_"

    #Invoke-Expression 'shutdown /a /m \\$_'
    $shutcode= $LASTEXITCODE

    if ($shutcode -eq 5){
    echo "$_ is denied access"
    echo "$_,`"Access Denied`",$path" | Out-File -Append -Encoding ascii -FilePath $rebooterror

    }


    }
    else {

    $strName = "$_"
    $objDomain = New-Object System.DirectoryServices.DirectoryEntry
    $strFilter = "(&(objectCategory=computer)(name=" + $strName + "))"
    $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objSearcher.SearchRoot = $objDomain
    $objSearcher.Filter = $strFilter
    $strPath = $objSearcher.FindOne().Path 

    $path = ""
    if ($strPath){
    $cleanPathArr = ""
    $strPathArr = $strPath.Split(',')
    [array]::Reverse($strPathArr)   # Reverse that craps CN/OU/OU/DC > DC/OU/OU/CN
    $strPathArr | ForEach-Object {
    $split = $_.Split('=')
    [array]$cleanPathArr += $split[1]}
    $cleanPathArr[5..15] | ForEach-Object {[string]$path = $path + $_  + '/'}
    }
    #echo $path




    echo "$_ is offline"
    echo "$_,`"System is offline`",$path" | Out-File -Append -Encoding ascii -FilePath $rebooterror


    }


    }

}#End Reboot-Workstations

function Send-File {

    ##############################################################################
    ##
    ## Send-File
    ##
    ## From Windows PowerShell Cookbook (O'Reilly)
    ## by Lee Holmes (http://www.leeholmes.com/guide)
    ##
    ##############################################################################

    <#

    .SYNOPSIS

    Sends a file to a remote session.
    You'll need to create the session and store it in a variable first.

    .EXAMPLE

    PS >$session = New-PsSession leeholmes1c23
    PS >Send-File c:\temp\test.exe c:\temp\test.exe $session

    #>

    param(
        ## The path on the local computer
        [Parameter(Mandatory = $true)]
        $Source,

        ## The target path on the remote computer
        [Parameter(Mandatory = $true)]
        $Destination,

        ## The session that represents the remote computer
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession] $Session
    )

    Set-StrictMode -Version Latest

    ## Get the source file, and then get its content
    $sourcePath = (Resolve-Path $source).Path
    $sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
    $streamChunks = @()

    ## Now break it into chunks to stream
    Write-Progress -Activity "Sending $Source" -Status "Preparing file"
    $streamSize = 1MB
    for($position = 0; $position -lt $sourceBytes.Length;
        $position += $streamSize)
    {
        $remaining = $sourceBytes.Length - $position
        $remaining = [Math]::Min($remaining, $streamSize)

        $nextChunk = New-Object byte[] $remaining
        [Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
        $streamChunks += ,$nextChunk
    }
 
    $remoteScript = {
        param($destination, $length)

        ## Convert the destination path to a full filesytem path (to support
        ## relative paths)
        $Destination = $executionContext.SessionState.`
            Path.GetUnresolvedProviderPathFromPSPath($Destination)

        ## Create a new array to hold the file content
        $destBytes = New-Object byte[] $length
        $position = 0

        ## Go through the input, and fill in the new array of file content
        foreach($chunk in $input)
        {
            Write-Progress -Activity "Writing $Destination" `
                -Status "Sending file" `
                -PercentComplete ($position / $length * 100)

            [GC]::Collect()
            [Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
            $position += $chunk.Length
        }

        ## Write the content to the new file
        [IO.File]::WriteAllBytes($destination, $destBytes)
 
        ## Show the result
        Get-Item $destination
        [GC]::Collect()
    }

    ## Stream the chunks into the remote script
    $streamChunks | Invoke-Command -Session $session $remoteScript `
        -ArgumentList $destination,$sourceBytes.Length


        <#
        
        Here is the old syntax:



        Program: Transfer a File to a Remote Computer

        When you’re working with remote computers, a common problem you’ll face is how to bring your local tools and environment to that computer. Using file shares or FTP transfers is a common way to share tools between systems, but these options are not always available.

        As a solution, Example 29-7 builds on PowerShell Remoting to transfer the file content over a regular PowerShell Remoting connection.

        To do this, it reads the content of the file into an array of bytes. Then, it breaks that array into one-megabyte chunks. It streams each chunk to the remote system, which then recombines the chunks into the destination file. By breaking the file into large chunks, the script optimizes the network efficiency of PowerShell Remoting. By limiting these chunks to one megabyte, it avoids running into any quota issues.


        Example 29-7. Send-File.ps1

        ##############################################################################
        ##
        ## Send-File
        ##
        ## From Windows PowerShell Cookbook (O'Reilly)
        ## by Lee Holmes (http://www.leeholmes.com/guide)
        ##
        ##############################################################################

        <#

        .SYNOPSIS

        Sends a file to a remote session.

        .EXAMPLE

        PS > $session = New-PsSession leeholmes1c23
        PS > Send-File c:\temp\test.exe c:\temp\test.exe $session
        ##
        

        param(
            ## The path on the local computer
            [Parameter(Mandatory = $true)]
            $Source,

            ## The target path on the remote computer
            [Parameter(Mandatory = $true)]
            $Destination,

            ## The session that represents the remote computer
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.Runspaces.PSSession] $Session
        )

        Set-StrictMode -Version 3

        $remoteScript = {
            param($destination, $bytes)

            ## Convert the destination path to a full filesystem path (to support
            ## relative paths)
            $Destination = $executionContext.SessionState.`
                Path.GetUnresolvedProviderPathFromPSPath($Destination)

            ## Write the content to the new file
            $file = [IO.File]::Open($Destination, "OpenOrCreate")
            $null = $file.Seek(0, "End")
            $null = $file.Write($bytes, 0, $bytes.Length)
            $file.Close()
        }

        ## Get the source file, and then start reading its content
        $sourceFile = Get-Item $source

        ## Delete the previously-existing file if it exists
        Invoke-Command -Session $session {
            if(Test-Path $args[0]) { Remove-Item $args[0] }
        } -ArgumentList $Destination

        ## Now break it into chunks to stream
        Write-Progress -Activity "Sending $Source" -Status "Preparing file"

        $streamSize = 1MB
        $position = 0
        $rawBytes = New-Object byte[] $streamSize
        $file = [IO.File]::OpenRead($sourceFile.FullName)

        while(($read = $file.Read($rawBytes, 0, $streamSize)) -gt 0)
        {
            Write-Progress -Activity "Writing $Destination" `
                -Status "Sending file" `
                -PercentComplete ($position / $sourceFile.Length * 100)

            ## Ensure that our array is the same size as what we read
            ## from disk
            if($read -ne $rawBytes.Length)
            {
                [Array]::Resize( [ref] $rawBytes, $read)
            }

            ## And send that array to the remote system
            Invoke-Command -Session $session $remoteScript `
                -ArgumentList $destination,$rawBytes

            ## Ensure that our array is the same size as what we read
            ## from disk
            if($rawBytes.Length -ne $streamSize)
            {
                [Array]::Resize( [ref] $rawBytes, $streamSize)
            }
    
            [GC]::Collect()
            $position += $read
        }

        $file.Close()

        ## Show the result
        Invoke-Command -Session $session { Get-Item $args[0] } -ArgumentList $Destination

        
        #>



}#End Send-File

function Copy-FileToRemote {

<#
.Synopsis
Copy a file over a PSSession.
.Description
This command can be used to copy files to remote computers using PowerShell remoting.
Instead of traditional file copying, this command copies files over a PSSession. 
You can copy the same file or files to multiple computers simultaneously. Existing files will be overwritten.

This is the URL for referencing this script:
https://www.petri.com/copy-files-powershell-remoting 

NOTE: The file size cannot exceed 10MB. Files larger than 10MB will throw an exception and not be copied.

.Parameter Path
The path to the local file to be copied. The file size cannot exceed 10MB.
.Parameter Destination
The folder path on the remote computer. The path must already exist.
.Parameter Computername
The name of remote computer. It must have PowerShell remoting enabled.
.Parameter Credential
Credentials to use for the remote connection.
.Parameter Passthru
By default this command does not write anything to the pipeline unless you use -passthru.
 
.Example
PS C:\> dir C:\data\mydata.xml | copy-filetoremote -destination c:\files -Computername SERVER01 -passthru
 
 
    Directory: C:\files
 
 
Mode                LastWriteTime     Length Name                        PSComputerName
----                -------------     ------ ----                        --------------
-a---        10/17/2014   7:51 AM    3126008 mydata.xml                        SERVER01
 
Copy the local file C:\data\mydata.xml to C:\Files\mydata.xml on SERVER01.
 
.Example
PS C:\> dir c:\data\*.* | Copy-FileToRemote -destination C:\Data -computername (Get-Content c:\work\computers.txt) -passthru
 
Copy all files from C:\Data locally to the directory C:\Data on all of the computers listed in the text file computers.txt. Results will be written to the pipeline.
.Notes
Last Updated: October 17,2014
Version     : 1.0
 
Learn more:
 PowerShell in Depth: An Administrator's Guide (http://www.manning.com/jones6/)
 PowerShell Deep Dives (http://manning.com/hicks/)
 Learn PowerShell in a Month of Lunches (http://manning.com/jones3/)
 Learn PowerShell Toolmaking in a Month of Lunches (http://manning.com/jones4/)
 
  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 
.Link
Copy-Item
New-PSSession
#>
 
    [CmdletBinding(DefaultParameterSetName='Path', SupportsShouldProcess=$true)]
     param(
         [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
         [Alias('PSPath')]
         [string[]]$Path,  
         [Parameter(Position=1, Mandatory=$True,
         HelpMessage = "Enter the remote folder path",ValueFromPipelineByPropertyName=$true)]
         [string]$Destination,
         [Parameter(Mandatory=$True,HelpMessage="Enter the name of a remote computer")]
         [string[]]$Computername=[System.Environment]::MachineName,
              [pscredential][System.Management.Automation.CredentialAttribute()]$Credential=[pscredential]::Empty,
         [Switch]$Passthru
         ) 
 
         Begin {
             Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
             Write-Verbose "Bound parameters"
             Write-Verbose ($PSBoundParameters | Out-String)
             Write-Verbose "WhatifPreference = $WhatIfPreference"
             #create PSSession to remote computer
             Write-Verbose "Creating PSSessions"
             $myRemoteSessions = New-PSSession -ComputerName $Computername -Credential $credential
         
             #validate destination
             Write-Verbose "Validating destination path $destination on remote computers"
             foreach ($sess in $myRemoteSessions) {
               if (Invoke-Command {-not (Test-Path $using:destination)} -session $sess) {
                 Write-Warning "Failed to verify $destination on $($sess.ComputerName)"
                 #always remove the session
                 $sess | Remove-PSSession -WhatIf:$False
               }
 
             }
 
             #remove closed sessions from variable
             $myRemoteSessions = $myRemoteSessions | where {$_.state -eq 'Opened'}
 
             Write-Verbose ($myRemoteSessions | Out-String)
         } #begin
     
         Process {
            foreach ($item in $path) {
 
              #get the filesystem path for the item. Necessary if piping in a DIR command
              $itemPath = $item | Convert-Path
          
              #get the file contents in bytes
              $content = [System.IO.File]::ReadAllBytes($itempath)
 
              #get the name of the file from the incoming file
              $filename = Split-Path -Path $itemPath -Leaf
 
              #construct the destination file name for the remote computer
              $destinationPath = Join-path -Path $Destination  -ChildPath $filename
              Write-Verbose "Copying $itempath to $DestinationPath"
         
              #run the command remotely
              #define a scriptblock to run remotely
              $sb = {
              [cmdletbinding(SupportsShouldProcess=$True)]
              Param([bool]$Passthru,[bool]$WhatifPreference)
          
              #test if path exists
              if (-Not (Test-Path -Path $using:Destination)) {
                #this should never be reached since we are testing in the begin block
                #but just in case...
                Write-Warning "[$env:computername] Can't find path $using:Destination"
                #bail out
                Return
              }
 
              #values for WhatIf
              $target = "[$env:computername] $using:DestinationPath"
              $action = 'Copy Remote File'
 
              if ($PSCmdlet.ShouldProcess($target,$action)) {
                  #create the new file
                  [System.IO.File]::WriteAllBytes($using:DestinationPath,$using:content) 
          
                  If ($passthru) {
                    #display the result if -Passthru
                   Get-Item $using:DestinationPath
                  }  
              } #if should process
 
              } #end scriptblock
 
              Try {
                Invoke-Command -scriptblock $sb -ArgumentList @($Passthru,$WhatIfPreference) -Session $myRemoteSessions -ErrorAction Stop
              }
              Catch {
                Write-Warning "Command failed. $($_.Exception.Message)"
              }
            }
         } #process
 
         End {
            #remove PSSession
            Write-Verbose "Removing PSSessions"
            if ($myRemoteSessions) {
              #always remove sessions regardless of Whatif
              $myRemoteSessions | Remove-PSSession -WhatIf:$False
            }
            Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
         } #end
 
}#End Copy-FileToRemote

function Remote-FileCopy {
<#

.Synopsis
This shit ain't workin' yet

To avoid the “Whole file into memory” (E.g. chunking), I’d do something like this.

Create a function for reading a file into a “chunk array” which can fit into memory.

Eg. function Get-File-As-Chunks($file, $chunkSize, $startChunk=0, $maxChunks=1000) { … }

Then, get the array of corresponding “chunks”

$chunks = Get-File-As-Chunks(“MyTest.exe”, 64);

# Clear the remote file first..
Invoke-Command -Session $s -Command { Clear-Content C:\\Tmp\\RemoteSpeach.exe -Force -Encoding byte}

For each chunk, write the data (chunk) to the remote server (appending content each “chunk”)
$chunks|%{
Invoke-Command -Session $s -Command { $ARGS|Add-Content C:\\Tmp\\RemoteSpeach.exe -Force -Encoding byte} -ArgumentList $_
}

Do a loop as long as you have more chunks you could possibly read from the initial file and this should work pretty well I imagine.. :)

Hope this helps;)

#>


    # Get credentials - or you could use my previous post when automating this 
    #$credentials = Get-Credential --- I left this just in case for the future. 
    #It isn't needed on our network

    #Create a session 
    Write-Host -ForegroundColor Yellow "      Enter the name or IP of the system you want to remote to:"
    $RemoteSystem = Read-Host
    $s = New-PSSession $RemoteSystem -Port 80 #-Credential #$credentials

    # Get binary contents of your local file
    Write-Host -ForegroundColor Green "
            Enter the name of the file you want to copy

            Specify the full path if it is not in the 
            PWD (Primary Working Directory)" `n`n
    $TheFileName = Read-Host
    $content = Get-Content -encoding byte .\$TheFileName


    # Get Destination path AND file
    Write-Host -ForegroundColor Cyan "
            Enter the name of the path AND file
            destination you want to copy to on
            the remote system. "
    $TheDestinationFileName = Read-Host

    # Copy the binary contents to the remote computer
    Invoke-Command -Session $s -Command { $ARGS|Set-Content C:\users\michael.melonas.sa\desktop\$TheDestinationFileName `
    -Force -Encoding byte} -ArgumentList $content

}#End Remote-FileCopy

function Query-TAADisabledComputers {

    #Declared Variables containing the Active Directory queries for disabled computer accounts


    $DisabledComps = (Get-ADComputer -f {enabled -eq 'False'} -SearchBase `
    "ou=TAA,ou=tad,dc=nad,dc=ds,dc=usace,dc=army,dc=mil") |
    ? {$_.DistinguishedName -notlike '*OU=Disabled Devices,*'} |
    ft Name,sam*,en*,dist* -AutoSize -Wrap



    #The Query now informs the user if any ADComputers are Disabled outside of Authorized OUs, and lists them if they exist.

    if ($DisabledComps.Count -gt 0) {

        cls
        Write-Host -ForegroundColor Red `n`n"     You have Disabled Computers Outside the Disabled Devices OU"
        $DisabledComps
        Write-Host -ForegroundColor Yellow "     Would you like to Move these to the Disabled Devices OU?`n     Type 'y' for yes."


        #This is the prompt to the operator to make a decision on moving the objects.
    
        $caption = "Move Disabled AD Computers"    
        $message = "Please Confirm OU movement of Disabled Active Directory Computer Objects to the Disabled Devices OU"
        [int]$defaultChoice = 1
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Move the Objects."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not move the Objects."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($caption,$message, $options,$defaultChoice)

            switch ($result)
            
                {

                    0 {$DisabledComps | % {Move-ADObject $_.distinguishedname -TargetPath "OU=Disabled Devices,OU=BGA,OU=TAA,OU=TAD,DC=nad,DC=ds,DC=usace,DC=army,DC=mil"}}
                    1 {"You selected No."}

                }#End switch for $DisabledComps

    }#End $DisabledComps if Statement

    else {
    
        Write-Host -ForegroundColor Green `n`n"     All Disabled Computers Accounted for."

    }#End $DisabledComps else Statement

}#End Query-TAADisabledComputers

function Query-TAADisabledUsers {

    #Declared Variables containing the Active Directory queries for disabled user accounts

    $DisabledUsers = (Get-ADUser -f {enabled -eq 'False'} -SearchBase `
    "ou=TAA,ou=tad,dc=nad,dc=ds,dc=usace,dc=army,dc=mil") |
    ? {$_.DistinguishedName -notlike '*OU=Disabled Users,*'} |
    ft Name,sam*,en*,dist* -AutoSize -Wrap

    #The Query now informs the user if any ADComputers are Disabled outside of Authorized OUs, and lists them if they exist.

    if ($DisabledUsers.Count -gt 0) {

        cls
        Write-Host -ForegroundColor Red `n`n"     You have Disabled Users Outside the Disabled Users OU"
        $DisabledUsers
        Write-Host -ForegroundColor Yellow "     Would you like to Move these to the Disabled Users OU?`n"


        #This is the prompt to the operator to make a decision on moving the objects.
    
        $caption = "Move Disabled AD Users"    
        $message = "Please Confirm OU movement of Disabled Active Directory User accounts to the Disabled Users OU"
        [int]$defaultChoice = 1
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Do the job."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not do the job."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $choiceRTN = $host.ui.PromptForChoice($caption,$message, $options,$defaultChoice)

            switch ($result)
            
                {

                    0 {Move-ADObject $DisabledComps.distinguishedname -TargetPath "OU=Disabled Users,OU=Common,OU=TAA,OU=TAD,DC=nad,DC=ds,DC=usace,DC=army,DC=mil"}
                    1 {"You selected No."}

                }#End switch for $DisabledUsers

    }#End $DisabledUsers if Statement

    else {
    
        Write-Host -ForegroundColor Green `n`n"     All Disabled Computers Accounted for."

    }#End $DisabledUsers else Statement

}#Query-TAADisabledUsers

function Get-AllTAAServers {

<#

.SYNOPSIS
This command gets all servers in the USACE TAA OU.

#>

    cls

    Set-ExecutionPolicy Bypass

    Write-Host -BackgroundColor DarkCyan -ForegroundColor Yellow `n`n `
    "     Working . . . . . . . . . . . . :P     *" `n`n

    $CurrentUser = [Environment]::UserName

    $FilePath = "C:\Users\$CurrentUser\Desktop\"

    $TAA_Servers =  Get-ADComputer -Filter * -Property * -SearchBase `
                    "OU=TAA,OU=TAD,DC=nad,DC=ds,DC=usace,DC=army,DC=mil" |
                    ? -Property OperatingSystem -like "Windows Server*" |
                    Sort-Object OperatingSystem -Descending |
                    select Name,OperatingSystem,OperatingSystemServicePack,desc*,Enabled

    $TAA_ServersEnabled = Get-ADComputer -Filter {enabled -eq $true} -Property * -SearchBase `
                          "OU=TAA,OU=TAD,DC=nad,DC=ds,DC=usace,DC=army,DC=mil" |
                          ? -Property OperatingSystem -like "Windows Server*" |
                          Sort-Object OperatingSystem -Descending |
                          select Name,OperatingSystem,OperatingSystemServicePack,desc*,Enabled

    $A = ($TAA_Servers).count

    $O = ($TAA_ServersEnabled).count

    #Ask the user if it wants to export to CSV

    Write-Host -ForegroundColor Magenta -BackgroundColor Black `
    "     Would you like to export to a CSV file? [Y/N]          *"
    Write-Host -ForegroundColor Magenta -BackgroundColor Black `
    "     Default is No.                                         *" `n`n

    $ans = Read-Host 
    if ($ans -eq "Y" -or $ans -eq "y"){
 
        #It takes some time to connect, let the user know they should expect a delay
        Write-Host -ForegroundColor Yellow "     OK, here goes . . . "

        #Exporting the file to CSV
        $TAA_Servers | Export-Csv $FilePath\OurServers.csv -NoTypeInformation
        
        #Good Suggestion for formatting.
        Write-Host -ForegroundColor Magenta `n`n`n`n`n`n`n `
        "     For best results open the CSV, and save as an Excel file."`n`n

    }#End if
    
    else{
 
        #Default output
        Write-Host -ForegroundColor Cyan -BackgroundColor DarkRed `n`n `
"                                                          *
             No File will be created.                      *
                                                           *"
        Write-Host `n`n
    
    }#End else

    $TAA_Servers | Sort-Object -Property OperatingSystem -Descending |
    Out-GridView -Title "All TAA Servers"#ft -AutoSize
 
    Write-Host `n`n -ForegroundColor Yellow -BackgroundColor DarkBlue `
"                                                                           *
         We have " $A " Servers total in the TAA OU.                          *
                                                                            *"
    
    write-host -BackgroundColor DarkBlue -ForegroundColor Green `
"                                                                            *
         " $O " of these Servers are operational.                             *
                                                                            *"

    Write-Host `n`n

}#End Get-AllTAAServers


function Start-PowerCLI {

    Import-Module MyVMwareMod

}#End Start-PowerCLI

function Connect-OurVMwareServers {

    [array[]]$vCenters = ("TAA-VC2KNQ","TAA-VC3BGA")

    foreach ($vCenter in $vCenters) {

        $ans = Read-Host "Connect to $vCenter [Y/N]"
        if ($ans -eq "Y" -or $ans -eq "y"){
 
            #It takes some time to connect, let the user know they should expect a delay
            "Connecting, please wait.."
 
            #Connect to the server
            Connect-VIServer $vCenter
        }#End if
        
        else{
 
            #Display the connection syntax to help the user connect manually in the future
            "Use Connect-VIServer [server] to connect when ready"
        }#End else

    }#End foreach

}#End Connect-OurVMwareServers

function Get-UserLogons {

<#

.SYNOPSIS
This command will get ALL user accounts that have logged off and logged on to a machine.

#>
    Param (
     [string[]]$ComputerName #= (Read-Host Remote computer name)
     )

     if ($ComputerName -eq $null) {

        $ComputerName = hostname
     }
     cls
    # Awesome Reference article:
    # http://stackoverflow.com/questions/23810280/how-to-read-logon-events-and-lookup-user-information-using-powershell

    # event id 7001 is Logon, event id 7002 is Logoff
    function WinlogonEventIdToString($EventID) {switch($EventID){7001{"Logon";break}7002{"Logoff";break}}}

    # look up SID in Active Directory and cache the results in a hashtable
    $AdUsers = @{}
    function SidToAdUser($sid) {
      $AdUser = $AdUsers[$sid]
      if ($AdUser -eq $null) {
        $AdUser = $AdUsers[$sid] = [adsi]("LDAP://<SID=" + $sid + ">")
      }
      return $AdUser
    }

    $outputFilename = [System.IO.Path]::GetTempPath() + "DisplayLatestLogonEvents.html"

    # the first Select extracts the SID from the event log entry and converts the event id to a descriptive string
    # the second Select is responsible for looking up the User object in Active Directory, using the SID
    # the final Select picks the various attribute data from the User object, ready for display in the table
    # to retrieve only recent log entries, one can use something like this in Get-EventLog: -After (Get-Date).AddDays(-14)
    [string]$ServiceHTML = "<h2>All User Logons and Logoffs</h2>$(Get-Eventlog -Logname "System" -Source "Microsoft-Windows-Winlogon" -InstanceId 7001,7002 -ComputerName $ComputerName `
      | Select TimeGenerated, @{n='Operation';e={WinlogonEventIdToString $_.EventID}}, @{n='SID';e={$_.ReplacementStrings[1]}} `
      | Select TimeGenerated, Operation, @{n='AdUser';e={(SidToAdUser $_.SID)}} `
      | Select TimeGenerated, Operation, `
               @{n='Username';e={$_.AdUser.sAMAccountName}}, `
               @{n='Full name';e={$_.AdUser.firstname + " " + $_.AdUser.lastname}}, `
               @{n='Title';e={$_.AdUser.title}}, `
               @{n='Department';e={$_.AdUser.department}}, `
               @{n='Company';e={$_.AdUser.company}} `
      | ConvertTo-Html -fragment | out-string | Add-HTMLTableAttribute -AttributeName 'class' -Value 'MyTable')"

    ConvertTo-HTML -Body $ServiceHTML -Head $CSS | Out-File $outputFilename

    # this will open the default web browser
    Invoke-Expression $outputFilename

}#End Get-UserLogons

function Access-RemoteRegistryPath {

    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', 'TAA-PS2KNQ')
    $key = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')

    $key.GetSubKeyNames() | ForEach-Object {
        $subkey = $key.OpenSubKey($_)
        $i = @{}
        $i.Name = $subkey.GetValue('DisplayName')
        $i.Version = $subkey.GetValue('DisplayVersion')
        New-Object PSObject -Property $i
        $subkey.Close()
    }

    $key.Close()
    $reg.Close()

}#End Access-RemoteRegistryPath

Function Test-RegistryValue {

<#
.SYNOPSIS
This function validates a registry path and key
.DESCRIPTION
Reference website for this command:

http://stackoverflow.com/questions/5648931/test-if-registry-value-exists

Reference site for all examples listed here to find and set the proper registry keys:

https://social.technet.microsoft.com/Forums/windowsserver/en-US/e8ad7037-2b91-4ce8-a767-485189fb66c9/powershell-check-for-registry-value-and-change-if-not-correct?forum=winserverpowershell

.EXAMPLE
$val = Get-ItemProperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA"
if($val.EnableLUA -ne 0)
{
 set-itemproperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA" -value 0
}
.Example
if ((Get-ItemProperty 'hklm:software\microsoft\windows\currentversion\policies\system' -name enablelua | select -exp enablelua) -ne 0) {
    Set-ItemProperty 'hklm:software\microsoft\windows\currentversion\policies\system' -Name enablelua -Value 0 }
.Example
$val = Get-ItemProperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA"
if($val.EnableLUA -ne 0)
{
 set-itemproperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA" -value 0
}
#>

    param(
        [Alias("PSPath")]
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name
        ,
        [Parameter(Mandatory=$true)]
        [string]
        # The remote Computer
        [String[]]$ComputerName,
        [Switch]$PassThru
    ) 

    process {
        if (Test-Path $Path) {
            $Key = Get-Item -LiteralPath $Path
            if ($Key.GetValue($Name, $null) -ne $null) {
                if ($PassThru) {
                    Get-ItemProperty $Path $Name
                } else {
                    $true
                }
            } else {
                $false
            }
        } else {
            $false
        }
    }
}#End Test-RegistryValue

function Test-RegistryKeyValue {
    <#
    .SYNOPSIS
    Tests if a registry value exists.
    
    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.
    
    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'
    
    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.

    .LINKS
    https://msdn.microsoft.com/en-us/library/microsoft.win32.registryvaluekind(v=vs.110).aspx
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The remote Computer
        [String[]]$ComputerName
    )
    
    <# These are settings from Carbon that I got out of the way.
       They just check to ensure PowerShell 4.0 or newer is being used.
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    #>

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }
    
    $properties = Get-ItemProperty -Path $Path 
    if( -not $properties )
    {
        return $false
    }
    
    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }
}#End Test-RegistryKeyValue

function Import-RegistrySettings {

    <#Looping through CSV file for our registry requirements, reference below:
    http://discoposse.com/2012/01/23/csv-yeah-you-know-me-powershell-and-the-import-csv-cmdlet-part-1/
        
    Use this later to have the user get a file without Read-Host typing the damn thing:

    $file = Get-FileName

    #>

    Write-Host -ForegroundColor Magenta `n`n "
    Please select a csv file for the list of Registry
    Requirements. Only CSV files will work for this.
    Press CTRL+C to quit this process, and return to
    the prompt, or press Enter to continue." `n`n
    Pause

    [array[]]$STIGs = Import-Csv (Get-FileName) -ErrorAction SilentlyContinue

    <#
    Write-Host -ForegroundColor Magenta `n`n "
    Please select a file for the list of computers.
    Ensure that your text file contains a list of 
    computers that do not have extra spaces and 
    carriage returns. Press CTRL+C to quit this
    process, and return to the prompt, or press
    Enter to continue." `n`n
    Pause
    [string[]]$ComputerNames = (Get-FileName)
    #>
    
    [string[]]$SIDUsers = (Get-UserSidsOnThisComputer)
     
    foreach ($STIG in $STIGs){       

        #Assign the content to variables within this loop.
        $RegPath      = $STIG.Path
        $RegName      = $STIG.Name
        $RegNameType  = $STIG.ValueType
        $RegKeyValue  = $STIG.Value

        Write-Host -ForegroundColor Cyan " `n
        $RegPath is the path, `n `
        $RegName is the name of the key, `n `
        $RegNameType is the type of key, and  `n `
        $RegKeyValue is the setting it should be." `n 


            if($RegPath -like "*SIDUser*"){

                foreach ($SIDUser in $SIDUsers){

                    #$SIDRegPath = $RegPath.replace('SIDUser', $SIDUser)

                    #-------------------------------------------------------------------

                    #new-Psdrive -name $SIDUser -PSProvider Registry -root <blih>
                    #cd <blah>:
                    # Some Set-ItemProperty and Get-ItemProperty calls here referring to
                    # your PSDrive and using PowerShell variables
                    #Remove-PSDrive <blah>

                    #-------------------------------------------------------------------


                    IF(!(Test-Path $RegPath)) {
                        
                        Write-Host -ForegroundColor Yellow `n `
                        "     Creating "`n `
                              $SIDRegPath ","`n `
                        "     and applying "$RegKeyValue `n `
                        "     to the Registry "$RegName `n`n

                        New-Item -Path $RegPath -Force | Out-Null
                        New-ItemProperty -Path $SIDRegPath -Name $RegName -Value $RegKeyValue `
                        -PropertyType $RegNameType -Force | Out-Null

                    }#End IF $RegPath

                    ELSE {

                        Write-Host -ForegroundColor Yellow `n `
                        "     Applying "$RegKeyValue " in"`n `
                              $SIDRegPath `n `
                        "     to the Registry "$RegName `n`n

                        New-ItemProperty -Path $SIDRegPath -Name $RegName -Value $RegKeyValue `
                        -PropertyType $RegNameType -Force | Out-Null

                    }#End ELSE $SIDRegPath
                
                }#End foreach SIDUser

            }#End if SIDUser

            else{

                IF(!(Test-Path $RegPath)) {

                    Write-Host -ForegroundColor Yellow `n `
                    "     Creating "`n `
                    $RegPath ","`n `
                    "     and applying "$RegKeyValue `n `
                    "     to the Registry "$RegName `n`n

                    New-Item -Path $RegPath -Force | Out-Null
                    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegKeyValue `
                    -PropertyType $RegNameType -Force | Out-Null
                }#End IF $RegPath

                ELSE {

                    Write-Host -ForegroundColor Yellow `n `
                    "     Applying "$RegKeyValue " in"`n `
                          $RegPath `n `
                    "     to the Registry "$RegName `n`n

                    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegKeyValue `
                    -PropertyType $RegNameType -Force | Out-Null

                }#End ELSE $RegPath

            }#End else

        }#End foreach STIG
    
}#End Import-RegistrySetting

function Get-UserSidsOnThisComputer {

(ls 'hklm:software/microsoft/windows nt/currentversion/profilelist' ).PSchildname

}#End Get-UserSidsOnThisComputer



function Enable-Server2012R2RDP {

    [CmdletBinding()]
    param(
	    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	    [Alias("CN","Computer")]
	    [String[]]$ComputerName,
	    [String]$ErrorLog,
	    $sb = [scriptblock]::Create($rdpcmd),    

$rdpcmd=@"

#Enable Remote Desktop

set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0;


#Allow incoming RDP on firewall

Enable-NetFirewallRule -DisplayGroup "Remote Desktop";


#Enable secure RDP authentication

set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1; 

"@)

    #if(!($ComputerName)){$ComputerName = Read-Host "Computer to enable RDP on"}


    Invoke-Command -ComputerName $ComputerName -ScriptBlock $sb

}#End Enable-Server2012R2RDP

function Lightning {

    #Awesome Lightning generation script

    Param (
        [Parameter(position = 0, Mandatory = $false)]
        [ValidateScript({
            $_ -gt 0 -AND $_ -lt $Width
        })]
        $Start, 
        [Parameter(position = 1, mandatory = $false)]
        $Width = 80,
        [Parameter(position = 2, mandatory = $false)]
        $Speed = 50,
        [ValidateRange(1, 100)]
        $SplitFrequency = 5,
        [ValidateRange(1, 100)]
        $Inertia = 50
    )

    Function DrawLine {
        Param (
            [System.Collections.ArrayList]$Points
        )
        $sb = New-Object System.Text.StringBuilder (" " * ($Width + 2))
        $sb[0] = "|"
        $sb[$Width + 1] = "|"
        $Crash = @()
        foreach($Point in $Points) {
            if($sb[$Point.Location] -ne " ") {                
                $sb[$Point.Location] = "*"
                $Crash += $Points | Where-Object {$_.Location -eq $Point.Location}
            } else {
                $sb[$Point.Location] = $Point.Symbol
            }
        }
        foreach($Crashed in $Crash) {
            $Points.Remove($crashed) | Out-Null
        }
        Write-host $sb.ToString()
        if($Points.Count -eq 0) {
            return $false
        } else {
            return $true
        }
    }

    Function MovePoints {
        Param (
            [System.Collections.ArrayList]$Points
        )
        $NewPoints = New-Object System.Collections.ArrayList
        for($i = 0; $i -lt $Points.Count; $i++) {
            $InertiaRoll = Get-Random -Minimum 0 -Maximum 101
            if($InertiaRoll -gt $Inertia) {
                switch($Points[$i].Symbol) {
                    "|" {
                            $Direction = Get-Random -Minimum 0 -Maximum 2
                            switch($Direction) {
                                0 {$Symbol = "/"; $Diff = -1}
                                1 {$Symbol = "\"; $Diff = 1}
                            }
                        }
                    default { $Symbol = "|"; $Diff = 0 }
                }
            } else {
                $Symbol = $Points[$i].Symbol
                $Diff = switch($Symbol) {
                            "\" {1}
                            "/" {-1}
                            "|" {0}
                        }
            }
            $SplitRoll = Get-Random -Minimum 0 -Maximum 101
            if($SplitRoll -lt $SplitFrequency) {
                switch($Diff) {
                    0 { $LowSymbol = "/"; $HighSymbol = "\"; $LowDiff = -1; $HighDiff = 1 }
                    1 { $LowSymbol = "/"; $HighSymbol = "|"; $LowDiff = -1; $HighDiff = 0 }
                    -1 { $LowSymbol = "|"; $HighSymbol = "\"; $LowDiff = 0; $HighDiff = 1 }
                }
                $NewDirection = Get-Random -Minimum 0 -Maximum 2
                switch($NewDirection) {
                    0 {$NewSymbol = $LowSymbol; $NewDiff = $LowDiff}
                    1 {$NewSymbol = $HighSymbol; $NewDiff = $HighDiff}
                }
                $NewPoints.Add((New-Object psobject -Property @{Location = $Points[$i].Location + $NewDiff; Symbol = $NewSymbol})) | Out-Null
            }
            $Points[$i].Symbol = $Symbol
            $Points[$i].Location += $Diff
        }
        $Points.AddRange($NewPoints)
    }

    if($Start -like $null) {
        $Start = Get-Random -Minimum 1 -Maximum $Width
    }
    $Points = New-Object System.Collections.ArrayList
    $Points.Add((New-Object psobject -Property @{location = $Start; Symbol = "|"})) | Out-Null
    while((DrawLine $Points)){
        Start-Sleep -Milliseconds $Speed
        MovePoints $Points
    }


}#End Lightning

function The-Matrix {

#Hide the Scroll bars link and code.
#http://stackoverflow.com/questions/3296644/hiding-the-scrollbar-on-an-html-page
##<style type="text/css">body {overflow:hidden;}</style>


$TheMatrix = @'
<body style=margin:0>
<canvas id=q /><script>var q=document.getElementById('q'),
s=window.screen,w=q.width=s.width,h=q.height=s.height,p=Array(512).join(1).split(''),
c=q.getContext("2d"),m=Math;setInterval(function(){c.fillStyle="rgba(0,0,0,0.05)";
c.fillRect(0,0,w,h);c.fillStyle="rgba(0,255,0,1)";p=p.map(function(v,i){
c.fillText(String.fromCharCode(m.floor(2720+m.random()*33)),i*10,v);v+=10;
if(v>768+m.random()*10000)v=0;return v})},33)</script>
<style type="text/css">body {overflow:hidden;}</style>
'@
<#Other hide the scrollbars with link & code @ $Head.
#http://www.htmlgoodies.com/beyond/dhtml/article.php/3470521

$Head = @'
<!--window.open("The-Matrix.html","fs","fullscreen=yes") //-->
'@#>

    $outputFilename = [System.IO.Path]::GetTempPath() + "The-Matrix.html" 

    ConvertTo-Html -Body $TheMatrix | #-Head $Head |
    Out-File $outputFilename

    #credit to this guy for .NET solution here
    #http://www.irasenthil.com/2011/04/different-ways-to-open.html
    #[void] [System.Reflection.Assembly]::LoadWithPartialName("'System.Diagnostics")    
    [System.Diagnostics.Process]::Start("brave.exe","$outputFilename")
    
    #credit to send keyboard strokes
    #http://stackoverflow.com/questions/19824799/how-to-send-ctrl-or-alt-any-other-key
    #[void] [System.Reflection.Assembly]::LoadWithPartialName("'System.Windows.Forms")
    #[System.Windows.Forms.SendKeys]::Sendwait("{F11}")

    #Continue?
    #https://technet.microsoft.com/en-us/library/ff731008.aspx

}#End The-Matrix

function Reset-LocalAdminPassword {

    [array[]]$computers = Get-FileName
    $computers = gc $computers
    write-host -f White "     $computers "
    $password = Read-Host -prompt "Enter new password for user" -assecurestring
    $decodedpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    Foreach($computer in $computers)
    {
        write-host -f Magenta "     $computer"

         $computer
         $user = [adsi]"WinNT://$computer/administrator,user"
         $user.SetPassword($decodedpassword)
         $user.SetInfo()
    }


}#End Reset-LocalAdminPassword

function Get-MissingAndDupes {

    <#
    .SYNOPSIS
    Find duplicates, and missing numbers from a data set compared to what is expected .
    
    .DESCRIPTION
    Using a hashtable, you initialize the keys to the $expected values in the list, to 0 indicating not found. 
    Next, you loop through the actual list items, using the key lookup in the hashtable and bump the “count” by one $h.$item+=1.
    This does two things, it indicates that the item was found and if it is greater than 1, shows it appears in the list more than once.

    The last step of the process you return a list of missing and duplicates items, by creating a hashtable and casting it to 
    PSCustomObject object with two properties, Missing and Duplicate. These values are set by iterating over the values in the hashtable, 
    and any value that has 0 shows up in the Missing list, a value greater than 1 in Duplciate
    
    .EXAMPLE
    Get-MissingAndDupes (4, 4, 5, 6, 1, 7, 1,11,11) (1..12)

    .LINKS
    https://dfinke.github.io/powershell/2018/10/27/How-To-Use-PowerShell-To-Check-for-Missing-and-Duplicate-Values-in-a-List.html
    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$list,
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$expected
    )

    $h=@{}

    $count = $expected.count
    for ($idx = 0; $idx -lt $count; $idx+=1) {
        $item = $expected[$idx]
        $h.$item=0
    }

    $count = $list.count
    for ($idx = 0; $idx -lt $count; $idx+=1) {
        $item = $list[$idx]
        $h.$item+=1
    }

    [PSCustomObject]@{
        Missing   = $h.GetEnumerator().Where({$_.Value -eq 0}).Name
        Duplicate = $h.GetEnumerator().Where({$_.Value -gt 1}).Name
    }
} # End Get-MissingAndDupes

touch {

    <#
    .SYNOPSIS
    PowerShell touch command equivalent to touch in Linux.
    
    .DESCRIPTION
    PowerShell touch command equivalent to touch in Linux.

    .EXAMPLE
    touch file1.txt

    .LINKS
    https://superuser.com/questions/502374/equivalent-of-linux-touch-to-create-an-empty-file-with-powershell
    #>

    Param
    (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]
    $enteredFileName
    )

    Write-Output $null >> $enteredFileName

} #End touch

function New-2MuchInfoDynamicAnsibleInventory {

    <#
    .SYNOPSIS
    Create a Dynamic Ansible Inventory file.

    .DESCRIPTION
    Create a Dynamic Ansible Inventory file from a list of IPs.

    .EXAMPLE
    

    .LINKS
    https://qwant.com
    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $TheListedItems
    )

    BEGIN {
        $ActualUniqueIPasIP = $TheListedItems | Select-Object -Unique | ForEach-Object {[ipaddress]$_}
        $IP_Grouping = $ActualUniqueIPasIP.IPAddressToString | Group-Object { $_.Substring(0, $_.LastIndexOf('.')) }
        $TheStartIteration = $ActualUniqueIPasIP[0].IPAddressToString
        $ProperlyFormattedTable
    }#End Begin

    PROCESS {
        for ($i = 1;$i -lt ($ActualUniqueIPasIP.IPAddressToString).count; $i++) {
            if ([int]$ActualUniqueIPasIP[$i].IPAddressToString.Split('.')[3] -ne ([int]($ActualUniqueIPasIP[$i-1]).IPAddressToString.Split('.')[3] + 1)) {
                
                $ProperlyFormattedTable += @{[string]('Range' + ($i)) = (
                    $IP_Grouping.name + '.' + '['+$TheStartIteration.Split('.')[3] + ':'+$ActualUniqueIPasIP[$i-1].IPAddressToString.Split('.')[3] + ']')}
                $TheStartIteration = $ActualUniqueIPasIP[$i].IPAddressToString
            }#End if
        }#End for loop 
    }#End Process

    END {    
        $ProperlyFormattedTable += @{TheLastRange = (
            ($IP_Grouping.name)+'.'+'['+$TheStartIteration.Split('.')[3]+':'+$ActualUniqueIPasIP[($IP_Grouping.count - 1)].IPAddressToString.Split('.')[3]+']')}
        return $ProperlyFormattedTable
    }#End END

}#End New-2MuchInfoDynamicAnsibleInventory

function New-DynamicAnsibleInventory {

    <#
    .SYNOPSIS
    Create a Dynamic Ansible Inventory file.

    .DESCRIPTION
    Create a Dynamic Ansible Inventory file from a list of IPs.

    .EXAMPLE
    

    .LINKS
    https://qwant.com
    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $TheListedItems <#,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [string[]]$TheNamingConventions
        #>
    )

    BEGIN {
        $ActualUniqueIPasIP = $TheListedItems | Select-Object -Unique | ForEach-Object {[ipaddress]$_}
        $IP_Grouping = $ActualUniqueIPasIP.IPAddressToString | Group-Object { $_.Substring(0, $_.LastIndexOf('.')) }
        $TheStartIteration = $ActualUniqueIPasIP[0].IPAddressToString
        #$ProperlyFormattedTable = [pscustomobject]@{hcl=''}
        $self = @{products=@{o1x="1X";o2x="2X";pro="prototype";srv="servers"}}
        $self += @{purpose=@{dev="development";tst="testing";run="runtime";glr="glrunner"
                  bzr="bazelremote";aqu="aquasec";aap="ansible";gpu="nvidia"}}
        $self += @{inventory=@{}}
        $self += @{IPs=@{}}
    }#End Begin

    PROCESS {
        foreach ($productKey in $self.products.Keys) {
            foreach ($purposeKey in $self.purpose.Keys){
                Write-Host "u8-$productKey-$purposeKey."
                $self.inventory += @{
                    (($productKey)+'-'+($purposeKey)) = (($self.products.$productKey)+'_'+($self.purpose.$purposeKey))
                }#End $self.inventory hash        
            }#End purpose for loop            
        }#End product for loop

        for ($i = 1;$i -lt ($ActualUniqueIPasIP.IPAddressToString).count; $i++) {
            if ([int]$ActualUniqueIPasIP[$i].IPAddressToString.Split('.')[3] -ne `
            ([int]($ActualUniqueIPasIP[$i-1]).IPAddressToString.Split('.')[3] + 1)) {
                $self.IPs += @{$i=([string]$IP_Grouping.name + '.[' + [string]$TheStartIteration.Split('.')[3] `
                + ':' + [string]$ActualUniqueIPasIP[$i-1].IPAddressToString.Split('.')[3]  + ']')}
                $TheStartIteration = $ActualUniqueIPasIP[$i].IPAddressToString
            }#End if
        }#End for loop
    }#End Process

    END {    
        $self.IPs += @{$i=([string](($IP_Grouping.name) + '.[' + $TheStartIteration.Split('.')[3] `
        + ':' + $ActualUniqueIPasIP[($IP_Grouping.count - 1)].IPAddressToString.Split('.')[3] + ']'))}
        #$self.inventory.$inventoryKey = $self.inventory.$inventoryKey.Split(',')
        return $self
    }#End END

}#End New-DynamicAnsibleInventory

function New-DynamicAnsibleInventoryNumber2 {

    <#
    .SYNOPSIS
    Create a Dynamic Ansible Inventory file.

    .DESCRIPTION
    Create a Dynamic Ansible Inventory file from a list of IPs.

    .EXAMPLE
    

    .LINKS
    https://qwant.com
    #>

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $TheListedItems <#,
        [Parameter(Mandatory=$true,ValueFromPipeline=$false)]
        [string[]]$TheNamingConventions
        #>
    )

    BEGIN {
        $ActualUniqueIPasIP = $TheListedItems | Select-Object -Unique | ForEach-Object {[ipaddress]$_}
        $IP_Grouping = $ActualUniqueIPasIP.IPAddressToString | Group-Object { $_.Substring(0, $_.LastIndexOf('.')) }
        $TheStartIteration = $ActualUniqueIPasIP[0].IPAddressToString
        $self += @{products=@{o1x="1X";o2x="2X";pro="prototype";srv="servers"}}
        $self += @{purpose=@{dev="development";tst="testing";run="runtime";glr="glrunner"
                  bzr="bazelremote";aqu="aquasec";aap="ansible";gpu="nvidia"}}
        $self += @{inventory = @{}};$ProdPurposeKeyCombo;$ProdPurposeValueCombo
        $ip_blob;$TheStartIteration
    }#End Begin

    PROCESS {

        foreach ($productKey in $self.products.Keys) {
            Write-Host $productKey -ForegroundColor Cyan
            foreach ($purposeKey in $self.purpose.Keys) {
                $ip_blob = @()
                $TheStartIteration = $ActualUniqueIPasIP[0].IPAddressToString
                $ProdPurposeKeyCombo   = (($productKey)+'-'+($purposeKey))
                $ProdPurposeValueCombo = (($self.products.$productKey)+'_'+($self.purpose.$purposeKey))
                Write-Host "For u8-$productKey-$purposeKey computers, each will be assigned in $ProdPurposeValueCombo, which is in $ProdPurposeKeyCombo."
                for ($i = 0;$i -lt ($ActualUniqueIPasIP.IPAddressToString).count; $i++) {
                    $CurrentIteratedIP = [int]$ActualUniqueIPasIP[$i].IPAddressToString.Split('.')[3]
                    $TheLastIteratedIP = [int]$ActualUniqueIPasIP[$i-1].IPAddressToString.Split('.')[3]
                    
                    if  ($i -eq ($ActualUniqueIPasIP.IPAddressToString.Count -1)) {
                        $ip_blob += ([string](($IP_Grouping.name) + '.[' + $TheStartIteration.Split('.')[3] + ':' `
                        + $ActualUniqueIPasIP[($IP_Grouping.count - 1)].IPAddressToString.Split('.')[3] + ']'))
                    }#End if #>
                    
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
                    
                }#End for loop
                
                Write-Host $ip_blob -ForegroundColor Cyan

                $self.inventory += @{$ProdPurposeKeyCombo = @{$ProdPurposeValueCombo = $ip_blob}}

                Write-Host $self.inventory.$ProdPurposeKeyCombo.$ProdPurposeValueCombo -ForegroundColor Green

                #Take Pause out when fixed: Pause

            }#End purpose foreach loop            
        }#End product foreach loop
    }#End Process

    END {    
        return $self
    }#End END

}#End New-DynamicAnsibleInventory
