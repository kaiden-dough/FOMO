param(
    [Parameter(Mandatory = $true)]
    [string]$MapsApiKey,
    [string]$SupabaseUrl = "",
    [string]$SupabasePublishableKey = "",
    [string]$BackendUrl = "http://localhost:8000",
    [string]$WebHost = "localhost",
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $projectRoot "web/index.html"
$flutterArgs = @(
    "run",
    "-d", "chrome",
    "--web-hostname", $WebHost,
    "--web-port", $Port,
    "--dart-define=BACKEND_URL=$BackendUrl",
    "--dart-define=SUPABASE_URL=$SupabaseUrl",
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$SupabasePublishableKey"
)

$original = Get-Content -Path $indexPath -Raw

try {
    $patched = $original -replace 'https://maps\.googleapis\.com/maps/api/js\?key=[^"]*', "https://maps.googleapis.com/maps/api/js?key=$MapsApiKey"
    Set-Content -Path $indexPath -Value $patched -NoNewline

    Push-Location $projectRoot
    try {
        flutter @flutterArgs
    } finally {
        Pop-Location
    }
}
finally {
    # Always restore tracked file so keys are never left in git state.
    Set-Content -Path $indexPath -Value $original -NoNewline
}
