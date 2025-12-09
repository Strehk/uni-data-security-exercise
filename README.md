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

## Aufgaben

### Aufgabe 1: Traffic Sniffing (Live-Überwachung)
**Lernziel:** Verstehen, wie Netzwerkverkehr in Echtzeit beobachtet werden kann.

1.  Starte auf **Maschine B** das Tool `iptraf-ng`.
2.  Wähle das Interface `eth0` aus (IP Traffic Monitor).
3.  Öffne ein zweites Terminal für **Maschine B** und erzeugen Sie unverschlüsselten HTTP-Traffic zum Server:
    ```bash
    curl http://10.10.10.10
    ```
4.  Beobachten Sie im `iptraf-ng` Fenster die Pakete (Flags, Bytes, TCP-Verbindung).
5.  *Ziel:* Erstellen Sie einen Screenshot oder Log-Auszug der Verbindung.

### Aufgabe 2: HTTP Analyse mit Wireshark/Tshark
**Lernziel:** HTTP-Anfragen im Detail analysieren und unsichere Übertragungen erkennen.

1.  Starte auf **Maschine B** einen Packet-Capture im Hintergrund:
    ```bash
    tshark -i eth0 -w /captures/aufgabe2.pcap &
    ```
2.  Rufe die Webseite von Maschine A auf:
    ```bash
    curl http://10.10.10.10/index.php

    # oder einfach
    curl http://10.10.10.10
    ```
3.  Beende den Capture (wenn der Prozess im Hintergrund läuft: `killall tshark`) und öffne die Datei `captures/aufgabe2.pcap` auf deinem Host-Computer mit Wireshark.
4.  *Ziel:* Filtere nach `http`. Finde das Paket mit dem `GET /index.php` Request und mache einen Screenshot bzw. Log-Auszug.

### Aufgabe 3: FTP - Passwörter im Klartext
**Lernziel:** Demonstrieren, warum FTP unsicher ist und wie einfach Passwörter abgefangen werden können.

1.  Erstelle auf **Maschine B** eine Datei mit sensiblem Inhalt:
    ```bash
    echo "Das ist geheim." > a.txt
    ```
2.  Starte den Capture:
    ```bash
    tshark -i eth0 -w /captures/aufgabe3.pcap &
    ```
3.  Lade die Datei per FTP auf Maschine A hoch (Login: `student`, Passwort: `secret`):
    ```bash
    ftp -n 10.10.10.10 <<END_SCRIPT
    quote USER student
    quote PASS secret
    put a.txt
    quit
    END_SCRIPT
    ```
4.  Beende tshark.
5.  *Ziel:* Öffne das Pcap in Wireshark. Suche nach dem **Passwort** im Klartext (Filter: `ftp`) und dem **Inhalt der Textdatei** (Filter: `ftp-data`). Mache Screenshots bzw. Log-Auszüge.

## Aufgabe 4: HTTPS Kommunikation
**Lernziel:** Den Unterschied zu verschlüsselter Kommunikation verstehen (TLS Handshake).

1.  Starte einen Capture auf **Maschine B**.
2.  Rufe eine verschlüsselte externe Seite auf:
    ```bash
    curl -I https://www.htw-berlin.de
    ```
3.  *Ziel:* Analysiere den Mitschnitt. Du wirst den Inhalt der Webseite *nicht* lesen können. Identifiziere stattdessen den **TLS Handshake** (Client Hello, Server Hello, Certificate Exchange). Mache Screenshots bzw. Log-Auszüge der relevanten Pakete.

## Aufgabe 5: Reconnaissance (Port Scanning)
**Lernziel:** Herausfinden, welche Dienste und Versionen auf einem fremden Server laufen.

1.  Nutze `nmap` auf **Maschine B**, um **Maschine A** zu scannen.
2.  Versuche, offene Ports und die Versionen der Dienste zu ermitteln.
    ```bash
    nmap -sV 10.10.10.10
    ```
    Dabei steht `-sV` für "Service Version Detection".
3.  *Ziel:* Erstelle eine Liste aller offenen Ports und der dort laufenden Software-Versionen (z.B. Apache x.x.x, vsftpd x.x.x).

## Aufgabe 6: Intrusion Detection (Snort Konfiguration)
**Lernziel:** Ein IDS (Intrusion Detection System) konfigurieren, um Angriffe zu erkennen.

>[!IMPORTANT]
Dies ist die einzige Aufgabe, die auf **Maschine A** (Server) stattfindet!

1.  Öffne die Konfiguration: `nano /etc/snort/snort.conf`.
2.  Konfiguriere Snort so, dass Portscans erkannt werden.
    *   Suche den Abschnitt zum **Portscan-Preprocessor** (`sfportscan`).
    *   Aktiviere (auskommentieren entfernen) und konfiguriere ihn, sodass er Scans auf dem Heimnetzwerk überwacht.
    *   Stellen Sie sicher, dass Logs geschrieben werden.
3.  *Ziel:* Dokumentiere die geänderten Zeilen in der `snort.conf`.

## Aufgabe 7: Angriffserkennung (Blue Team)
**Lernziel:** Einen laufenden Angriff (aus Aufgabe 5) im IDS sichtbar machen.

1.  Starte Snort auf **Maschine A** im Konsolen-Modus, um Alarme direkt zu sehen:
    ```bash
    snort -A console -q -c /etc/snort/snort.conf -i eth0
    ```
2.  Wechsel zu **Maschine B** und führe erneut den Portscan aus Aufgabe 5 durch (`nmap -sV 10.10.10.10`).
3.  Beobachte die Ausgabe auf Maschine A.
4.  *Ziel:* Sichere den Log-Output von Snort, der zeigt, dass der Portscan erkannt wurde (z.B. Meldungen wie "TCP Portscan detected").

---

## Tipps und Tricks zum Lösungsweg der Aufgaben (Docker vs. VM)

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

---

## Lizenz
![https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-sa.png](https://mirrors.creativecommons.org/presskit/buttons/88x31/png/by-nc-sa.png)

Dieses Projekt steht unter der CC BY-NC-SA 4.0 Lizenz. Siehe die [LICENSE](LICENSE) Datei für Details.