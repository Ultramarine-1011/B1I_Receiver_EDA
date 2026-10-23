param([string]$EvidenceDirectory='reports/f_stage/real20')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$python='C:\Users\26255\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if(-not(Test-Path -LiteralPath $python)){throw 'Bundled Python unavailable; load_workspace_dependencies and pass its verified runtime path'}
$report=Join-Path $root $EvidenceDirectory
$bin=Join-Path $report 'receiver_records.bin'
$runs=[Collections.Generic.List[object]]::new()
function Check([string[]]$Arguments,[string]$LogName) {
    $log=Join-Path $report $LogName
    "COMMAND: $python $($Arguments -join ' ')" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & $python @Arguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    $runs.Add(@{command=@($python)+$Arguments;exit_code=$code;log=$log;wall_seconds=$timer.Elapsed.TotalSeconds})
    if($code -ne 0){throw "F verification failed ($code): $log"}
}
Push-Location $root
try {
    Check @('model/receiver_multi_score.py',$report,'--require-navigation') 'score.log'
    Check @('model/f_reference_score.py',$report) 'e_prefix.log'
    $summary=Get-Content -LiteralPath (Join-Path $report 'metrics.json') -Raw | ConvertFrom-Json
    Check @('student_release/student_release/tools/check_records.py',$bin,'--expected-samples',"$($summary.samples)",'--minimum-acquisitions','4','--require-tracking') 'structure_final.log'
    Check @('student_release/student_release/tools/self_check.py',$bin,'--expected-samples',"$($summary.samples)",'--minimum-acquisitions','4','--require-tracking','--require-navigation','--require-common-observation') 'self_check.log'
    Check @('student_release/student_release/tools/route_a_position.py',$bin,'-o',(Join-Path $report 'positions.jsonl')) 'route_a.log'
    $runs | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $report 'validation_commands.json') -Encoding utf8
} finally {Pop-Location}
Write-Output 'F_PUBLIC20_VERIFICATION_PASS'
exit 0
