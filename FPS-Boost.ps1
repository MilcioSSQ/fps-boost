#Requires -Version 5.1
<#
.SYNOPSIS
    FPS Boost - a transparent Windows gaming optimizer for input latency and
    background load.

.DESCRIPTION
    Applies a set of well-known, reversible tweaks that reduce input lag and
    background noise while gaming. Every change is written to a backup file
    first, so "Restore" puts your system back exactly the way it was.

    This tool does NOT ship random binaries, does NOT disable core services,
    and does NOT pretend to update your GPU driver - it detects your GPU and
    opens the official download page instead.

.NOTES
    Author  : MilcioSSQ
    License : MIT
    Version : 1.0.0
    Repo    : https://github.com/MilcioSSQ/fps-boost

    Backup is stored at: %LOCALAPPDATA%\fps-boost-backup.json
#>

# ---------------------------------------------------------------------------
# Elevation: relaunch as admin if needed
# ---------------------------------------------------------------------------
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Start-Process powershell.exe -Verb RunAs -ArgumentList `
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
        exit
    }
    Write-Host "Please run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}

$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# Constants / state
# ---------------------------------------------------------------------------
$Script:BackupFile   = Join-Path $env:LOCALAPPDATA 'fps-boost-backup.json'
$Script:DisabledDir  = Join-Path $env:LOCALAPPDATA 'fps-boost-disabled-startup'
$GUID_HighPerf       = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'   # High performance
$GUID_Balanced       = '381b4222-f694-41f0-9685-ff5bb260df2e'   # Balanced (Windows default)

$Script:Backup = $null   # loaded lazily

# ---------------------------------------------------------------------------
# Small logging helpers (kept intentionally minimal)
# ---------------------------------------------------------------------------
function Section($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Ok($t)      { Write-Host "  + $t"   -ForegroundColor Green }
function Note($t)    { Write-Host "  . $t"   -ForegroundColor DarkGray }
function Warn($t)    { Write-Host "  ! $t"   -ForegroundColor Yellow }
function Fail($t)    { Write-Host "  x $t"   -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Backup: load / save
# ---------------------------------------------------------------------------
function Get-Backup {
    if ($Script:Backup) { return $Script:Backup }
    if (Test-Path $Script:BackupFile) {
        try {
            $raw = Get-Content $Script:BackupFile -Raw | ConvertFrom-Json
            $Script:Backup = [PSCustomObject]@{
                registry  = @($raw.registry)
                power     = $raw.power
                autostart = @($raw.autostart)
            }
            return $Script:Backup
        } catch { }
    }
    $Script:Backup = [PSCustomObject]@{ registry = @(); power = $null; autostart = @() }
    return $Script:Backup
}

function Save-Backup {
    (Get-Backup) | ConvertTo-Json -Depth 6 | Set-Content $Script:BackupFile -Encoding UTF8
}

# ---------------------------------------------------------------------------
# Registry write that records the original value for a clean restore
# ---------------------------------------------------------------------------
function Set-Reg($path, $name, $value, $type) {
    $b = Get-Backup
    try {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }

        $old = $null; $existed = $false
        $cur = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
        if ($null -ne $cur) { $old = $cur.$name; $existed = $true }

        $id = "$path||$name"
        if (-not ($b.registry | Where-Object { $_.id -eq $id })) {
            $b.registry += [PSCustomObject]@{
                id = $id; path = $path; name = $name
                old = $old; type = $type; existed = $existed
            }
        }
        New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
        Ok "$name = $value"
    } catch { Fail "$name : $($_.Exception.Message)" }
}

# ===========================================================================
# TWEAK: Mouse - raw input, no acceleration, 1:1 sensitivity
# ===========================================================================
function Set-MouseTweaks {
    Section 'Mouse - raw input / no acceleration'
    # "Enhance pointer precision" (mouse acceleration) off
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed'      '0'  String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0'  String
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0'  String
    # 1:1 pointer speed (the neutral value on the Windows slider)
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' String
    Note 'Sign out / reboot for the mouse changes to fully apply.'
    Note 'Also set a fixed polling rate (1000 Hz) in your mouse software.'
    Save-Backup
}

# ===========================================================================
# TWEAK: Keyboard - fastest key repeat (menu / WASD responsiveness)
# ===========================================================================
function Set-KeyboardTweaks {
    Section 'Keyboard - faster key repeat (WASD / menus)'
    # shortest repeat delay (0) + fastest repeat rate (31)
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0'  String
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' String
    Note 'This speeds up key-repeat (menus, typing, held WASD in menus).'
    Note 'Note: games read key state directly, so raw in-game input latency'
    Note 'is unchanged - this is about responsiveness feel, not a magic fix.'
    Save-Backup
}

# ===========================================================================
# TWEAK: Latency - power plan, GPU scheduling, MMCSS game priority
# ===========================================================================
function Set-LatencyTweaks {
    Section 'Latency - power plan / GPU scheduling / MMCSS'

    # Power plan -> High performance (back up the current one first)
    $cur = [regex]::Match((powercfg /getactivescheme), '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}').Value
    $b = Get-Backup
    if (-not $b.power) { $b.power = $cur }
    powercfg /setactive $GUID_HighPerf 2>$null
    $now = [regex]::Match((powercfg /getactivescheme), '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}').Value
    if ($now -eq $GUID_HighPerf) { Ok 'Power plan: High performance' }
    else { Warn 'High performance plan hidden on this device - left unchanged.' }

    # Hardware-accelerated GPU scheduling (needs reboot)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 DWord

    # Keep Game Mode ON (this one genuinely helps)
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 DWord

    # MMCSS: give the "Games" task a bit more priority (mild, reversible)
    $mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-Reg $mm 'SystemResponsiveness' 10 DWord
    Set-Reg "$mm\Tasks\Games" 'GPU Priority'        8      DWord
    Set-Reg "$mm\Tasks\Games" 'Priority'            6      DWord
    Set-Reg "$mm\Tasks\Games" 'Scheduling Category' 'High' String
    Set-Reg "$mm\Tasks\Games" 'SFIO Priority'       'High' String

    Note 'Reboot required for GPU scheduling to take effect.'
    Save-Backup
}

# ===========================================================================
# TWEAK: Background - Game DVR off, Store apps not running in background
# ===========================================================================
function Set-BackgroundTweaks {
    Section 'Background - Game DVR + Store apps'
    # Game DVR / background recording off
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 DWord
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 DWord
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0 DWord
    # Stop UWP/Store apps from running in the background (does NOT touch desktop apps)
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' 'LetAppsRunInBackground' 2 DWord
    Note 'Steam, Discord, OBS and games are unaffected (only Store apps).'
    Save-Backup
}

# ===========================================================================
# TWEAK: Network - a couple of safe, reversible options (effect is small)
# ===========================================================================
function Set-NetworkTweaks {
    Section 'Network - safe & reversible (small effect, be honest)'
    Warn 'The biggest real wins are a LAN cable and closing bandwidth hogs.'

    # Remove the multimedia network throttle (default index is 10 / 0xa)
    $mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-Reg $mm 'NetworkThrottlingIndex' 0xffffffff DWord

    # Disable Nagle on active adapters (experimental - benchmark it yourself)
    $active = Get-CimInstance Win32_NetworkAdapterConfiguration |
              Where-Object { $_.IPEnabled -and $_.DefaultIPGateway }
    foreach ($a in $active) {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($a.SettingID)"
        if (Test-Path $key) {
            Set-Reg $key 'TcpAckFrequency' 1 DWord
            Set-Reg $key 'TCPNoDelay'      1 DWord
        }
    }
    Note 'If you notice no difference, restore this section - no shame in that.'
    Save-Backup
}

# ===========================================================================
# TWEAK: Autostart manager - list & disable startup entries (reversible)
# ===========================================================================
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

function Invoke-AutostartManager {
    Section 'Autostart manager'
    $entries = Get-StartupEntries
    if ($entries.Count -eq 0) { Ok 'No startup entries found.'; return }

    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = $entries[$i]
        $src = if ($e.Hive -match 'HKCU') { 'user  ' } elseif ($e.Hive -match 'HKLM') { 'system' } else { 'folder' }
        $target = if ($e.Type -eq 'reg') { $e.Value } else { $e.Path }
        Write-Host ("  [{0,2}] ({1}) {2}" -f ($i + 1), $src, $e.Name) -ForegroundColor Yellow
        Write-Host ("        {0}" -f $target) -ForegroundColor DarkGray
    }
    Note 'Tip: keep audio (Realtek/Nahimic) and GPU (NVIDIA/AMD) drivers enabled.'

    $sel = Read-Host "`nNumbers to disable (e.g. 1,3,5 / 'all' / Enter to skip)"
    if ([string]::IsNullOrWhiteSpace($sel)) { Note 'Skipped.'; return }
    $idx = if ($sel.Trim().ToLower() -eq 'all') { 1..$entries.Count }
           else { $sel -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } }

    if (-not (Test-Path $Script:DisabledDir)) { New-Item -ItemType Directory -Path $Script:DisabledDir -Force | Out-Null }
    $b = Get-Backup
    foreach ($n in $idx) {
        if ($n -lt 1 -or $n -gt $entries.Count) { continue }
        $e = $entries[$n - 1]
        try {
            if ($e.Type -eq 'reg') {
                $b.autostart += [PSCustomObject]@{ type='reg'; hive=$e.Hive; name=$e.Name; value=$e.Value }
                Remove-ItemProperty -Path $e.Hive -Name $e.Name -ErrorAction Stop
            } else {
                $dest = Join-Path $Script:DisabledDir ([IO.Path]::GetFileName($e.Path))
                Move-Item $e.Path $dest -Force -ErrorAction Stop
                $b.autostart += [PSCustomObject]@{ type='file'; original=$e.Path; movedTo=$dest }
            }
            Ok "Disabled: $($e.Name)"
        } catch { Fail "$($e.Name): $($_.Exception.Message)" }
    }
    Save-Backup
}

