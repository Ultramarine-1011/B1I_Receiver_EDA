param([ValidateSet('bridge','smoke','frontend','acquisition','tracking','nhd1','nhprompt')][string]$Task='bridge')
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release\student_release'
$report=Join-Path $root 'reports\local'
function LinuxPath([string]$path) {
    $full=[IO.Path]::GetFullPath($path)
    if($full -notmatch '^([A-Za-z]):\\(.*)$') {throw "Not a drive path: $full"}
    "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}
function Run([string]$command,[string]$log) {
    "COMMAND: $command" | Set-Content -LiteralPath $log -Encoding utf8
    & wsl.exe -d Ubuntu -- bash -lc $command 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code" | Add-Content -LiteralPath $log
    if($code -ne 0) {throw "Command failed ($code): $log"}
}
function Sim([string]$top,[string[]]$files,[string]$cwd,[string]$plusArgs='') {
    $build=Join-Path $root "work\verilator\$top"
    New-Item -ItemType Directory -Force -Path $build | Out-Null
    $sources=($files | ForEach-Object {"'$(LinuxPath (Join-Path $root $_))'"}) -join ' '
    Run "verilator --binary --timing -j 2 -O2 -Wno-fatal -Wno-TIMESCALEMOD -I'$(LinuxPath (Join-Path $root 'rtl'))' -I'$(LinuxPath (Join-Path $package 'rtl'))' --top-module $top --Mdir '$(LinuxPath $build)' $sources" (Join-Path $report "$top.build.log")
    Run "cd '$(LinuxPath $cwd)' && '$(LinuxPath $build)/V$top' $plusArgs" (Join-Path $report "$top.run.log")
}
New-Item -ItemType Directory -Force -Path $report | Out-Null
$student=@('student_release/student_release/rtl/receiver_contract_pkg.sv','student_release/student_release/rtl/stream_unpacker.sv','student_release/student_release/rtl/student_receiver_core.sv')
if($Task -eq 'bridge') {
    Sim 'tb_stream_unpacker' @($student[1],'tb/tb_stream_unpacker.sv') $root
    Sim 'tb_student_transport' @($student + 'tb/tb_student_transport.sv') $root
} elseif($Task -eq 'smoke') {
    $output=Join-Path $package 'output'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    Sim 'tb_student_file_smoke' @($student + @('student_release/student_release/sim/if2_file_player.sv','student_release/student_release/sim/receiver_tb_template.sv','tb/tb_student_file_smoke.sv')) $package '+MAX_BYTES=40920'
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
} elseif($Task -eq 'acquisition') {
    Run "cd '$(LinuxPath $root)' && python3 model/acquisition_vectors.py" (Join-Path $report 'acquisition_vectors.log')
    $cwd=Join-Path $root 'work\acquisition'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_acquisition_serial' @('rtl/b1i_prn_gen.sv','rtl/code_nco.sv','rtl/carrier_nco_mixer.sv','rtl/epl_correlator.sv','rtl/tracking_frontend.sv','student_release/student_release/rtl/acquisition_serial.sv','tb/tb_acquisition_serial.sv') $cwd
    Run "cd '$(LinuxPath $root)' && python3 model/acquisition_vectors.py --check" (Join-Path $report 'acquisition_float_score.log')
} elseif($Task -eq 'tracking') {
    $cwd=Join-Path $root 'work\tracking'
    New-Item -ItemType Directory -Force -Path $cwd | Out-Null
    Sim 'tb_tracking_minimal' @('rtl/b1i_prn_gen.sv','rtl/code_nco.sv','rtl/carrier_nco_mixer.sv','rtl/epl_correlator.sv','student_release/student_release/rtl/tracking_frontend_spaced.sv','student_release/student_release/rtl/tracking_channel_minimal.sv','tb/tb_tracking_minimal.sv') $cwd
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
