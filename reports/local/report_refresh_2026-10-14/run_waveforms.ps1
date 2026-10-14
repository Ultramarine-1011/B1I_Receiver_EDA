$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$area=$PSScriptRoot
$evidence=Join-Path $root 'reports/local/report_refresh_2026-10-14'
New-Item -ItemType Directory -Force -Path $evidence,(Join-Path $area 'rom') | Out-Null
$student=Join-Path $root 'student_release/student_release/rtl'
$inputs=@('nh20_sync.sv','d1_word_sync.sv','navigation_d1.sv','b1i_prn_gen.sv','code_nco.sv','carrier_nco_mixer.sv','epl_correlator.sv','tracking_frontend.sv','tracking_frontend_spaced.sv','tracking_channel_minimal.sv','fft4096_serial.sv','acquisition_pcps.sv','acquisition_refine.sv') | ForEach-Object {Join-Path $student $_}
$tests=@('tb_nh_d1.sv','tb_navigation_d1.sv','tb_p02_probe.sv','tb_tracking_minimal.sv')
foreach($test in $tests) {
    $source=Get-Content -LiteralPath (Join-Path $root "tb/$test") -Raw
    $source=$source.Replace('../../tb/vectors/',($root.Replace('\','/')+'/tb/vectors/'))
    $source=$source.Replace('../../reports/local/',($area.Replace('\','/')+'/'))
    [IO.File]::WriteAllText((Join-Path $area $test),$source,[Text.UTF8Encoding]::new($false))
}
Copy-Item -LiteralPath (Join-Path $root 'tb/vectors/b1i_prn_06.mem') -Destination $area
Copy-Item -Path (Join-Path $root 'student_release/student_release/rom/fft*.mem') -Destination (Join-Path $area 'rom')
Copy-Item -Path (Join-Path $root 'work/navigation/*.mem') -Destination $area
$sources=$inputs+@($tests | ForEach-Object {Join-Path $area $_})
$sources | ForEach-Object { @{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence 'wave_sources.json') -Encoding utf8
function Invoke-Logged([string]$program,[string[]]$arguments,[string]$name) {
    $log=Join-Path $evidence $name
    ('COMMAND: '+$program+' '+($arguments -join ' ')) | Set-Content -LiteralPath $log -Encoding utf8
    & $program @arguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code" | Add-Content -LiteralPath $log
    if($code -ne 0) {throw "Failed $name ($code)"}
}
Push-Location $area
try {
    Invoke-Logged 'C:\modeltech64_10.5\win64\vlib.exe' @('wave_work') 'modelsim_library.log'
    Invoke-Logged 'C:\modeltech64_10.5\win64\vlog.exe' (@('-sv','-work','wave_work',('+incdir+'+$student.Replace('\','/')))+$sources) 'modelsim_compile.log'
    Invoke-Logged 'C:\modeltech64_10.5\win64\vsim.exe' @('-c','-onfinish','stop','-voptargs=+acc','-wlf','nh_d1.wlf','wave_work.tb_nh_d1','-do','log /tb_nh_d1/nh_locked /tb_nh_d1/nh_phase /tb_nh_d1/prompt_valid /tb_nh_d1/bit_valid /tb_nh_d1/data_bit /tb_nh_d1/word_valid /tb_nh_d1/word_number /tb_nh_d1/raw_word /tb_nh_d1/information /tb_nh_d1/corrected_bits /tb_nh_d1/bch_valid /tb_nh_d1/polarity_inverted; run -all; quit -code 0 -f') 'modelsim_nh_d1.log'
} finally {Pop-Location}
