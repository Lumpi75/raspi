#!/bin/bash
set -euo pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear

echo -e "${GREEN}--------------------------------------${NC}"
echo -e "${YELLOW}🛠️  Raspberry Pi Komplett-Installationsskript${NC}"
echo -e "${GREEN}--------------------------------------${NC}"

pause() { read -p "Weiter mit [Enter]..."; }

# --- Helper: config.txt Pfad finden (Pi OS/Debian kann variieren) ---
boot_config_path() {
  if [[ -f /boot/firmware/config.txt ]]; then
    echo "/boot/firmware/config.txt"
  elif [[ -f /boot/config.txt ]]; then
    echo "/boot/config.txt"
  else
    echo ""
  fi
}

# --- Funktionen ---

update_system() {
  echo "System wird aktualisiert..."
  sudo apt update
  sudo apt upgrade -y
  echo -e "${GREEN}✅ System-Update abgeschlossen.${NC}"
  pause
}

install_tools() {
  # Standard-Tools (ohne tilde)
  local tools=("git" "htop" "curl" "python3-pip")
  sudo apt update

  for tool in "${tools[@]}"; do
    read -p "$tool installieren? (Y/n): " answer
    case "$answer" in
      [Yy]* | "" )
        sudo apt install -y "$tool"
        echo -e "${GREEN}✅ $tool installiert.${NC}"
        ;;
      [Nn]* )
        echo -e "${YELLOW}➡️  $tool übersprungen.${NC}"
        ;;
      * )
        echo -e "${RED}❌ Ungültige Eingabe. $tool wird übersprungen.${NC}"
        ;;
    esac
  done

  pause
}

# Option 8: tilde installieren (wie bisher als separater Schritt)
# Hinweis: Falls das Repo-Skript/URL nicht mehr passt, schlägt dieser Punkt fehl.
install_tilde() {
  echo -e "${YELLOW}Installiere tilde Editor (externes Repository)...${NC}"

  if command -v tilde >/dev/null 2>&1; then
    echo -e "${GREEN}✅ tilde ist bereits installiert.${NC}"
    pause
    return
  fi

  sudo apt update
  sudo apt install -y wget ca-certificates

  echo "➕ Repo-Skript laden..."
  wget -q http://os.ghalkes.nl/sources.list.d/install_repo.sh -O /tmp/install_tilde_repo.sh

  echo "➕ Repo hinzufügen..."
  sudo sh /tmp/install_tilde_repo.sh

  echo "📦 Paketliste aktualisieren..."
  sudo apt update

  echo "⬇️ tilde installieren..."
  sudo apt install -y tilde

  echo -e "${GREEN}✅ tilde erfolgreich installiert.${NC}"
  pause
}

ssh_keys_loschen() {
  echo "SSH-Schlüssel werden gelöscht..."
  rm -rf ~/.ssh/*
  echo -e "${GREEN}✅ SSH-Schlüssel gelöscht.${NC}"
  pause
}

set_editor_tilde() {
  if ! command -v tilde >/dev/null 2>&1; then
    echo -e "${RED}❌ tilde ist nicht installiert.${NC}"
    echo -e "${YELLOW}➡️  Bitte zuerst Menüpunkt 8 „tilde Editor installieren“ ausführen.${NC}"
    pause
    return
  fi

  if ! grep -q '^export EDITOR=' ~/.bashrc 2>/dev/null; then
    echo "export EDITOR=tilde" >> ~/.bashrc
  else
    sed -i 's/^export EDITOR=.*/export EDITOR=tilde/' ~/.bashrc
  fi

  echo -e "${GREEN}✅ EDITOR=tilde gesetzt (wirkt nach neuem Login / neuer Shell).${NC}"
  pause
}

set_timezone_berlin() {
  sudo timedatectl set-timezone Europe/Berlin
  echo -e "${GREEN}✅ Zeitzone auf Berlin gesetzt.${NC}"
  pause
}

ssh_aktivieren() {
  sudo systemctl enable ssh
  sudo systemctl start ssh
  echo -e "${GREEN}✅ SSH-Dienst aktiviert.${NC}"
  pause
}

install_mhs35_display() {
  echo "📺 Installiere MHS-3.5'' Touch Display..."

  local WORKDIR="/tmp/mhs35"
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
  echo -e "${YELLOW}⚠️  Achtung: Root-Login per SSH ist unsicher.${NC}"
  read -p "Root-Login wirklich aktivieren? (y/N): " ok
  case "$ok" in
    [Yy]* ) ;;
    * )
      echo -e "${YELLOW}➡️  Abgebrochen.${NC}"
      pause
      return
      ;;
  esac

  read -s -p "Neues root Passwort eingeben: " ROOTPW
  echo
  read -s -p "Passwort wiederholen: " ROOTPW2
  echo
  if [[ "$ROOTPW" != "$ROOTPW2" ]]; then
    echo -e "${RED}❌ Passwörter stimmen nicht überein.${NC}"
    pause
    return
  fi

  echo "root:$ROOTPW" | sudo chpasswd

  if grep -qE '^\s*#?\s*PermitRootLogin' /etc/ssh/sshd_config; then
    sudo sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  else
    echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config >/dev/null
  fi

  sudo systemctl restart ssh
  echo -e "${GREEN}✅ Root-Login aktiviert.${NC}"
  pause
}

