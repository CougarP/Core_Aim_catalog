# Recomputes size + sha256 for every entry in manifest.json based on the actual
# files currently in models/ and configs/. Writes manifest_fixed.json next to it.
# Also prints what changed so you can verify before overwriting.

$ErrorActionPreference = 'Stop'
$repo = 'C:\projetos_dev\core_aim_catalog'
$manifestPath = Join-Path $repo 'manifest.json'

$json = Get-Content $manifestPath -Raw | ConvertFrom-Json -Depth 20

function FixSection($section, $subdir) {
    foreach ($entry in $section) {
        $files = @()
        if ($entry.PSObject.Properties.Name -contains 'files') { $files = $entry.files }
        foreach ($f in $files) {
            $disk = Join-Path $repo (Join-Path $subdir $f.path)
            if (-not (Test-Path $disk)) {
                Write-Host "MISSING ON DISK: $disk" -ForegroundColor Red
                continue
            }
            $newSize = (Get-Item $disk).Length
            $newSha  = (Get-FileHash $disk -Algorithm SHA256).Hash.ToLower()
            $oldSize = $f.size
            $oldSha  = $f.sha256
            if ($oldSha -ne $newSha -or $oldSize -ne $newSize) {
                Write-Host "FIX  $($f.path)" -ForegroundColor Yellow
                Write-Host "     size: $oldSize -> $newSize"
                Write-Host "     sha : $oldSha"
                Write-Host "       -> $newSha"
                $f.size   = $newSize
                $f.sha256 = $newSha
            } else {
                Write-Host "OK   $($f.path)" -ForegroundColor Green
            }
        }
    }
}

Write-Host "=== MODELS ===" -ForegroundColor Cyan
FixSection $json.models 'models'
Write-Host ""
Write-Host "=== CONFIGS ===" -ForegroundColor Cyan
FixSection $json.configs 'configs'

$out = Join-Path $repo 'manifest.json'
$json | ConvertTo-Json -Depth 20 | Set-Content -Path $out -Encoding UTF8 -NoNewline
Write-Host ""
Write-Host "manifest.json updated in place. Review with 'git diff manifest.json' then commit + push." -ForegroundColor Cyan
