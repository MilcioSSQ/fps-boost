import React, { useState, useEffect } from 'react';
import { FiZap, FiSettings, FiPlay, FiRotateCw, FiWifi, FiMouse, FiTrendingUp, FiDownload, FiCheck } from 'react-icons/fi';
import './App.css';

const App = () => {
  const [stats, setStats] = useState(null);
  const [gameDetected, setGameDetected] = useState(null);
  const [backup, setBackup] = useState(null);
  const [mouseSettings, setMouseSettings] = useState(null);
  const [networkInfo, setNetworkInfo] = useState(null);
  const [running, setRunning] = useState(false);
  const [optimizationLevel, setOptimizationLevel] = useState('balanced');

  useEffect(() => {
    refreshAllData();
    const interval = setInterval(refreshAllData, 2000);
    return () => clearInterval(interval);
  }, []);

  const refreshAllData = async () => {
    try {
      const [perf, games, bak, mouse, net] = await Promise.all([
        window.api.getPerformanceStats(),
        window.api.detectGames(),
        window.api.checkBackup(),
        window.api.getMouseSettings(),
        window.api.getNetworkInfo(),
      ]);

      setStats(perf);
      setGameDetected(games);
      setBackup(bak);
      setMouseSettings(mouse);
      setNetworkInfo(net);
    } catch (error) {
      console.error('Error refreshing data:', error);
    }
  };

  const applyGamingMode = async () => {
    setRunning(true);
    try {
      const result = await window.api.applyGamingTweaks(optimizationLevel);
      alert(result.success ? '✅ Gaming Mode aktiviert! Neustart empfohlen.' : '❌ Fehler: ' + result.output);
    } catch (error) {
      alert('❌ Fehler: ' + error.message);
    } finally {
      setRunning(false);
      setTimeout(refreshAllData, 1000);
    }
  };

  const cleanAutostart = async () => {
    setRunning(true);
    try {
      const result = await window.api.runAutostartClean();
      alert(result.success ? '✅ Autostart aufgeräumt!' : '❌ Fehler');
    } catch (error) {
      alert('❌ Fehler: ' + error.message);
    } finally {
      setRunning(false);
    }
  };

  const getHealthClass = (value, thresholds) => {
    if (value < thresholds.good) return 'excellent';
    if (value < thresholds.fair) return 'good';
    if (value < thresholds.poor) return 'fair';
    return 'poor';
  };

  return (
    <div className="gaming-dashboard">
      {/* Header */}
      <header className="header">
        <div className="header-content">
          <div className="logo">
            <FiZap className="logo-icon" />
            <h1>FPS BOOST</h1>
            <span className="subtitle">Gaming Performance Dashboard</span>
          </div>

          {gameDetected?.isGaming && (
            <div className="game-detected">
              🎮 GAMING MODE DETECTED: {gameDetected.games.join(', ')}
            </div>
          )}
        </div>
      </header>

      <div className="container">
        {/* Performance Grid */}
        {stats && (
          <section className="performance-section">
            <h2>⚡ LIVE PERFORMANCE</h2>

            <div className="perf-grid">
              {/* CPU */}
              <div className={`perf-card ${getHealthClass(stats.cpu, { good: 50, fair: 75, poor: 90 })}`}>
                <div className="perf-icon">CPU</div>
                <div className="perf-value">{stats.cpu}%</div>
                <div className="perf-bar">
                  <div className="perf-fill" style={{ width: `${stats.cpu}%` }}></div>
                </div>
                <div className="perf-label">Processor Load</div>
              </div>

              {/* GPU */}
              <div className={`perf-card ${getHealthClass(stats.gpu, { good: 70, fair: 85, poor: 95 })}`}>
                <div className="perf-icon">GPU</div>
                <div className="perf-value">{stats.gpu}%</div>
                <div className="perf-bar">
                  <div className="perf-fill" style={{ width: `${stats.gpu}%` }}></div>
                </div>
                <div className="perf-label">Graphics Load</div>
              </div>

              {/* RAM */}
              <div className={`perf-card ${getHealthClass(stats.ram, { good: 60, fair: 80, poor: 90 })}`}>
                <div className="perf-icon">RAM</div>
                <div className="perf-value">{stats.ram}%</div>
                <div className="perf-bar">
                  <div className="perf-fill" style={{ width: `${stats.ram}%` }}></div>
                </div>
                <div className="perf-label">Memory Usage</div>
              </div>

              {/* VRAM */}
              <div className={`perf-card ${getHealthClass(stats.vram, { good: 50, fair: 75, poor: 90 })}`}>
                <div className="perf-icon">VRAM</div>
                <div className="perf-value">{stats.vram}%</div>
                <div className="perf-bar">
                  <div className="perf-fill" style={{ width: `${stats.vram}%` }}></div>
                </div>
                <div className="perf-label">Video Memory</div>
              </div>

              {/* TEMP */}
              <div className={`perf-card ${getHealthClass(stats.temperature, { good: 60, fair: 75, poor: 85 })}`}>
                <div className="perf-icon">°C</div>
                <div className="perf-value">{stats.temperature}°</div>
                <div className="perf-bar">
                  <div className="perf-fill" style={{ width: `${(stats.temperature / 100) * 100}%` }}></div>
                </div>
                <div className="perf-label">CPU Temperature</div>
              </div>

              {/* FPS */}
              <div className="perf-card highlight">
                <div className="perf-icon">🎮</div>
                <div className="perf-value">{stats.fps}</div>
                <div className="perf-label">Current FPS</div>
                <div className="perf-trend">📈 Stable</div>
              </div>
            </div>
          </section>
        )}

        {/* Quick Actions */}
        <section className="actions-section">
          <h2>⚙️ OPTIMIZATION</h2>

          <div className="optimization-controls">
            <div className="level-selector">
              <label>Level:</label>
              <select value={optimizationLevel} onChange={(e) => setOptimizationLevel(e.target.value)}>
                <option value="balanced">⚖️ Balanced</option>
                <option value="aggressive">⚡ Aggressive</option>
                <option value="network">🌐 Network Only</option>
              </select>
            </div>

            <button
              className="gaming-btn primary"
              onClick={applyGamingMode}
              disabled={running}
            >
              {running ? (
                <>
                  <FiRotateCw className="spin" /> APPLYING...
                </>
              ) : (
                <>
                  <FiPlay /> GAMING MODE
                </>
              )}
            </button>

            <button
              className="gaming-btn secondary"
              onClick={cleanAutostart}
              disabled={running}
            >
              <FiSettings /> CLEAN AUTOSTART
            </button>
          </div>
        </section>

        {/* Settings Grid */}
        <div className="settings-grid">
          {/* Mouse Settings */}
          {mouseSettings && (
            <div className="settings-card">
              <h3><FiMouse /> Mouse Settings</h3>
              <div className="setting-item">
                <span>Sensitivity:</span>
                <strong>{mouseSettings.sensitivity}</strong>
              </div>
              <div className="setting-item">
                <span>Acceleration:</span>
                <strong className={mouseSettings.acceleration === 'Off' ? 'good' : 'warn'}>
                  {mouseSettings.acceleration}
                </strong>
              </div>
              <div className="setting-item">
                <span>Polling Rate:</span>
                <strong>{mouseSettings.polling}</strong>
              </div>
              <div className="setting-item">
                <span>DPI:</span>
                <strong>{mouseSettings.dpi}</strong>
              </div>
            </div>
          )}

          {/* Network Info */}
          {networkInfo && (
            <div className="settings-card">
              <h3><FiWifi /> Network</h3>
              <div className="setting-item">
                <span>IP Address:</span>
                <strong>{networkInfo.ip}</strong>
              </div>
              <div className="setting-item">
                <span>Connection:</span>
                <strong className="good">{networkInfo.type}</strong>
              </div>
              <div className="setting-item">
                <span>Ping:</span>
                <strong>{networkInfo.ping}</strong>
              </div>
              <div className="setting-item">
                <span>Status:</span>
                <strong className="good">✅ {networkInfo.status}</strong>
              </div>
            </div>
          )}

          {/* Backup Status */}
          {backup && (
            <div className="settings-card">
              <h3><FiCheck /> Backup & Restore</h3>
              {backup.exists ? (
                <>
                  <div className="backup-status good">✅ Backup Found</div>
                  <div className="setting-item">
                    <span>Size:</span>
                    <strong>{backup.size}</strong>
                  </div>
                  <div className="setting-item">
                    <span>Modified:</span>
                    <strong>{backup.modified}</strong>
                  </div>
                  <button className="restore-btn">🔄 Restore Original</button>
                </>
              ) : (
                <div className="backup-status warn">⚠️ No Backup Yet</div>
              )}
            </div>
          )}

          {/* GPU Driver */}
          <div className="settings-card">
            <h3><FiDownload /> GPU Driver</h3>
            <p>Keep your graphics driver updated for best performance</p>
            <button className="driver-btn">
              📥 Download Latest Driver
            </button>
            <div className="driver-note">
              💡 Recommended for: Reduced latency & stability
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
