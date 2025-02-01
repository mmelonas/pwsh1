# Disable Inactive Users Script

This script is run on a scheduled weekly task on the primary domain controller.

|                  |                                |
| ---------------- | ------------------------------ |
| Script Location  | ahcl0sp-dc00001                |
| Folder Location  | c:\scripts\                    |
| Reports Location | c:\Reports\InactiveUsersReport |
| Schedule         | Weekly, Sunday Evening         |


**Functions:**

- Disable any accounts that have not been active for at least 35 days
- Move the account to the **Disabled** OU.
- Create CSV report for review

5 January 2023
Updated fields to check for user accounts:

 - Exclude Service Accounts by checking the Username (SamAccountName), and Distinguishedname fields
 - Ensuring to only check Enabled accounts
 - Checking the last date the account logged into a system on the domain from LastLogonTimestamp, LastLogon, and LastLogondate ADUC Attributes.

