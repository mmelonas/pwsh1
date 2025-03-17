
function AnswerQuestions {

    [CmdletBinding()]

    param(
        [Parameter(
            Position=0,
            ParameterSetName="NonPipeline"
        )]
        [Alias("UserHomePath")]
        [string]$UserHome,

        [Parameter(
            Position=1,
            ParameterSetName="NonPipeline"
        )]
        [Alias("UserEnvironmentPath")]
        [string]$UserEnvPath
    )

    #Temp Yes/No Regex Vars
    $YesMatch        = '^y(?:e)?(?:s)?$'
    $NoMatch         = '^n(?:o)?$|^\s+$|^$'
    $UserInputEntry  = Read-Host

    switch -Regex ($UserInputEntry) {

        $YesMatch { Write-Host ''
                    Write-Host '    Copying over the latest VMware Modules . . .' -ForegroundColor Green
                    if ([System.Environment]::OSVersion.VersionString -like '*nix*'){

                        cp -r $UserHome\VMware-PowerCLI-13.1.0-21624340\* $UserEnvPath;Write-Host '';Write-Host '' 

                    }#End if *nix

                    elseif ([System.Environment]::OSVersion.VersionString -like '*windows*'){

                        cp -r $UserHome\VMware-PowerCLI-13.1.0-21624340\* $UserEnvPath -Force;Write-Host '';Write-Host '' 

                    }#End elseif Windows

                    Write-Host '';Write-Host "    Loading MyHCL.Automation module" -ForegroundColor Green;Write-Host '';Write-Host '' }#End YesMatch 

        $NoMatch { Write-Host '';Write-Host "    Loading MyHCL.Automation module" -ForegroundColor Green;Write-Host '';Write-Host '' }#End NoMatch

        default { Write-Host "
                  Insistence on dumb or stupid responses will not be tolerated.
                  Exiting the workflow," -ForegroundColor Yellow
                  Write-Host "
                  NOW!!!!!!!!!!!!!!!!!!

                  " -ForegroundColor Red;break}#End default

    }#End switch selection

}#End AnswerQuestions

function DetermineOS {

    if ([System.Environment]::OSVersion.VersionString -like '*nix*') {

        Write-Host "    It looks like you are running PowerShell on Linux. Press Enter to continue if true; otherwise CTRL+C to exit out."
        Write-Host ""
        Pause
        Write-Host ""
        Write-Host ""

        Set-Item -Path Env:USERDNSDOMAIN -Value (dnsdomainname)
        $LinuxUserHomePath = "$HOME/Documents/Git/jedi/PowerShell/Modules/"
        $TheUsersEnvPath = "$HOME/.local/share/powershell/Modules/"
        cp -r $LinuxUserHomePath/MyHCL* $TheUsersEnvPath 

        Write-Host "Would you like to copy VMware's PowerCLI Modules over to the same directory?" -ForegroundColor Cyan
        Write-Host "Please type Yes or [Default]No:" -ForegroundColor Cyan -NoNewline

        AnswerQuestions -UserHomePath $LinuxUserHomePath -UserEnvironmentPath $TheUsersEnvPath

    }#End if

    elseif ([System.Environment]::OSVersion.VersionString -like '*Windows*') {

        Write-Host "    It looks like you are running on a Microsoft Windows OS. Press Enter if true; otherwise CTRL+C to exit out."
        Write-Host ""
        Pause
        Write-Host ""
        Write-Host ""

        $WindowsUserHomePath = "$HOME\Documents\Git\jedi\PowerShell\Modules\"
        $TheUsersEnvPath     = "$env:USERPROFILE\Documents\PowerShell\Modules\"
        cp -r $env:USERPROFILE\Documents\Git\jedi\PowerShell\Modules\MyHCL* $TheUsersEnvPath -Force

        Write-Host "Would you like to copy VMware's PowerCLI Modules over to the same directory?" -ForegroundColor Cyan
        Write-Host "Please type Yes or [Default]No:" -ForegroundColor Cyan -NoNewline

        AnswerQuestions -UserHomePath $WindowsUserHomePath -UserEnvironmentPath $TheUsersEnvPath

    }#End elseif

    else { Write-Host "     You are not using Linux, Unix, or Windows. It isn't recommended to use this module yet.";break}#End else

}#End DetermineOS

DetermineOS
Import-Module MyHCL.Automation -DisableNameChecking
Get-MyHCL-Commands
CommonActiveDirectoryCommands
Set-MyVariables
Write-Host "    Press Enter to connect to vSphere and Horizon View using PowerCLI, or CTRL+C to go to the prompt." `n `n -ForegroundColor Green
Pause
Check-PowerCLIConfiguration
Write-Host `n "    Connecting to vSphere, and then Horizon View . . . " `n -ForegroundColor DarkGray
GoTo-HCL-vSphere
GoTo-HCL-HorizonView
Ask-ToRunYourADUserAcctsQuery
