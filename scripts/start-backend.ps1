param([string]$Java = 'java', [string]$LocalConfig = "$PSScriptRoot/../backend/.env.local.json")
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $LocalConfig) {
    $config = Get-Content -LiteralPath $LocalConfig -Raw | ConvertFrom-Json
    $config.PSObject.Properties | ForEach-Object { [Environment]::SetEnvironmentVariable($_.Name, [string]$_.Value, 'Process') }
}
foreach ($key in @('JWT_SECRET', 'DB_PASSWORD')) {
    if (-not [Environment]::GetEnvironmentVariable($key)) { throw "Set $key before starting the backend" }
}
$jar = Join-Path $PSScriptRoot '../backend/target/field-notes-backend-1.0.0.jar'
if (-not (Test-Path -LiteralPath $jar)) { throw 'Run mvn clean package in backend first' }
& $Java -jar $jar
exit $LASTEXITCODE
