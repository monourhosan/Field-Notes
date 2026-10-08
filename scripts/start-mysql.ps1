param([string]$HomeDirectory = "$env:USERPROFILE/.cache/field-notes-audit/mysql")
$ErrorActionPreference = 'Stop'
$binary = Join-Path $HomeDirectory 'mysql-8.4.11-winx64/bin/mysqld.exe'
$config = Join-Path $HomeDirectory 'my.ini'
if (-not (Test-Path -LiteralPath $binary) -or -not (Test-Path -LiteralPath $config)) {
    throw 'MySQL is not installed in this directory. Configure your MySQL server and DB_URL instead.'
}
$listener = Get-NetTCPConnection -State Listen -LocalPort 3307 -ErrorAction SilentlyContinue
if ($listener) {
    if ((Get-Process -Id $listener.OwningProcess).Path -ne $binary.Replace('/', '\')) {
        throw 'Port 3307 is occupied by another process.'
    }
    Write-Output 'MySQL is already running on port 3307.'
    return
}
$server = Start-Process -FilePath $binary -ArgumentList ('"--defaults-file=' + $config + '"') -WindowStyle Hidden -PassThru
Write-Output "Started MySQL process $($server.Id)."
