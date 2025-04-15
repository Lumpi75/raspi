install_mhs35_display() {
    echo "📺 Installiere MHS-3.5'' Touch Display mit 180° Drehung..."

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

    echo "🛠️ Installiere Display-Treiber (Rotation: 180°)..."
    sudo chmod +x LCD35-show
    sudo ./LCD35-show 180

    echo -e "${GREEN}✅ MHS-3.5'' Display installiert und auf 180° rotiert. Gerät startet nun neu...${NC}"
    sleep 3
    sudo reboot
}
