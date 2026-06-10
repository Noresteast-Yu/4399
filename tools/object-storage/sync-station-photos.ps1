$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$runtimeRoot = Join-Path $env:LOCALAPPDATA "SmartTravel\MinIO"
$mcExe = Join-Path $runtimeRoot "bin\mc.exe"
$configFile = Join-Path $runtimeRoot "credentials.env"
$seedDir = Join-Path $repoRoot "backend\object-storage\seed\stations\tongji_university"

if (-not (Test-Path -LiteralPath $mcExe) -or -not (Test-Path -LiteralPath $configFile)) {
    throw "MinIO is not initialized. Run start-minio.ps1 first."
}

$credentials = @{}
Get-Content -LiteralPath $configFile | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]*)=(.*)$") {
        $credentials[$matches[1].Trim()] = $matches[2].Trim()
    }
}

& $mcExe alias set smarttravel "http://127.0.0.1:9000" `
    $credentials["MINIO_ROOT_USER"] $credentials["MINIO_ROOT_PASSWORD"] | Out-Null
& $mcExe mirror --overwrite --remove $seedDir `
    "smarttravel/station-media/stations/tongji_university"

Write-Host "Station photos synchronized."
