# FPS Boost by MilcioSSQ — one-line installer
# Usage: irm https://raw.githubusercontent.com/MilcioSSQ/fps-boost/main/install.ps1 | iex

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -Command irm https://raw.githubusercontent.com/MilcioSSQ/fps-boost/main/install.ps1 | iex" -Verb RunAs
    exit
}

$zip = Join-Path $env:TEMP 'fps-boost.zip'
$ext = Join-Path $env:TEMP 'fps-boost-extract'
if (Test-Path $ext) { Remove-Item $ext -Recurse -Force }
Invoke-WebRequest 'https://github.com/MilcioSSQ/fps-boost/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
Expand-Archive $zip $ext -Force
Remove-Item $zip -Force
$folder = (Get-ChildItem $ext)[0].FullName
& (Join-Path $folder 'FPS-Boost.ps1')
Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue
