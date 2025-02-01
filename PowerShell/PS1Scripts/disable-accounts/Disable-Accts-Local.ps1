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
$DateCheck = Get-Date
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

# Example:
#    Get-LocalUserAccount -ComputerName SERVER-A
#    Get-LocalUserAccount -ComputerName SERVER-A -UserName james | fl *
Function Get-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername,
     [string]$UserName
    )
    
    ForEach ($comp in $ComputerName) {

        [ADSI]$server="WinNT://$comp"

        if ($UserName)
        {

                foreach ($User in $UserName){
                    $server.children |
                    where {$_.schemaclassname -eq "user" -and $_.name -eq $user}
                }    
        }
        else
        {
            $server.children |
            where {$_.schemaclassname -eq "user"}
        }
    }
}

# Example:
#    Convert-UserFlag -UserFlag $user.UserFlags.Value
#    SCRIPT, ACCOUNTDISABLE, NORMAL_ACCOUNT
Function Convert-UserFlag  {

  Param ($UserFlag)

  $List = New-Object System.Collections.ArrayList

  Switch  ($UserFlag) {

      ($UserFlag  -BOR 0x0001)  {[void]$List.Add('SCRIPT')}

      ($UserFlag  -BOR 0x0002)  {[void]$List.Add('ACCOUNTDISABLE')}

      ($UserFlag  -BOR 0x0008)  {[void]$List.Add('HOMEDIR_REQUIRED')}

      ($UserFlag  -BOR 0x0010)  {[void]$List.Add('LOCKOUT')}

      ($UserFlag  -BOR 0x0020)  {[void]$List.Add('PASSWD_NOTREQD')}

      ($UserFlag  -BOR 0x0040)  {[void]$List.Add('PASSWD_CANT_CHANGE')}

      ($UserFlag  -BOR 0x0080)  {[void]$List.Add('ENCRYPTED_TEXT_PWD_ALLOWED')}

      ($UserFlag  -BOR 0x0100)  {[void]$List.Add('TEMP_DUPLICATE_ACCOUNT')}

      ($UserFlag  -BOR 0x0200)  {[void]$List.Add('NORMAL_ACCOUNT')}

      ($UserFlag  -BOR 0x0800)  {[void]$List.Add('INTERDOMAIN_TRUST_ACCOUNT')}

      ($UserFlag  -BOR 0x1000)  {[void]$List.Add('WORKSTATION_TRUST_ACCOUNT')}

      ($UserFlag  -BOR 0x2000)  {[void]$List.Add('SERVER_TRUST_ACCOUNT')}

      ($UserFlag  -BOR 0x10000)  {[void]$List.Add('DONT_EXPIRE_PASSWORD')}

      ($UserFlag  -BOR 0x20000)  {[void]$List.Add('MNS_LOGON_ACCOUNT')}

      ($UserFlag  -BOR 0x40000)  {[void]$List.Add('SMARTCARD_REQUIRED')}

      ($UserFlag  -BOR 0x80000)  {[void]$List.Add('TRUSTED_FOR_DELEGATION')}

      ($UserFlag  -BOR 0x100000)  {[void]$List.Add('NOT_DELEGATED')}

      ($UserFlag  -BOR 0x200000)  {[void]$List.Add('USE_DES_KEY_ONLY')}

      ($UserFlag  -BOR 0x400000)  {[void]$List.Add('DONT_REQ_PREAUTH')}

      ($UserFlag  -BOR 0x800000)  {[void]$List.Add('PASSWORD_EXPIRED')}

      ($UserFlag  -BOR 0x1000000)  {[void]$List.Add('TRUSTED_TO_AUTH_FOR_DELEGATION')}

      ($UserFlag  -BOR 0x04000000)  {[void]$List.Add('PARTIAL_SECRETS_ACCOUNT')}

  }

  $List -join ', '

} 

Function ListAllAccounts{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername
    )

    ForEach ($comp in $ComputerName){
    
        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            LogWrite "$($user.Name)" $true
        }
    }
}

Function List-Disable-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername
    )

    ForEach ($comp in $ComputerName){
    
        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            $flags = Convert-UserFlag -UserFlag $user.UserFlags.Value
            
            if ("$flags" -like "*ACCOUNTDISABLE*")
            {
                LogWrite "$($user.Name)" $true
            }
        }
    }
}

Function List-Enable-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername
    )

    ForEach ($comp in $ComputerName){
        
        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
        
            $flags = Convert-UserFlag -UserFlag $user.UserFlags.Value
            
            if ("$flags" -notlike "*ACCOUNTDISABLE*")
            {
                LogWrite "$($user.Name)" $true
            }
        }
    }
}

