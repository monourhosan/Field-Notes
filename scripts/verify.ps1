param([string]$Maven = 'mvn', [switch]$Android, [switch]$LiveApi, [string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Assert-Exit([string]$step) { if ($LASTEXITCODE -ne 0) { throw "$step failed with exit code $LASTEXITCODE" } }
Push-Location (Join-Path $root 'backend')
try { & $Maven clean package; Assert-Exit 'Backend build/tests' } finally { Pop-Location }
Push-Location (Join-Path $root 'mobile')
try {
    & flutter pub get; Assert-Exit 'Dependencies'
    & flutter analyze; Assert-Exit 'Analysis'
    & flutter test; Assert-Exit 'Mobile tests'
    & flutter build web --debug; Assert-Exit 'Web build'
    if ($Android) { & flutter build apk --debug; Assert-Exit 'Android build' }
} finally { Pop-Location }
if ($LiveApi) {
    & $Python (Join-Path $PSScriptRoot 'api_smoke.py'); Assert-Exit 'Live API checks'
    $verificationApi = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { 'http://localhost:8080' }
    Push-Location (Join-Path $root 'mobile')
    try {
        & flutter test test/live_sync_verification.dart "--dart-define=API_BASE_URL=$verificationApi"
        Assert-Exit 'Live offline/sync/reinstall checks'
    } finally { Pop-Location }
}
