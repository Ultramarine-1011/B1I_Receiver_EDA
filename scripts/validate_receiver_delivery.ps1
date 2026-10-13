param([string]$EvidenceDirectory='reports/e_stage/final',
      [string]$PythonExe=(Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'))
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release/student_release'
$report=Join-Path $root $EvidenceDirectory
New-Item -ItemType Directory -Force $report,(Join-Path $root 'work') | Out-Null
$bin=Join-Path $package 'output/receiver_records.bin'
$bootstrap=Join-Path $root 'work/run_teacher_tool.py'
@'
from pathlib import Path
import sys, runpy
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'work/plotdeps'))
sys.path.insert(0,str(root/'student_release/student_release/tools'))
sys.argv=sys.argv[1:]
runpy.run_path(sys.argv[0],run_name='__main__')
'@ | Set-Content -LiteralPath $bootstrap -Encoding utf8
function RunPython([string]$tool,[string[]]$toolArguments,[string]$name) {
    $toolPath=Join-Path $root $tool
    $log=Join-Path $report "$name.log"
    "COMMAND: $PythonExe $bootstrap $toolPath $($toolArguments -join ' ')" | Set-Content $log -Encoding utf8
    & $PythonExe $bootstrap $toolPath @toolArguments 2>&1 | Tee-Object -FilePath $log -Append
    $code=$LASTEXITCODE
    "EXIT_CODE: $code" | Add-Content $log
    if($code -ne 0){throw "FAIL $name exit=$code"}
}
RunPython 'student_release/student_release/tools/check_records.py' @($bin,'--expected-samples','1636800000','--minimum-acquisitions','4','--require-tracking','--require-navigation','--require-common-observation') 'check_records'
RunPython 'student_release/student_release/tools/self_check.py' @($bin,'--expected-samples','1636800000','--minimum-acquisitions','4','--require-tracking','--require-navigation','--require-common-observation') 'self_check'
# Final BIN remains in the ignored teacher output directory; use a local report copy
# only for independent scoring and preserve its SHA256 in the release manifest.
Copy-Item -LiteralPath $bin -Destination (Join-Path $report 'receiver_records.bin') -Force
RunPython 'model/receiver_multi_score.py' @($report,'--require-navigation') 'independent_score'
RunPython 'student_release/student_release/tools/route_a_position.py' @($bin,'-o',(Join-Path $report 'position.jsonl'),'--ephemeris-json',(Join-Path $report 'ephemeris.json')) 'route_a'
RunPython 'model/delivery_summary.py' @($report,$bin) 'summary'
