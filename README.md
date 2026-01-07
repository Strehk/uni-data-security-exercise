# Laborumgebung: Datenschutz & Datensicherheit (Docker Edition)

Dieses Repository stellt eine alternative, containerbasierte Lösung für die Laboraufgaben "Datenschutz und Datensicherheit" bereit. Anstatt zwei schwere virtuelle Maschinen (VMs) herunterzuladen und zu konfigurieren, werden zwei Docker-Container (`machine-a-server` und `machine-b-client`) in einem isolierten Netzwerk (`10.10.10.0/24`) gestartet.

Dieser Ansatz ist sehr ressourcenschonend und ermöglicht eine schnelle Einrichtung und Erweiterung der Laborumgebung. Die Container sind vorkonfiguriert mit den notwendigen Diensten und Tools, um die Aufgaben durchzuführen. Kali-Linux wird hierbei durch ein leichtgewichtiges Debian-basiertes Image ersetzt, das nur die benötigten Penetration-Testing-Tools enthält.

## Known Issues

- **ARM Unterstützung:** Diese Docker-Container sind primär für x86_64 (Intel/AMD) Architekturen gebaut. ARM-basierte Systeme (z.B. Apple M1/M2) werden derzeit (noch) nicht unterstützt. Beiträge zur ARM-Unterstützung sind herzlich willkommen. Aktuell scheitert es an der Installation der Dependencies in den Images.

## Architektur

- **Container/VM A (Server - `10.10.10.10`):**
  - Simuliert das Zielsystem.
  - Dienste: Apache Webserver (PHP), Tomcat, vsftpd (FTP), MariaDB, PostgreSQL, Snort.
  - Credentials:
    - SSH/Login: `student` / `secret`
    - Datenbank: `admin` / `secret`
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
> [!NOTE]
> Sollte ein Dienst auf Maschine A nicht laufen, kannst du den Container mit `docker restart machine-a-server` neu starten.

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

## Aufgaben

### Aufgabe 1: Traffic Sniffing (Live-Überwachung)

**Lernziel:** Verstehen, wie Netzwerkverkehr in Echtzeit beobachtet werden kann.

Da wir in einer Docker-Umgebung ohne GUI arbeiten, nutzen wir `iptraf-ng` direkt im Terminal.

1. Starte auf **Maschine B** das Tool `iptraf-ng`:
   ```bash
   docker exec -it machine-b-client bash
   iptraf-ng
   ```
2. Wähle das Interface `eth0` aus (IP Traffic Monitor).
3. Öffne ein **zweites Terminal** auf deinem Host-Computer und verbinde dich erneut mit **Maschine B**, um Traffic zu erzeugen:
   ```bash
   docker exec -it machine-b-client bash
   curl http://10.10.10.10
   ```
4. Beobachte im ersten Terminal (`iptraf-ng`) die Pakete (Flags, Bytes, TCP-Verbindung).
5. _Ziel:_ Erstelle einen Screenshot oder Log-Auszug der Verbindung.

> [!NOTE]
> Die IP `10.10.10.10` ist die statische IP von Maschine A in unserem Docker-Netzwerk).*

### Aufgabe 2: HTTP Analyse mit Wireshark/Tshark

**Lernziel:** HTTP-Anfragen im Detail analysieren und unsichere Übertragungen erkennen.

Da Docker keine GUI für Wireshark bietet, nutzen wir `tshark` (die Terminal-Version) zum Aufzeichnen und werten die Daten anschließend am Host-PC in der Wireshark GUI aus. Dafür muss natürlich Wireshark auf deinem Host installiert sein.

1. Starte auf **Maschine B** einen Packet-Capture im Hintergrund. Wir speichern die Datei in `/captures/`, damit sie automatisch auf deinen Host synchronisiert wird:

   ```bash
   # Starte Capture im Hintergrund (&)
   tshark -i eth0 -w /captures/aufgabe2.pcap &
   ```

2. Rufe die Webseite von Maschine A (`10.10.10.10`) auf:

   ```bash
   curl http://10.10.10.10/index.php
   # oder einfach
   curl http://10.10.10.10
   ```

3. Beende den Capture:
   ```bash
   killall tshark
   ```

4. **Auswertung:** Die Datei `aufgabe2.pcap` liegt nun in deinem lokalen Projektordner unter `captures/`. Öffne diese Datei mit Wireshark auf deinem Host-Computer.
5. _Ziel:_ Filtere nach `http`. Finde das Paket mit dem `GET /index.php` Request und mache einen Screenshot bzw. Log-Auszug.

### Aufgabe 3: FTP - Passwörter im Klartext

**Lernziel:** Demonstrieren, warum FTP unsicher ist und wie einfach Passwörter abgefangen werden können.

