param([double]$DurationSeconds=51,[ValidateSet(1,4,12)][int]$Channels=4,
      [string]$EvidenceDirectory='reports/g_stage/real51',
      [string]$InputPath='student_release/student_release/input/scenario.if2',
      [switch]$Narrow,[switch]$SkipBuild,[double]$FixedClockHz=0,[int]$FifoWords=0)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release/student_release'
$report=Join-Path $root $EvidenceDirectory
$mode=if($Narrow){1}else{0}
$build=Join-Path $root "work/verilator/g_receiver_c${Channels}_n$mode"
New-Item -ItemType Directory -Force $report,$build | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Expected drive path'}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$log) {
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    if($code -ne 0){throw "G RTL command failed ($code): $log"}
}
$rtl=Get-ChildItem (Join-Path $package 'rtl') -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name
$files=@($rtl.FullName)+(Join-Path $root 'tb/g_receiver_probe.sv')+(Join-Path $root 'scripts/g_receiver.cpp')
$hashFiles=$files+@(Get-ChildItem (Join-Path $package 'rtl') -Filter '*.svh' | Select-Object -ExpandProperty FullName)+@(Get-ChildItem (Join-Path $package 'rom') -Filter '*.mem' | Select-Object -ExpandProperty FullName)
$hashes=@($hashFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$inputFile=[IO.Path]::GetFullPath((Join-Path $root $InputPath))
$manifest=@{head=(& git -C $root rev-parse HEAD);channels=$Channels;narrow=$Narrow.IsPresent;duration_s=$DurationSeconds;
  timestamp_utc=[DateTime]::UtcNow.ToString('o');sources=$hashes;input=@{path=$inputFile;sha256=(Get-FileHash -LiteralPath $inputFile -Algorithm SHA256).Hash;bytes=(Get-Item -LiteralPath $inputFile).Length};fixed_clock_hz=$FixedClockHz;fifo_words=$FifoWords}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $report 'sources.json') -Encoding utf8
if(-not $SkipBuild) {
    $sources=($files | ForEach-Object {"'$(LinuxPath $_)'"}) -join ' '
    Run "verilator --cc --exe --build -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module g_receiver_probe -GCHANNELS=$Channels -GNARROW=$mode --Mdir '$(LinuxPath $build)' $sources" (Join-Path $report 'build.log')
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $build 'sources.json') -Encoding utf8
} else {
    $built=Get-Content -LiteralPath (Join-Path $build 'sources.json') -Raw | ConvertFrom-Json
    if($built.channels -ne $Channels -or $built.narrow -ne $Narrow.IsPresent -or @($built.sources).Count -ne $hashes.Count){throw 'SkipBuild config/source set mismatch'}
    foreach($h in $hashes){if(-not($built.sources | Where-Object {$_.path -eq $h.path -and $_.sha256 -eq $h.sha256})){throw 'SkipBuild source hash mismatch'}}
}
$bytes=[int64]([Math]::Floor($DurationSeconds*16368000/16)*4)
Run "cd '$(LinuxPath $package)' && stdbuf -oL -eL '$(LinuxPath $build)/Vg_receiver_probe' '$(LinuxPath $inputFile)' '$(LinuxPath (Join-Path $report 'receiver_records.bin'))' $bytes $FixedClockHz $FifoWords" (Join-Path $report 'run.log')
Run "cd '$(LinuxPath $root)' && python3 model/g_run_score.py --folder '$(LinuxPath $report)'" (Join-Path $report 'score.log')
exit 0
