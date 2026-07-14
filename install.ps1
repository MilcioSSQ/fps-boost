<#
.SYNOPSIS
    One-line installer for FPS Boost by MilcioSSQ.
    Run:  irm https://raw.githubusercontent.com/MilcioSSQ/fps-boost/main/install.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

# ── Download & extract (works without admin) ─────────────────────────────────
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

Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile -UseBasicParsing
Expand-Archive -Path $zipFile -DestinationPath $extract -Force
Remove-Item $zipFile -Force

$folder = Get-ChildItem $extract | Where-Object { $_.PSIsContainer } | Select-Object -First 1

if (-not $folder) {
    Write-Host "  Download failed." -ForegroundColor Red
    Read-Host "  Enter to exit"
    exit 1
}

Write-Host "  Starting FPS Boost..." -ForegroundColor Green

# ── Launch in a clean, elevated PowerShell process ───────────────────────────
$mainScript = Join-Path $folder.FullName 'FPS-Boost.ps1'
Start-Process powershell.exe -Verb RunAs -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$mainScript`""
) -Wait

# ── Cleanup ──────────────────────────────────────────────────────────────────
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
