param([ValidateSet('acquisition','tracking','hold','recovery','service','all')][string]$Task='acquisition',[double]$AcquisitionCn0=40,
      [string]$PythonPath='C:\Users\26255\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
$ErrorActionPreference='Stop';$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot;$package=Join-Path $root 'student_release/student_release'
function LinuxPath([string]$path){$p=[IO.Path]::GetFullPath($path);if($p -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Drive path required'};"/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"}
function Run([string]$command,[string]$log){
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8;$timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE;"EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    if($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match '\$readmem[^\r\n]*file not found'){throw "G regression structural failure ($code): $log"}
}
function Py([string[]]$Arguments,[string]$log){
    "COMMAND: $PythonPath $($Arguments -join ' ')" | Set-Content -LiteralPath $log -Encoding utf8
    & $PythonPath @Arguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE;"EXIT_CODE: $code" | Add-Content -LiteralPath $log;if($code -ne 0){throw "G Python failed ($code): $log"}
}
function Build([string]$top,[string[]]$extra,[string]$folder,[string]$arguments=''){
    $build=Join-Path $root "work/verilator/$top$arguments";$build=$build.Replace(' ','_').Replace('=','_')
    New-Item -ItemType Directory -Force $build,$folder | Out-Null
    $rtl=Get-ChildItem (Join-Path $package 'rtl') -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name
    $files=@($rtl.FullName)+@($extra | ForEach-Object {Join-Path $root $_})
    $hashFiles=$files+@(Get-ChildItem (Join-Path $package 'rtl') -Filter '*.svh' | Select-Object -ExpandProperty FullName)+@(Get-ChildItem (Join-Path $package 'rom') -Filter '*.mem' | Select-Object -ExpandProperty FullName)
    @{head=(& git -C $root rev-parse HEAD);top=$top;parameters=$arguments;sources=@($hashFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $folder 'sources.json') -Encoding utf8
    $sources=($files | ForEach-Object {"'$(LinuxPath $_)'"}) -join ' '
    $cpp=@($extra | Where-Object {$_ -like '*.cpp'}).Count -gt 0
    $kind=if($cpp){'--cc --exe --build'}else{'--binary --timing'}
    Run "verilator $kind -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module $top $arguments --Mdir '$(LinuxPath $build)' $sources" (Join-Path $folder 'build.log') | Out-Host
    return $build
}
if($Task -in @('acquisition','all')) {
    $name=if($AcquisitionCn0 -eq 40){'acquisition'}else{"acquisition_cn$([int]$AcquisitionCn0)"}
    $folder=Join-Path $root "reports/g_stage/$name";New-Item -ItemType Directory -Force $folder | Out-Null
    Py @('model/g_acquisition_vectors.py','--cn0',"$AcquisitionCn0",'--name',$name) (Join-Path $folder 'vectors.log')
    $build=Build 'tb_g_acquisition' @('tb/tb_g_acquisition.sv') $folder
    New-Item -ItemType Directory -Force (Join-Path $root "work/g_stage/$name/rom") | Out-Null
    Copy-Item (Join-Path $package 'rom/*.mem') (Join-Path $root "work/g_stage/$name/rom") -Force
    Run "cd '$(LinuxPath (Join-Path $root "work/g_stage/$name"))' && stdbuf -oL -eL '$(LinuxPath $build)/Vtb_g_acquisition'" (Join-Path $folder 'run.log')
    Copy-Item (Join-Path $root "work/g_stage/$name/acquisition_results.jsonl") $folder -Force
    Py @('model/g_acquisition_score.py','--folder',$folder) (Join-Path $folder 'score.log')
}
if($Task -in @('tracking','all')) {
    $folder=Join-Path $root 'reports/g_stage/tracking';New-Item -ItemType Directory -Force $folder | Out-Null
    $build=Build 'g_tracking_probe' @('tb/g_tracking_probe.sv','scripts/g_tracking.cpp') $folder
    foreach($case in @(@('static',4,4300,0),@('D01',5,4301,0),@('D02',8,4302,0),@('D03',7,4303,0),@('D04',6,4304,9750))) {
        $name=$case[0];$seconds=$case[1];$trace=Join-Path $folder "$name`_detail.csv"
        $signal=Join-Path $root "work/g_stage/signals/$name"
        $cached=$false
        if(Test-Path -LiteralPath (Join-Path $signal 'truth.json')) {
            $known=Get-Content -LiteralPath (Join-Path $signal 'truth.json') -Raw | ConvertFrom-Json
            $cached=$known.duration_s -eq $seconds -and $known.noise_seed -eq $case[2] -and $known.cn0_db_hz -eq 40 -and $known.generator_sha256 -eq (Get-FileHash -LiteralPath (Join-Path $root 'model/g_signal_scenarios.py') -Algorithm SHA256).Hash.ToLower()
            if($cached){$cached=(Get-FileHash -LiteralPath (Join-Path $signal 'scenario.if2') -Algorithm SHA256).Hash.ToLower() -eq $known.if_sha256}
        }
        if(-not $cached){Py @('model/g_signal_scenarios.py','--kind',$name,'--seconds',"$seconds",'--seed',"$($case[2])",'--cn0','40') (Join-Path $folder "$name.vectors.log")}
        else {"CACHED_SIGNAL_HASH_MATCH kind=$name generator=$($known.generator_sha256) IF=$($known.if_sha256)" | Set-Content -LiteralPath (Join-Path $folder "$name.vectors.log")}
        Run "cd '$(LinuxPath $package)' && stdbuf -oL -eL '$(LinuxPath $build)/Vg_tracking_probe' '$(LinuxPath (Join-Path $signal 'scenario.if2'))' '$(LinuxPath $trace)' $([int64]($seconds*16368000)) $($case[3])" (Join-Path $folder "$name.run.log")
        Copy-Item (Join-Path $signal 'truth.json') (Join-Path $folder "$name.truth.json") -Force
        Py @('model/g_tracking_score.py','--trace',$trace,'--truth',(Join-Path $folder "$name.truth.json"),'--output',(Join-Path $folder "$name.metrics.json")) (Join-Path $folder "$name.score.log")
    }
}
if($Task -in @('recovery','all')) {
    $folder=Join-Path $root 'reports/g_stage/recovery';New-Item -ItemType Directory -Force $folder | Out-Null
    Py @('model/g_rf_recovery_vectors.py') (Join-Path $folder 'vectors.log')
    Copy-Item (Join-Path $root 'work/g_stage/signals/recovery/truth.json') $folder -Force
    & (Join-Path $PSScriptRoot 'run_g_rtl.ps1') -DurationSeconds 40 -Channels 4 -Narrow -InputPath work/g_stage/signals/recovery/scenario.if2 -EvidenceDirectory reports/g_stage/recovery
    if($LASTEXITCODE -ne 0){throw 'G RF recovery structural run failed'}
    Py @('model/g_recovery_score.py') (Join-Path $folder 'recovery_score.log')
}
if($Task -in @('hold','all')) {
    $folder=Join-Path $root 'reports/g_stage/holding';New-Item -ItemType Directory -Force $folder | Out-Null
    $build=Build 'g_tracking_probe' @('tb/g_tracking_probe.sv','scripts/g_tracking.cpp') $folder
    foreach($cn0 in @(50,40)) {
        $name="hold_cn$cn0";$trace=Join-Path $folder "$name`_detail.csv"
        Py @('model/g_signal_scenarios.py','--kind','static','--seconds','62','--seed',"$(4350+$cn0)",'--cn0',"$cn0",'--warm-cn0','50','--name',$name) (Join-Path $folder "$name.vectors.log")
        $signal=Join-Path $root "work/g_stage/signals/$name"
        Run "cd '$(LinuxPath $package)' && stdbuf -oL -eL '$(LinuxPath $build)/Vg_tracking_probe' '$(LinuxPath (Join-Path $signal 'scenario.if2'))' '$(LinuxPath $trace)' 1014816000 0" (Join-Path $folder "$name.run.log")
        Copy-Item (Join-Path $signal 'truth.json') (Join-Path $folder "$name.truth.json") -Force
        Py @('model/g_tracking_score.py','--trace',$trace,'--truth',(Join-Path $folder "$name.truth.json"),'--output',(Join-Path $folder "$name.metrics.json")) (Join-Path $folder "$name.score.log")
    }
}
if($Task -in @('service','all')) {
    foreach($channels in @(1,4,12)) {
        $folder=Join-Path $root "reports/g_stage/service/c$channels";New-Item -ItemType Directory -Force $folder | Out-Null
        $build=Build 'g_bank_service' @('tb/g_bank_service.sv','scripts/g_bank.cpp') $folder "-GCHANNELS=$channels"
        Run "cd '$(LinuxPath $package)' && stdbuf -oL -eL '$(LinuxPath $build)/Vg_bank_service' '$(LinuxPath (Join-Path $package 'input/scenario.if2'))' 1636800 '$(LinuxPath (Join-Path $folder 'metrics.json'))'" (Join-Path $folder 'run.log')
    }
    Py @('model/g_service_summary.py') (Join-Path $root 'reports/g_stage/service/summary.log')
}
exit 0
