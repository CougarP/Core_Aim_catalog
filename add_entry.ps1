# Add a catalog entry safely to manifest.json without breaking JSON structure.
#
# Usage:
#   .\add_entry.ps1 model     # adds to models[]
#   .\add_entry.ps1 config    # adds to configs[]
#
# Opens Notepad for you to paste the JSON entry. Save + close → script merges it
# into manifest.json, validates, and reports success.

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('model','config')]
    [string]$Kind
)

$ErrorActionPreference = 'Stop'
$repo = 'C:\projetos_dev\core_aim_catalog'
$manifestPath = Join-Path $repo 'manifest.json'
$tmpEntry = Join-Path $env:TEMP "core_aim_entry.json"

# Pre-fill the temp file with a template comment.
@"
{
  "name": "",
  "format": "onnx",
  "author": "",
  "game": "",
  "description": "",
  "uploaded": "$(Get-Date -Format yyyy-MM-dd)",
  "files": [
    {
      "path": "",
      "size": 0,
      "sha256": ""
    }
  ]
}
"@ | Set-Content -Path $tmpEntry -Encoding UTF8

Write-Host ""
Write-Host "Notepad vai abrir. Cole o JSON da entry (substitua todo o conteudo)," -ForegroundColor Cyan
Write-Host "salve com Ctrl+S e feche o Notepad. O script continua sozinho." -ForegroundColor Cyan
Write-Host ""

Start-Process notepad.exe -ArgumentList $tmpEntry -Wait

# Parse the pasted entry.
try {
    $entry = Get-Content $tmpEntry -Raw | ConvertFrom-Json -Depth 20
} catch {
    Write-Host "ERRO: o que voce colou nao eh JSON valido." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($entry.name)) {
    Write-Host "ERRO: o campo 'name' esta vazio. Cancelando." -ForegroundColor Red
    exit 1
}

# Load manifest, find target section.
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json -Depth 20
$section  = if ($Kind -eq 'model') { 'models' } else { 'configs' }
$arr      = @($manifest.$section)

# Reject duplicates by name.
$dup = $arr | Where-Object { $_.name -ieq $entry.name }
if ($dup) {
    Write-Host "ERRO: ja existe uma entry com name='$($entry.name)' em $section[]." -ForegroundColor Red
    Write-Host "Edite o manifest.json a mao para sobrescrever." -ForegroundColor Yellow
    exit 1
}

# Verify each declared file actually exists on disk.
$subdir = if ($Kind -eq 'model') { 'models' } else { 'configs' }
$missing = @()
foreach ($f in $entry.files) {
    $disk = Join-Path $repo (Join-Path $subdir $f.path)
    if (-not (Test-Path $disk)) { $missing += $disk }
}
if ($missing.Count -gt 0) {
    Write-Host "AVISO: estes arquivos nao foram encontrados no disco:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    $resp = Read-Host "Continuar mesmo assim? (s/N)"
    if ($resp -ne 's' -and $resp -ne 'S') { exit 1 }
}

# Append + write.
$arr += $entry
$manifest.$section = $arr
$manifest | ConvertTo-Json -Depth 20 | Set-Content -Path $manifestPath -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "OK: entry '$($entry.name)' adicionada em $section[]." -ForegroundColor Green
Write-Host ""
Write-Host "Recomputando hashes para garantir consistencia..." -ForegroundColor Cyan
& (Join-Path $repo 'fix_hashes.ps1')

Write-Host ""
Write-Host "Pronto. Proximos passos:" -ForegroundColor Cyan
Write-Host "  git diff manifest.json" -ForegroundColor White
Write-Host "  git add manifest.json" -ForegroundColor White
Write-Host "  git commit -m `"catalog: add $($entry.name)`"" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White

Remove-Item $tmpEntry -ErrorAction SilentlyContinue
