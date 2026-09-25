#!/usr/bin/env bash
# Install (or update) the DaVinci KDE Plasma 6 wallpaper and set it on every desktop.
# Usage: ./install.sh [saved-page.html]
#   saved-page.html  a page from the settings panel's "Save for wallpaper" (e.g. ~/Downloads/davinci.html).
#                    Only its settings are kept, in ~/.config/davinci/settings.json; index.html is never changed.
#                    Later installs reuse them. Delete that file to go back to the defaults.
set -euo pipefail
src=${1:+$(realpath "$1")}  # resolve before cd so relative paths still work
cd "$(dirname "$0")"

conf=${XDG_CONFIG_HOME:-$HOME/.config}/davinci/settings.json
pkg=${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/com.pembasmikuman.davinci
open_tag='<script id="settings" type="application/json">'

# Keep just the settings from a saved page (the JSON on its settings line).
if [[ -n $src ]]; then
  json=$(sed -n "s|^${open_tag}\(.*\)</script>\$|\1|p" "$src")
  [[ -n $json ]] || { echo "$1 doesn't look like a page saved from the DaVinci settings panel" >&2; exit 1; }
  mkdir -p "$(dirname "$conf")"
  printf '%s\n' "$json" > "$conf"
  echo "Saved your settings to $conf"
fi

# The wallpaper renders the page with Qt WebEngine, which a fresh Plasma install may lack.
if ! ls /usr/lib*/qt6/qml/QtWebEngine >/dev/null 2>&1; then
  echo "Qt WebEngine for QML is missing. On Arch/CachyOS: sudo pacman -S qt6-webengine" >&2
  exit 1
fi

kpackagetool6 -t Plasma/Wallpaper -u kde 2>/dev/null || kpackagetool6 -t Plasma/Wallpaper -i kde

# Swap your saved settings into the installed copy of the page (the repo's index.html keeps the defaults).
if [[ -f $conf ]]; then
  page=$pkg/contents/ui/index.html
  awk -v conf="$conf" -v tag="$open_tag" \
    'index($0, tag) == 1 { getline json < conf; print tag json "</script>"; next } { print }' \
    "$page" > "$page.tmp" && mv "$page.tmp" "$page"
  echo "Using your settings from $conf"
fi

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
desktops().forEach(d => { d.wallpaperPlugin = "com.pembasmikuman.davinci"; d.reloadConfig() })'

# Plasma caches QML, so restart it to pick up changes on an update.
systemctl --user restart plasma-plasmashell
echo "DaVinci wallpaper installed."
