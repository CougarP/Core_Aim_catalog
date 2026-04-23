$url = 'https://raw.githubusercontent.com/CougarP/Core_Aim_catalog/main/models/Bolinha_Rosa_int8.xml'
$tmp = [IO.Path]::GetTempFileName()
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' }
$remote = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
$rsize  = (Get-Item $tmp).Length
Remove-Item $tmp

$local = (Get-FileHash 'C:\projetos_dev\core_aim_catalog\models\Bolinha_Rosa_int8.xml' -Algorithm SHA256).Hash.ToLower()
$lsize = (Get-Item 'C:\projetos_dev\core_aim_catalog\models\Bolinha_Rosa_int8.xml').Length

Write-Host "REMOTE (GitHub raw): size=$rsize  sha=$remote"
Write-Host "LOCAL  (your disk):  size=$lsize  sha=$local"
Write-Host "MANIFEST expects:    size=773449  sha=794526a4a6571359ef278acb81683701ab23d0c49165681d5dcb8ccb6a40f824"
Write-Host ""
if ($remote -eq $local) { Write-Host "OK: GitHub now serves the same file as your disk." -ForegroundColor Green }
else { Write-Host "MISMATCH: GitHub still has a different file (CDN cache or push not done)." -ForegroundColor Yellow }
