
function Get-MyADAccountsStatus {

    Write-Host '

    #
    #####################################################################################################
    #                                                                                                   #
    #                                                                                                   #
    #Common Commands I use on the DC:                                                                   #
    #                                                                                                   #
    #Import-Module ActiveDirectory                                                                      #
    #Get-ADUser -f {name -like "*melonas*"} -prop * |                                                   #
    #               ft name,sam*me,en*,when*,lock*, `                                                   #
    #               @{l="Account Lockout Time";e={[datetime]::FromFileTime($_.AccountLockoutTime)}}, `  #
    #               @{l="Last Logon Timestamp";e={[datetime]::FromFileTime($_.lastlogontimestamp)}}, `  #
    #               last*te,@{l="Last Logon";e={[datetime]::FromFileTime($_.lastlogon)}} -autosize      #
    #                                                                                                   #
    #ncpa.cpl   Opens the Network Connections to change IP settings in the Windows GUI.                 #
    #mstsc      Opens RDP GUI.                                                                          #
    #####################################################################################################
    
    
    Would you like to run the Get-ADUser command above?
    
    
    ' -ForegroundColor Green

    $MyAnswer = Read-Host "Answer [Y]es or <Default>[N]o"
    Write-Host `n `n "You answered $MyAnswer" `n `n -ForegroundColor Gray

        switch -Regex ($MyAnswer) {

        '^y(?:e)?(?:s)?$' { 

            Get-ADUser -f {name -like '*melonas*'} -prop * |
                ft name,sam*me,en*,when*,lock*, `
                @{l='Account Lockout Time';e={[datetime]::FromFileTime($_.AccountLockoutTime)}}, `
                @{l='Last Logon Timestamp';e={[datetime]::FromFileTime($_.lastlogontimestamp)}}, `
                last*te,@{l='Last Logon';e={[datetime]::FromFileTime($_.lastlogon)}} -AutoSize
                break
                    }#End regex yes
        
        default    { Write-Host "Dropping to the shell." ; break }#End default

            }#End switch selection


}#End Get-MyADAccountsStatus

Get-MyADAccountsStatus 