Function Find-InActive-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername
    )
    
    $Found = 0
    
    ForEach ($comp in $ComputerName){

        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            Try
            {
                $user_inact = [datetime]([string]($user.lastLogin.Value))
				$flags = Convert-UserFlag -UserFlag $user.UserFlags.Value

                if (((New-TimeSpan -Start $user_inact -End $DateCheck).days -ge $TimeSpan.days ) -And "$flags" -notlike "*ACCOUNTDISABLE*" -And "$Accounts" -notlike "*$($user.Name)*" )
                {
                    Disable-LocalUserAccount -ComputerName $comp -UserName $user.Name
                }
            }
            Catch
            {
                $err = $_
            }
            
        }
    }
    
    LogWrite "$($lineRes)" $true
    
    ForEach ($comp in $ComputerName){

        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            Try
            {
                $user_inact = [datetime]([string]($user.lastLogin.Value))
                $flags = Convert-UserFlag -UserFlag $user.UserFlags.Value
                
                if (((New-TimeSpan -Start $user_inact -End $DateCheck).days -ge $TimeSpan.days ) -And "$flags" -notlike "*ACCOUNTDISABLE*" -And "$Accounts" -notlike "*$($user.Name)*" )
                {
                    $Found++
                }
            }
            Catch
            {
                $err = $_
            }
        }
    }
    
    if ($Found -eq 0)
    {
        LogWrite "SUCCESS! No accounts were found to be InActive..." $true
        $Summary[0]++
    }
    else
    {
        LogWrite "FAILED! Not all inactive accounts were disabled..." $true
        $Summary[1]++
    }
}

Function Find-Expired-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername
    )
    
    $Found = 0
    
    ForEach ($comp in $ComputerName){

        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            Try
            {
                $user_expr = [datetime]([string]($user.AccountExpirationDate))
				$flags = Convert-UserFlag -UserFlag $user.UserFlags.Value
                
                if (($DateCheck -gt $user_expr) -And "$flags" -notlike "*ACCOUNTDISABLE*" -And "$Accounts" -notlike "*$($user.Name)*" )
                {
                    Disable-LocalUserAccount -ComputerName $comp -UserName $user.Name
                }
            }
            Catch
            {
                # Do Nothing
                $err = $_
            }          
        }
    }
    
    LogWrite "$($lineRes)" $true
    
    ForEach ($comp in $ComputerName){

        $user_accts = Get-LocalUserAccount -ComputerName $comp
        
        ForEach ($user in $user_accts)
        {
            Try
            {
                $user_expr = [datetime]([string]($user.AccountExpirationDate))
                $flags = Convert-UserFlag -UserFlag $user.UserFlags.Value
                
                if (($DateCheck -gt $user_expr) -And "$flags" -notlike "*ACCOUNTDISABLE*" -And "$Accounts" -notlike "*$($user.Name)*" )
                {
                    $Found++
                }
            }
            Catch
            {
                # Do Nothing
                $err = $_
            }  
        }
    }
    
    if ($Found -eq 0)
    {
        LogWrite "SUCCESS! No accounts were found to be expired..." $true
        $Summary[0]++
    }
    else
    {
        LogWrite "FAILED! Not all expired accounts were disabled..." $true
        $Summary[1]++
    }
}

# Example:
#    Disable-LocalUserAccount -ComputerName SERVER-A -UserName Rockey
Function Disable-LocalUserAccount{
    [CmdletBinding()]
    param (
     [parameter(ValueFromPipeline=$true,
       ValueFromPipelineByPropertyName=$true)]
     [string[]]$ComputerName=$env:computername,

     [parameter(Mandatory=$true)]
     [string[]]$UserName
    )

    ForEach ($comp in $ComputerName){

        ForEach ($User in $UserName){

            if ("$Accounts" -notlike "*$($user)*")
            {
                LogWrite "Disabling: $user" $true
                $user_acc= Get-LocalUserAccount -ComputerName $comp -UserName $user
                $user_acc.userflags.value = $user_acc.userflags.value -bor "0x0002"
                $user_acc.SetInfo()
            }
        }
    }
}

Function DisableAccts
{
    # Disable Expired
    LogWrite (CreateTitle "Disabling Expired Accounts" "-" ($intTermW.Width)) $true
    
    Find-Expired-LocalUserAccount
    
    LogWrite "$($lineSep)" $true

    # Disable InActive
    LogWrite (CreateTitle "Disabling InActive Accounts" "-" ($intTermW.Width)) $true
    
    Find-InActive-LocalUserAccount
    
    LogWrite "$($lineSep)" $true
}


Function Main
{
    Try
    {
        LogWrite (CreateTitle "$($Name)" "-" ($intTermW.Width)) $true

        ValidAccounts
        
        LogWrite (CreateTitle "Listing All Local Accounts" "-" ($intTermW.Width)) $true
        
        ListAllAccounts
        
        LogWrite "$($lineSep)" $true

        LogWrite (CreateTitle "Before Disabling Accounts" "-" ($intTermW.Width)) $true
        
        LogWrite (CreateTitle "List of Locally Enabled Accounts" "-" ($intTermW.Width)) $true

        List-Enable-LocalUserAccount
        
        LogWrite "$($lineSep)" $true
        
        LogWrite (CreateTitle "List of Locally Disabled Accounts" "-" ($intTermW.Width)) $true

        List-Disable-LocalUserAccount
        
        LogWrite "$($lineSep)" $true

        # Disable
        DisableAccts

        LogWrite (CreateTitle "After Disabling Accounts" "-" ($intTermW.Width)) $true

        LogWrite (CreateTitle "List of Locally Enabled Accounts" "-" ($intTermW.Width)) $true

        List-Enable-LocalUserAccount
        
        LogWrite "$($lineSep)" $true
        
        LogWrite (CreateTitle "List of Locally Disabled Accounts" "-" ($intTermW.Width)) $true

        List-Disable-LocalUserAccount
        
        LogWrite "$($lineSep)" $true
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
        
        if ($Summary[0] -eq 0 -And $Summary[1] -eq 0)
        {
            $Summary[1] = 1
        }

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