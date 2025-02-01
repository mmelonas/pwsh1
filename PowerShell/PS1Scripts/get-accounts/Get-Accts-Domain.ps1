Set-StrictMode -Version latest 

#---------------------------------------------------------------------------------------------------------
#	PRE-SETUP
#---------------------------------------------------------------------------------------------------------

# Setup Powershell Window
$StartProg = Get-Date
$uniqueDate = (Get-Date).ToString("yyyyMMdd-HHmmss")
$localPath = (Get-Location).Path
$Prog_Name = $MyInvocation.MyCommand.Name
$Name = $Prog_Name.Split(".")[0]

$pshost = Get-Host              # Get the PowerShell Host.

$version = (Get-ChildItem "$($localPath)\$($Prog_Name)" | select -ExpandProperty LastWriteTime).ToString("yyyy.MM.dd.HH")
$revert = $pshost.UI.RawUI.Get_WindowTitle()
$pshost.UI.RawUI.Set_WindowTitle("$Name - $version")

$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.
$intTermW = $pswindow.windowsize # Get the UI's current Window Size.
$Summary = @(0,0)

#---------------------------------------------------------------------------------------------------------
#	VARIABLES
#---------------------------------------------------------------------------------------------------------
$LOG_FILE = "$localPath\Log_$($Name)_$($uniqueDate).txt"

$lineSep = "-" * ($intTermW.Width - 1)
$lineRes = "=" * ($intTermW.Width - 1)

$TimeSpan = New-Timespan –Days 35 
# Win 2012 (R2) DC 
# STIG V-1112, V-52854r2_rule
# Value: 35
# CCI: CCI-000795 # The organization manages information system identifiers by disabling the identifier after an organization #     defined time period of inactivity. # NIST SP 800-53 :: IA-4 e # NIST SP 800-53A :: IA-4.1 (iii) # NIST SP 800-53 Revision 4 :: IA-4 e 

#---------------------------------------------------------------------------------------------------------
#	FUNCTIONS
#---------------------------------------------------------------------------------------------------------

