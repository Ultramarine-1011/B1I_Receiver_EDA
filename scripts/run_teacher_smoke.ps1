param([double]$DurationSeconds=0.01,
      [string]$PythonExe=(Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'))
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path -Parent $PSScriptRoot
$package=Join-Path $root 'student_release\student_release'
$log=Join-Path $root 'reports\local\official_runner_current.log'
if(-not(Test-Path -LiteralPath $PythonExe)){throw 'Provide the bundled Python executable via -PythonExe'}
$build=Join-Path $package 'build\verilator'
New-Item -ItemType Directory -Force -Path $build | Out-Null
# Public runner has no RTL include flag; stage the exact old LUT in its cwd.
Copy-Item -LiteralPath (Join-Path $root 'rtl\carrier_quarter_lut.svh') -Destination $build -Force
$savedPath=$env:PATH
try {
    $env:PATH=(Split-Path -Parent $PythonExe)+';'+$savedPath
    # Process-scoped only: execute the downloaded public script without changing policy.
    & pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $package 'scripts\run_student_sim.ps1') -PackageDir $package -DurationSeconds $DurationSeconds 2>&1 | Tee-Object -FilePath $log
    $publicExit=$LASTEXITCODE
} finally {$env:PATH=$savedPath}
"PUBLIC_SCRIPT_EXIT_CODE: $publicExit" | Add-Content -LiteralPath $log
if($publicExit -ne 0){throw "Public build/simulation command failed: $log"}
# Public script does not propagate self_check failures. Report the actual child exit.
$samples=[int64][Math]::Floor($DurationSeconds*16368000.0)
& $PythonExe (Join-Path $package 'tools\self_check.py') (Join-Path $package 'output\receiver_records.bin') --expected-samples $samples --minimum-acquisitions 4 --require-tracking --require-navigation --require-common-observation 2>&1 | Tee-Object -FilePath (Join-Path $root 'reports\local\official_functional_current.log')
$functionalExit=$LASTEXITCODE
"FUNCTIONAL_EXIT_CODE: $functionalExit" | Add-Content -LiteralPath (Join-Path $root 'reports\local\official_functional_current.log')
Write-Output "Public TB result is in $log. Full functional result exit=$functionalExit."
exit $functionalExit
