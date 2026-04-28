param(
    [Parameter(Mandatory = $true)]
    [string]$MapsApiKey,
    [Parameter(Mandatory = $true)]
    [string]$GoogleWebClientId,
    [string]$Host = "localhost",
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $projectRoot "web/index.html"
$flutterArgs = @(
    "run",
    "-d", "chrome",
    "--web-hostname", $Host,
    "--web-port", $Port,
    "--dart-define=GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
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
