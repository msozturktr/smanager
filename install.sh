#!/bin/sh
# Ses Yöneticisi kurulum betiği
#   ./install.sh             kur (uygulama menüsüne ekler)
#   ./install.sh --otomatik  kur + oturum açılınca tepside başlat
#   ./install.sh --kaldir    kaldır
set -e

BIN="$HOME/.local/bin/ses-yoneticisi"
APPS="$HOME/.local/share/applications/ses-yoneticisi.desktop"
AUTO="$HOME/.config/autostart/ses-yoneticisi.desktop"

desktop_entry() {
    cat <<DESKTOP
[Desktop Entry]
Type=Application
Name=Ses Yöneticisi
Comment=%300'e kadar ses kontrolü
Exec=$BIN $1
Icon=multimedia-volume-control
Categories=AudioVideo;Audio;Mixer;
Terminal=false
StartupWMClass=ses-yoneticisi
DESKTOP
}

if [ "$1" = "--kaldir" ]; then
    pkill -f "python3 $BIN" 2>/dev/null || true
    rm -f "$BIN" "$APPS" "$AUTO"
    echo "Ses Yöneticisi kaldırıldı."
    exit 0
fi

missing=""
command -v pactl >/dev/null 2>&1 || missing="$missing pulseaudio-utils"
python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" 2>/dev/null \
    || missing="$missing python3-gi gir1.2-gtk-3.0"
if [ -n "$missing" ]; then
    echo "Eksik paketler:$missing"
    echo "Kurmak için: sudo apt install$missing"
    exit 1
fi

mkdir -p "$(dirname "$BIN")" "$(dirname "$APPS")"
install -m 755 "$(dirname "$0")/ses-yoneticisi" "$BIN"
desktop_entry "" > "$APPS"
echo "Kuruldu: $BIN"

if [ "$1" = "--otomatik" ]; then
    mkdir -p "$(dirname "$AUTO")"
    desktop_entry "--gizli" > "$AUTO"
    echo "Otomatik başlatma etkin: $AUTO"
fi

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "Not: ~/.local/bin PATH içinde değil; terminalden çalıştırmak için PATH'e ekleyin." ;;
esac
