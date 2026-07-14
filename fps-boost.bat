@echo off
:: FPS Boost by MilcioSSQ — double-click to run
:: Downloads the latest version and opens the menu.

:: ── Elevate to admin ────────────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ── Download, extract, launch ───────────────────────────────────────────────
title FPS Boost by MilcioSSQ
echo.
echo   FPS Boost by MilcioSSQ
echo   ────────────────────────────────────────────────────
echo   Downloading latest version...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$zip = Join-Path $env:TEMP 'fps-boost.zip'; " ^
    "$ext = Join-Path $env:TEMP 'fps-boost-extract'; " ^
    "if (Test-Path $ext) { Remove-Item $ext -Recurse -Force }; " ^
    "Invoke-WebRequest 'https://github.com/MilcioSSQ/fps-boost/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing; " ^
    "Expand-Archive $zip $ext -Force; Remove-Item $zip -Force; " ^
    "$f = (Get-ChildItem $ext)[0].FullName; " ^
    "& (Join-Path $f 'FPS-Boost.ps1'); " ^
    "Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue"
