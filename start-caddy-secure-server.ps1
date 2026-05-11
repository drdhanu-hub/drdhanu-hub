$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$configHome = Join-Path $root ".caddy-config"
$dataHome = Join-Path $root ".caddy-data"

New-Item -ItemType Directory -Force -Path $configHome | Out-Null
New-Item -ItemType Directory -Force -Path $dataHome | Out-Null

$env:XDG_CONFIG_HOME = $configHome
$env:XDG_DATA_HOME = $dataHome
$env:CADDY_CONFIG_DIR = $configHome
$env:CADDY_DATA_DIR = $dataHome

Write-Host "Smart Parking secure website running at https://localhost:8447"
Write-Host "LAN test link: https://10.14.29.30:8447"
Write-Host "Using local Caddy state at $configHome and $dataHome"

caddy run --config (Join-Path $root "Caddyfile") --adapter caddyfile
