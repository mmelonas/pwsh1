$PCLIST = Get-Content '.\PCLIST.TXT'

ForEach ($computer in $PCLIST) {

    Try {
        Enter-PSSession -ComputerName $computer

        #$GetUserName = [Environment]::UserName

        #$CmdMessage has to be one line
        #$CmdMessage = {C:\windows\system32\msg.exe $GetUserName 'Hello' $GetUserName 'This is a test!'}
    
        $CmdMessage = "net stop w32time; net start w32time; w32tm /resync"
    
        Invoke-Command -Scriptblock $CmdMessage
    } Catch {
        Write-Warning "$computer failed to connect" 
    }
}