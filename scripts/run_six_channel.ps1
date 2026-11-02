param([ValidateSet('navigation','receiver','permuted','paced','recovery','legacy','all')][string]$Task='all',
      [string]$EvidenceDirectory='reports/six_channel_20261102')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release/student_release'
$report=Join-Path $root $EvidenceDirectory
$cwd=Join-Path $root 'work/six_channel_20261102'
New-Item -ItemType Directory -Force $report,$cwd | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Expected drive path'}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$name) {
    $log=Join-Path $report "$name.log"
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    if($code -ne 0){throw "Failed ($code): $log"}
}
$rtl=Get-ChildItem (Join-Path $package 'rtl') -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name
$sources=($rtl | ForEach-Object {"'$(LinuxPath $_.FullName)'"}) -join ' '
$hashFiles=@($rtl.FullName)+@(Get-ChildItem (Join-Path $package 'rtl') -Filter '*.svh' | Select-Object -ExpandProperty FullName)+@(Get-ChildItem (Join-Path $package 'rom') -Filter '*.mem' | Select-Object -ExpandProperty FullName)
$hashFiles+=@('scripts/run_six_channel.ps1','scripts/six_receiver.cpp','model/six_channel_vectors.py','tb/six_receiver_probe.sv','tb/tb_six_navigation.sv') | ForEach-Object {Join-Path $root $_}
@{timestamp_utc=[DateTime]::UtcNow.ToString('o');task=$Task;sources=@($hashFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $report "$Task.sources.json") -Encoding utf8
New-Item -ItemType Directory -Force (Join-Path $cwd 'rom') | Out-Null
Copy-Item (Join-Path $package 'rom/*.mem') (Join-Path $cwd 'rom') -Force
if($Task -in @('navigation','all')) {
    $build=Join-Path $root 'work/verilator/tb_six_navigation'
    Run "verilator --binary --timing --assert -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module tb_six_navigation --Mdir '$(LinuxPath $build)' $sources '$(LinuxPath (Join-Path $root 'tb/tb_six_navigation.sv'))'" 'navigation_build'
    Run "cd '$(LinuxPath $cwd)' && '$(LinuxPath $build)/Vtb_six_navigation'" 'navigation_run'
}
if($Task -in @('receiver','permuted','paced','recovery','all')) {
    $build=Join-Path $root 'work/verilator/six_receiver'
    Run "verilator --cc --exe --build --assert --trace --trace-depth 1 -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module six_receiver_probe --Mdir '$(LinuxPath $build)' $sources '$(LinuxPath (Join-Path $root 'tb/six_receiver_probe.sv'))' '$(LinuxPath (Join-Path $root 'scripts/six_receiver.cpp'))'" 'receiver_build'
    if($Task -in @('receiver','all')) {Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/Vsix_receiver_probe' six.if2 nominal nominal" 'receiver_run'}
    if($Task -in @('permuted','all')) {Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/Vsix_receiver_probe' six.if2 permuted permuted" 'permuted_run'}
    if($Task -in @('paced','all')) {Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/Vsix_receiver_probe' six.if2 paced paced" 'paced_run'}
    if($Task -in @('recovery','all')) {Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/Vsix_receiver_probe' recovery.if2 recovery recovery" 'recovery_run'}
}
if($Task -in @('legacy','all')) {
    & (Join-Path $PSScriptRoot 'run_f_stage.ps1') -Task channels -EvidenceDirectory "$EvidenceDirectory/legacy_channels"
    if($LASTEXITCODE -ne 0){throw 'Legacy channels failed'}
    & (Join-Path $PSScriptRoot 'run_f_stage.ps1') -Task navigation -EvidenceDirectory "$EvidenceDirectory/legacy_navigation"
    if($LASTEXITCODE -ne 0){throw 'Legacy navigation failed'}
    & (Join-Path $PSScriptRoot 'run_local_verilator.ps1') -Task e0 -EvidenceDirectory "$EvidenceDirectory/legacy_e0"
    if($LASTEXITCODE -ne 0){throw 'Legacy E0 failed'}
}
exit 0
