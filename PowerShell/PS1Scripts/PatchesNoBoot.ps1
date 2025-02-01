$MSUs = Get-ChildItem \\ahcl0uv-share01\admin2\software_installs\Microsoft\Updates\*.msu
foreach ($file in $MSUs) 
{
    Try 
    {
        Write-Host ("`n Preparing to install: " + $file) -ForegroundColor Yellow
        Write-Host ("`n Installing...") -ForegroundColor Magenta
        $SB = 
        {
            $arglist = "$file", "/quiet", "/norestart"
            Start-Process -FilePath "C:\windows\system32\wusa.exe" -ArgumentList $arglist -Wait
        }
            Invoke-Command -ScriptBlock $SB
            Write-Host "`n Installation complete`n" -ForegroundColor Green
    }
    Catch 
    {
        [System.Exception]
        Write-Host "Installation failed with Error -- $Error()" -ForegroundColor Red
        $Error.Clear()
    }
}

$CABs = Get-ChildItem \\ahcl0uv-share01\admin2\software_installs\Microsoft\Updates\*.cab
foreach ($file in $CABs) 
{
    Try 
    {
        Write-Host ("`n Preparing to install: " + $file) -ForegroundColor Yellow
        Write-Host ("`n Installing...") -ForegroundColor Magenta
        $SB = 
        {
            $arglist = "/Online", "/Add-Package", "/PackagePath:$file"
            Start-Process -FilePath "dism.exe" -ArgumentList $arglist -Wait
        }
            Invoke-Command -ScriptBlock $SB
            Write-Host "`n Installation complete`n" -ForegroundColor Green
    }
    Catch 
    {
        [System.Exception]
        Write-Host "Installation failed with Error -- $Error()" -ForegroundColor Red
        $Error.Clear()
    }
}

$MSIs = Get-ChildItem \\ahcl0uv-share01\admin2\software_installs\Microsoft\Updates\*.msi
foreach ($file in $MSIs) 
{
    Try 
    {
        Write-Host ("`n Preparing to install: " + $file) -ForegroundColor Yellow
        Write-Host ("`n Installing...") -ForegroundColor Magenta
        $SB = 
        {
            $arglist = "/i", "$file", "/quiet"
            Start-Process -FilePath "C:\windows\system32\msiexec.exe" -ArgumentList $arglist -Wait
        }
            Invoke-Command -ScriptBlock $SB
            Write-Host "`n Installation complete`n" -ForegroundColor Green
    }
    Catch 
    {
        [System.Exception]
        Write-Host "Installation failed with Error -- $Error()" -ForegroundColor Red
        $Error.Clear()
    }
}

#Restart-Computer -Force