Function LogWrite
{
   Param ([string]$logstring, [bool]$print)

   $timezone = [Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1')
   $date = (Get-Date -Format "ddd MMM dd yyyy HH:mm:ss")
   $log_time = "[$($date) $($timezone)]"

   Add-content $LOG_FILE -value "$log_time $logstring"
   
   if ($print -eq $true)
   {
		Write-Host "$logstring"
   }
}

Function CreateTitle
{
    Param ([string]$title, [string]$symbol, [int]$totalLen)

    $intLenTitle = $title.Length
    $intHalf = [math]::floor(($totalLen - $intLenTitle - 2) / 2)

    $text = "$symbol" * $intHalf + " $title " + "$symbol" * $intHalf
   
    if ( $text.Length -ge $intTermW.Width )
    {
        return "$symbol" * $intHalf + " $title " + "$symbol" * ($intHalf - 1)
    }
    else
    {
        return $text
    }
    
}

Function ListAccounts
{
    Try
    {
        LogWrite (CreateTitle "List of All Accounts" "-" ($intTermW.Width)) $true
        $Results = (Get-ADUser -Filter *)

        ForEach ($Result in $Results)
        {
            LogWrite "$($Result)" $true
        }

        LogWrite "$($lineSep)" $true
    }
    Catch
    {
        LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
}

Function ListEnabled
{
    Try
    {
        LogWrite (CreateTitle "List of Enabled Accounts" "-" ($intTermW.Width)) $true
        $Results = (Get-ADUser -Filter * | Where-Object {$_.Enabled})

        ForEach ($Result in $Results)
        {
            LogWrite "$($Result)" $true
        }

        LogWrite "$($lineSep)" $true
    }
    Catch
    {
        LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
}

Function ListDisabled
{
    Try
    {
        LogWrite (CreateTitle "List of Disabled Accounts" "-" ($intTermW.Width)) $true
        $Results = (Search-ADAccount -AccountDisabled)

        ForEach ($Result in $Results)
        {
            LogWrite "$($Result)" $true
        }

        LogWrite "$($lineSep)" $true
    }
    Catch
    {
        LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
}

Function FindExpiredAccts
{
    Try
    {
        LogWrite (CreateTitle "Listing Expired Accounts" "-" ($intTermW.Width)) $true

        $Results = Search-ADAccount -AccountExpired -UsersOnly | Where-Object {$_.Enabled}

        if ($Results)
        {
            LogWrite "$($lineRes)" $true

            LogWrite "Listing Accounts that are found to be expired: " $true

            ForEach ($Result in $Results)
            {
                LogWrite "$($Result)" $true
            }

            LogWrite "$($lineRes)" $true

            LogWrite "FAILURE! Expired accounts are not disabled. Verify this finding!" $true

            $Summary[1]++

            LogWrite "$($lineRes)" $true
        }
        else
        {
            LogWrite "SUCCESS! No accounts were found to be expired..." $true
            $Summary[0]++
        }

        LogWrite "$($lineSep)" $true
    }
    Catch
    {
        LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
}

Function FindInActiveAccts
{
    Try
    {
        LogWrite (CreateTitle "Listing InActive Accounts" "-" ($intTermW.Width)) $true

        $Results = Search-ADAccount –UsersOnly –AccountInactive –TimeSpan $TimeSpan | Where-Object {$_.Enabled}

        if ($Results)
        {
            LogWrite "$($lineRes)" $true

            LogWrite "Listing Accounts that are found to be inactive ($TimeSpan): " $true

            ForEach ($Result in $Results)
            {
                LogWrite "$($Result)" $true
            }

            LogWrite "$($lineRes)" $true

            LogWrite "FAILURE! Inactive accounts needs to be disabled. Verify this finding!" $true

            $Summary[1]++

            LogWrite "$($lineRes)" $true
        }
        else
        {
            LogWrite "SUCCESS! No accounts were found to be inactive..." $true
            $Summary[0]++
        }

        LogWrite "$($lineSep)" $true
    }
    Catch
    {
        LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
}

Function FindAccts
{
    # Find Expired
    FindExpiredAccts

    # Find InActive
    FindInActiveAccts
}


Function Main
{
    Try
    {
        LogWrite (CreateTitle "$($Name)" "-" ($intTermW.Width)) $true
        
        ListAccounts

        ListEnabled

        ListDisabled

        # Find
        FindAccts
    }
    Catch
    {
        LogWrite "Process terminated prematurely, results may be in error..." $true
		LogWrite "$($_.Exception.GetType().FullName)" $true
		LogWrite "$($_.Exception.Message)" $true
		LogWrite "$_"
    }
    Finally
    {
       #LogWrite "$lineSep" $true
		LogWrite (CreateTitle "Completed Process Summary" "-" ($intTermW.Width)) $true

		$FinishProg = Get-Date -format HH:mm:ss
		$TimeDiff = New-TimeSpan $StartProg $FinishProg
		if ($TimeDiff.Seconds -lt 0) {
			$Days = ($TimeDiff.Days)
			$Hrs = ($TimeDiff.Hours) + 23
			$Mins = ($TimeDiff.Minutes) + 59
			$Secs = ($TimeDiff.Seconds) + 59 }
		else {
			$Days = $TimeDiff.Days
			$Hrs = $TimeDiff.Hours
			$Mins = $TimeDiff.Minutes
			$Secs = $TimeDiff.Seconds }

        $rate = "{0:P0}" -f ($Summary[0] / ($Summary[0] + $Summary[1]))

	    LogWrite "Success: $($Summary[0]) -- Failed: $($Summary[1]) --  Success Rate: $rate" $true
        
        LogWrite "$($lineSep)" $true
			
		$Difference = '{0:00} Days : {1:00} Hours : {2:00} Minutes : {3:00} Seconds' -f $Days,$Hrs,$Mins,$Secs
		
		LogWrite "Time taken to Complete: $($Difference)" $true
		
		cd $localPath

		LogWrite "Restoring powershell configuration..." $true
		LogWrite "$lineSep" $true

		# Restore
		$pshost.UI.RawUI.Set_WindowTitle($revert)
    }
}

Main