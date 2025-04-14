#!/bin/bash
echo "Schnittstellen werden aktiviert..."
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_serial 1
echo -e "\033[0;32m✅ VNC, SPI, I2C, Serial aktiviert.\033[0m"
read -p "Weiter mit [Enter]..."
