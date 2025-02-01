<#
.Purpose
    Backup McAfee AV Logs to a central location
.Notes
    The following variable needs to be changed according to each networks storage locations
    1. $Path: This is the path to the storage aggregate location - Line 16
.Author
    Spencer Kitchens
    Lockheed Martin
    August 8, 2019    
#>

$Hosts = Get-Content (Read-Host "Input path to .txt host list")

#Set variables. Edit line 16 per network
#$Path = ""
$Date = Get-Date -Format yyyyMMdd
$FailedLogFile = "$Path\FailedAVLogs`_$Date.log"

foreach($H in $Hosts)
{
    #Update which client is being processed
    Write-Host -ForegroundColor Green "Backing up AV Log: $H"
    
    #Copy log to central location
    Copy-Item "\\$H\C$\ProgramData\McAfee\DesktopProtection\OnAccessScanLog.txt" -Destination "$Path\$H`_OnAccessScanLog.txt" -Verbose
}

#Ask if user wants to verify logs
$Verify = Read-Host -Prompt "Would you like to verify logs have been backed up? (y or n)"

if ($Verify -like 'y')
{
    foreach ($H in $Hosts)
    {
        #Save tests to variables
        $LogPresent = Test-Path "$Path\$H`_OnAccessScanLog.txt"

        #Test App Log
        if($LogPresent -eq $false)
        {
            Write-Host -ForegroundColor Red "Failed to backup AV Log on: $H"
            "Failed to backup AV Log on: $H" | Out-File $FailedLogFile -Append
        }
        else
        {
            Write-Host -ForegroundColor Green "AV log successfully rotated for: $H"
        }

        #Write new line after each host for better formatting
        Write-Host ""
    }
}