#!/bin/bash
echo "POE-HAT Installation startet..."

read -p "Benutzername (Standard: admin): " USERNAME
USERNAME=${USERNAME:-admin}
USERDIR="/home/$USERNAME"

if [ ! -d "$USERDIR" ]; then
    echo -e "\033[0;31m❌ Benutzer $USERNAME existiert nicht.\033[0m"
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
    echo "POE-HAT Verzeichnis vorhanden, führe update aus..."
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

echo -e "\033[0;32m✅ POE-HAT Installation abgeschlossen.\033[0m"
read -p "Weiter mit [Enter]..."