1. Erstelle auf **Maschine B** eine Datei mit sensiblem Inhalt:

   ```bash
   echo "Das ist geheim." > a.txt
   ```

2. Starte den Capture im Hintergrund:

   ```bash
   tshark -i eth0 -w /captures/aufgabe3.pcap &
   ```

3. Lade die Datei per FTP auf Maschine A hoch.
   - **User:** `student`
   - **Passwort:** `secret`
   - **Server:** `10.10.10.10`

   ```bash
   ftp ftp://student:secret@10.10.10.10:21
   # Falls nach Login gefragt wird: User `student`, Passwort `secret`
   # in der FTP-Shell:
   put a.txt
   exit
   ```

4. Beende tshark (`killall tshark`) und öffne die Aufzeichnung `captures/aufgabe3.pcap` auf dem Host mit Wireshark.
5. _Ziel:_ Suche nach dem **Passwort** im Klartext (Filter: `ftp`) und dem **Inhalt der Textdatei** (Filter: `ftp-data`). Mache Screenshots bzw. Log-Auszüge.

### Aufgabe 4: HTTPS Kommunikation

**Lernziel:** Den Unterschied zu verschlüsselter Kommunikation verstehen (TLS Handshake).

1. Starte einen Capture auf **Maschine B** (ähnlich wie oben):
   ```bash
   tshark -i eth0 -w /captures/aufgabe4.pcap &
   ```
2. Rufe eine verschlüsselte externe Seite auf:
   ```bash
   curl -I https://www.htw-berlin.de
   ```
3. Beende den Capture (`killall tshark`).
4. _Ziel:_ Analysiere den Mitschnitt auf deinem Host-PC. Du wirst den Inhalt der Webseite _nicht_ lesen können. Identifiziere stattdessen den **TLS Handshake** (Client Hello, Server Hello, Certificate Exchange). Mache Screenshots bzw. Log-Auszüge der relevanten Pakete.

### Aufgabe 5: Reconnaissance (Port Scanning)

**Lernziel:** Herausfinden, welche Dienste und Versionen auf einem fremden Server laufen.

1. Nutze `nmap` auf **Maschine B**, um **Maschine A** (`10.10.10.10`) zu scannen.
2. Versuche, offene Ports und die Versionen der Dienste zu ermitteln:

   ```bash
   nmap -sV 10.10.10.10
   ```
   Dabei steht `-sV` für "Service Version Detection".

3. _Ziel:_ Erstelle eine Liste aller offenen Ports und der dort laufenden Software-Versionen (z.B. Apache x.x.x, vsftpd x.x.x).

### Aufgabe 6: Intrusion Detection (Snort Konfiguration)

**Lernziel:** Ein IDS (Intrusion Detection System) konfigurieren, um Angriffe zu erkennen.

> [!IMPORTANT]
> Dies ist die einzige Aufgabe, die auf **Maschine A** (Server) stattfindet!
> Verbinde dich hierfür mit: `docker exec -it machine-a-server bash`

1. Öffne im Container die Konfiguration mit dem Editor `nano`:
   ```bash
   nano /etc/snort/snort.conf
   ```
2. Konfiguriere Snort so, dass Portscans erkannt werden.
   - Suche den Abschnitt zum **Portscan-Preprocessor** (`sfportscan`).
   - Aktiviere diesen (Kommentierung `#` entfernen) und konfiguriere ihn, sodass er Scans auf dem Heimnetzwerk überwacht.
   - Stelle sicher, dass Logs geschrieben werden.
3. _Ziel:_ Dokumentiere die geänderten Zeilen in der `snort.conf`.

### Aufgabe 7: Angriffserkennung (Blue Team)

**Lernziel:** Einen laufenden Angriff (aus Aufgabe 5) im IDS sichtbar machen.

1. Bleibe auf **Maschine A** und starte Snort im Konsolen-Modus, um Alarme direkt zu sehen:

   ```bash
   snort -A console -q -c /etc/snort/snort.conf -i eth0
   ```

2. Wechsel in einem anderen Terminal zu **Maschine B** und führe erneut den Portscan aus Aufgabe 5 durch:
   ```bash
   nmap -sV 10.10.10.10
   ```

3. Beobachte die Ausgabe im Terminal von Maschine A.
4. _Ziel:_ Sichere den Log-Output von Snort, der zeigt, dass der Portscan erkannt wurde (z.B. Meldungen wie "TCP Portscan detected").

---

## Aufräumen

Um die Umgebung komplett zu stoppen und zu entfernen:

```bash
docker compose down
```

(Hinweis: Aufgenommene `.pcap` Dateien im Ordner `captures/` bleiben erhalten).

---

## Lizenz

![https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-sa.png](https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-sa.png)

Dieses Projekt steht unter der CC BY-NC-SA 4.0 Lizenz. Siehe die [LICENSE](LICENSE) Datei für Details.

