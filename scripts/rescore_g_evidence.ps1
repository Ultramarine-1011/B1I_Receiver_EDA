param([string]$PythonPath='C:\Users\26255\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
# Reuse existing raw records/traces; never starts RTL or generates new IF.
$ErrorActionPreference='Stop';$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
function Score([string[]]$Arguments,[string]$Log) {
    "COMMAND: $PythonPath $($Arguments -join ' ')" | Set-Content -LiteralPath $Log -Encoding utf8
    & $PythonPath @Arguments 2>&1 | Out-File -LiteralPath $Log -Append -Encoding utf8
    $code=$LASTEXITCODE;"EXIT_CODE: $code" | Add-Content -LiteralPath $Log
    if($code -ne 0){throw "G scorer failed ($code): $Log"}
    Write-Output "SCORING_COMPLETED exit=0 log=$Log; inspect metric status for performance PASS/FAIL"
}
Push-Location $root
try {
    foreach($name in @('real51','real52','recovery','fixed_fifo102400')) {
        Score @('model/g_run_score.py','--folder',"reports/g_stage/$name") "reports/g_stage/$name/score_final.log"
    }
    foreach($name in @('acquisition','acquisition_cn50')) {
        Score @('model/g_acquisition_score.py','--folder',"reports/g_stage/$name") "reports/g_stage/$name/score_final.log"
    }
    foreach($folder in @('tracking','holding')) {
        foreach($truth in Get-ChildItem -LiteralPath "reports/g_stage/$folder" -Filter '*.truth.json') {
            $name=$truth.Name.Replace('.truth.json','');$base="reports/g_stage/$folder/$name"
            Score @('model/g_tracking_score.py','--trace',"${base}_detail.csv",'--truth',"$base.truth.json",'--output',"$base.metrics.json") "$base.score_final.log"
        }
    }
    Score @('model/g_recovery_score.py') 'reports/g_stage/recovery/recovery_score_final.log'
    Score @('model/g_service_summary.py') 'reports/g_stage/service/summary.log'
    foreach($name in @('real51','real52')) {
        Score @('model/online_navigation.py','--bin',"reports/g_stage/$name/receiver_records.bin",'--sidecar',"reports/g_stage/$name/receiver_records.bin.availability.jsonl",'--output',"reports/g_stage/$name/causal") "reports/g_stage/$name/causal_final.log"
    }
    Score @('model/test_g_evaluation.py') 'reports/g_stage/evaluation_tests.log'
    Score @('model/g_resource_audit.py','--output','reports/g_stage/final_resource_audit.json') 'reports/g_stage/frozen_final.log'
    Score @('model/g_delivery_audit.py') 'reports/g_stage/delivery_audit.log'
} finally {Pop-Location}
exit 0
