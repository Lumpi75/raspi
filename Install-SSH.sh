#!/bin/bash
sudo systemctl enable ssh
sudo systemctl start ssh
echo -e "\033[0;32m✅ SSH aktiviert.\033[0m"
read -p "Weiter mit [Enter]..."
