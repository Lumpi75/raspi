#!/bin/bash

set -e

echo "📺 MHS-3.5 Touch Display Installer für Raspberry Pi"

# 1. SPI aktivieren
echo "🔧 SPI aktivieren..."
sudo raspi-config nonint do_spi 0

# 2. Abhängigkeiten installieren
echo "📦 Abhängigkeiten installieren..."
sudo apt update
sudo apt install -y xserver-xorg-input-evdev xinput xinput-calibrator git

# 3. Verzeichnisse
WORKDIR="/tmp/mhs35"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 4. Treiber von GitHub klonen (WaveShare MHS35 kompatibel)
echo "⬇️ Treiber herunterladen..."
git clone https://github.com/goodtft/LCD-show.git
cd LCD-show

# 5. Display installieren (rot=0°)
echo "🛠️ Displaytreiber installieren..."
sudo chmod +x LCD35-show
sudo ./LCD35-show

# Das Skript rebootet automatisch!
