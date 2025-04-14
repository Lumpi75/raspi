#!/bin/bash
echo "SSH-Schlüssel werden gelöscht..."
rm -rf ~/.ssh/*
echo -e "\033[0;32m✅ SSH-Schlüssel gelöscht.\033[0m"
read -p "Weiter mit [Enter]..."
