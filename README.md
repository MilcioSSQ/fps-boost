# FPS Boost Dashboard

A **high-performance Electron + React dashboard** for the FPS Boost PowerShell gaming optimizer. Monitor your gaming performance in real-time, detect active games, and apply gaming tweaks with one click.

![Gaming Dashboard](screenshot.png)

---

## ⚡ Features

### Performance Monitoring
- **Live CPU, GPU, RAM, VRAM, Temperature** tracking (updated every 2 seconds)
- **Real-time FPS Counter** while gaming
- **Color-coded health indicators** (Excellent, Good, Fair, Poor)
- **Smooth performance graphs** with trend indicators

### Game Detection
- 🎮 **Automatic Game Detection** (Fortnite, Valorant, CS:GO, Apex, R6, OW2)
- **Active Game Display** in header
- **Gaming Mode Auto-Trigger** when game detected

### Gaming Optimization
- ⚡ **One-Click Gaming Mode** (applies all tweaks)
- 🎯 **Multiple Optimization Levels** (Balanced, Aggressive, Network)
- 🔄 **Autostart Cleaner** (removes bloatware from startup)
- 🖱️ **Mouse Settings Monitor** (Acceleration, Sensitivity, DPI, Polling Rate)

### Network & System
- 🌐 **Network Status** (IP, Connection Type, Ping, Health)
- ⚙️ **GPU Driver Management** (Link to official drivers)
- 💾 **Backup & Restore** (Safe rollback of all changes)

### UI/UX
- 🎨 **Gaming-Focused Aesthetic** (Purple/Blue/Neon)
- 📱 **Responsive Design** (Desktop, Tablet, Mobile)
- ✨ **Smooth Animations & Transitions**
- 🌙 **Dark Theme** optimized for gaming

---

## 🎮 What it Does

| Feature | Description |
|---------|-------------|
| **Performance Monitoring** | Track CPU/GPU/RAM/Temp in real-time while gaming |
| **Game Detection** | Detects when you start playing (Fortnite, Valorant, CS:GO, etc.) |
| **Gaming Mode** | Applies all FPS Boost tweaks with one click |
| **Mouse Settings** | Shows raw input, acceleration, DPI, polling rate |
| **Network Status** | Displays IP, connection type, ping, and health |
| **GPU Driver Manager** | Links to official NVIDIA/AMD/Intel driver downloads |
| **Autostart Cleaner** | Removes bloatware and startup programs |
| **Backup & Restore** | Safe rollback of all system changes |

---

## 🚀 Quick Start

### Prerequisites
- Node.js 14+
- npm or yarn
- Windows 10/11
- PowerShell 5.1+
- FPS Boost repo in parent directory

### Installation

```bash
# Install dependencies
npm install

# Start development mode
npm run electron-dev

# Build for distribution
npm run electron-build
```

---

## 📊 Performance Metrics

### Real-time Displays
- **CPU Load** - Processor usage percentage
- **GPU Load** - Graphics card usage
- **RAM Usage** - System memory consumption
- **VRAM Usage** - Video memory usage
- **CPU Temperature** - Processor temperature in Celsius
- **Current FPS** - Frames per second counter

### Health Indicators
```
🟢 Excellent: 0-50% (Green)
🟢 Good:      50-75% (Cyan)
🟡 Fair:      75-85% (Orange)
🔴 Poor:      85%+   (Red)
```

---

## 🎯 Gaming Mode Options

### Balanced (Default)
- Mouse acceleration: Off
- Power Plan: High Performance
- Game DVR: Off
- GPU Scheduling: On
- MMCSS: Enabled

### Aggressive
- All from Balanced +
- Background apps: Disabled
- Autostart bloatware: Removed
- Network optimizations: Applied

### Network Only
- Network throttle removed
- Nagle disabled on adapters
- Latency optimizations

---

## 🔧 System Requirements

- **Windows 10 or 11**
- **PowerShell 5.1+** (built-in)
- **Administrator rights** (auto-elevated)
- **GPU drivers** (NVIDIA/AMD/Intel) current version recommended

---

## 📁 Project Structure

```
fps-boost-dashboard/
├── main.js              # Electron backend
├── preload.js           # Security bridge
├── index.html           # HTML shell
├── package.json         # Dependencies
├── README.md            # This file
└── src/
    ├── App.js           # React component
    ├── App.css          # Gaming UI styling
    └── index.js         # React entry point
```

---

## 🔌 IPC Handlers

The dashboard communicates with FPS Boost via these handlers:

- `get-performance-stats` → CPU, GPU, RAM, VRAM, Temp, FPS, Ping
- `detect-games` → Active games detection
- `apply-gaming-tweaks` → Apply FPS Boost optimizations
- `run-autostart-clean` → Clean startup programs
- `check-backup` → Backup status
- `get-mouse-settings` → Mouse configuration
- `get-network-info` → Network status

---

## 🎨 Customization

### Colors
Edit `src/App.css`:
```css
Primary Pink:   #ff006e
Accent Cyan:    #00d4ff
Success Green:  #00ff88
Warning Orange: #ffaa00
```

### Update Frequency
Edit `src/App.js`:
```javascript
// Change refresh rate (milliseconds)
const interval = setInterval(refreshAllData, 2000); // 2 seconds
```

### Game List
Edit `main.js` in `detect-games`:
```javascript
const games = ['Fortnite', 'csgo', 'VALORANT', 'Apex', ...];
```

---

## 🐛 Troubleshooting

### "Module not found: react"
```bash
npm install
npm install react react-dom react-icons
```

### "Port 3000 already in use"
```bash
npx kill-port 3000
npm run electron-dev
```

### "PowerShell script not found"
- Ensure FPS Boost repo is in parent directory
- Check path in `main.js` matches your setup

### Admin rights not working
- Right-click PowerShell → Run as Administrator
- Try running the app as admin

---

## 📈 Performance Tips

1. **Keep GPU drivers updated** (use Dashboard link)
2. **Close unnecessary background apps** (use Autostart Cleaner)
3. **Monitor temperatures** (prevent thermal throttling)
4. **Use wired network** (more stable than WiFi)
5. **Reboot after applying** tweaks for full effect

---

## 🔄 Backup & Restore

All changes are backed up in:
```
%LOCALAPPDATA%\fps-boost-backup.json
```

**To restore:**
1. Click "🔄 Restore Original" button in dashboard
2. Reboot system
3. All changes reverted to original state

---

## 🚀 Building & Distribution

### Create .exe Installer
```bash
npm run electron-build
```

Creates:
- `dist/FPS Boost Dashboard Setup 1.0.0.exe` (Installer)
- `dist/FPS Boost Dashboard 1.0.0.exe` (Portable)

### Sign & Distribute
- Distribute the portable `.exe` directly
- Or use NSIS installer for professional deployment

---

## 📝 License

MIT © MilcioSSQ

---

## 🎮 Credits

Dashboard built for [FPS Boost](../fps-boost-main) by **MilcioSSQ**

Integrates with PowerShell gaming optimizer for maximum performance.

---

## 💬 Support

- Report issues on GitHub
- Check `SETUP.md` for detailed setup
- Review `QUICK-UPLOAD.md` for upload instructions

---

**Optimize your gaming. Monitor your performance. Dominate your games.** 🎮⚡
