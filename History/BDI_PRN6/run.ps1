param([string[]]$Cases = @('main','gaps','phase3','terminal','zero','restart'))
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$runner = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'scripts/run.py'))
if ($runner -notmatch '^([A-Za-z]):\\(.*)$') { throw "Expected Windows drive path: $runner" }
$linuxRunner = "/mnt/$($Matches[1].ToLower())/$($Matches[2].Replace('\','/'))"
& wsl.exe -d Ubuntu -- python3 $linuxRunner --cases @Cases
$result = $LASTEXITCODE
Write-Host "BDI_RUNNER_EXIT_CODE: $result"
exit $result
