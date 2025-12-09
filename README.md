# Laborumgebung: Datenschutz & Datensicherheit (Docker Edition)

Dieses Repository stellt eine alternative, containerbasierte Lösung für die Laboraufgaben "Datenschutz und Datensicherheit" bereit. Anstatt zwei schwere virtuelle Maschinen (VMs) herunterzuladen und zu konfigurieren, werden zwei Docker-Container (`machine-a-server` und `machine-b-client`) in einem isolierten Netzwerk (`10.10.10.0/24`) gestartet.

Dieser Ansatz ist sehr ressourcenschonend und ermöglicht eine schnelle Einrichtung der Laborumgebung. Die Container sind vorkonfiguriert mit den notwendigen Diensten und Tools, um die Aufgaben durchzuführen. Kali-Linux wird hierbei durch ein leichtgewichtiges Debian-basiertes Image ersetzt, das nur die benötigten Penetration-Testing-Tools enthält.

Der Ansatz ist viel schneller einzurichten und zu betreiben und ebenfalls deutlich einfacher zu erweitern oder anzupassen, als erst zwei ressourcenintensive VMs zu konfigurieren.

## Architektur

- **Container/VM A (Server - `10.10.10.10`):**
  - Simuliert das Zielsystem.
  - Dienste: Apache Webserver (PHP), Tomcat, vsftpd (FTP), MariaDB, PostgreSQL, Snort.
- **Container/VM B (Angreifer/Client - `10.10.10.20`):**
  - Simuliert den Client für Penetration Testing und Netzwerkanalyse.
  - Tools: Nmap, Wireshark in der Terminal-Version (tshark), iptraf-ng, curl, ftp.
- **Netzwerk:**
  - Internes Docker Bridge Netzwerk (`10.10.10.0/24`).
  - Isoliert, aber NAT-Zugriff ins Internet für Updates.

## Installation & Start

> [!IMPORTANT]
> Voraussetzung: [Docker](https://www.docker.com/get-started/) und [Docker Compose](https://docs.docker.com/compose/install/) müssen installiert sein.

1. **Repository klonen** (oder Dateien herunterladen).
2. **Container starten:**

   ```bash
   docker compose up -d --build
   ```
   Dabei startet Docker die beiden Container entsprechend der Definition in der [`docker-compose.yml`](docker-compose.yml) Datei. Die `-d` Flag sorgt dafür, dass die Container im Hintergrund laufen, und `--build` stellt sicher, dass die Images neu gebaut werden.

3. **Warten:** Der erste Start dauert einige Minuten, da Updates und Pakete installiert werden. Der Prozess ist abgeschlossen, wenn beide Container als `started`, `running` oder `healthy` angezeigt werden (je nach Docker-Version).
4. **Verifizieren (optional):** Mit `docker ps` kannst du überprüfen, ob beide Container laufen.
5. **Logs prüfen (optional):**

   ```bash
   docker logs machine-a-server # Hier sollten die Info logs des Start-Skripts zu sehen sein
   docker logs machine-b-client # Hier sollte nichts zu sehen sein
   ```

## Verwendung

Um die Aufgaben zu bearbeiten, nutzen wir interaktive Shells in den Containern.

### Zugriff auf Container/VM A (Server)

Zum Konfigurieren von Snort oder Logs prüfen:

```bash
docker exec -it machine-a-server bash
```

### Zugriff auf Container/VM B (Client/Angreifer)

Zum Ausführen von Scans und Angriffen:

```bash
docker exec -it machine-b-client bash
```

---

## Lösungsweg der Aufgaben (Docker vs. VM)

Da wir keine GUI haben, unterscheidet sich der Workflow minimal von der PDF-Anleitung. Hier sind die Anpassungen für jede Aufgabe:

### Aufgabe 1: Traffic Sniffing mit `iptraf`

- **Original:** GUI Tool öffnen.
- **Docker:** Funktioniert direkt im Terminal.
  1. In Maschine B: `iptraf-ng` starten.
  2. Interface `eth0` auswählen.
  3. In einem zweiten Terminal (ebenfalls in Maschine B eingeloggt) Traffic erzeugen (z.B. `curl 10.10.10.10`).

> [!IMPORTANT]
> Alle logs, die du speichern möchtest, kannst du im Container unter `/captures/<Dateiname>` ablegen. Diese werden automatisch in deinem Projektordner auf dem Host gespeichert, wo du sie später analysieren kannst, ohne im Container zu arbeiten. Dadurch bleiben deine Aufnahmen auch nach dem Stoppen der Container erhalten.

### Aufgabe 2 & 3: Wireshark (via `tshark`)

- **Problem:** Docker hat keinen Monitor für Wireshark GUI.
- **Lösung:** Wir nutzen `tshark` (CLI-Version) zum Aufzeichnen und werten am Host-PC aus.
  1. **Aufnahme starten (in Maschine B):**

      ```bash
      tshark -i eth0 -w /captures/aufgabe2.pcap
      ```

  2. **Aktion durchführen:** (z.B. `ftp 10.10.10.10` oder Webseitenaufruf).
  3. **Aufnahme stoppen:** `killall tshark`
  4. **Auswertung:** Die Datei `aufgabe2.pcap` liegt nun automatisch in deinem Projektordner unter `captures/`. Öffne diese Datei mit Wireshark auf deinem Computer.

> [!IMPORTANT]
> Die Credentials für FTP/SSH findest du weiter unten!

> [!TIP]
> Wenn du auf Maschine B arbeitest und parallel arbeiten möchtest, dann kannst du entweder einfach ein weiteres Terminal öffnen und den `docker exec -it machine-b bash` Befehl erneut ausführen, oder du startest einen Befehl im Hintergrund mit `&` am Ende.

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

## Wichtige Hinweise & Unterschiede

1. **IP-Adressen:**
    - Statt DHCP-IPs nutzen wir statische IPs:
      - Server: `10.10.10.10` (statt IP der VM A)
      - Client: `10.10.10.20` (statt IP der VM B)
2. **Dienste neu starten:**
    - Sollte ein Dienst auf Maschine A nicht laufen, starte das Initial-Skript manuell mit `/start.sh`, starte den Dienst direkt (wie in der [`Dockerfile von Container A`](./machine-a/Dockerfile) Datei gezeigt), oder starte den Container neu mit `docker restart machine-a`.
3. **Credentials:**
    - FTP/SSH User: `student`
    - Passwort: `secret`
    - Datenbank User: `admin` / `secret`

## Aufräumen

Um die Umgebung komplett zu stoppen und zu entfernen:

```bash
docker compose down
```

(Hinweis: Aufgenommene `.pcap` Dateien im Ordner `captures/` bleiben erhalten).