# ===========================================================================
# GPU driver: detect vendor and open the official download page
# ===========================================================================
function Open-GpuDriverPage {
    Section 'GPU driver'
    $gpus = Get-CimInstance Win32_VideoController |
            Where-Object { $_.Name -and $_.Name -notmatch 'Basic|Remote|Virtual|Meta' }
    if (-not $gpus) { Warn 'No GPU detected.'; return }

    foreach ($g in $gpus) { Note "Detected: $($g.Name)  (driver $($g.DriverVersion))" }
    $name = ($gpus | Select-Object -First 1).Name

    $url = switch -Regex ($name) {
        'NVIDIA|GeForce|RTX|GTX' {
            Note 'In NVIDIA Control Panel -> Manage 3D settings, set:'
            Note '  Low Latency Mode = Ultra, Power Management = Prefer maximum performance'
            'https://www.nvidia.com/download/index.aspx'
        }
        'AMD|Radeon' {
            Note 'In AMD Software, enable Radeon Anti-Lag and set the power profile to Esports/Performance.'
            'https://www.amd.com/en/support/download/drivers.html'
        }
        'Intel' { 'https://www.intel.com/content/www/us/en/download-center/home.html' }
        default { $null }
    }
    if ($url) { Ok "Opening official driver page..."; Start-Process $url }
    else { Warn 'Unknown vendor - update via Windows Update or your OEM support page.' }
}

