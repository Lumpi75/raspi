#!/bin/bash
set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pause() { read -p "Weiter mit [Enter]..."; }

# ------------------------------------------------------------
# SYSTEM
# ------------------------------------------------------------

update_system() {
    sudo apt update
    sudo apt upgrade -y
    echo -e "${GREEN}✅ System-Update abgeschlossen.${NC}"
    pause
}

install_tools() {
    local tools=("git" "htop" "curl" "python3-pip")
    sudo apt update

    for tool in "${tools[@]}"; do
        read -p "$tool installieren? (Y/n): " a
        [[ "$a" =~ ^[Yy]?$ ]] && sudo apt install -y "$tool"
    done

    echo -e "${GREEN}✅ Tools abgeschlossen.${NC}"
    pause
}

# ------------------------------------------------------------
# TILDE – SOURCE BUILD (KORREKT)
# ------------------------------------------------------------

install_tilde() {
    echo -e "${YELLOW}Installiere tilde (Source-Build, Git-Dev)…${NC}"

    if command -v tilde >/dev/null 2>&1; then
        echo -e "${GREEN}✅ tilde ist bereits installiert: $(which tilde)${NC}"
        pause
        return
    fi

    echo "📦 Abhängigkeiten installieren…"
    sudo apt update
    sudo apt install -y \
        git build-essential pkg-config \
        flex gettext \
        libacl1-dev libattr1-dev \
        libgpm-dev \
        libncurses-dev \
        libpcre2-dev \
        libtool-bin \
        libunistring-dev \
        libxcb1-dev libx11-dev \
        clang

    WORKDIR="/tmp/tilde-dev"
    rm -rf "$WORKDIR"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    echo "⬇️ Repositories klonen…"
    for r in makesys transcript t3shared t3window t3widget t3key t3config t3highlight tilde; do
        git clone https://github.com/gphalkes/$r.git
    done

    echo "🛠️ Build aller Komponenten…"
    ./t3shared/doall --skip-non-source --stop-on-error make -C src

    BIN="$WORKDIR/tilde/src/.objects/edit"
    if [[ ! -x "$BIN" ]]; then
        echo -e "${RED}❌ tilde Binary nicht gefunden.${NC}"
        echo "➡️ Build ist vorher fehlgeschlagen – siehe Output."
        pause
        return
    fi

    sudo install -m 0755 "$BIN" /usr/local/bin/tilde

    echo -e "${GREEN}✅ tilde installiert: /usr/local/bin/tilde${NC}"
    pause
}

set_editor_tilde() {
    if ! command -v tilde >/dev/null 2>&1; then
        echo -e "${RED}❌ tilde nicht installiert.${NC}"
        pause
        return
    fi

    grep -q '^export EDITOR=' ~/.bashrc \
        && sed -i 's/^export EDITOR=.*/export EDITOR=tilde/' ~/.bashrc \
        || echo 'export EDITOR=tilde' >> ~/.bashrc

    echo -e "${GREEN}✅ EDITOR=tilde gesetzt (neue Shell nötig).${NC}"
    pause
}

# ------------------------------------------------------------
# DIVERSES
# ------------------------------------------------------------

ssh_keys_loschen() {
    rm -rf ~/.ssh/*
    echo -e "${GREEN}✅ SSH-Schlüssel gelöscht.${NC}"
    pause
}

set_timezone_berlin() {
    sudo timedatectl set-timezone Europe/Berlin
    echo -e "${GREEN}✅ Zeitzone gesetzt.${NC}"
    pause
}

ssh_aktivieren() {
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo -e "${GREEN}✅ SSH aktiviert.${NC}"
    pause
}

schnittstellen_aktivieren() {
    sudo raspi-config nonint do_vnc 0
    sudo raspi-config nonint do_spi 0
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_serial 1
    echo -e "${GREEN}✅ VNC / SPI / I2C / Serial aktiviert.${NC}"
    pause
}

# ------------------------------------------------------------
# DISPLAY ROTATION
# ------------------------------------------------------------

boot_config_path() {
    [[ -f /boot/firmware/config.txt ]] && echo /boot/firmware/config.txt && return
    [[ -f /boot/config.txt ]] && echo /boot/config.txt && return
    echo ""
}

rotate_display_180() {
    CFG=$(boot_config_path)
    [[ -z "$CFG" ]] && echo "❌ config.txt nicht gefunden" && pause && return

    sudo sed -i '/^display_rotate=/d' "$CFG"
    echo "display_rotate=2" | sudo tee -a "$CFG" >/dev/null

    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/40-touch-rotate-180.conf >/dev/null <<'EOF'
Section "InputClass"
    Identifier "Rotate Touchscreen 180"
    MatchIsTouchscreen "on"
    MatchDriver "libinput"
    Option "CalibrationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
EOF

    echo -e "${GREEN}✅ Display + Touch auf 180° gesetzt (Reboot nötig).${NC}"
    read -p "Jetzt neu starten? (y/N): " r
    [[ "$r" =~ ^[Yy]$ ]] && sudo reboot
    pause
}

# ------------------------------------------------------------
# MENÜ
# ------------------------------------------------------------

menu() {
    clear
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade"
    echo "2) Tools installieren"
    echo "3) SSH-Schlüssel löschen"
    echo "4) EDITOR auf tilde setzen"
    echo "5) Zeitzone auf Berlin setzen"
    echo "6) SSH aktivieren"
    echo "8) tilde Editor installieren (Source-Build)"
    echo "10) VNC, SPI, I2C, Serial aktivieren"
    echo "12) Display 180° drehen (dauerhaft)"
    echo "Q) Beenden"
    echo ""
}

while true; do
    menu
    read -p "Option wählen: " c
    case "$c" in
        1) update_system ;;
        2) install_tools ;;
        3) ssh_keys_loschen ;;
        4) set_editor_tilde ;;
        5) set_timezone_berlin ;;
        6) ssh_aktivieren ;;
        8) install_tilde ;;
        10) schnittstellen_aktivieren ;;
        12) rotate_display_180 ;;
        Q|q) exit 0 ;;
        *) echo "❌ Ungültig"; pause ;;
    esac
done
