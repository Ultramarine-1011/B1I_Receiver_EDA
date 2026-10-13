param([ValidateSet('channels','manager','integration','transport','navigation','timing','metrics','all')][string]$Task='channels',
      [string]$EvidenceDirectory='reports/f_stage')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release/student_release'
$report=Join-Path $root $EvidenceDirectory
$cwd=Join-Path $root 'work/f_stage'
New-Item -ItemType Directory -Force $report,$cwd | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Expected drive path'}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$log,[switch]$ExpectFailure) {
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    if($ExpectFailure) {
        if($code -eq 0 -or (Get-Content -LiteralPath $log -Raw) -notmatch 'Invalid channel configuration|Supported independent-channel configurations') {throw 'Configuration rejection was not observed'}
        'EXPECTED_CONFIGURATION_REJECTION_PASS' | Add-Content -LiteralPath $log
    } elseif($code -ne 0){throw "Failed ($code): $log"}
}
function Sim([string]$top,[string[]]$extra,[switch]$ExpectedFailure) {
    $build=Join-Path $root "work/verilator/$top"
    New-Item -ItemType Directory -Force $build | Out-Null
    $rtl=Get-ChildItem (Join-Path $package 'rtl') -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name
    $files=@($rtl.FullName)+@($extra | ForEach-Object {Join-Path $root $_})
    $hashFiles=$files+@(Get-ChildItem (Join-Path $package 'rtl') -Filter '*.svh' | Select-Object -ExpandProperty FullName)+@(Get-ChildItem (Join-Path $package 'rom') -Filter '*.mem' | Select-Object -ExpandProperty FullName)
    @{top=$top;timestamp_utc=[DateTime]::UtcNow.ToString('o');sources=@($hashFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $report "$top.sources.json") -Encoding utf8
    Copy-Item (Join-Path $package 'rom/*.mem') $cwd -Force
    New-Item -ItemType Directory -Force (Join-Path $cwd 'rom') | Out-Null
    Copy-Item (Join-Path $package 'rom/*.mem') (Join-Path $cwd 'rom') -Force
    Copy-Item (Join-Path $root 'tb/vectors/b1i_prn_06.mem') $cwd -Force
    $sources=($files | ForEach-Object {"'$(LinuxPath $_)'"}) -join ' '
    Run "verilator --binary --timing -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module $top --Mdir '$(LinuxPath $build)' $sources" (Join-Path $report "$top.build.log")
    Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/V$top'" (Join-Path $report "$top.run.log") -ExpectFailure:$ExpectedFailure
}
if($Task -in @('channels','all')) {
    Sim 'tb_channel_bank' @('tb/tb_channel_bank.sv')
    Sim 'tb_channel_reuse' @('tb/tb_channel_reuse.sv')
}
if($Task -in @('manager','all')) {Sim 'tb_satellite_manager' @('tb/tb_satellite_manager.sv')}
if($Task -in @('navigation','all')) {
    Run "cd '$(LinuxPath $root)' && python3 model/navigation_vectors.py" (Join-Path $report 'nav_vectors.log')
    Copy-Item (Join-Path $root 'work/navigation/*.mem') $cwd -Force
    Sim 'tb_navigation_bank' @('tb/tb_navigation_bank.sv')
}
if($Task -in @('transport','all')) {
    Sim 'tb_f_transport' @('tb/tb_f_transport.sv')
    Sim 'tb_f_bad_config' @('tb/tb_f_bad_config.sv') -ExpectedFailure
}
if($Task -in @('integration','all')) {
    Run "cd '$(LinuxPath $root)' && python3 model/f_signal_vectors.py" (Join-Path $report 'synthetic_prn.log')
    Sim 'tb_f_integration' @('tb/tb_f_integration.sv')
}
if($Task -in @('metrics','all')) {Run "cd '$(LinuxPath $root)' && python3 model/performance_metrics.py --self-test" (Join-Path $report 'metrics_self_test.log')}
if($Task -in @('timing','all')) {
    Sim 'tb_p02_probe' @('tb/tb_p02_probe.sv')
    Copy-Item (Join-Path $cwd 'p02_probe.json') $report -Force
    Run "cd '$(LinuxPath $root)' && python3 model/performance_metrics.py --input '$(LinuxPath (Join-Path $report 'p02_probe.json'))' --output '$(LinuxPath (Join-Path $report 'p02_metrics.json'))'" (Join-Path $report 'p02_score.log')
}
exit 0
