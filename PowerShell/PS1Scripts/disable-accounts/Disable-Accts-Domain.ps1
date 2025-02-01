# ---------------------------------------------
# |  Lockheed Martin Proprietary Information  |
# ---------------------------------------------
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
# If you need to exempt application accounts from this check, please add them to the text file located at 
#    C:\Users\valid_accounts.txt
if (Test-Path "C:\Users\valid_accounts.txt")
{
    $VAL_FILE = "C:\Users\valid_accounts.txt"
}
else
{
    if (Test-Path "$localPath\valid_accounts.txt")
    {
        $VAL_FILE = "$localPath\valid_accounts.txt"
    }
    else
    {
        Write-Warning "valid_accounts.txt needs to exist (even if it is just empty)."
        Write-Warning "Manual action required as the operator needs to either know the accounts or accept that any account found might be disabled (if file is empty)."
        exit 1
    }
}


$lineSep = "-" * ($intTermW.Width - 1)
$lineRes = "=" * ($intTermW.Width - 1)

$TimeSpan = New-Timespan –Days 35 
# Win 2012 (R2) DC 
# STIG V-1112, V-52854r2_rule
# Value: 35
# CCI: CCI-000795 # The organization manages information system identifiers by disabling the identifier after an organization #     defined time period of inactivity. # NIST SP 800-53 :: IA-4 e # NIST SP 800-53A :: IA-4.1 (iii) # NIST SP 800-53 Revision 4 :: IA-4 e 

$global:Accounts = ""

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

Function ValidAccounts
{
    Try
    {
        LogWrite (CreateTitle "Obtain List of Valid Accounts" "-" ($intTermW.Width)) $true

        $global:Accounts = Get-Content "$VAL_FILE"

        ForEach ($Account in $Accounts)
        {
            LogWrite "$Account" $true
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

Function DisableExpiredAccts
{
    Try
    {
        LogWrite (CreateTitle "Disable Expired Accounts" "-" ($intTermW.Width)) $true
	
		# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
        $Results = Search-ADAccount -AccountExpired -UsersOnly | Where-Object {$_.Enabled}
		
		# Regardless of state, if the account is Expired, set the password to be expired
		# Search-ADAccount -AccountExpired -UsersOnly | Where-Object {("$Accounts" -notlike "*$($_.Name)*")} | Set-ADUser -ChangePasswordAtLogon $True 
		
        if ($Results)
        {
            LogWrite "$($lineRes)" $true

            LogWrite "Listing Accounts that are found to be expired: " $true

            ForEach ($Result in $Results)
            {
                LogWrite "$($Result)" $true
            }

            LogWrite "$($lineRes)" $true

            LogWrite "Accounts were found to be expired, attempting to disable them..." $true

            # Method 1
            #Import-Module ActiveDirectory
            #$now = (Get-Date).ToFileTime()
            #$ldapfilter = "(&(!userAccountControl:1.2.840.113556.1.4.803:=2)(accountexpires<=$now)(!accountexpires=0))"
            #Get-ADUser -ldapfilter $ldapfilter| Disable-ADAccount
			
            # Method 2
			# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
            Search-ADAccount -AccountExpired -UsersOnly | Where-Object {$_.Enabled} | Disable-ADAccount
			
            LogWrite "$($lineRes)" $true

            LogWrite "Sanity check for expired accounts..." $true
			
			# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
            $Results = Search-ADAccount -AccountExpired -UsersOnly | Where-Object {$_.Enabled}

            if ($Results)
            {
                LogWrite "FAILED! Not all expired accounts were disabled..." $true

                ForEach ($Result in $Results)
                {
                    LogWrite "$($Result)" $true
                }

                $Summary[1]++
            }
            else
            {
                LogWrite "SUCCESS! All expired accounts were disabled..." $true
                $Summary[0]++
            }

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

Function DisableInActiveAccts
{
    Try
    {
        LogWrite (CreateTitle "Disable InActive Accounts" "-" ($intTermW.Width)) $true

			
		# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
        $Results = Search-ADAccount –UsersOnly –AccountInactive –TimeSpan $TimeSpan | Where-Object {$_.Enabled -And "$Accounts" -notlike "*$($_.Name)*" }

        if ($Results)
        {
            LogWrite "$($lineRes)" $true

            LogWrite "Listing Accounts that are found to be inactive ($TimeSpan): " $true

            ForEach ($Result in $Results)
            {
                LogWrite "$($Result)" $true
            }

            LogWrite "$($lineRes)" $true

            LogWrite "Accounts were found to be inactive, attempting to disable them..." $true
			
			# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
            Search-ADAccount –UsersOnly –AccountInactive –TimeSpan $TimeSpan | Where-Object {$_.Enabled -And "$Accounts" -notlike "*$($_.Name)*" } | Disable-ADAccount

            LogWrite "$($lineRes)" $true

            LogWrite "Sanity check for inactive accounts..." $true

			# If you want OU's to be excluded, must add to the end after the $Accounts: -And (($_.distinguishedname -notlike '*OU1*') -And ($_.distinguishedname -notlike '*OU2*'))}
            $Results = Search-ADAccount –UsersOnly –AccountInactive –TimeSpan $TimeSpan | Where-Object {$_.Enabled -And "$Accounts" -notlike "*$($_.Name)*" }

            if ($Results)
            {
                LogWrite "FAILED! Not all inactive accounts were disabled..." $true
                    
                ForEach ($Result in $Results)
                {
                    LogWrite "$($Result)" $true
                }

                $Summary[1]++
            }
            else
            {
                LogWrite "SUCCESS! All inactive accounts were disabled..." $true
                $Summary[0]++
            }

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

Function DisableAccts
{
    # Disable Expired
    DisableExpiredAccts

    # Disable InActive
    DisableInActiveAccts
}


Function Main
{
    Try
    {
        LogWrite (CreateTitle "$($Name)" "-" ($intTermW.Width)) $true

        ValidAccounts
        
        ListAccounts

        LogWrite (CreateTitle "Before Disabling Accounts" "-" ($intTermW.Width)) $true

        ListEnabled

        ListDisabled

        # Disable
        DisableAccts

        LogWrite (CreateTitle "After Disabling Accounts" "-" ($intTermW.Width)) $true

        ListEnabled

        ListDisabled
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