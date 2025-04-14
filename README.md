# 🛠️ Raspberry Pi Setup (by Lumpi75)

Dieses Projekt ermöglicht eine einfache Installation und Konfiguration deines Raspberry Pi Systems über ein übersichtliches Installationsmenü.

## 📥 Installation

Starte das Setup auf deinem Raspberry Pi mit folgenden Befehlen:

```bash
git clone https://github.com/Lumpi75/raspi.git
cd raspi/raspi-setup
chmod +x *.sh
./Install-Raspi.sh
```

## 📜 Funktionen im Menü

- System-Update & Upgrade
- Tools installieren (git, tilde, htop, curl, python3-pip)
- SSH-Schlüssel löschen
- EDITOR auf tilde setzen
- Zeitzone auf Europe/Berlin setzen
- SSH aktivieren
- Root-Login aktivieren
- VNC, SPI, I2C, Serial aktivieren
- POE-HAT Fan HAT installieren

## ℹ️ Hinweise

- Alle Skripte liegen im gleichen Ordner und werden automatisch erkannt.
- Voraussetzung: Internetverbindung und aktuelle Systempakete.

---

© Lumpi75, 2025
