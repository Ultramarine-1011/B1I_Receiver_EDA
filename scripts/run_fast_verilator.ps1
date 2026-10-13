param([double]$DurationSeconds=1,[string]$EvidenceDirectory='reports/e_stage/fast', [switch]$SkipBuild,[switch]$Backpressure)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release/student_release'
$report=Join-Path $root $EvidenceDirectory
$build=Join-Path $root 'work/verilator/receiver_fast'
New-Item -ItemType Directory -Force $report,$build,(Join-Path $package 'output') | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Expected drive path'}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$log) {
    "COMMAND: $command" | Set-Content $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content $log
    if($code -ne 0){throw "Failed ($code): $log"}
}
$rtl=Get-ChildItem (Join-Path $package 'rtl') -Filter '*.sv' | Sort-Object @{Expression={if($_.Name -like '*_pkg.sv'){0}else{1}}},Name
$sourceFiles=@($rtl.FullName)+@(Get-ChildItem (Join-Path $package 'rtl') -Filter '*.svh' | Select-Object -ExpandProperty FullName)+@(Get-ChildItem (Join-Path $package 'rom') -Filter '*.mem' | Select-Object -ExpandProperty FullName)+(Join-Path $root 'scripts/receiver_fast.cpp')
$sourceHashes=@($sourceFiles | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
$manifest=@{duration=$DurationSeconds;timestamp_utc=[DateTime]::UtcNow.ToString('o');sources=$sourceHashes;backpressure=$Backpressure.IsPresent;driver='direct clock RTL; IF2/record transport only'}
$manifest | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $report 'sources.json') -Encoding utf8
if(-not $SkipBuild) {
    $sources=($rtl | ForEach-Object {"'$(LinuxPath $_.FullName)'"}) -join ' '
    Run "verilator --cc --exe --build -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module student_receiver_core --Mdir '$(LinuxPath $build)' $sources '$(LinuxPath (Join-Path $root 'scripts/receiver_fast.cpp'))'" (Join-Path $report 'build.log')
} else {
    $previous=Join-Path $build 'sources.json'
    if(-not(Test-Path $previous)){throw 'No stored built source manifest'}
    $built=Get-Content $previous -Raw | ConvertFrom-Json
    foreach($item in $sourceHashes){if(-not($built.sources | Where-Object {$_.path -eq $item.path -and $_.sha256 -eq $item.sha256})){throw 'SkipBuild source differs from built manifest'}}
}
Copy-Item (Join-Path $report 'sources.json') (Join-Path $build 'sources.json') -Force
$maxBytes=[int64]([Math]::Floor($DurationSeconds*16368000/16)*4)
$bin=Join-Path $package 'output/receiver_records.bin'
$stallArgument=if($Backpressure){'--stall-output'}else{''}
Run "cd '$(LinuxPath $package)' && stdbuf -oL -eL '$(LinuxPath $build)/Vstudent_receiver_core' input/scenario.if2 '$(LinuxPath $bin)' $maxBytes $stallArgument" (Join-Path $report 'run.log')
Copy-Item $bin $report -Force
Run "cd '$(LinuxPath $package)' && python3 tools/check_records.py output/receiver_records.bin --expected-samples $($maxBytes*4) --minimum-acquisitions 4 --require-tracking" (Join-Path $report 'structure.log')
