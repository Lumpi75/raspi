#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e
clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo -e "${GREEN}--------------------------------------${NC}"
echo -e "${YELLOW}🛠️  Raspberry Pi Installationsmenü${NC}"
echo -e "${GREEN}--------------------------------------${NC}"

show_menu() {
    echo ""
    echo "Was möchtest du tun?"
    echo "1) System-Update & Upgrade"
    echo "2) Tools installieren"
    echo "3) SSH-Schlüssel löschen"
    echo "4) EDITOR auf tilde setzen"
    echo "5) Zeitzone auf Berlin setzen"
    echo "6) SSH aktivieren"
    echo "9) Root-Login aktivieren"
    echo "10) VNC, SPI, I2C, Serial aktivieren"
    echo "11) POE-HAT installieren"
    echo "Q) Beenden"
    echo ""
}

while true; do
    clear
    show_menu
    read -p "Option wählen [1-11, q]: " choice
    case $choice in
        1) bash "$SCRIPT_DIR/Install-Updates.sh" ;;
        2) bash "$SCRIPT_DIR/Install-Tools.sh" ;;
        3) bash "$SCRIPT_DIR/Delete-SSH-Keys.sh" ;;
        4) bash "$SCRIPT_DIR/Install-Editor.sh" ;;
        5) sudo timedatectl set-timezone Europe/Berlin && echo -e "${GREEN}✅ Zeitzone gesetzt.${NC}" ;;
        6) bash "$SCRIPT_DIR/Install-SSH.sh" ;;
        9) bash "$SCRIPT_DIR/Root-Login.sh" ;;
        10) bash "$SCRIPT_DIR/Install-VNC-SPI-I2C.sh" ;;
        11) bash "$SCRIPT_DIR/Install-POE-Hat.sh" ;;
        Q|q)
            clear
            echo -e "${GREEN}✅ Setup abgeschlossen. Tschüss!${NC}"
            exit 0 ;;
        *) echo -e "${RED}❌ Ungültige Eingabe.${NC}" ;;
    esac
done