# ===========================================================================
# Restore everything from the backup
# ===========================================================================
function Restore-All {
    Section 'Restore - undo all changes'
    if (-not (Test-Path $Script:BackupFile)) { Warn 'No backup found - nothing to restore.'; return }
    $b = Get-Content $Script:BackupFile -Raw | ConvertFrom-Json

    foreach ($r in @($b.registry)) {
        try {
            if (-not (Test-Path $r.path)) { New-Item -Path $r.path -Force | Out-Null }
            if ($r.existed) {
                New-ItemProperty -Path $r.path -Name $r.name -Value $r.old -PropertyType $r.type -Force | Out-Null
                Ok "$($r.name) -> $($r.old)"
            } else {
                Remove-ItemProperty -Path $r.path -Name $r.name -ErrorAction SilentlyContinue
                Ok "$($r.name) removed (was not set before)"
            }
        } catch { Fail "$($r.name): $($_.Exception.Message)" }
    }

    if ($b.power) { powercfg /setactive $b.power 2>$null; Ok 'Power plan restored' }

    foreach ($a in @($b.autostart)) {
        try {
            if ($a.type -eq 'reg') {
                if (-not (Test-Path $a.hive)) { New-Item -Path $a.hive -Force | Out-Null }
                New-ItemProperty -Path $a.hive -Name $a.name -Value $a.value -PropertyType String -Force | Out-Null
                Ok "Autostart restored: $($a.name)"
            } elseif (Test-Path $a.movedTo) {
                Move-Item $a.movedTo $a.original -Force -ErrorAction Stop
                Ok "Autostart restored: $([IO.Path]::GetFileName($a.original))"
            }
        } catch { Fail $_.Exception.Message }
    }

    Remove-Item $Script:BackupFile -ErrorAction SilentlyContinue
    $Script:Backup = $null
    Note 'Reboot to make sure everything is back to normal.'
}

