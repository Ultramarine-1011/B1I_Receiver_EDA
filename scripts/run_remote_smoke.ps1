param(
  [string]$HostName = "192.168.159.128",
  [string]$UserName = "7901_15",
  [string]$KeyPath = "$HOME\.ssh\id_rsa_eda_codex"
)

$ErrorActionPreference = "Stop"
$target = "${UserName}@${HostName}"
$sshArgs = @("-o", "BatchMode=yes", "-i", $KeyPath)

& ssh @sshArgs $target "bash -lc 'source ~/eda_env.sh && cd ~/eda_project && make smoke'"
if ($LASTEXITCODE -ne 0) {
  throw "Remote smoke test failed with exit code $LASTEXITCODE"
}

