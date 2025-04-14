#!/bin/bash

set -e

clear

echo "--------------------------------------"
echo "🛠️  Raspberry Pi Standard Setup Script - V4 (mit Menü und Root-Login)"
echo "--------------------------------------"

# Funktionen

show_menu() {
    echo ""
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade durchführen"
    echo "2) Tools installieren (git, tilde, htop, curl, python3-pip)"
    echo "3) SSH-Schlüssel löschen"
    echo "4) EDITOR=tilde als Umgebungsvariable setzen"
    echo "5) Zeitzone auf Europe/Berlin setzen"
    echo "6) SSH aktivieren"
    echo "7) Neustarten"
    echo "9) Root-Login aktivieren und Root-Passwort auf 'admin' setzen"
    echo "10) VNC, SPI, I2C, Serial Port aktivieren"
    echo "11) POE-HAT Fan HAT + OLED installieren"
    echo "Q) Skript beenden"
    echo ""
}

install_tools() {
    local tools=("git" "tilde" "htop" "curl" "python3-pip")
    for tool in "${tools[@]}"; do
        read -p "Möchtest du $tool installieren? (Y/n): " answer
        case "$answer" in
            [Yy]* | "" ) sudo apt install -y $tool ;;
            [Nn]* ) echo "$tool wird übersprungen." ;;
            * ) echo "Ungültige Eingabe. $tool wird übersprungen." ;;
        esac
    done
}

activate_root_login() {
    echo "Root-Login via SSH wird aktiviert und Passwort wird gesetzt..."
    sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    echo "root:admin" | sudo chpasswd
    sudo systemctl restart ssh
    echo "✅ Root-Login aktiviert und Passwort auf 'admin' gesetzt."
}

enable_vnc_spi_i2c_serial() {
    echo "Aktiviere VNC, SPI, I2C und Serial Port..."
    sudo raspi-config nonint do_vnc 0
    sudo raspi-config nonint do_spi 0
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_serial 1
    echo "✅ Alle Schnittstellen wurden aktiviert!"
}

install_poe_hat() {
    echo ""
    echo "==> Installation POE-HAT Fan HAT + OLED Display"
    echo ""

    read -p "Bitte gib den Benutzer an (Standard: admin): " USERNAME
    USERNAME=${USERNAME:-admin}
    USERDIR="/home/$USERNAME"

    if [ ! -d "$USERDIR" ]; then
        echo "❌ Benutzerordner $USERDIR existiert nicht! Installation abgebrochen."
        exit 1
    fi

    echo "Benutzer $USERNAME ausgewählt."

    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-smbus i2c-tools git stress
    sudo pip3 install --break-system-packages smbus2 RPi.GPIO Pillow

    cd "$USERDIR/"
    if [ ! -d "POE-HAT" ]; then
        git clone https://github.com/Lumpi75/raspi.git
        mv raspi/POE-HAT .
        rm -rf raspi
    else
        echo "Verzeichnis POE-HAT existiert bereits, führe git pull aus..."
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

    echo "✅ POE-HAT Installation abgeschlossen!"
    echo "ℹ️ Dienst-Status: sudo systemctl status poe-hat-c.service"
}

# Hauptmenü-Schleife
while true; do
    show_menu
    read -p "Bitte wähle eine Option [1-11, q]: " choice
    case $choice in
        1)
            sudo apt update && sudo apt upgrade -y
            ;;
        2)
            install_tools
            ;;
        3)
            echo "Alle SSH-Schlüssel werden gelöscht..."
            rm -rf ~/.ssh/*
            echo "SSH-Schlüssel gelöscht!"
            read -p "Weiter mit [Enter]..."
            ;;
        4)
            if ! grep -q "EDITOR=tilde" ~/.bashrc; then
                echo "export EDITOR=tilde" >> ~/.bashrc
                echo "Umgebungsvariable EDITOR=tilde gesetzt."
            else
                echo "EDITOR=tilde ist bereits in .bashrc gesetzt."
            fi
            ;;
        5)
            sudo timedatectl set-timezone Europe/Berlin
            ;;
        6)
            sudo systemctl enable ssh
            sudo systemctl start ssh
            ;;
        7)
            echo "Neustart wird ausgeführt..."
            sudo reboot
            ;;
        9)
            activate_root_login
            ;;
        10)
            enable_vnc_spi_i2c_serial
            ;;
        11)
            install_poe_hat
            ;;
        Q|q)
            echo "Beende Setup. Tschüss!"
            exit 0
            ;;
        *)
            echo "Ungültige Eingabe, bitte Option 1-11 oder q wählen."
            ;;
    esac

done
