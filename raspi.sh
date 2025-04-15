#!/bin/bash

set -e

# Farben definieren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear

echo -e "${GREEN}--------------------------------------${NC}"
echo -e "${YELLOW}🛠️  Raspberry Pi Komplett-Installationsskript${NC}"
echo -e "${GREEN}--------------------------------------${NC}"

# Funktionen definieren
update_system() {
    echo "System wird aktualisiert..."
    sudo apt update && sudo apt upgrade -y
    echo -e "${GREEN}✅ System-Update abgeschlossen.${NC}"
    read -p "Weiter mit [Enter]..."
}

install_tools() {
    tools=("git" "tilde" "htop" "curl" "python3-pip")
    for tool in "${tools[@]}"; do
        read -p "$tool installieren? (Y/n): " answer
        case "$answer" in
            [Yy]* | "" ) sudo apt install -y $tool && echo -e "${GREEN}✅ $tool installiert.${NC}" ;;
            [Nn]* ) echo -e "${YELLOW}➡️  $tool übersprungen.${NC}" ;;
            * ) echo -e "${RED}❌ Ungültige Eingabe. $tool wird übersprungen.${NC}" ;;
        esac
    done
    read -p "Weiter mit [Enter]..."
}

ssh_keys_loschen() {
    echo "SSH-Schlüssel werden gelöscht..."
    rm -rf ~/.ssh/*
    echo -e "${GREEN}✅ SSH-Schlüssel gelöscht.${NC}"
    read -p "Weiter mit [Enter]..."
}

set_editor_tilde() {
    if ! grep -q "EDITOR=tilde" ~/.bashrc; then
        echo "export EDITOR=tilde" >> ~/.bashrc
        echo -e "${GREEN}✅ EDITOR=tilde gesetzt.${NC}"
    else
        echo -e "${YELLOW}➡️  EDITOR=tilde ist bereits gesetzt.${NC}"
    fi
    read -p "Weiter mit [Enter]..."
}

set_timezone_berlin() {
    sudo timedatectl set-timezone Europe/Berlin
    echo -e "${GREEN}✅ Zeitzone auf Berlin gesetzt.${NC}"
    read -p "Weiter mit [Enter]..."
}

ssh_aktivieren() {
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo -e "${GREEN}✅ SSH-Dienst aktiviert.${NC}"
    read -p "Weiter mit [Enter]..."
}

install_mhs35_display() {
    echo "📺 Installiere MHS-3.5'' Touch Display..."

    WORKDIR="/tmp/mhs35"
    rm -rf "$WORKDIR"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    echo "🔧 SPI aktivieren..."
    sudo raspi-config nonint do_spi 0

    echo "📦 Abhängigkeiten installieren..."
    sudo apt update
    sudo apt install -y xserver-xorg-input-evdev xinput xinput-calibrator git

    echo "⬇️ Lade Treiber herunter..."
    git clone https://github.com/goodtft/LCD-show.git
    cd LCD-show

    echo "🛠️ Installiere Display-Treiber (Rotation: 0°)..."
    sudo chmod +x LCD35-show
    sudo ./LCD35-show

    echo -e "${GREEN}✅ MHS-3.5'' Display installiert. Gerät startet nun neu...${NC}"
    sleep 3
    sudo reboot
}

root_login_aktivieren() {
    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    echo "root:admin" | sudo chpasswd
    sudo systemctl restart ssh
    echo -e "${GREEN}✅ Root-Login aktiviert (Passwort: admin).${NC}"
    read -p "Weiter mit [Enter]..."
}

schnittstellen_aktivieren() {
    sudo raspi-config nonint do_vnc 0
    sudo raspi-config nonint do_spi 0
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_serial 1
    echo -e "${GREEN}✅ VNC, SPI, I2C, Serial Port aktiviert.${NC}"
    read -p "Weiter mit [Enter]..."
}

install_poe_hat() {
    echo "Installiere POE-HAT Fan HAT + OLED Display..."

    read -p "Benutzername (Standard: admin): " USERNAME
    USERNAME=${USERNAME:-admin}
    USERDIR="/home/$USERNAME"

    if [ ! -d "$USERDIR" ]; then
        echo -e "${RED}❌ Benutzer $USERNAME existiert nicht.${NC}"
        exit 1
    fi

    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-smbus i2c-tools git stress
    sudo pip3 install --break-system-packages smbus2 RPi.GPIO Pillow

    cd "$USERDIR/"
    if [ ! -d "POE-HAT" ]; then
        git clone https://github.com/Lumpi75/raspi.git
        mv raspi/POE-HAT .
        rm -rf raspi
    else
        echo "POE-HAT Verzeichnis vorhanden, update..."
        cd POE-HAT
        git pull
    fi

    sudo tee /etc/systemd/system/poe-hat-c.service > /dev/null <<EOF
[Unit]
Description=POE-FAN-HAT-C Service
After=network.target

[Service]
Restart=always
RestartSec=5
Type=simple
ExecStart=/usr/bin/python3 -u $USERDIR/POE-HAT/python/main.py
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable poe-hat-c.service
    sudo systemctl start poe-hat-c.service

    echo -e "${GREEN}✅ POE-HAT Installation abgeschlossen.${NC}"
    read -p "Weiter mit [Enter]..."
}

# Menü Funktion
display_menu() {
    echo ""
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade"
    echo "2) Tools installieren"
    echo "3) SSH-Schlüssel löschen"
    echo "4) EDITOR auf tilde setzen"
    echo "5) Zeitzone auf Berlin setzen"
    echo "6) SSH aktivieren"
    echo "7) MHS-3.5'' Display installieren"
    echo "9) Root-Login aktivieren"
    echo "10) VNC, SPI, I2C, Serial aktivieren"
    echo "11) POE-HAT installieren"
    echo "Q) Beenden"
    echo ""
}

# Hauptmenü-Schleife
while true; do
    clear
    display_menu
    read -p "Option wählen [1-11, q]: " choice
    case $choice in
        1) update_system ;;
        2) install_tools ;;
        3) ssh_keys_loschen ;;
        4) set_editor_tilde ;;
        5) set_timezone_berlin ;;
        6) ssh_aktivieren ;;
        7) install_mhs35_display ;;
        9) root_login_aktivieren ;;
        10) schnittstellen_aktivieren ;;
        11) install_poe_hat ;;
        Q|q)
            clear
            echo -e "${GREEN}✅ Setup abgeschlossen. Tschüss!${NC}"
            exit 0 ;;
        *) echo -e "${RED}❌ Ungültige Eingabe.${NC}" ;;
    esac
done
