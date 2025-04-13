#!/bin/bash

echo "--------------------------------------"
echo "🛠️  Raspberry Pi Schnittstellen aktivieren (Mini-Version)"
echo "--------------------------------------"

echo "Aktiviere VNC..."
sudo raspi-config nonint do_vnc 0

echo "Aktiviere SPI..."
sudo raspi-config nonint do_spi 0

echo "Aktiviere I2C..."
sudo raspi-config nonint do_i2c 0

echo "Aktiviere Serial Port (nur Hardware, keine Konsole)..."
sudo raspi-config nonint do_serial 1

echo "✅ Alle gewünschten Schnittstellen wurden erfolgreich aktiviert!"
