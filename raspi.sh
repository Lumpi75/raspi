#!/bin/bash

echo "--------------------------------------"
echo "🛠️  Raspberry Pi Standard Setup Script - V3 (mit Menü und Root-Login)"
echo "--------------------------------------"

# Funktion für Menü
show_menu() {
    echo ""
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade durchführen"
    echo "2) Tools installieren (git, tilde, htop, curl, python3-pip)"
    echo "3) Python-Pakete vorbereiten (aktuell leer)"
    echo "4) EDITOR=tilde als Umgebungsvariable setzen"
    echo "5) Zeitzone auf Europe/Berlin setzen"
    echo "6) SSH aktivieren"
    echo "7) Neustarten"
    echo "8) Skript beenden"
    echo "9) Root-Login aktivieren und Root-Passwort auf 'admin' setzen"
    echo ""
}

install_tools() {
    tools=("git" "tilde" "htop" "curl" "python3-pip")
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
    sudo service ssh restart
    echo "✅ Root-Login aktiviert und Passwort auf 'admin' gesetzt."
}

while true; do
    show_menu
    read -p "Bitte wähle eine Option [1-9]: " choice
    case $choice in
        1)
            sudo apt update && sudo apt upgrade -y
            ;;
        2)
            install_tools
            ;;
        3)
            echo "Python-Setup aktuell leer. Du kannst später Pakete mit 'pip install paketname' installieren."
            ;;
        4)
            if ! grep -q "EDITOR=tilde" ~/.bashrc; then
                echo "export EDITOR=tilde" >> ~/.bashrc
                echo "Umgebungsvariable EDITOR=tilde gesetzt (wird beim nächsten Login aktiv)."
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
        8)
            echo "Setup-Skript beendet. ✅"
            exit 0
            ;;
        9)
            activate_root_login
            ;;
        *)
            echo "Ungültige Eingabe, bitte Option 1-9 wählen."
            ;;
    esac
done
