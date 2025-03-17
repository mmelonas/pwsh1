Welcome to my PowerShell repo!

After cloning this repository to get successfully started up you need:

1. workstation (wa), member server (ms), and Domain Administrator (da) active accounts in Active Directory

2. PowerShell installed, which is only needed to be installed on Linux systems.

3. Check the Set-MyVariables PowerShell variables for credentials and servers you may want to manually input.

4. run the ./jedi/PowerShell/PS1Scripts/Start-MyApps.ps1 script
---
**NOTE**
        
        Make sure you check your repository path in the script.
        The script is statically set, and the default path used by this repository is:

        ~/Documents/Git/
        
        You can adapt to this File Hierarchy schema, or modify the script with what you want.
---

5. After running through all of the steps displayed in the Start-MyApps PowerShell script
   you should be connected to vSphere, Horizon View, and able to use the customized cmd-lets
   found in the MyHCL.Automation.psm1 PowerShell Module.

From here explore the commands, use them to your advantage, and report back anything you think
should be improved or not working as expected. Have fun!