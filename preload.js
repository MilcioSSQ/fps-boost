const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getPerformanceStats: () => ipcRenderer.invoke('get-performance-stats'),
  detectGames: () => ipcRenderer.invoke('detect-games'),
  checkBackup: () => ipcRenderer.invoke('check-backup'),
  applyGamingTweaks: (tweaks) => ipcRenderer.invoke('apply-gaming-tweaks', tweaks),
  runAutostartClean: () => ipcRenderer.invoke('run-autostart-clean'),
  getMouseSettings: () => ipcRenderer.invoke('get-mouse-settings'),
  getNetworkInfo: () => ipcRenderer.invoke('get-network-info'),
});