schnittstellen_aktivieren() {
  sudo raspi-config nonint do_vnc 0
  sudo raspi-config nonint do_spi 0
  sudo raspi-config nonint do_i2c 0
  sudo raspi-config nonint do_serial 1
  echo -e "${GREEN}✅ VNC, SPI, I2C, Serial Port aktiviert.${NC}"
  pause
}

install_poe_hat() {
  echo "Installiere POE-HAT Fan HAT + OLED Display..."

  read -p "Benutzername (Standard: admin): " USERNAME
  USERNAME=${USERNAME:-admin}
  local USERDIR="/home/$USERNAME"

  if [[ ! -d "$USERDIR" ]]; then
    echo -e "${RED}❌ Benutzer $USERNAME existiert nicht.${NC}"
    pause
    return
  fi

  sudo apt update
  sudo apt install -y python3 python3-pip python3-smbus i2c-tools git stress
  sudo pip3 install --break-system-packages smbus2 RPi.GPIO Pillow

  cd "$USERDIR/"
  if [[ ! -d "POE-HAT" ]]; then
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
  pause
}

# --- NEU: Display + Touch dauerhaft 180° drehen ---
rotate_display_180() {
  echo -e "${YELLOW}🔁 Setze Display-Rotation dauerhaft auf 180° (Bild + Touch).${NC}"

  local CFG
  CFG="$(boot_config_path)"
  if [[ -z "$CFG" ]]; then
    echo -e "${RED}❌ Konnte config.txt nicht finden (/boot/firmware/config.txt oder /boot/config.txt).${NC}"
    pause
    return
  fi

  echo "➡️  Boot-Konfig: $CFG"

  # 1) Bild drehen: display_rotate=2 setzen (ersetzen oder hinzufügen)
  if sudo grep -qE '^\s*display_rotate\s*=' "$CFG"; then
    sudo sed -i 's/^\s*display_rotate\s*=.*/display_rotate=2/' "$CFG"
  else
    echo "display_rotate=2" | sudo tee -a "$CFG" >/dev/null
  fi

  echo -e "${GREEN}✅ display_rotate=2 gesetzt.${NC}"

  # 2) Touch drehen (X11): Xorg conf anlegen
  sudo mkdir -p /etc/X11/xorg.conf.d

  sudo tee /etc/X11/xorg.conf.d/40-touch-rotate-180.conf >/dev/null <<'EOF'
# Rotate touchscreen input by 180° (Xorg)
# Works with libinput (CalibrationMatrix) and evdev (TransformationMatrix)

Section "InputClass"
    Identifier "Rotate Touchscreen 180 (libinput)"
    MatchIsTouchscreen "on"
    MatchDriver "libinput"
    Option "CalibrationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection

Section "InputClass"
    Identifier "Rotate Touchscreen 180 (evdev)"
    MatchIsTouchscreen "on"
    MatchDriver "evdev"
    Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
EOF

  echo -e "${GREEN}✅ Touch-Rotation (X11) gesetzt: /etc/X11/xorg.conf.d/40-touch-rotate-180.conf${NC}"
  echo -e "${YELLOW}Hinweis:${NC} Touch-Rotation wirkt bei X11. Wenn du nur Wayland nutzt, greift das ggf. nicht."

  echo -e "${GREEN}✅ Fertig. Reboot erforderlich.${NC}"
  read -p "Jetzt neu starten? (y/N): " rb
  case "$rb" in
    [Yy]* ) sudo reboot ;;
    * ) pause ;;
  esac
}

display_menu() {
  echo ""
  echo "Was möchtest du tun?"
  echo "1) System-Update & Upgrade"
  echo "2) Tools installieren (ohne tilde)"
  echo "3) SSH-Schlüssel löschen"
  echo "4) EDITOR auf tilde setzen"
  echo "5) Zeitzone auf Berlin setzen"
  echo "6) SSH aktivieren"
  echo "7) MHS-3.5'' Display installieren"
  echo "8) tilde Editor installieren"
  echo "9) Root-Login aktivieren"
  echo "10) VNC, SPI, I2C, Serial aktivieren"
  echo "11) POE-HAT installieren"
  echo "12) Display 180° drehen (dauerhaft)"
  echo "Q) Beenden"
  echo ""
}

# --- Hauptmenü ---
while true; do
  clear
  display_menu
  read -p "Option wählen [1-12, q]: " choice
  case "$choice" in
    1) update_system ;;
    2) install_tools ;;
    3) ssh_keys_loschen ;;
    4) set_editor_tilde ;;
    5) set_timezone_berlin ;;
    6) ssh_aktivieren ;;
    7) install_mhs35_display ;;
    8) install_tilde ;;
    9) root_login_aktivieren ;;
    10) schnittstellen_aktivieren ;;
    11) install_poe_hat ;;
    12) rotate_display_180 ;;
    Q|q)
      clear
      echo -e "${GREEN}✅ Setup abgeschlossen. Tschüss!${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ Ungültige Eingabe.${NC}"
      pause
      ;;
  esac
done
