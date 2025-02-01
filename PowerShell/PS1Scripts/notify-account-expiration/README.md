# Account Expiration Notification Script

Assuming that you want to run this as a scheduled task on the domain controller, for this script to function, there are a couple things you will want to do.

- Create an Active Directory service account specifically to run the scheduled task.
- Give that service account the "Log on as a batch job" user right.
- Make sure that account has write permissions to the c:\scripts directory.

Once the account is created, on the Default Domain Controller Policy (or whichever policy is relevant), set the following configuration.

Computer Configuration \ Windows Settings \ Security Settings \ Local Policies \ User Rights Assignment

Set Log on as a batch job to "Defined" and add the service account.