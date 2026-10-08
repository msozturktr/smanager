#!/bin/sh
# smanager installer
#   ./install.sh               install (adds an application menu entry)
#   ./install.sh --autostart   install and start hidden in the tray at login
#   ./install.sh --uninstall   remove smanager
set -e

BIN="$HOME/.local/bin/smanager"
APPS="$HOME/.local/share/applications/smanager.desktop"
AUTO="$HOME/.config/autostart/smanager.desktop"
FONTS="$HOME/.local/share/fonts/smanager"

desktop_entry() {
    cat <<DESKTOP
[Desktop Entry]
Type=Application
Name=smanager
Comment=Volume control up to 300% and media control
Exec=$BIN $1
Icon=multimedia-volume-control
Categories=AudioVideo;Audio;Mixer;
Terminal=false
StartupWMClass=smanager
DESKTOP
}

if [ "$1" = "--uninstall" ]; then
    pkill -f "python3 $BIN" 2>/dev/null || true
    rm -f "$BIN" "$APPS" "$AUTO"
    rm -rf "$FONTS"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    echo "smanager removed."
    exit 0
fi

missing=""
command -v pactl >/dev/null 2>&1 || missing="$missing pulseaudio-utils"
python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" 2>/dev/null \
    || missing="$missing python3-gi gir1.2-gtk-3.0"
python3 -c "import gi; gi.require_foreign('cairo')" 2>/dev/null || missing="$missing python3-gi-cairo"
if [ -n "$missing" ]; then
    echo "Missing packages:$missing"
    echo "Install them with: sudo apt install$missing"
    exit 1
fi

mkdir -p "$(dirname "$BIN")" "$(dirname "$APPS")"
install -m 755 "$(dirname "$0")/smanager" "$BIN"
desktop_entry "" > "$APPS"
mkdir -p "$FONTS"
cp "$(dirname "$0")"/fonts/*.ttf "$(dirname "$0")"/fonts/OFL-*.txt "$FONTS"/
command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
echo "Installed: $BIN"

if [ "$1" = "--autostart" ]; then
    mkdir -p "$(dirname "$AUTO")"
    desktop_entry "--hidden" > "$AUTO"
    echo "Autostart enabled: $AUTO"
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "Note: ~/.local/bin is not in your PATH; add it to run smanager from a terminal." ;;
esac
