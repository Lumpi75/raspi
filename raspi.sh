#!/bin/bash

# Farben definieren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

clear

echo -e "${GREEN}--------------------------------------${NC}"
echo -e "${YELLOW}🛠️  LUMPIs Raspberry Pi Setup Script - V1${NC}"
echo -e "${GREEN}--------------------------------------${NC}"

# Funktionen
show_menu() {
    echo ""
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade"
    echo "2) Tools installieren"
    echo "3) SSH-Schlüssel löschen"
    echo "4) EDITOR auf tilde setzen"
    echo "5) Zeitzone auf Berlin setzen"
    echo "6) SSH aktivieren"
    echo "7) Neustart"
    echo "9) Root-Login aktivieren"
    echo "10) VNC, SPI, I2C, Serial aktivieren"
    echo "11) POE-HAT installieren"
    echo "Q) Beenden"
    echo ""
}

install_tools() {
    local tools=("git" "tilde" "htop" "curl" "python3-pip")
    for tool in "${tools[@]}"; do
        read -p "$tool installieren? (Y/n): " answer
        case "$answer" in
            [Yy]* | "" ) sudo apt install -y $tool && echo -e "${GREEN}✅ $tool installiert.${NC}" ;;
            [Nn]* ) echo -e "${YELLOW}➡️  $tool übersprungen.${NC}" ;;
            * ) echo -e "${RED}❌ Ungültige Eingabe. $tool übersprungen.${NC}" ;;
        esac
    done
}

activate_root_login() {
    echo "Root-Login aktivieren..."
    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    echo "root:admin" | sudo chpasswd
    sudo systemctl restart ssh
    echo -e "${GREEN}✅ Root-Login aktiviert.${NC}"
}

enable_vnc_spi_i2c_serial() {
    echo "Schnittstellen aktivieren..."
    sudo raspi-config nonint do_vnc 0
    sudo raspi-config nonint do_spi 0
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_serial 1
    echo -e "${GREEN}✅ Alle Schnittstellen aktiviert.${NC}"
}

install_poe_hat() {
    echo ""
    echo "==> POE-HAT Fan HAT + OLED installieren"

    read -p "Benutzername (Standard: admin): " USERNAME
    USERNAME=${USERNAME:-admin}
    USERDIR="/home/$USERNAME"

    if [ ! -d "$USERDIR" ]; then
        echo -e "${RED}❌ Benutzerordner $USERDIR existiert nicht!${NC}"
        exit 1
    fi

    echo "Benutzer: $USERNAME"

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
}

# Hauptmenü
while true; do
    clear
    show_menu
    read -p "Option wählen [1-11, q]: " choice
    case $choice in
        1) sudo apt update && sudo apt upgrade -y && echo -e "${GREEN}✅ System-Update abgeschlossen.${NC}" ;;
        2) install_tools ;;
        3) echo "SSH-Schlüssel löschen..." && rm -rf ~/.ssh/* && echo -e "${GREEN}✅ SSH-Schlüssel gelöscht.${NC}" ;;
        4)
            if ! grep -q "EDITOR=tilde" ~/.bashrc; then
                echo "export EDITOR=tilde" >> ~/.bashrc
                echo -e "${GREEN}✅ EDITOR=tilde gesetzt.${NC}"
            else
                echo -e "${YELLOW}➡️  EDITOR=tilde bereits gesetzt.${NC}"
            fi
            ;;
        5) sudo timedatectl set-timezone Europe/Berlin && echo -e "${GREEN}✅ Zeitzone gesetzt.${NC}" ;;
        6) sudo systemctl enable ssh && sudo systemctl start ssh && echo -e "${GREEN}✅ SSH aktiviert.${NC}" ;;
        7)
            read -p "Bist du sicher, dass du neu starten willst? (Y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ || $confirm == "" ]]; then
                echo "Neustart..."
                sudo reboot
            else
                echo "Neustart abgebrochen."
            fi
            ;;
        9) activate_root_login ;;
        10) enable_vnc_spi_i2c_serial ;;
        11) install_poe_hat ;;
        Q|q)
            clear
            echo -e "${GREEN}✅ Setup abgeschlossen. Tschüss!${NC}"
            exit 0 ;;
        *) echo -e "${RED}❌ Ungültige Eingabe.${NC}" ;;
    esac
done
