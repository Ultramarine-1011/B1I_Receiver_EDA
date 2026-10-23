param([string]$PythonPath='C:\Users\26255\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe',
      [string]$EvidenceDirectory='reports/g_stage/real52')
$ErrorActionPreference='Stop';$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot;$folder=Join-Path $root $EvidenceDirectory
$commands=[Collections.Generic.List[object]]::new()
function Check([string[]]$Arguments,[string]$logName) {
    $log=Join-Path $folder $logName;"COMMAND: $PythonPath $($Arguments -join ' ')" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew();& $PythonPath @Arguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE;"EXIT_CODE: $code`nWALL_SECONDS: $($timer.Elapsed.TotalSeconds)" | Add-Content -LiteralPath $log
    $commands.Add(@{arguments=$Arguments;exit_code=$code;wall_seconds=$timer.Elapsed.TotalSeconds;log=$log})
    if($code -ne 0){throw "G delivery check failed ($code): $log"}
}
Push-Location $root
try {
    Check @('student_release/student_release/tools/check_records.py',(Join-Path $folder 'receiver_records.bin'),'--expected-samples','851136000','--minimum-acquisitions','4','--require-tracking') 'structure_final.log'
    Check @('student_release/student_release/tools/self_check.py',(Join-Path $folder 'receiver_records.bin'),'--expected-samples','851136000','--minimum-acquisitions','4','--require-tracking','--require-navigation','--require-common-observation') 'self_check.log'
    Check @('model/f_reference_score.py',$folder) 'e_prefix.log'
    Check @('model/receiver_multi_score.py',$folder,'--require-navigation') 'independent_NAV.log'
    Copy-Item -LiteralPath (Join-Path $folder 'metrics.json') -Destination (Join-Path $folder 'receiver_validation.json') -Force
    Check @('model/g_run_score.py','--folder',$folder) 'score.log'
    Check @('model/online_navigation.py','--bin',(Join-Path $folder 'receiver_records.bin'),'--sidecar',(Join-Path $folder 'receiver_records.bin.availability.jsonl'),'--output',(Join-Path $folder 'causal')) 'causal_replay.log'
    $commands | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $folder 'validation_commands.json') -Encoding utf8
} finally {Pop-Location}
Write-Output 'G_PUBLIC52_RECORD_VERIFICATION_PASS'
exit 0
