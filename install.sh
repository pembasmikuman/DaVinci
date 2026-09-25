#!/usr/bin/env bash
# Install (or update) the DaVinci KDE Plasma 6 wallpaper and set it on every desktop.
set -euo pipefail
cd "$(dirname "$0")"

# The wallpaper renders the page with Qt WebEngine, which a fresh Plasma install may lack.
if ! ls /usr/lib*/qt6/qml/QtWebEngine >/dev/null 2>&1; then
  echo "Qt WebEngine for QML is missing. On Arch/CachyOS: sudo pacman -S qt6-webengine" >&2
  exit 1
fi

kpackagetool6 -t Plasma/Wallpaper -u kde 2>/dev/null || kpackagetool6 -t Plasma/Wallpaper -i kde

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
desktops().forEach(d => { d.wallpaperPlugin = "com.pembasmikuman.davinci"; d.reloadConfig() })'

# Plasma caches QML, so restart it to pick up changes on an update.
systemctl --user restart plasma-plasmashell
echo "DaVinci wallpaper installed."
