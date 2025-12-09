# Laborumgebung: Datenschutz & Datensicherheit (Docker Edition)

Dieses Repository stellt eine alternative, containerbasierte Lösung für die Laboraufgaben "Datenschutz und Datensicherheit" (WiSe 25/26) bereit. Anstatt zwei schwere virtuelle Maschinen (VMs) herunterzuladen und zu konfigurieren, werden zwei Docker-Container (`machine-a` und `machine-b`) in einem isolierten Netzwerk gestartet.

## 🏗 Architektur

- **Maschine A (Server - 10.10.10.10):**
  - Simuliert das Zielsystem.
  - Dienste: Apache Webserver (PHP), Tomcat, vsftpd (FTP), MariaDB, PostgreSQL, Snort.
- **Maschine B (Angreifer/Client - 10.10.10.20):**
  - Simuliert den Client für Penetration Testing und Netzwerkanalyse.
  - Tools: Nmap, Wireshark (tshark), iptraf-ng, curl, ftp, telnet.
- **Netzwerk:**
  - Internes Docker Bridge Netzwerk (`10.10.10.0/24`).
  - Isoliert, aber NAT-Zugriff ins Internet für Updates.

## 🚀 Installation & Start

Voraussetzung: Docker und Docker Compose müssen installiert sein.

1. **Repository klonen** (oder Dateien herunterladen).
2. **Container starten:**

   ```bash
   docker compose up -d --build
   ```

3. **Warten:** Der erste Start dauert einige Minuten, da Updates und Pakete installiert werden.

## 💻 Verwendung

Um die Aufgaben zu bearbeiten, nutzen wir interaktive Shells in den Containern.

### Zugriff auf Maschine A (Server)

Zum Konfigurieren von Snort oder Logs prüfen:

```bash
docker exec -it machine-a bash
```

### Zugriff auf Maschine B (Client/Angreifer)

Zum Ausführen von Scans und Angriffen:

```bash
docker exec -it machine-b bash
```

---

## 📝 Lösungsweg der Aufgaben (Docker vs. VM)

Da wir keine GUI haben, unterscheidet sich der Workflow minimal von der PDF-Anleitung. Hier sind die Anpassungen für jede Aufgabe:

### Aufgabe 1: Traffic Sniffing mit `iptraf`

- **Original:** GUI Tool öffnen.
- **Docker:** Funktioniert direkt im Terminal.
  1. In Maschine B: `iptraf-ng` starten.
  2. Interface `eth0` auswählen.
  3. In einem zweiten Terminal (ebenfalls in Maschine B eingeloggt) Traffic erzeugen (z.B. `curl 10.10.10.10`).

### Aufgabe 2 & 3: Wireshark (via `tshark`)

- **Problem:** Docker hat keinen Monitor für Wireshark GUI.
- **Lösung:** Wir nutzen `tshark` (CLI-Version) zum Aufzeichnen und werten am Host-PC aus.
  1. **Aufnahme starten (in Maschine B):**

      ```bash
      # Startet Aufnahme im Hintergrund
      tshark -i eth0 -w /captures/aufgabe2.pcap &
      ```

  2. **Aktion durchführen:** (z.B. `ftp 10.10.10.10` oder Webseitenaufruf).
  3. **Aufnahme stoppen:** `killall tshark`
  4. **Auswertung:** Die Datei `aufgabe2.pcap` liegt nun automatisch in deinem Projektordner unter `captures/`. Öffne diese Datei mit Wireshark auf deinem PC/Mac.

### Aufgabe 5: Portscan mit `nmap`

- In Maschine B einfach das neue Subnetz nutzen:

  ```bash
  nmap -sV 10.10.10.10
  ```

### Aufgabe 6 & 7: Snort (IDS)

- **Konfiguration:** Snort ist auf Maschine A vorinstalliert.
- **Editieren:** Nutze `nano /etc/snort/snort.conf` innerhalb von Maschine A.
- **Starten:**

  ```bash
  snort -A console -q -c /etc/snort/snort.conf -i eth0
  ```

---

## ⚠️ Wichtige Hinweise & Unterschiede

1. **IP-Adressen:**
    - Statt DHCP-IPs nutzen wir statische IPs:
      - Ziel: `10.10.10.10` (statt IP der VM A)
      - Quelle: `10.10.10.20` (statt IP der VM B)
2. **Dienste neu starten:**
    - Sollte ein Dienst auf Maschine A nicht laufen, starte das Initial-Skript manuell: `/start.sh`.
3. **Credentials:**
    - FTP/SSH User: `student`
    - Passwort: `secret`
    - Datenbank User: `admin` / `secret`

## 🧹 Aufräumen

Um die Umgebung komplett zu stoppen und zu entfernen:

```bash
docker compose down
```

(Hinweis: Aufgenommene `.pcap` Dateien im Ordner `captures/` bleiben erhalten).
