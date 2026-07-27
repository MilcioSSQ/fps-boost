#Requires -Version 5.1
<#
================================================================================
  AUTOSTART-CLEAN  -  disable unnecessary startup apps automatically
================================================================================
  Turns OFF the junk that auto-starts with Windows (updaters, OneDrive, tray
  tools, etc.) but PROTECTS the things you actually want at boot:

    - GPU drivers (NVIDIA / AMD / Intel)
    - Audio drivers (Realtek / Nahimic / ...)
    - Mouse & keyboard software (Logitech G HUB, Razer, SteelSeries, Corsair ...)
    - Touchpad drivers (Synaptics / ELAN)
    - Antivirus / security tools

  Disabled apps are NOT deleted - they just don't launch at startup anymore.
  You can still open them by hand, and "Restore" brings everything back.

  Note: this handles classic desktop autostart (Run keys + Startup folder).
  For Store apps in the background (Widgets, WhatsApp Store, Xbox), use the
  fps-boost "Background" option or Settings > Apps > Startup.

  Menu:
    1) Clean    - disable all non-protected startup apps
    2) Show     - list what starts up (read only)
    3) Restore  - undo everything
    0) Exit

  Starts itself as Administrator.
================================================================================
#>

# ---- elevate ---------------------------------------------------------------
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList `
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
        exit
    }
    Write-Host "Please run as Administrator." -ForegroundColor Red
    Read-Host "Enter to exit"; exit 1
}

$ErrorActionPreference = 'Continue'
$BackupFile  = Join-Path $env:LOCALAPPDATA 'autostart-clean-backup.json'
$DisabledDir = Join-Path $env:LOCALAPPDATA 'autostart-clean-disabled'

function Ok($t)   { Write-Host "  + $t" -ForegroundColor Green }
function Keep($t) { Write-Host "  = $t" -ForegroundColor DarkCyan }
function Note($t) { Write-Host "  . $t" -ForegroundColor DarkGray }
function Warn($t) { Write-Host "  ! $t" -ForegroundColor Yellow }
function Fail($t) { Write-Host "  x $t" -ForegroundColor Red }

# ---- things we NEVER auto-disable (matched against name AND command) -------
$Protect = @(
    'nvidia', 'geforce', 'amd', 'radeon', 'intel.*graphic', 'igfx',
    'realtek', 'rtk', 'nahimic', 'waves', 'audio', 'dolby',
    'logitech', 'lghub', 'g ?hub', 'razer', 'synapse', 'steelseries', 'corsair', 'icue', 'wooting',
    'synaptics', 'elan', 'touchpad',
    'defender', 'antimalware', 'securityhealth', 'avast', 'avira', 'bitdefender',
    'kaspersky', 'malwarebytes', 'mcafee', 'norton', 'eset',
    'msi center', 'armoury', 'dragon center', 'crash defender'
)
function Test-Protected($name, $cmd) {
    foreach ($p in $Protect) { if ($name -match $p -or $cmd -match $p) { return $true } }
    return $false
}

# ---- backup helpers --------------------------------------------------------
function Get-Backup {
    if (Test-Path $BackupFile) {
        try { return @(Get-Content $BackupFile -Raw | ConvertFrom-Json) } catch { }
    }
    return @()
}
function Save-Backup($arr) { ,@($arr) | ConvertTo-Json -Depth 6 | Set-Content $BackupFile -Encoding UTF8 }

# ---- collect autostart entries ---------------------------------------------
function Get-StartupEntries {
    $list = New-Object System.Collections.Generic.List[object]
    $hives = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($h in $hives) {
        if (Test-Path $h) {
            (Get-ItemProperty $h).PSObject.Properties |
                Where-Object { $_.Name -notmatch '^PS' -and $_.Name -ne '(default)' } |
                ForEach-Object { $list.Add([PSCustomObject]@{ Type='reg'; Hive=$h; Name=$_.Name; Value=[string]$_.Value }) }
        }
    }
    foreach ($f in @([Environment]::GetFolderPath('Startup'),
                     (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\StartUp'))) {
        if (Test-Path $f) {
            Get-ChildItem $f -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ne 'desktop.ini' } |
                ForEach-Object { $list.Add([PSCustomObject]@{ Type='file'; Path=$_.FullName; Name=$_.Name }) }
        }
    }
    return $list
}

function Show-Startup {
    $entries = Get-StartupEntries
    if ($entries.Count -eq 0) { Ok 'No startup entries found.'; return }
    Write-Host "`n  Current autostart entries:" -ForegroundColor Cyan
    foreach ($e in $entries) {
        $cmd = if ($e.Type -eq 'reg') { $e.Value } else { $e.Path }
        if (Test-Protected $e.Name $cmd) { Keep "$($e.Name)   [protected - kept]" }
        else { Write-Host "  - $($e.Name)" -ForegroundColor Yellow }
    }
}

