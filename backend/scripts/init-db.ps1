param(
    [string]$User = "root",
    [string]$Password = "smart_travel_dev",
    [string]$Database = "smart_travel",
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$backendDir = Split-Path -Parent $PSScriptRoot
$schemaPath = Join-Path $backendDir "schema.sql"
$seedPath = Join-Path $backendDir "seed.sql"
$checkPath = Join-Path $backendDir "db_check.sql"
$migrationDir = Join-Path $backendDir "migrations"

if (-not (Get-Command mysql -ErrorAction SilentlyContinue)) {
    throw "mysql command was not found. Install MySQL client, or run Docker with: docker compose -f backend/docker-compose.yml up -d"
}

$previousMysqlPwd = $env:MYSQL_PWD
$env:MYSQL_PWD = $Password

function Invoke-MySqlFile {
    param(
        [string]$Path,
        [string]$TargetDatabase,
        [switch]$Table
    )

    $mysqlArgs = @("-u", $User, "--default-character-set=utf8mb4")
    if ($Table) {
        $mysqlArgs += "--table"
    }
    if ($TargetDatabase) {
        $mysqlArgs += $TargetDatabase
    }

    Get-Content -LiteralPath $Path -Encoding UTF8 | mysql @mysqlArgs
}

try {
    if (-not $CheckOnly) {
        Invoke-MySqlFile -Path $schemaPath
        Invoke-MySqlFile -Path $seedPath -TargetDatabase $Database
        Get-ChildItem -LiteralPath $migrationDir -Filter "*.sql" |
            Sort-Object Name |
            ForEach-Object {
                Invoke-MySqlFile -Path $_.FullName -TargetDatabase $Database
            }
    }

    Invoke-MySqlFile -Path $checkPath -TargetDatabase $Database -Table
}
finally {
    $env:MYSQL_PWD = $previousMysqlPwd
}
