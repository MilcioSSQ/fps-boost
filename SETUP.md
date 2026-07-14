# 🎮 FPS Boost Dashboard - Setup Guide

Kompletter Guide um das Gaming Dashboard zum Laufen zu bringen.

---

## Step 1: Prerequisites

### Node.js & npm
1. Download: https://nodejs.org/ (LTS)
2. Installieren
3. Terminal: `node --version` + `npm --version`

### Git
Download: https://git-scm.com/

---

## Step 2: Projekt-Struktur

```
Dein Ordner:
├── fps-boost-main/          ← Dein bestehendes FPS-Boost Repo
│   ├── FPS-Boost.ps1
│   ├── Autostart-Clean.ps1
│   └── README.md
└── fps-boost-dashboard/     ← Das neue Dashboard
    ├── main.js
    ├── package.json
    └── src/
```

**Wichtig:** Beide Ordner müssen nebeneinander sein!

---

## Step 3: Installation

```bash
cd fps-boost-dashboard
npm install
```

Dauert 2-3 Minuten!

---

## Step 4: Starten

### Development Mode (mit Hot-Reload)
```bash
npm run electron-dev
```

Öffnet:
- React Dev Server (Port 3000)
- Electron Fenster mit Dashboard
- DevTools (F12)

### Nur App (ohne Dev-Tools)
In `main.js` kommentiere aus:
```javascript
// mainWindow.webContents.openDevTools();
```

---

## Step 5: Testen

### Was checken?
- [ ] Performance Stats anzeigen (CPU, GPU, RAM)
- [ ] Refresh Button klicken → Werte aktualisieren
- [ ] "Gaming Mode" Button klicken
- [ ] Mouse Settings anzeigen
- [ ] Network Status anzeigen
- [ ] Backup Status überprüfen

### Tools manuell testen
```powershell
# Im fps-boost-main Ordner
powershell -ExecutionPolicy Bypass -File .\FPS-Boost.ps1
powershell -ExecutionPolicy Bypass -File .\Autostart-Clean.ps1
```

---

## Step 6: Bauen

### Executable erstellen
```bash
npm run electron-build
```

Output in `dist/`:
- Setup-Installer (.exe)
- Portable (.exe)

---

## Häufige Fehler

### "Cannot find module 'react'"
```bash
npm install
```

### "fps-boost-main not found"
Stelle sicher beide Ordner nebeneinander sind:
```
📁 fps-boost-main/
📁 fps-boost-dashboard/
```

### Port 3000 in Benutzung
```bash
netstat -ano | findstr :3000
taskkill /PID XXXX /F
```

### PowerShell Script startet nicht
- Admin-Rechte prüfen
- PowerShell Version: `$PSVersionTable.PSVersion`
- Pfad in `main.js` checken

---

## GitHub Upload

```bash
git init
git add .
git commit -m "msg"
git branch -M main
git remote add origin https://...
git push -u origin main
```

Siehe `QUICK-UPLOAD.md` für 3-Minuten Guide!

---

## Performance Tips

1. **Keep it Running** - Dashboard läuft im Hintergrund
2. **Refresh Rate** - Alle 2 Sekunden (in App.js)
3. **Memory** - ~200-300 MB typisch
4. **Build Size** - ~150 MB mit Dependencies

---

## Customization

### Colors in App.css
```css
/* Change these colors */
--primary: #ff006e;    /* Pink */
--accent: #00d4ff;     /* Cyan */
--success: #00ff88;    /* Green */
--warn: #ffaa00;       /* Orange */
```

### Game Detection
In `main.js`, `detect-games` Funktion:
```javascript
const games = ['Fortnite', 'csgo', 'VALORANT', ...];
```

### Update Frequency
In `src/App.js`:
```javascript
const interval = setInterval(refreshAllData, 2000); // 2000ms = 2 Sekunden
```

---

## Support

- Siehe `README.md` - Dokumentation
- Siehe `QUICK-UPLOAD.md` - GitHub Upload
- Check `package.json` - Dependencies

---

**Viel Spaß beim Optimieren! 🎮⚡**