# ---- clean -----------------------------------------------------------------
function Invoke-Clean {
    $entries = Get-StartupEntries
    if ($entries.Count -eq 0) { Ok 'No startup entries found - nothing to do.'; return }

    $toDisable = @(); $kept = @()
    foreach ($e in $entries) {
        $cmd = if ($e.Type -eq 'reg') { $e.Value } else { $e.Path }
        if (Test-Protected $e.Name $cmd) { $kept += $e } else { $toDisable += $e }
    }

    Write-Host "`n  WILL DISABLE (auto-start off):" -ForegroundColor Yellow
    if ($toDisable) { $toDisable | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Yellow } }
    else { Note 'nothing - already clean' }

    Write-Host "`n  WILL KEEP (drivers / audio / mouse / antivirus):" -ForegroundColor DarkCyan
    if ($kept) { $kept | ForEach-Object { Write-Host "    = $($_.Name)" -ForegroundColor DarkCyan } }
    else { Note 'none detected' }

    if ($toDisable.Count -eq 0) { return }

    $ans = Read-Host "`n  Disable the yellow list? Type JA (uppercase)"
    if ($ans -cne 'JA') { Warn 'Cancelled - nothing changed.'; return }

    if (-not (Test-Path $DisabledDir)) { New-Item -ItemType Directory -Path $DisabledDir -Force | Out-Null }
    $backup = Get-Backup

    foreach ($e in $toDisable) {
        try {
            if ($e.Type -eq 'reg') {
                $backup += [PSCustomObject]@{ type='reg'; hive=$e.Hive; name=$e.Name; value=$e.Value }
                Remove-ItemProperty -Path $e.Hive -Name $e.Name -ErrorAction Stop
            } else {
                $dest = Join-Path $DisabledDir ([IO.Path]::GetFileName($e.Path))
                Move-Item $e.Path $dest -Force -ErrorAction Stop
                $backup += [PSCustomObject]@{ type='file'; original=$e.Path; movedTo=$dest }
            }
            Ok "Disabled: $($e.Name)"
        } catch { Fail "$($e.Name): $($_.Exception.Message)" }
    }
    Save-Backup $backup
    Write-Host "`n  Done. Changes take effect at next startup." -ForegroundColor Green
}

# ---- restore ---------------------------------------------------------------
function Restore-All {
    if (-not (Test-Path $BackupFile)) { Warn 'No backup found - nothing to restore.'; return }
    $backup = Get-Backup
    foreach ($a in $backup) {
        try {
            if ($a.type -eq 'reg') {
                if (-not (Test-Path $a.hive)) { New-Item -Path $a.hive -Force | Out-Null }
                New-ItemProperty -Path $a.hive -Name $a.name -Value $a.value -PropertyType String -Force | Out-Null
                Ok "Restored: $($a.name)"
            } elseif (Test-Path $a.movedTo) {
                Move-Item $a.movedTo $a.original -Force -ErrorAction Stop
                Ok "Restored: $([IO.Path]::GetFileName($a.original))"
            }
        } catch { Fail $_.Exception.Message }
    }
    Remove-Item $BackupFile -ErrorAction SilentlyContinue
    Write-Host "`n  Everything restored. Reboot to be sure." -ForegroundColor Green
}

# ---- menu ------------------------------------------------------------------
while ($true) {
    Write-Host ""
    Write-Host "  AUTOSTART-CLEAN" -ForegroundColor White -NoNewline
    Write-Host "  -  keeps your drivers, kills the junk" -ForegroundColor DarkGray
    Write-Host "  ------------------------------------------------"
    Write-Host "  [1] Clean    - disable non-protected startup apps" -ForegroundColor Cyan
    Write-Host "  [2] Show     - list what starts up"                -ForegroundColor Gray
    Write-Host "  [3] Restore  - undo everything"                    -ForegroundColor Yellow
    Write-Host "  [0] Exit"                                          -ForegroundColor DarkGray
    Write-Host "  ------------------------------------------------"
    switch (Read-Host "  Select") {
        '1' { Invoke-Clean;  Read-Host "`n  Enter for menu" }
        '2' { Show-Startup;  Read-Host "`n  Enter for menu" }
        '3' { Restore-All;   Read-Host "`n  Enter for menu" }
        '0' { break }
        default { Warn 'Pick 1, 2, 3 or 0.' }
    }
}
