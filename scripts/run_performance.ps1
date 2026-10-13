param([ValidateSet('plan','metrics','run')][string]$Mode='plan',
      [ValidateSet('P01','P02','P03','P04','P05','P06','P07','P08','P09')][string]$Metric='P02',
      [string]$Manifest='reports/f_stage/performance/scenario_plan.json',
      [string]$MetricInput='', [string]$EvidenceDirectory='reports/f_stage/performance')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$report=Join-Path $root $EvidenceDirectory
New-Item -ItemType Directory -Force $report | Out-Null
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$'){throw 'Expected drive path'}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function PythonRun([string]$command,[string]$log) {
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE;"EXIT_CODE: $code" | Add-Content -LiteralPath $log
    if($code -ne 0){throw "Performance command failed: $log"}
}
if($Mode -eq 'plan') {
    PythonRun "cd '$(LinuxPath $root)' && python3 model/performance_plan.py --output '$(LinuxPath $report)'" (Join-Path $report 'plan.log')
    PythonRun "cd '$(LinuxPath $root)' && python3 model/performance_metrics.py --self-test" (Join-Path $report 'calculator.log')
} elseif($Mode -eq 'metrics') {
    if(-not $MetricInput){throw 'MetricInput must identify an actual offline evaluation trace'}
    PythonRun "cd '$(LinuxPath $root)' && python3 model/performance_metrics.py --input '$(LinuxPath (Join-Path $root $MetricInput))' --output '$(LinuxPath (Join-Path $report "$Metric.metrics.json"))'" (Join-Path $report "$Metric.metrics.log")
} else {
    $plan=Get-Content -LiteralPath (Join-Path $root $Manifest) -Raw | ConvertFrom-Json
    $task=@($plan.formal_tasks | Where-Object {$_.id -eq $Metric})
    if($task.Count -ne 1){throw 'Metric absent or duplicated in manifest'}
    if($task[0].status -eq 'BLOCKED_INPUT' -or -not $task[0].cases) {
        @{metric=$Metric;status='BLOCKED_INPUT';reason=$task[0].needed;receiver_runs=0} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $report "$Metric.run_status.json") -Encoding utf8
        Write-Output "$Metric BLOCKED_INPUT: $($task[0].needed)";exit 2
    }
    # Future legal case manifest: path/hash/origin/duration/channels/seed,
    # plus separate evaluation truth path. Only IF enters the DUT.
    foreach($case in $task[0].cases) {
        if($case.origin -notin @('official','self_generated')){throw 'Case origin required'}
        $source=Join-Path $root $case.path
        if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLower() -ne $case.sha256.ToLower()){throw 'Scenario hash mismatch'}
        if((Get-Item -LiteralPath $source).Length -lt [Math]::Floor($case.duration_s*16368000/16)*4){throw 'Scenario too short'}
        $caseReport="$EvidenceDirectory/$Metric/$($case.id)"
        & (Join-Path $PSScriptRoot 'run_fast_verilator.ps1') -Channels $case.channels -DurationSeconds $case.duration_s -InputPath $case.path -EvidenceDirectory $caseReport
        if($LASTEXITCODE -ne 0){throw "Receiver run failed for $($case.id)"}
    }
    @{metric=$Metric;status='RUN_COMPLETE_METRICS_PENDING';receiver_runs=$task[0].cases.Count;limitation='RTL simulation exit 0 is not a formal performance PASS; offline truth scoring and complete statistics required'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $report "$Metric.run_status.json") -Encoding utf8
}
exit 0
