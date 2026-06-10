$ports = 9000, 9001
$processIds = Get-NetTCPConnection -LocalPort $ports -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique

foreach ($processId in $processIds) {
    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
}

Write-Host "MinIO stopped."
