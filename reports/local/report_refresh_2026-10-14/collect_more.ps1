$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$evidence=Join-Path $root 'reports/local/report_refresh_2026-10-14'
function Collect([string]$top,[string]$file,[string]$commands) {
    $arguments=@('-c','-onfinish','stop','-voptargs=+acc','-wlf',$file,('wave_work.'+$top),'-do',$commands)
    $log=Join-Path $evidence ('modelsim_'+$top+'.log')
    ('COMMAND: C:\modeltech64_10.5\win64\vsim.exe '+($arguments -join ' ')) | Set-Content -LiteralPath $log -Encoding utf8
    & 'C:\modeltech64_10.5\win64\vsim.exe' @arguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code" | Add-Content -LiteralPath $log
    if($code -ne 0) {throw "Wave collection $top failed $code"}
}
Push-Location $PSScriptRoot
try {
    Collect 'tb_navigation_d1' 'navigation.wlf' 'log /tb_navigation_d1/nh_valid /tb_navigation_d1/nh_phase /tb_navigation_d1/frame_valid /tb_navigation_d1/time_valid /tb_navigation_d1/bch_valid /tb_navigation_d1/record_valid /tb_navigation_d1/record_ready /tb_navigation_d1/record_data /tb_navigation_d1/dut/word_valid /tb_navigation_d1/dut/word_number /tb_navigation_d1/dut/sow /tb_navigation_d1/dut/publishing; run -all; quit -code 0 -f'
    Collect 'tb_p02_probe' 'acquisition.wlf' 'log /tb_p02_probe/coarse/state /tb_p02_probe/sample_valid /tb_p02_probe/sample_ready /tb_p02_probe/coarse_valid /tb_p02_probe/coarse_detected /tb_p02_probe/prn /tb_p02_probe/coarse_lag /tb_p02_probe/coarse_doppler /tb_p02_probe/coarse_peak /tb_p02_probe/coarse_mean /tb_p02_probe/fine_request /tb_p02_probe/refine/state /tb_p02_probe/fine_valid /tb_p02_probe/fine_detected /tb_p02_probe/fine_lag /tb_p02_probe/fine_doppler /tb_p02_probe/fine_peak; run -all; quit -code 0 -f'
    Collect 'tb_tracking_minimal' 'tracking.wlf' 'log /tb_tracking_minimal/window_done /tb_tracking_minimal/window_ref /tb_tracking_minimal/feedback_valid /tb_tracking_minimal/feedback_ref /tb_tracking_minimal/ip /tb_tracking_minimal/qp /tb_tracking_minimal/ie /tb_tracking_minimal/il /tb_tracking_minimal/dll_error_q16 /tb_tracking_minimal/pll_error_q16 /tb_tracking_minimal/code_step_q /tb_tracking_minimal/carrier_step_word /tb_tracking_minimal/locked; run 30000 us; echo TRACKING_WAVE_PARTIAL_30000US_NOT_FULL_REGRESSION; examine -radix decimal /tb_tracking_minimal/feedbacks /tb_tracking_minimal/locked /tb_tracking_minimal/sample_ref; quit -code 0 -f'
} finally {Pop-Location}
