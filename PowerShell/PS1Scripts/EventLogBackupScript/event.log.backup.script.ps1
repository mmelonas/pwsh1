######################################################################################################################
# Windows Event Log Backup Script
#
# UNCLASSIFIED
# Information that the owner desires to protect from unauthorized disclosure to a Third Party (an individual or entity
# other than Lockheed Martin such as a supplier, contractor, partner, customer, or competitor) that can provide the 
# owner with a business, technological, or economic advantage over its competitors, or which, if known or used by a 
# Third Party or if used by the owner's employees or agents in an unauthorized manner, might be detrimental to the 
# owner's interests.  Refer to CRX-015C for more information.
#
# Author: Martin Parlier
#
######################################################################################################################

######################################################################################################################
# Setting Expectations
######################################################################################################################
<# The idea here is to perform the following:
    1. Rotate the logs on each machine, and store those logs locally on each machine.
    2. Compress the logs on each machine.
    3. Copy the logs from each machine to a central file share.
    4. Ultimately, the logs should end up in \\ahcl0uv-share01\admin2\security\win.event.logs\$hostname\$date
#>

#Requires -RunAsAdministrator
$starttime=Get-Date
$date = (Get-Date -Format yyyyMMdd)
$workstations = $PSScriptRoot + "\workstations.txt"
$collection = Get-Content $workstations
# $logdir = "\\ahcl0uv-share01\admin2\security\win.event.logs"

######################################################################################################################
# Create the central shared folder based on hostname, if it does not exist.
######################################################################################################################
Write-Output "============================================"
Write-Host -ForegroundColor Green "Checking for central file share folders"
Write-Output "============================================"

foreach ($item in $collection) {
    if ((Test-Path -Path "\\ahcl0uv-share01\admin2\security\win.event.logs\$item\$date") -eq $false) {
        New-Item -Path "\\ahcl0uv-share01\admin2\security\win.event.logs\$item" -name "$date" -ItemType Directory | Out-Null
    }
}

######################################################################################################################
# Back up logs locally on each machine.
######################################################################################################################
Write-Output "============================================"
Write-Host -ForegroundColor Green "Backing up logs locally on each machine."
Write-Output "============================================"

foreach ($item in $collection) {
    # Update which client is being processed.
    Write-Host -ForegroundColor Yellow "Rolling logs on: $item"

    Invoke-Command -ComputerName $item -ScriptBlock {
        
        # Bring over variables to remote session
        $LocalLogPath = "c:\temp"

        # Create local log directory if not present
        if ((Test-Path -Path $LocalLogPath) -eq $false) {
            New-Item -Path $LocalLogPath -ItemType "directory" | Out-Null
        }

        # Back up and clear the application log
        $ApplicationLog = Get-WmiObject -Class Win32_NTEventlogFile | Where-Object LogfileName -EQ 'application'
        if((Test-Path -Path $LocalLogPath\application.evtx) -eq $true) {
            Remove-Item $LocalLogPath\application.evtx
        }
        $ApplicationLog.BackupEventlog('c:\temp\application.evtx') | Out-Null

        $SystemLog = Get-WmiObject -Class Win32_NTEventlogFile | Where-Object LogfileName -EQ 'system'
        if((Test-Path -Path $LocalLogPath\system.evtx) -eq $true) {
            Remove-Item $LocalLogPath\system.evtx
        }
        $SystemLog.BackupEventlog('c:\temp\system.evtx') | Out-Null

        $SecurityLog = Get-WmiObject -Class Win32_NTEventlogFile | Where-Object LogfileName -EQ 'security'
        if((Test-Path -Path $LocalLogPath\security.evtx) -eq $true) {
            Remove-Item $LocalLogPath\security.evtx
        }
        $SecurityLog.BackupEventlog('c:\temp\security.evtx') | Out-Null
    }
}

######################################################################################################################
# Compress logs locally on each machine.
######################################################################################################################
Write-Output "============================================"
Write-Host -ForegroundColor Green "Compressing logs locally on each machine."
Write-Output "============================================"

foreach ($item in $collection) {

    Write-Host -ForegroundColor Yellow "Compressing logs on: $item"

    Invoke-Command -ComputerName $item -ScriptBlock {
        $date = (Get-Date -Format yyyyMMdd)
        $hostname = $env:COMPUTERNAME
        Compress-Archive "c:\temp\*.evtx" "c:\temp\$date.$hostname.zip" -Force
    }
}

######################################################################################################################
# Copy the files from each machine to the windows file share.
######################################################################################################################
Write-Output "============================================"
Write-Host -ForegroundColor Green "Copying the compressed log files from each machine to the central file share."
Write-Host -ForegroundColor Green "File share = \\ahcl0uv-share01\admin2\security\win.event.logs"
Write-Output "============================================"

$RemoteLogPath = "C$\temp"
foreach ($item in $collection) {

    Write-Host -ForegroundColor Yellow "Copying logs for: $item"
    Copy-Item "\\$item\$RemoteLogPath\$date.$item.zip" -Destination "\\ahcl0uv-share01\admin2\security\win.event.logs\$item\$date"
}

######################################################################################################################
# Print out script start/end times.
######################################################################################################################
$endtime=Get-Date
Write-Output ""
Write-Output "============================================"
$collection
Write-Output "============================================"
Write-Output ""
Write-Output "Started $starttime"
Write-Output "Finished $endtime"