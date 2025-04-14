#!/bin/bash
echo "System wird aktualisiert..."
sudo apt update && sudo apt upgrade -y
echo -e "\033[0;32m✅ System-Update abgeschlossen.\033[0m"
read -p "Weiter mit [Enter]..."
