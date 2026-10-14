param([string]$PythonPath='C:\Users\26255\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe')
$ErrorActionPreference='Stop';$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$small=Join-Path $root 'reports/g_stage/fixed_fifo64';New-Item -ItemType Directory -Force $small | Out-Null
try {
    & (Join-Path $PSScriptRoot 'run_g_rtl.ps1') -DurationSeconds .1 -Channels 4 -Narrow -SkipBuild -FixedClockHz 100000000 -FifoWords 64 -InputPath work/g_stage/signals/recovery/scenario.if2 -EvidenceDirectory reports/g_stage/fixed_fifo64
    throw 'Small FIFO unexpectedly completed; expected overflow was not observed'
} catch {
    $log=Join-Path $small 'run.log'
    if(-not(Test-Path -LiteralPath $log) -or (Get-Content -LiteralPath $log -Raw) -notmatch 'G_FIXED_SOURCE_FIFO_OVERFLOW'){throw}
    @{status='FAIL';scope='actual fixed-rate 100MHz-assumed source with finite 64-word FIFO';expected_overflow_observed=$true;limitation='This is a measured capacity failure for the specified model, not an official clock or a general real-time qualification'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $small 'status.json') -Encoding utf8
    Write-Output 'G_EXPECTED_SMALL_FIFO_OVERFLOW_RECORDED status=FAIL capacity_words=64'
}
& (Join-Path $PSScriptRoot 'run_g_rtl.ps1') -DurationSeconds .1 -Channels 4 -Narrow -SkipBuild -FixedClockHz 100000000 -FifoWords 102400 -InputPath work/g_stage/signals/recovery/scenario.if2 -EvidenceDirectory reports/g_stage/fixed_fifo102400
if($LASTEXITCODE -ne 0){throw 'Large finite FIFO diagnostic did not complete'}
@{status='SELF_GENERATED_PASS';scope='bounded 0.1s IF, paced source at assumed100MHz, FIFO102400 words';limitation='Finite input fits buffer. Completion does not prove sustained real-time or physical timing closure.'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'reports/g_stage/fixed_fifo102400/status.json') -Encoding utf8
exit 0
