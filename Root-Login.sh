#!/bin/bash
echo "Root-Login wird aktiviert..."
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "root:admin" | sudo chpasswd
sudo systemctl restart ssh
echo -e "\033[0;32m✅ Root-Login aktiviert.\033[0m"
read -p "Weiter mit [Enter]..."
