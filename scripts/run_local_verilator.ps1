param([ValidateSet('bridge','smoke','frontend','acquisition','tracking','pull','nhd1','nhprompt','navigation','e0','fft','pcps','real')][string]$Task='bridge',
      [string]$EvidenceDirectory='reports/e_stage',[double]$DurationSeconds=1)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release\student_release'
$report=Join-Path $root $EvidenceDirectory
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$') {throw "Not a drive path: $full"}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$log) {
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    $timer=[Diagnostics.Stopwatch]::StartNew()
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code" | Add-Content -LiteralPath $log
    "WALL_SECONDS: $($timer.Elapsed.TotalSeconds.ToString('F3',[Globalization.CultureInfo]::InvariantCulture))" | Add-Content -LiteralPath $log
    if($code -ne 0) {throw "Command failed ($code): $log"}
}
function Sim([string]$top,[string[]]$files,[string]$cwd,[string]$plusArgs='') {
    @{
        timestamp_utc=[DateTime]::UtcNow.ToString('o');top=$top;cwd=$cwd;plusargs=$plusArgs
        sources=@($files | ForEach-Object { $sourceFile=Join-Path $root $_; @{path=$_;sha256=(Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash} })
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $report "$top.sources.json") -Encoding utf8
    $build=Join-Path $root "work\verilator\$top"
    New-Item -ItemType Directory -Force -Path $build | Out-Null
    $sources=($files | ForEach-Object {"'$(LinuxPath (Join-Path $root $_))'"}) -join ' '
    Run "verilator --binary --timing -j 2 -O2 -CFLAGS '-O3' -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $root 'rtl'))' -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module $top --Mdir '$(LinuxPath $build)' $sources" (Join-Path $report "$top.build.log")
    Run "cd '$(LinuxPath $cwd)' && stdbuf -oL -eL '$(LinuxPath $build)/V$top' $plusArgs" (Join-Path $report "$top.run.log")
}
New-Item -ItemType Directory -Force -Path $report | Out-Null
$student=@('student_release/student_release/rtl/receiver_contract_pkg.sv','student_release/student_release/rtl/stream_unpacker.sv','student_release/student_release/rtl/student_receiver_core.sv')
$studentDatapath=@('student_release/student_release/rtl/b1i_prn_gen.sv','student_release/student_release/rtl/code_nco.sv','student_release/student_release/rtl/carrier_nco_mixer.sv','student_release/student_release/rtl/epl_correlator.sv','student_release/student_release/rtl/tracking_frontend.sv','student_release/student_release/rtl/acquisition_serial.sv','student_release/student_release/rtl/tracking_frontend_spaced.sv','student_release/student_release/rtl/tracking_channel_minimal.sv')
$studentDatapath+=@('student_release/student_release/rtl/fft4096_serial.sv','student_release/student_release/rtl/acquisition_pcps.sv','student_release/student_release/rtl/acquisition_refine.sv')
$studentDatapath+=@('student_release/student_release/rtl/nh20_sync.sv','student_release/student_release/rtl/d1_word_sync.sv','student_release/student_release/rtl/navigation_d1.sv')
$studentDatapath+=@('student_release/student_release/rtl/receiver_single.sv','student_release/student_release/rtl/receiver_channel.sv','student_release/student_release/rtl/receiver_multichannel.sv')
$studentDatapath+=@('student_release/student_release/rtl/tracking_record_framer.sv')
$studentDatapath+=@('student_release/student_release/rtl/satellite_manager.sv')
if($Task -eq 'bridge') {
    Sim 'tb_stream_unpacker' @($student[1],'tb/tb_stream_unpacker.sv') $root
    Sim 'tb_student_transport' @($student + $studentDatapath + 'tb/tb_student_transport.sv') $root
} elseif($Task -eq 'smoke') {
    $output=Join-Path $package 'output'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    Sim 'tb_student_file_smoke' @($student + $studentDatapath + @('student_release/student_release/sim/if2_file_player.sv','student_release/student_release/sim/receiver_tb_template.sv','tb/tb_student_file_smoke.sv')) $package '+MAX_BYTES=40920'
    $p=LinuxPath $package
    Run "cd '$p' && python3 tools/decode_records.py output/receiver_records.bin -o output/receiver_records.jsonl" (Join-Path $report 'decode_records.log')
    # This is an A-stage structure-only check, not the receiver functional check.
    Run "cd '$p' && python3 tools/check_records.py output/receiver_records.bin --expected-samples 163680 --minimum-acquisitions 0" (Join-Path $report 'transport_structure.log')
    $command="cd '$p' && python3 tools/self_check.py output/receiver_records.bin --expected-samples 163680 --minimum-acquisitions 4 --require-tracking --require-navigation --require-common-observation"
    "COMMAND: $command" | Set-Content -LiteralPath (Join-Path $report 'receiver_functional.log')
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath (Join-Path $report 'receiver_functional.log') -Append
    $functionalCode=$LASTEXITCODE
    "EXIT_CODE: $functionalCode" | Add-Content -LiteralPath (Join-Path $report 'receiver_functional.log')
    "Transport finished. Receiver functional check exit=$functionalCode (acquisition/tracking/navigation remain incomplete)."
} elseif($Task -eq 'e0') {
    $cwd=Join-Path $root 'work\e0'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_receiver_e0' @($student + $studentDatapath + 'tb/tb_receiver_e0.sv') $cwd
    Sim 'tb_receiver_tail' @($student + $studentDatapath + 'tb/tb_receiver_tail.sv') $cwd
    Run "cd '$(LinuxPath $root)' && python3 model/receiver_e0_score.py" (Join-Path $report 'e0_score.log')
} elseif($Task -eq 'fft') {
    Run "cd '$(LinuxPath $root)' && python3 model/fft_fixed.py" (Join-Path $report 'fft_vectors.log')
    Sim 'tb_fft4096' @('student_release/student_release/rtl/fft4096_serial.sv','tb/tb_fft4096.sv') (Join-Path $root 'work/fft')
} elseif($Task -eq 'pcps') {
    Sim 'tb_pcps_real' @('student_release/student_release/rtl/b1i_prn_gen.sv','student_release/student_release/rtl/fft4096_serial.sv','student_release/student_release/rtl/acquisition_pcps.sv','student_release/student_release/rtl/stream_unpacker.sv','student_release/student_release/sim/if2_file_player.sv','tb/tb_pcps_real.sv') $package '+MAX_BYTES=16368'
} elseif($Task -eq 'real') {
    $maxBytes=[int64]([Math]::Floor($DurationSeconds*16368000/16)*4)
    New-Item -ItemType Directory -Force (Join-Path $package 'output') | Out-Null
    Sim 'tb_receiver_multi' @($student + $studentDatapath + @('student_release/student_release/sim/if2_file_player.sv','student_release/student_release/sim/receiver_tb_template.sv','tb/tb_receiver_multi.sv')) $package "+MAX_BYTES=$maxBytes"
    Run "cd '$(LinuxPath $package)' && python3 tools/decode_records.py output/receiver_records.bin -o output/receiver_records.jsonl" (Join-Path $report 'real_decode.log')
    Run "cd '$(LinuxPath $package)' && python3 tools/check_records.py output/receiver_records.bin --expected-samples $($maxBytes*4) --minimum-acquisitions 4 --require-tracking" (Join-Path $report 'real_structure.log')
} elseif($Task -eq 'acquisition') {
    Run "cd '$(LinuxPath $root)' && python3 model/acquisition_vectors.py" (Join-Path $report 'acquisition_vectors.log')
    $cwd=Join-Path $root 'work\acquisition'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_acquisition_serial' @('rtl/b1i_prn_gen.sv','rtl/code_nco.sv','rtl/carrier_nco_mixer.sv','rtl/epl_correlator.sv','rtl/tracking_frontend.sv','student_release/student_release/rtl/acquisition_serial.sv','tb/tb_acquisition_serial.sv') $cwd
    Run "cd '$(LinuxPath $root)' && python3 model/acquisition_vectors.py --check" (Join-Path $report 'acquisition_float_score.log')
} elseif($Task -eq 'tracking' -or $Task -eq 'pull') {
    $cwd=Join-Path $root 'work\tracking'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    $trackingFiles=@('rtl/b1i_prn_gen.sv','rtl/code_nco.sv','rtl/carrier_nco_mixer.sv','rtl/epl_correlator.sv','student_release/student_release/rtl/tracking_frontend_spaced.sv','student_release/student_release/rtl/tracking_channel_minimal.sv','tb/tb_tracking_minimal.sv')
    if($Task -eq 'pull'){Sim 'tb_tracking_pull' @($trackingFiles+'tb/tb_tracking_pull.sv') $cwd}
    else{Sim 'tb_tracking_minimal' $trackingFiles $cwd}
} elseif($Task -eq 'navigation') {
    Run "cd '$(LinuxPath $root)' && python3 model/navigation_vectors.py" (Join-Path $report 'navigation_vectors.log')
    Sim 'tb_navigation_d1' @('student_release/student_release/rtl/nh20_sync.sv','student_release/student_release/rtl/d1_word_sync.sv','student_release/student_release/rtl/navigation_d1.sv','tb/tb_navigation_d1.sv') (Join-Path $root 'work/navigation')
} elseif($Task -eq 'nhd1') {
    Run "cd '$(LinuxPath $root)' && python3 model/nh_d1_vectors.py" (Join-Path $report 'nh_d1_vectors.log')
    $cwd=Join-Path $root 'work\nh_d1'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_nh_d1' @('student_release/student_release/rtl/nh20_sync.sv','student_release/student_release/rtl/d1_word_sync.sv','tb/tb_nh_d1.sv') $cwd
} elseif($Task -eq 'nhprompt') {
    Run "cd '$(LinuxPath $root)' && python3 model/export_tracking_prompt.py" (Join-Path $report 'tracking_prompt_export.log')
    $cwd=Join-Path $root 'work\nh_d1'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_nh_actual_prompt' @('student_release/student_release/rtl/nh20_sync.sv','tb/tb_nh_actual_prompt.sv') $cwd
} else {
    $cwd=Join-Path $root 'work\frontend'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_tracking_frontend' @('rtl/b1i_prn_gen.sv','rtl/code_nco.sv','rtl/carrier_nco_mixer.sv','rtl/epl_correlator.sv','rtl/tracking_frontend.sv','tb/tb_tracking_frontend.sv') $cwd
}
