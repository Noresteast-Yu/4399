param(
    [string]$PublicUrl = "http://10.0.2.2:9000"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$runtimeRoot = Join-Path $env:LOCALAPPDATA "SmartTravel\MinIO"
$binDir = Join-Path $runtimeRoot "bin"
$dataDir = Join-Path $runtimeRoot "data"
$configFile = Join-Path $runtimeRoot "credentials.env"
$seedDir = Join-Path $repoRoot "backend\object-storage\seed\stations\tongji_university"
$minioExe = Join-Path $binDir "minio.exe"
$mcExe = Join-Path $binDir "mc.exe"
$serverLog = Join-Path $runtimeRoot "minio-server.log"
$serverErrorLog = Join-Path $runtimeRoot "minio-server-error.log"

New-Item -ItemType Directory -Force -Path $binDir, $dataDir | Out-Null

if (-not (Test-Path -LiteralPath $minioExe)) {
    Write-Host "Downloading MinIO server..."
    Invoke-WebRequest `
        -Uri "https://dl.min.io/server/minio/release/windows-amd64/minio.exe" `
        -OutFile $minioExe
}

if (-not (Test-Path -LiteralPath $mcExe)) {
    Write-Host "Downloading MinIO client..."
    Invoke-WebRequest `
        -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" `
        -OutFile $mcExe
}

if (-not (Test-Path -LiteralPath $configFile)) {
    $secret = ([guid]::NewGuid().ToString("N") + [guid]::NewGuid().ToString("N"))
    @(
        "MINIO_ROOT_USER=smarttraveladmin"
        "MINIO_ROOT_PASSWORD=$secret"
    ) | Set-Content -LiteralPath $configFile -Encoding ASCII
}

$credentials = @{}
Get-Content -LiteralPath $configFile | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]*)=(.*)$") {
        $credentials[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$env:MINIO_ROOT_USER = $credentials["MINIO_ROOT_USER"]
$env:MINIO_ROOT_PASSWORD = $credentials["MINIO_ROOT_PASSWORD"]

$listener = Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue
if (-not $listener) {
    Remove-Item -LiteralPath $serverLog, $serverErrorLog -Force -ErrorAction SilentlyContinue
    Start-Process `
        -FilePath $minioExe `
        -ArgumentList @("server", $dataDir, "--address", ":9000", "--console-address", ":9001") `
        -WindowStyle Hidden `
        -RedirectStandardOutput $serverLog `
        -RedirectStandardError $serverErrorLog | Out-Null

    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Seconds 1
        try {
            Invoke-WebRequest -Uri "http://127.0.0.1:9000/minio/health/live" -UseBasicParsing | Out-Null
            $ready = $true
            break
        } catch {
            # Keep waiting while MinIO initializes its data directory.
        }
    }
    if (-not $ready) {
        throw "MinIO failed to start. See $serverErrorLog"
    }
}

& $mcExe alias set smarttravel "http://127.0.0.1:9000" `
    $env:MINIO_ROOT_USER $env:MINIO_ROOT_PASSWORD | Out-Null
& $mcExe mb --ignore-existing "smarttravel/station-media" | Out-Null
& $mcExe anonymous set download "smarttravel/station-media" | Out-Null

if (Test-Path -LiteralPath $seedDir) {
    & $mcExe mirror --overwrite $seedDir `
        "smarttravel/station-media/stations/tongji_university" | Out-Null
}

Write-Host "MinIO object storage is ready."
Write-Host "API endpoint: http://127.0.0.1:9000"
Write-Host "Console:      http://127.0.0.1:9001"
Write-Host "App URL:      $PublicUrl/station-media/stations/tongji_university/"
Write-Host "Credentials:  $configFile"
