param(
    [string]$PackageDir = (Split-Path -Parent $PSScriptRoot),
    [double]$DurationSeconds = 100.0
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $PackageDir).Path
$inputFile = Join-Path $root 'input\scenario.if2'
$outputDir = Join-Path $root 'output'
$buildDir = Join-Path $root 'build\verilator'
$objDir = Join-Path $buildDir 'obj_dir'
$outputFile = Join-Path $outputDir 'receiver_records.bin'

foreach ($path in @($inputFile, (Join-Path $root 'rtl\student_receiver_core.sv'),
    (Join-Path $root 'sim\if2_file_player.sv'),
    (Join-Path $root 'sim\receiver_tb_template.sv'))) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing required file: $path" }
}

New-Item -ItemType Directory -Force -Path $outputDir, (Join-Path $root 'logs'), $buildDir | Out-Null

# Optional receiver lookup tables belong to the student's implementation, but
# the public runner is responsible for making them visible to $readmemh. Any
# *.mem file placed in rom/ is copied beside the Verilator executable.
$romDir = Join-Path $root 'rom'
if (Test-Path -LiteralPath $romDir -PathType Container) {
    Get-ChildItem -LiteralPath $romDir -Filter '*.mem' -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $buildDir $_.Name) -Force
    }
}

function Convert-ToWslPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "Expected Windows path: $full" }
    return "/mnt/$($matches[1].ToLower())/$($matches[2].Replace('\','/'))"
}

$allRtlFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'rtl') -Filter '*.sv' -File | Sort-Object Name)
$packageFiles = @($allRtlFiles | Where-Object { $_.Name -like '*_pkg.sv' })
$moduleFiles = @($allRtlFiles | Where-Object { $_.Name -notlike '*_pkg.sv' })
# SystemVerilog packages must be compiled before modules that import them.
$rtlFiles = @($packageFiles.FullName) + @($moduleFiles.FullName)
$sources = @($rtlFiles) + @(
    (Join-Path $root 'sim\if2_file_player.sv'),
    (Join-Path $root 'sim\receiver_tb_template.sv')
)
$wslBuild = Convert-ToWslPath $buildDir
$wslOutput = Convert-ToWslPath $outputFile
$wslInput = Convert-ToWslPath $inputFile
$wslSources = ($sources | ForEach-Object { "'$(Convert-ToWslPath $_)'" }) -join ' '

$buildCommand = "set -e; cd '$wslBuild'; verilator --binary --timing -O3 -CFLAGS '-O3 -march=native -pthread' -Wno-fatal -Wno-TIMESCALEMOD -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --top-module receiver_tb_template -Mdir obj_dir $wslSources"
$savedErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& wsl.exe -d Ubuntu -- bash -lc $buildCommand
$wslExitCode = $LASTEXITCODE
$ErrorActionPreference = $savedErrorActionPreference
if ($wslExitCode -ne 0) { throw 'Verilator build failed' }

if (Test-Path -LiteralPath $outputFile) { Remove-Item -LiteralPath $outputFile -Force }
$samples = [int64][Math]::Floor($DurationSeconds * 16368000.0)
$bytes = [int64][Math]::Ceiling($samples / 4.0)
$runCommand = "cd '$wslBuild'; ./obj_dir/Vreceiver_tb_template +INPUT='$wslInput' +OUTPUT='$wslOutput' +MAX_BYTES=$bytes"
$savedErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& wsl.exe -d Ubuntu -- bash -lc $runCommand 2>&1 | Tee-Object -FilePath (Join-Path $root 'logs\simulation.log')
$wslExitCode = $LASTEXITCODE
$ErrorActionPreference = $savedErrorActionPreference
if ($wslExitCode -ne 0) { throw 'Simulation failed' }

$decode = Join-Path $root 'tools\decode_records.py'
$selfCheck = Join-Path $root 'tools\self_check.py'
python $decode $outputFile -o (Join-Path $outputDir 'receiver_records.jsonl')
python $selfCheck $outputFile --expected-samples ($bytes * 4) --minimum-acquisitions 4 --require-tracking --require-navigation --require-common-observation | Tee-Object -FilePath (Join-Path $outputDir 'self_check.log')
python (Join-Path $root 'tools\route_a_position.py') $outputFile -o (Join-Path $outputDir 'student_positions.jsonl') --ephemeris-json (Join-Path $outputDir 'student_ephemeris.json')
