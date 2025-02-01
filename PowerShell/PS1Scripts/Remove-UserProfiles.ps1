function Remove-UserProfiles {
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

}#End Remove-UserProfiles.

Remove-UserProfiles
