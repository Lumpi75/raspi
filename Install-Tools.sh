#!/bin/bash
tools=("git" "tilde" "htop" "curl" "python3-pip")
for tool in "${tools[@]}"; do
    read -p "$tool installieren? (Y/n): " answer
    case "$answer" in
        [Yy]* | "" ) sudo apt install -y $tool && echo -e "\033[0;32m✅ $tool installiert.\033[0m" ;;
        [Nn]* ) echo -e "\033[1;33m➡️  $tool übersprungen.\033[0m" ;;
        * ) echo -e "\033[0;31m❌ Ungültige Eingabe. $tool übersprungen.\033[0m" ;;
    esac
done
read -p "Weiter mit [Enter]..."
