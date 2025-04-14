#!/bin/bash
if ! grep -q "EDITOR=tilde" ~/.bashrc; then
    echo "export EDITOR=tilde" >> ~/.bashrc
    echo -e "\033[0;32m✅ EDITOR=tilde gesetzt.\033[0m"
else
    echo -e "\033[1;33m➡️  EDITOR=tilde bereits gesetzt.\033[0m"
fi
read -p "Weiter mit [Enter]..."
