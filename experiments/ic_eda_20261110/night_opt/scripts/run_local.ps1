param([ValidateSet('arithmetic','constant','loop','tracking','fll','six','recovery')][string]$Task='arithmetic',
      [string]$EvidenceGroup='')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$experiment=Split-Path -Parent $PSScriptRoot
$root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $experiment))
$report=Join-Path $experiment "evidence/$Task"
if($EvidenceGroup){$report=Join-Path $experiment "evidence/$EvidenceGroup/$Task"}
$work=Join-Path $experiment 'work'
New-Item -ItemType Directory -Force $report,$work | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    "/mnt/$($full.Substring(0,1).ToLower())/$($full.Substring(3).Replace('\','/'))"
}
function Run([string]$command,[string]$name) {
    $log=Join-Path $report "$name.log"
    "COMMAND $command" | Set-Content $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Add-Content $log
    $code=$LASTEXITCODE
    "EXIT_CODE $code`nWALL_SECONDS $($timer.Elapsed.TotalSeconds)" | Add-Content $log
    Get-Content $log -Tail 6
    if($code -ne 0){throw "Failed $log"}
}
$rtl=Join-Path $root 'student_release/student_release/rtl'
if($Task -eq 'constant') {
    $top='tb_constant_division_equivalence'
    $files=@((Join-Path $work 'constant_division_probe.sv'),(Join-Path $experiment 'tb/tb_constant_division_equivalence.sv'))
    $options=''
} elseif($Task -eq 'loop') {
    $top='tb_loop_equivalence'
    $files=@((Join-Path $work 'loop_probes.sv'),(Join-Path $experiment 'tb/tb_loop_equivalence.sv'))
    $options=''
} elseif($Task -eq 'arithmetic') {
    $top='tb_divider_equivalence'
    $files=@((Join-Path $work 'norm_probes.sv'),(Join-Path $experiment 'tb/tb_divider_equivalence.sv'))
    $options=''
} elseif($Task -in @('tracking','fll')) {
    $top='tb_tracking_equivalence'
    $files=@('b1i_prn_gen.sv','code_nco.sv','carrier_nco_mixer.sv','epl_correlator.sv','tracking_frontend_spaced.sv') | ForEach-Object {Join-Path $rtl $_}
    $files+=@((Join-Path $experiment 'rtl/tracking_channel_minimal.sv'),(Join-Path $work 'tracking_channel_original.sv'),(Join-Path $work 'tb_tracking_equivalence.sv'))
    $options=if($Task -eq 'fll'){'-GFLL_TEST=1'}else{''}
} else {
    $top='six_receiver_probe'
    $files=@(Get-ChildItem $rtl -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name | Where-Object {$_.Name -ne 'tracking_channel_minimal.sv'} | Select-Object -ExpandProperty FullName)
    $files+=@((Join-Path $experiment 'rtl/tracking_channel_minimal.sv'),(Join-Path $root 'tb/six_receiver_probe.sv'),(Join-Path $root 'scripts/six_receiver.cpp'))
    $options='--cc --exe --build --trace --trace-depth 1'
}
@{task=$Task;timestamp_utc=[DateTime]::UtcNow.ToString('o');sources=@($files | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_).Hash}})} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $report 'sources.json') -Encoding utf8
$sources=($files | ForEach-Object {"'$(LinuxPath $_)'"}) -join ' '
$build=Join-Path $work "build_$Task"
if($Task -eq 'recovery'){$build=Join-Path $work 'build_six'}
$mode=if($Task -in @('six','recovery')){''}else{'--binary --timing'}
Run "verilator $mode --assert -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath $rtl)' --top-module $top --Mdir '$(LinuxPath $build)' $options $sources" 'build'
$cwd=$work
if($Task -in @('tracking','fll')) {
    $cwd=Join-Path $work "run_$Task"
    New-Item -ItemType Directory -Force $cwd | Out-Null
}
$arguments=''
if($Task -eq 'arithmetic'){$arguments="+PROMPT_REPLAY='$(LinuxPath (Join-Path $work 'public_prompt.txt'))'"}
if($Task -in @('six','recovery')) {
    $cwd=Join-Path $root 'work/six_channel_20261102'
    $prefix=(LinuxPath (Join-Path $work $Task))
    $arguments=if($Task -eq 'six'){"six.if2 nominal $prefix"}else{"recovery.if2 recovery $prefix"}
}
Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/V$top' $arguments" 'run'
exit 0
