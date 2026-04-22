# bulk_import.ps1 — copies all models from a source folder into the catalog
# and rebuilds manifest.json. ONNX → 1-file entry; OpenVINO (.xml + matching .bin) → 2-file entry.
param(
    [Parameter(Mandatory)] [string]$Source,
    [string]$Author = "@CougarP",
    [string]$DefaultGame = "Generic"
)

$repoRoot     = $PSScriptRoot
$modelsDir    = Join-Path $repoRoot "models"
$manifestPath = Join-Path $repoRoot "manifest.json"
$today        = (Get-Date).ToString("yyyy-MM-dd")

if (-not (Test-Path $Source)) { throw "Source folder not found: $Source" }
New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null

function Get-FileInfo($fullPath) {
    $hash = (Get-FileHash -Algorithm SHA256 $fullPath).Hash.ToLower()
    [pscustomobject]@{
        path   = (Split-Path $fullPath -Leaf)
        size   = (Get-Item $fullPath).Length
        sha256 = $hash
    }
}

function Guess-Game($name) {
    if ($name -match "(?i)warzone") { return "Warzone" }
    if ($name -match "(?i)valorant|vlr") { return "Valorant" }
    if ($name -match "(?i)bolinha|aim ?lab|kovaak") { return "Aim Trainer" }
    return $DefaultGame
}

$models = @()

# Index files in source
$srcFiles = Get-ChildItem $Source -File | Where-Object { $_.Extension -in ".onnx",".xml",".bin" }
$xmlFiles = $srcFiles | Where-Object { $_.Extension -eq ".xml" }
$onnxFiles = $srcFiles | Where-Object { $_.Extension -eq ".onnx" }

# OpenVINO entries (xml + matching bin)
foreach ($xml in $xmlFiles) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($xml.Name)
    $bin  = $srcFiles | Where-Object { $_.Name -ieq "$base.bin" } | Select-Object -First 1
    if (-not $bin) { Write-Warning "Skipping $($xml.Name): no matching .bin"; continue }

    $totalSize = $xml.Length + $bin.Length
    if ($totalSize -gt 50MB) { Write-Warning "Skipping OV $base : >50MB total"; continue }

    Copy-Item $xml.FullName -Destination (Join-Path $modelsDir $xml.Name) -Force
    Copy-Item $bin.FullName -Destination (Join-Path $modelsDir $bin.Name) -Force

    $entry = [ordered]@{
        name        = $base
        format      = "openvino"
        author      = $Author
        game        = (Guess-Game $base)
        description = "OpenVINO IR model"
        uploaded    = $today
        files       = @(
            (Get-FileInfo (Join-Path $modelsDir $xml.Name)),
            (Get-FileInfo (Join-Path $modelsDir $bin.Name))
        )
    }
    $models += $entry
    Write-Host "+ OV   $base ($([math]::Round($totalSize/1MB,2)) MB)" -ForegroundColor Yellow
}

# ONNX entries
foreach ($onnx in $onnxFiles) {
    if ($onnx.Length -gt 50MB) { Write-Warning "Skipping ONNX $($onnx.Name): >50MB"; continue }
    Copy-Item $onnx.FullName -Destination (Join-Path $modelsDir $onnx.Name) -Force

    $base = [System.IO.Path]::GetFileNameWithoutExtension($onnx.Name)
    $entry = [ordered]@{
        name        = $base
        format      = "onnx"
        author      = $Author
        game        = (Guess-Game $base)
        description = "ONNX model"
        uploaded    = $today
        files       = @( (Get-FileInfo (Join-Path $modelsDir $onnx.Name)) )
    }
    $models += $entry
    Write-Host "+ ONNX $($onnx.Name) ($([math]::Round($onnx.Length/1MB,2)) MB)" -ForegroundColor Cyan
}

# Build manifest
$manifest = [ordered]@{
    schemaVersion = 2
    updated       = $today
    models        = $models
    configs       = @()
}

$json = $manifest | ConvertTo-Json -Depth 6
Set-Content -Path $manifestPath -Value $json -Encoding UTF8
Write-Host ""
Write-Host "Manifest written: $manifestPath  ($($models.Count) models)" -ForegroundColor Green
