# Helper script: generates a manifest.json entry for a model or config file.
# Usage:
#   pwsh ./gen_manifest_entry.ps1 -Path models/my_model.onnx -Author "@user" -Game "Valorant" -Description "..."
param(
    [Parameter(Mandatory)] [string]$Path,
    [Parameter(Mandatory)] [string]$Author,
    [Parameter(Mandatory)] [string]$Game,
    [Parameter(Mandatory)] [string]$Description
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$file   = Get-Item $Path
$hash   = (Get-FileHash -Algorithm SHA256 $file.FullName).Hash.ToLower()
$size   = $file.Length
$name   = $file.Name
$today  = (Get-Date).ToString("yyyy-MM-dd")

if ($size -gt 50MB) {
    Write-Error "File is larger than 50 MB ($([math]::Round($size/1MB,2)) MB). Reject."
    exit 1
}

$entry = [ordered]@{
    name        = $name
    size        = $size
    sha256      = $hash
    author      = $Author
    game        = $Game
    description = $Description
    uploaded    = $today
}

Write-Host ""
Write-Host "=== Copy this entry into manifest.json ===" -ForegroundColor Cyan
Write-Host ""
$entry | ConvertTo-Json -Depth 4
Write-Host ""
Write-Host "Size: $([math]::Round($size/1MB,2)) MB | SHA256: $hash" -ForegroundColor Yellow
