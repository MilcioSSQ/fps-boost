<#
.SYNOPSIS
    One-line installer for FPS Boost by MilcioSSQ.
    Run:  irm https://raw.githubusercontent.com/MilcioSSQ/fps-boost/main/install.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

# ── Elevate: save to temp file and relaunch as admin ─────────────────────────
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  FPS Boost needs Administrator. Elevating..." -ForegroundColor Yellow
    $tmp = Join-Path $env:TEMP 'fps-boost-install.ps1'
    Invoke-RestMethod 'https://raw.githubusercontent.com/MilcioSSQ/fps-boost/main/install.ps1' -OutFile $tmp
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$tmp`""
    )
    exit
}

# ── We are admin now, running as a real file ─────────────────────────────────
$repo    = 'MilcioSSQ/fps-boost'
$branch  = 'main'
$zipUrl  = "https://github.com/$repo/archive/refs/heads/$branch.zip"
$zipFile = Join-Path $env:TEMP 'fps-boost.zip'
$extract = Join-Path $env:TEMP 'fps-boost-extract'

Write-Host ""
Write-Host "  FPS BOOST" -ForegroundColor White -NoNewline
Write-Host "  by MilcioSSQ" -ForegroundColor DarkGray
Write-Host "  ────────────────────────────────────────────────────"
Write-Host "  Downloading latest version..." -ForegroundColor Cyan

if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $extract -Force
    Remove-Item $zipFile -Force
} catch {
    Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "  Enter to exit"
    exit 1
}

$folder = Get-ChildItem $extract | Where-Object { $_.PSIsContainer } | Select-Object -First 1

if (-not $folder) {
    Write-Host "  Extract failed." -ForegroundColor Red
    Read-Host "  Enter to exit"
    exit 1
}

Write-Host "  Starting FPS Boost..." -ForegroundColor Green
Write-Host ""

# ── Run the script directly (works because we are a real .ps1 file) ──────────
$mainScript = Join-Path $folder.FullName 'FPS-Boost.ps1'
& $mainScript

# ── Cleanup ──────────────────────────────────────────────────────────────────
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:TEMP 'fps-boost-install.ps1') -Force -ErrorAction SilentlyContinue
