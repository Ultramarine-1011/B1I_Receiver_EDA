[CmdletBinding()]
param(
    [ValidateSet('menu','prepare','all','acquisition','tracking','navigation','evidence','open','summary')][string]$Action='menu',
    [ValidateSet('acquisition','tracking','navigation','nh')][string]$Module='acquisition',
    [string]$ModelSimDirectory='C:\modeltech64_10.5\win64',
    [switch]$ShowWave,
    [int]$TimeoutSeconds=30
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$area=Join-Path $root 'work/acceptance_demo'
$build=Join-Path $area 'build'
$runs=Join-Path $area 'runs'
$vsim=Join-Path $ModelSimDirectory 'vsim.exe'
$utf8=[Text.UTF8Encoding]::new($false)
$rtl=Join-Path $root 'student_release/student_release/rtl'
$rtlNames=@('nh20_sync.sv','d1_word_sync.sv','navigation_d1.sv','b1i_prn_gen.sv','code_nco.sv','carrier_nco_mixer.sv','epl_correlator.sv','tracking_frontend.sv','tracking_frontend_spaced.sv','tracking_channel_minimal.sv','fft4096_serial.sv','acquisition_pcps.sv','acquisition_refine.sv')
$tops=@('tb_nh_d1','tb_navigation_d1','tb_p02_probe','tb_tracking_minimal')
$config=@{
    acquisition=@{top='tb_p02_probe';marker='P02_RTL_TIMING_PROBE_PASS';signals='coarse_valid coarse_detected prn coarse_lag coarse_doppler coarse_peak coarse_mean fine_valid fine_detected fine_lag fine_doppler fine_peak'}
    tracking=@{top='tb_tracking_minimal';marker='TRACKING_MINIMAL_PASS cases=2';signals='window_done window_ref feedback_valid feedback_ref ip qp ie il dll_error_q16 pll_error_q16 code_step_q carrier_step_word locked'}
    nh=@{top='tb_nh_d1';marker='NH_D1_MODULE_PASS cases=3 words=9';signals='nh_locked nh_phase bit_valid data_bit word_valid word_number raw_word information corrected_bits bch_valid'}
    navigation=@{top='tb_navigation_d1';marker='NAVIGATION_D1_PASS cases=2';signals='nh_valid nh_phase frame_valid time_valid bch_valid record_valid record_ready record_data dut/word_valid dut/word_number dut/sow'}
}
New-Item -ItemType Directory -Force -Path $build,$runs | Out-Null
function Write-Utf8([string]$Path,[string]$Value) { [IO.File]::WriteAllText($Path,$Value,$utf8) }
function Quote-Arg([string]$Value) { '"'+$Value.Replace('"','\"')+'"' }
function Invoke-Tool([string]$Program,[string[]]$Arguments,[string]$WorkingDirectory,[string]$Log,[int]$Limit=150) {
    if(!(Test-Path -LiteralPath $Program)){throw "Missing tool: $Program"}
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $process=New-Object Diagnostics.Process
    $process.StartInfo.FileName=$Program
    $process.StartInfo.Arguments=(($Arguments | ForEach-Object {Quote-Arg $_}) -join ' ')
    $process.StartInfo.WorkingDirectory=$WorkingDirectory
    $process.StartInfo.UseShellExecute=$false
    $process.StartInfo.CreateNoWindow=$true
    $process.StartInfo.RedirectStandardOutput=$true
    $process.StartInfo.RedirectStandardError=$true
    [void]$process.Start()
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
    $timedOut=$false
    while(!$process.WaitForExit(250)) { if($timer.Elapsed.TotalSeconds -gt $Limit){
        $timedOut=$true
        & "$env:SystemRoot\System32\taskkill.exe" /PID $process.Id /T /F 2>&1 | Out-Null
        [void]$process.WaitForExit(5000)
        break
    } }
    $code=if($process.HasExited){$process.ExitCode}else{124}
    if($timedOut){$code=124}
    $output=if($stdout.Wait(5000) -and $stderr.Wait(5000)){$stdout.Result+$stderr.Result}else{'Output pipe did not close after timeout.'}
    Write-Utf8 $Log ("COMMAND: $Program "+($Arguments -join ' ')+"`n"+$output+"`nEXIT_CODE: $code`nWALL_SECONDS: "+$timer.Elapsed.TotalSeconds.ToString('F3',[Globalization.CultureInfo]::InvariantCulture)+"`n")
    [pscustomobject]@{exit_code=$code;seconds=[Math]::Round($timer.Elapsed.TotalSeconds,3);text=$output;log=$Log}
}
function Get-Sources {
    $files=@($rtlNames | ForEach-Object {Join-Path $rtl $_})+@(Join-Path $rtl 'carrier_quarter_lut.svh')+@($tops | ForEach-Object {Join-Path $root "tb/$_.sv"})
    $files+=@(Get-ChildItem (Join-Path $rtl '../rom/fft*.mem') | ForEach-Object {$_.FullName})
    $files+=@('tb/vectors/b1i_prn_06.mem','tb/vectors/nh_d1/nav_bits.mem','tb/vectors/nh_d1/expected_words.mem','scripts/demo_acceptance/vectors/bits.mem','scripts/demo_acceptance/vectors/raw.mem','scripts/demo_acceptance/vectors/info.mem') | ForEach-Object {Join-Path $root $_}
    @($files | ForEach-Object {[ordered]@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
}
function Prepare-Demo {
    $manifest=Get-Sources;$signature=($manifest | ConvertTo-Json -Depth 5 -Compress)
    $stamp=Join-Path $build 'sources.json'
    if((Test-Path $stamp) -and (Test-Path (Join-Path $build 'demo_work/_info')) -and (Get-Content $stamp -Raw).Trim() -eq $signature){return}
    foreach($top in $tops){
        $source=Get-Content -LiteralPath (Join-Path $root "tb/$top.sv") -Raw
        $source=$source.Replace('../../tb/vectors/',($root.Replace('\','/')+'/tb/vectors/')).Replace('../../reports/local/','')
        Write-Utf8 (Join-Path $build "$top.sv") $source
    }
    $result=Invoke-Tool (Join-Path $ModelSimDirectory 'vlib.exe') @('demo_work') $build (Join-Path $build 'vlib.log')
    if($result.exit_code -ne 0){throw "Library FAIL: $($result.log)"}
    $sources=@($rtlNames | ForEach-Object {Join-Path $rtl $_})+@($tops | ForEach-Object {Join-Path $build "$_.sv"})
    $result=Invoke-Tool (Join-Path $ModelSimDirectory 'vlog.exe') (@('-sv','-work','demo_work',('+incdir+'+$rtl.Replace('\','/')))+$sources) $build (Join-Path $build 'compile.log')
    if($result.exit_code -ne 0 -or $result.text -match '\*\* Error'){throw "Compile FAIL: $($result.log)"}
    Write-Utf8 $stamp $signature
    Write-Host "PREPARE PASS ($($result.seconds)s compile): $build" -ForegroundColor Green
}
function Invoke-Demo([string]$Name) {
    Prepare-Demo;$case=$config[$Name]
    $dir=Join-Path $runs ((Get-Date -Format 'yyyyMMdd_HHmmss_fff')+'_'+$Name)
    New-Item -ItemType Directory -Force -Path $dir,(Join-Path $dir 'rom') | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'tb/vectors/b1i_prn_06.mem') -Destination $dir
    Copy-Item -Path (Join-Path $rtl '../rom/fft*.mem') -Destination (Join-Path $dir 'rom')
    foreach($memoryName in @('bits.mem','raw.mem','info.mem')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot "demo_acceptance/vectors/$memoryName") -Destination $dir}
    $paths=($case.signals.Split(' ') | ForEach-Object {'/'+$case.top+'/'+$_}) -join ' '
    Write-Utf8 (Join-Path $dir 'run.do') ("onerror {quit -code 2 -f}`nlog $paths`nrun -all`nquit -code 0 -f`n")
    Write-Host "RUN $Name : original self-check, timeout ${TimeoutSeconds}s"
    $result=Invoke-Tool $vsim @('-c','-onfinish','stop','-voptargs=+acc','-wlf','wave.wlf',((Join-Path $build 'demo_work').Replace('\','/')+'.'+$case.top),'-do','run.do') $dir (Join-Path $dir 'simulation.log') $TimeoutSeconds
    $passed=$result.exit_code -eq 0 -and $result.text.Contains($case.marker) -and $result.text -notmatch '\*\* (Fatal|Error)|# Fatal:'
    $entry=@{module=$Name;status=$(if($passed){'PASS'}else{'FAIL'});seconds=$result.seconds;exit_code=$result.exit_code;log=$result.log;wlf=(Join-Path $dir 'wave.wlf');sources=(Join-Path $build 'sources.json');verified_utc=[DateTime]::UtcNow.ToString('o')}
    Write-Utf8 (Join-Path $dir 'result.json') ($entry | ConvertTo-Json -Depth 5)
    if(!$passed){Write-Host "FAIL $Name ($($result.seconds)s): $($result.log)" -ForegroundColor Red;throw 'Self-check failed or timed out. See log; cached PASS is not substituted.'}
    $entry.source_signature=([string](Get-Content (Join-Path $build 'sources.json') -Raw)).Trim()
    Write-Utf8 (Join-Path $area "latest_$Name.json") ($entry | ConvertTo-Json -Depth 5)
    $result.text -split "`n" | Where-Object {$_ -match '_PASS|_METRIC'} | ForEach-Object {Write-Host $_}
    Write-Host "PASS $Name ($($result.seconds)s)  LOG: $($result.log)" -ForegroundColor Green
}
function Show-Summary {
    foreach($name in @('acquisition','tracking','nh','navigation')){
        $file=Join-Path $area "latest_$name.json"
        if(Test-Path $file){$r=Get-Content $file -Raw | ConvertFrom-Json;Write-Host "$name : $($r.status), $($r.seconds)s, $($r.verified_utc)";Write-Host "  $($r.log)"}else{Write-Host "$name : NOT RUN"}
    }
}
function Show-Evidence {
    $file=Join-Path $root 'reports/e_stage/final/self_check.log'
    Write-Host 'E VERSION / 100s PUBLIC IF / SAVED TEACHER SELF-CHECK' -ForegroundColor Cyan
    Get-Content -LiteralPath $file
    Write-Host "SOURCE: $file"
    Write-Host 'Four PRNs 8/11/13/21; RTL NAV 560; valid OBS 324. Saved evidence; no whole-receiver rerun.'
}
function Show-Tracking {
    $file=Join-Path $area 'latest_tracking.json'
    if(!(Test-Path $file)){throw 'Missing rehearsed tracking result. See docs/ACCEPTANCE_DEMO.md.'}
    $r=Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json
    $current=(Get-Sources | ConvertTo-Json -Depth 5 -Compress)
    if($r.source_signature.Trim() -ne $current){throw 'Sources differ from rehearsed tracking. Use the recorded report instead.'}
    $saved=Get-Content $r.log -Raw
    if($r.status -ne 'PASS' -or $r.exit_code -ne 0 -or !$saved.Contains('TRACKING_MINIMAL_PASS cases=2')){throw 'Saved tracking self-check is incomplete.'}
    Write-Host "REPLAY PASS tracking: complete two-case ModelSim self-check, $($r.seconds)s at $($r.verified_utc)" -ForegroundColor Green
    $saved -split "`n" | Where-Object {$_ -match '_PASS|_METRIC'} | ForEach-Object {Write-Host $_}
    Write-Host "LOG: $($r.log)"
}
function Open-Wave([string]$Name) {
    $latest=Join-Path $area "latest_$Name.json"
    if(Test-Path $latest){
        $r=Get-Content $latest -Raw | ConvertFrom-Json
        $current=(Get-Sources | ConvertTo-Json -Depth 5 -Compress)
        if($r.source_signature.Trim() -ne $current){throw 'Sources differ from rehearsal; rerun the module first.'}
        $wlf=$r.wlf
    }else{
        $old=@{acquisition='acquisition';tracking='tracking';nh='nh_d1';navigation='navigation'}[$Name]
        $wlf=Join-Path $root "work/report_waveforms/$old.wlf"
        Write-Host 'Opening saved Oct14 waveform. Tracking fallback contains startup only.' -ForegroundColor Yellow
    }
    if(!(Test-Path $wlf)){throw "Missing WLF: $wlf. Run module first."}
    $do=Join-Path $PSScriptRoot "demo_acceptance/$Name.do"
    Start-Process -FilePath $vsim -ArgumentList ((@('-view',$wlf,'-do',('do {'+$do.Replace('\','/')+'}')) | ForEach-Object {Quote-Arg $_}) -join ' ') -WorkingDirectory $area -WindowStyle Normal | Out-Null
    Write-Host "OPEN $Name : $wlf"
}
try {
    switch($Action){
        'prepare' {Prepare-Demo}
        'all' {Invoke-Demo 'acquisition';Show-Tracking;Invoke-Demo 'nh';Invoke-Demo 'navigation';Show-Summary}
        'acquisition' {Invoke-Demo 'acquisition';if($ShowWave){Open-Wave 'acquisition'}}
        'tracking' {Show-Tracking;if($ShowWave){Open-Wave 'tracking'}}
        'navigation' {Invoke-Demo 'nh';Invoke-Demo 'navigation';if($ShowWave){Open-Wave 'navigation'}}
        'evidence' {Show-Evidence}
        'open' {Open-Wave $Module}
        'summary' {Show-Summary}
        'menu' {
            do {
                Write-Host "`nB1I ACCEPTANCE DEMO (5-10 min)" -ForegroundColor Cyan
                Write-Host '1 Run acquisition + waveform   2 Replay tracking PASS + WLF'
                Write-Host '3 Run NH/D1 + waveform         4 E100 saved self-check'
                Write-Host '5 Rehearsal results            6 Open acquisition WLF'
                Write-Host '7 Open tracking WLF            8 Open NAV WLF   9 Open NH WLF'
                Write-Host 'A Rehearse demo sequence       0 Exit'
                $choice=Read-Host 'Select'
                try {switch($choice){
                    '1' {Invoke-Demo 'acquisition';Open-Wave 'acquisition'}
                    '2' {Show-Tracking;Open-Wave 'tracking'}
                    '3' {Invoke-Demo 'nh';Invoke-Demo 'navigation';Open-Wave 'navigation'}
                    '4' {Show-Evidence} '5' {Show-Summary}
                    '6' {Open-Wave 'acquisition'} '7' {Open-Wave 'tracking'}
                    '8' {Open-Wave 'navigation'} '9' {Open-Wave 'nh'}
                    'a' {Invoke-Demo 'acquisition';Show-Tracking;Invoke-Demo 'nh';Invoke-Demo 'navigation';Show-Summary}
                    '0' {} default {Write-Host 'Select 0-9 or A.'}
                }}catch{Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red}
            }while($choice -ne '0')
        }
    }
} catch {Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red;exit 1}
