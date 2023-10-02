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

    Remove-Variable -Force LTH,LTL -ErrorAction SilentlyContinue

    $LTH = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileLoadTimeHigh -ErrorAction SilentlyContinue).LocalProfileLoadTimeHigh
    $LTL = '{0:X8}' -f (Get-ItemProperty -Path $p.PSPath -Name LocalProfileLoadTimeLow -ErrorAction SilentlyContinue).LocalProfileLoadTimeLow
   

    $LoadTime = if ($LTH -and $LTL)
    {
        [datetime]::FromFileTime("0x$LTH$LTL")
    }else
    {
        $null
    }

    if($LoadTime -lt $((Get-Date).AddDays(-45)))
    {
        $Sids += $p.PSChildName
    }

    $p.Dispose
} 

$Sids | select -skip 3 | %{
    [string]$sid = $_
    Write-Host "Deleting`t"-NoNewline
    Write-Host $sid -ForegroundColor Green
    Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.SID -eq $sid} | Remove-WmiObject -Verbose -Confirm:$false
}