param([string]$RunDirectory = '', [string]$PythonExecutable = '')
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RunDirectory) {
    $RunDirectory = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'runs/LATEST.txt') -Raw).Trim()
}
if ($RunDirectory -match '^/mnt/([a-z])/(.*)$') {
    $RunDirectory = "$($Matches[1].ToUpper()):\$($Matches[2].Replace('/','\'))"
}
$RunDirectory = [IO.Path]::GetFullPath($RunDirectory)
if (-not $PythonExecutable) {
    $PythonExecutable = Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) { throw 'Provide -PythonExecutable with Matplotlib available.' }
$plotter = Join-Path $PSScriptRoot 'scripts/plot_waveforms.py'
$log = Join-Path $RunDirectory 'plot.log'
$commandRecord = [ordered]@{
    argv = @($PythonExecutable, '-X', 'utf8', $plotter, '--run', $RunDirectory)
    time_singapore = [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).ToString('o')
}
& $PythonExecutable -X utf8 $plotter --run $RunDirectory 2>&1 | Tee-Object -FilePath $log
$result = $LASTEXITCODE
$commandRecord.exit_code = $result
$commandRecord | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $RunDirectory 'plot_command.json') -Encoding UTF8
Write-Host "BDI_PLOT_EXIT_CODE: $result"
exit $result
