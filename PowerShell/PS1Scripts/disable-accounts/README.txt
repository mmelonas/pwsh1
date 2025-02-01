Disable Accounts:
	
	Dependencies:

		- Disable-Accts-Domain (For Domain Systems)
			- Only on AD Server, needs the ActiveDirectory PowerShell module (feature) installed
		- Disable-Accts-Local (For the local box\Standalone)
			- Can work on any machine that has powershell. 
		- Both
			- valid_accounts.txt
		- Can be anywhere on drive (Recommended: C:\Users\)

	To Run:

		- Start Admin Powershell (needs elevated privileges, but has worked without it)
		
		- Change directory to script location
			- Ex. cd C:\Users\

		- Ensure there is a valid_accounts.txt file present at the location of the Powershell script. Each line represents a user.
			
		- Run the script
			- Ex. .\Disable-Accts-(Local|Domain).ps1
			- Script will disable any accounts not listed in the valid_accounts.txt file (both expired and inactive).
			- When completed, hit enter to exit
			
		- If the execution of scripts is disabled:
			
			-Get the current Execution Policy setting:
			
				Get-ExecutionPolicy
				
				Note the value returned to reset it back
			
			-Run the following command in Powershell:
	
				Set-ExecutionPolicy Unrestricted
	
			- You will have to change this setting back once the script is complete! Use the value presented from the Get-ExecutionPolicy command. The following is an example.
			
				Set-ExecutionPolicy restricted		

	Results:
	
		- Your results will be saved to the current directory of the running script:
			- Log file: Log_<ScriptName>_<YEAR><MONTH><DAY>-<HHMMSS>.txt