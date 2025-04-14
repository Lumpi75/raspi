#!/bin/bash

set -e

clear
echo "🛠️  Starte Raspberry Pi Setup-Installation..."

# Prüfen ob git installiert ist
if ! command -v git &> /dev/null
then
    echo "❌ Fehler: git ist nicht installiert!"
    echo "Bitte zuerst installieren mit: sudo apt install git"
    exit 1
fi

# Prüfen ob unzip installiert ist (für spätere Optionen)
if ! command -v unzip &> /dev/null
then
    echo "❌ Fehler: unzip ist nicht installiert!"
    echo "Bitte zuerst installieren mit: sudo apt install unzip"
    exit 1
fi

# Download-Verzeichnis prüfen
if [ -d "raspi" ]; then
    echo "⚠️  Ordner 'raspi' existiert bereits."
    echo "Lösche alten Ordner..."
    rm -rf raspi
fi

# Repo klonen
echo "📥 Lade Setup-Repository herunter..."
git clone https://github.com/Lumpi75/raspi.git

# In das richtige Verzeichnis wechseln
cd raspi/raspi-setup

# Skripte ausführbar machen
chmod +x *.sh

# Hauptmenü starten
echo "🚀 Starte Installationsmenü..."
./Install-Raspi.sh