# ===========================================================================
# Apply the full recommended set (except network + autostart, which are opt-in)
# ===========================================================================
function Invoke-Recommended {
    Set-MouseTweaks
    Set-KeyboardTweaks
    Set-LatencyTweaks
    Set-BackgroundTweaks
    Section 'Done'
    Ok 'Recommended tweaks applied. Reboot when you can.'
    Note 'Network and Autostart are opt-in - run them from the menu if you want.'
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------
function Show-Header {
    Write-Host ""
    Write-Host "  FPS BOOST" -ForegroundColor White -NoNewline
    Write-Host "  v1.0.0  -  by MilcioSSQ" -ForegroundColor DarkGray
    Write-Host "  Transparent gaming tweaks. Everything is reversible." -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------------"
}

while ($true) {
    Show-Header
    Write-Host "  [1] Apply recommended (mouse + keyboard + latency + background)" -ForegroundColor Cyan
    Write-Host "  [2] Mouse       - raw input, no acceleration"          -ForegroundColor Gray
    Write-Host "  [3] Keyboard    - fastest key repeat (WASD / menus)"   -ForegroundColor Gray
    Write-Host "  [4] Latency     - power plan, GPU scheduling, MMCSS"   -ForegroundColor Gray
    Write-Host "  [5] Background  - Game DVR + Store apps off"           -ForegroundColor Gray
    Write-Host "  [6] Autostart   - review & disable startup apps"       -ForegroundColor Gray
    Write-Host "  [7] Network     - safe, reversible (small effect)"     -ForegroundColor Gray
    Write-Host "  [8] GPU driver  - detect & open official download"     -ForegroundColor Gray
    Write-Host "  [9] Restore     - undo everything"                     -ForegroundColor Yellow
    Write-Host "  [0] Exit"                                              -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------------"
    switch (Read-Host "  Select") {
        '1' { Invoke-Recommended;      Read-Host "`n  Enter for menu" }
        '2' { Set-MouseTweaks;         Read-Host "`n  Enter for menu" }
        '3' { Set-KeyboardTweaks;      Read-Host "`n  Enter for menu" }
        '4' { Set-LatencyTweaks;       Read-Host "`n  Enter for menu" }
        '5' { Set-BackgroundTweaks;    Read-Host "`n  Enter for menu" }
        '6' { Invoke-AutostartManager; Read-Host "`n  Enter for menu" }
        '7' { Set-NetworkTweaks;       Read-Host "`n  Enter for menu" }
        '8' { Open-GpuDriverPage;      Read-Host "`n  Enter for menu" }
        '9' { Restore-All;             Read-Host "`n  Enter for menu" }
        '0' { break }
        default { Warn 'Pick a number from the menu.' }
    }
}
