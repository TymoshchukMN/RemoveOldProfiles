$profilelist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
[array]$Sids = @()
foreach ($p in $profilelist) {
    try
    {
        $objUser = (New-Object System.Security.Principal.SecurityIdentifier($p.PSChildName)).Translate([System.Security.Principal.NTAccount]).value
    }catch
    {
        $objUser = "[UNKNOWN]"
    }

    Remove-Variable -Force LTH,LTL,UTH,UTL -ErrorAction SilentlyContinue

    $LTH = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileLoadTimeHigh -ErrorAction SilentlyContinue).LocalProfileLoadTimeHigh
    $LTL = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileLoadTimeLow -ErrorAction SilentlyContinue).LocalProfileLoadTimeLow
    $UTH = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileUnloadTimeHigh -ErrorAction SilentlyContinue).LocalProfileUnloadTimeHigh
    $UTL = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileUnloadTimeLow -ErrorAction SilentlyContinue).LocalProfileUnloadTimeLow

    $LoadTime = if ($LTH -and $LTL)
    {
        [datetime]::FromFileTime("0x$LTH$LTL")
    }else
    {
        $null
    }

    $UnloadTime = if ($UTH -and $UTL)
    {
        [datetime]::FromFileTime("0x$UTH$UTL")
    }
    else
    {
        $null
    }

    if($LoadTime -lt $((Get-Date).AddDays(-30)))
    {
        $Sids += $p.PSChildName
   
        [pscustomobject][ordered]@{
            User = $objUser
            SID = $p.PSChildName
            Loadtime = $LoadTime
            UnloadTime = $UnloadTime
        }#>
    }

    $p.Dispose()

} 

$Sids | select -skip 3 | %{
    [string]$sid = $_
    Write-Host "Deleting`t"-NoNewline
    Write-Host $sid -ForegroundColor Green
    Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.SID -eq $sid} | Remove-WmiObject -Verbose -Confirm:$false
}