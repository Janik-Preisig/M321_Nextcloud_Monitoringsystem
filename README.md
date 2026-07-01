# Modul 321 - MQTT Smart Home Monitoring mit Nextcloud

Das bestehende MQTT-Projekt enthält zusätzlich einen persistenten Nextcloud-
Webserver mit MariaDB. Prometheus und Grafana überwachen dabei Nextcloud,
MariaDB, alle Docker-Container und den Docker-Host. Details, Betrieb und
Fehlersuche stehen in [docs/nextcloud-monitoring.md](docs/nextcloud-monitoring.md).

## Personen

Erstellt von: Fionn Laesser  
Sparing-Partner: Janik Preisig

## Projektidee

Dieses Projekt zeigt ein lauffähiges Smart-Home-Monitoring mit MQTT. Mehrere Bash-Sensoren und mehrere Java-Sensoren senden Messwerte an einen Mosquitto MQTT-Broker. Grafana ist über das MQTT Datasource Plugin mit dem Broker verbunden und zeigt die Daten in zwei getrennten Panels an.

Die Java-Sensoren haben zusätzlich eine Subscriber-Funktion. Über das Topic `java/commands` können die Befehle `status`, `pause`, `resume` und `stop` an alle Java-Sensoren gesendet werden.

## Systemübersicht

```text
Bash-Sensoren
  bash/r1
  bash/r2
  bash/r3
        \
         \-> Mosquitto MQTT-Broker -> Grafana MQTT Datasource -> Dashboard
         /
Java-Sensoren
  java/r1
  java/r2
  java/r3

Java-Subscriber:
  java/commands -> status, pause, resume, stop
```

## Repository-Struktur

```text
.
+-- README.md
+-- docker-compose.yml
+-- mosquitto/
|   +-- config/
|       +-- mosquitto.conf
+-- bash-sensoren/
|   +-- sensor.sh
|   +-- wohnzimmer-temperatur.sh
|   +-- bad-luftfeuchtigkeit.sh
|   +-- flur-helligkeit.sh
|   +-- start-all-sensors.sh
+-- java-sensoren/
|   +-- pom.xml
|   +-- start-java-sensoren.sh
|   +-- src/
+-- screenshots/
|   +-- README.md
+-- docs/
    +-- abgabe-notizen.md
```

## Voraussetzungen

Benötigt werden:

- Docker und Docker Compose
- Bash
- Java 21
- Maven
- optional lokal installierte Mosquitto-Clients (`mosquitto_pub`, `mosquitto_sub`)

Prüfen:

```bash
docker --version
docker compose version
java --version
mvn --version
```

Falls `mosquitto_pub` und `mosquitto_sub` lokal fehlen, können sie auf Debian/Ubuntu so installiert werden:

```bash
sudo apt update
sudo apt install -y mosquitto-clients
```

Die Bash-Sensoren können alternativ `docker exec mosquitto mosquitto_pub` verwenden, wenn der Mosquitto-Container läuft.

## MQTT und Grafana starten

Im Projektordner:

```bash
docker compose up -d
```

Beim ersten Start werden außerdem Nextcloud, MariaDB und die Monitoring-
Exporter initialisiert. Die mitgelieferte `.env` ist sofort für eine lokale
Demo nutzbar. Vor einem produktiven Einsatz müssen alle `change-me-*`-Werte
ersetzt werden; `.env.example` dokumentiert sämtliche Variablen.

Prüfen:

```bash
docker ps
docker logs mosquitto
docker logs grafana
```

Der MQTT-Broker stellt diese Ports bereit:

- `1883`: normales MQTT
- `9001`: MQTT über WebSockets

Grafana ist danach im Browser erreichbar:

```text
http://localhost:3001
```

Nextcloud ist unter `http://localhost:8080`, Prometheus unter
`http://localhost:9090` und cAdvisor unter `http://localhost:18080` erreichbar.

Login:

```text
Benutzername: admin
Passwort: admin
```

Das Docker Compose Setup installiert beim Start von Grafana das Plugin `grafana-mqtt-datasource`.

## Mosquitto-Konfiguration

Die Datei `mosquitto/config/mosquitto.conf` aktiviert zwei Listener:

```text
listener 1883 0.0.0.0
protocol mqtt
allow_anonymous true

listener 9001 0.0.0.0
protocol websockets
allow_anonymous true
```

Für die lokale Demo ist anonyme Verbindung erlaubt. Das ist für den Unterricht einfach, wäre aber in einem echten Produktivsystem nicht sicher genug.

## MQTT-Broker testen

Terminal 1:

```bash
mosquitto_sub -h localhost -p 1883 -t test -v
```

Terminal 2:

```bash
mosquitto_pub -h localhost -p 1883 -t test -m "hello mqtt"
```

Im ersten Terminal muss diese Nachricht sichtbar werden:

```text
test hello mqtt
```

Wenn `mosquitto_sub` lokal nicht installiert ist, kann der Test auch im Container ausgeführt werden:

```bash
docker exec -it mosquitto mosquitto_sub -h localhost -p 1883 -t test -v
docker exec mosquitto mosquitto_pub -h localhost -p 1883 -t test -m "hello mqtt"
```

## Bash-Sensoren

Die Bash-Sensoren senden Zufallswerte auf drei unterschiedliche Topics:

| Sensor | Topic | Werte |
| --- | --- | --- |
| `wohnzimmer-temperatur` | `bash/r1` | 18 bis 30 |
| `bad-luftfeuchtigkeit` | `bash/r2` | 30 bis 80 |
| `flur-helligkeit` | `bash/r3` | 0 bis 100 |

Alle Bash-Sensoren starten:

```bash
bash bash-sensoren/start-all-sensors.sh
```

Einzelne Sensoren starten:

```bash
bash bash-sensoren/wohnzimmer-temperatur.sh
bash bash-sensoren/bad-luftfeuchtigkeit.sh
bash bash-sensoren/flur-helligkeit.sh
```

Alle Bash-Nachrichten anzeigen:

```bash
mosquitto_sub -h localhost -p 1883 -t 'bash/#' -v
```

Die Terminalausgabe der Sensoren zeigt jeweils Sensorname, Topic, Broker und Wert, zum Beispiel:

```text
[bash] Sensorname=wohnzimmer-temperatur Topic=bash/r1 Broker=localhost:1883 Wert=24
```

`start-all-sensors.sh` startet alle drei Sensoren im Hintergrund und stoppt sie sauber mit `Ctrl + C`.

## Java-Sensoren

Die Java-Anwendung startet drei virtuelle MQTT-Clients. Jeder Client published auf ein eigenes Topic und subscribed zusätzlich auf `java/commands`.

| Sensor | Publish-Topic | Subscribe-Topic |
| --- | --- | --- |
| `java-wohnzimmer-temperatur` | `java/r1` | `java/commands` |
| `java-küche-energie` | `java/r2` | `java/commands` |
| `java-keller-luftqualität` | `java/r3` | `java/commands` |

Java-Sensoren starten:

```bash
bash java-sensoren/start-java-sensoren.sh
```

Das Startskript führt zuerst `mvn package` aus, wenn das JAR fehlt oder der Quellcode neuer ist als das JAR. Danach startet es:

```bash
java -jar target/m321-sq3-1.0-SNAPSHOT-jar-with-dependencies.jar
```

Optional kann ein anderer Broker übergeben werden:

```bash
bash java-sensoren/start-java-sensoren.sh tcp://localhost:1883
```

Alle Java-Nachrichten anzeigen:

```bash
mosquitto_sub -h localhost -p 1883 -t 'java/#' -v
```

Die Terminalausgabe zeigt die Topics klar sichtbar, zum Beispiel:

```text
[java] Sensorname=java-wohnzimmer-temperatur Topic=java/r1 Broker=tcp://localhost:1883 Wert=21.00
```

## Java-Subscriber testen

Alle Java-Sensoren subscribed auf:

```text
java/commands
```

Befehle senden:

```bash
mosquitto_pub -h localhost -p 1883 -t java/commands -m status
mosquitto_pub -h localhost -p 1883 -t java/commands -m pause
mosquitto_pub -h localhost -p 1883 -t java/commands -m resume
mosquitto_pub -h localhost -p 1883 -t java/commands -m stop
```

Erwartetes Verhalten:

| Befehl | Wirkung |
| --- | --- |
| `status` | Java-Terminal zeigt, ob Publishing aktiv ist. |
| `pause` | Java-Sensoren bleiben verbunden, senden aber keine neuen Werte. |
| `resume` | Java-Sensoren senden wieder Werte. |
| `stop` | Java-Sensoren beenden sich sauber. |

Beispielausgabe:

```text
[java] Sensorname=java-wohnzimmer-temperatur SubscribeTopic=java/commands Befehl=pause Aktion=Publishing pausiert
```

## Grafana Datasource

Grafana läuft im Docker Compose Setup auf:

```text
http://localhost:3000
```

Datasource einrichten:

```text
Connections
Data sources
Add new data source
MQTT auswählen
```

Wenn Grafana aus diesem Docker Compose Setup verwendet wird:

```text
URI: tcp://mosquitto:1883
```

Wenn Grafana lokal auf dem Host installiert ist:

```text
URI: tcp://localhost:1883
```

Falls die Datasource eine WebSocket-URL verlangt, kann der WebSocket-Listener verwendet werden:

```text
ws://localhost:9001
```

Danach `Save & test` ausführen. Die Datasource muss eine erfolgreiche Verbindung melden.

## Grafana Dashboard

Dashboard erstellen:

```text
Dashboards
New dashboard
Add visualization
Datasource: MQTT
```

Panel 1 für Bash-Daten:

```text
Panel title: Bash Sensoren
Panel type: Time series / Timeline
Datasource: MQTT
Topics:
  bash/r1
  bash/r2
  bash/r3
```

Panel 2 für Java-Daten:

```text
Panel title: Java Sensoren
Panel type: Time series / Timeline
Datasource: MQTT
Topics:
  java/r1
  java/r2
  java/r3
```

Das Dashboard muss am Ende zwei getrennte Panels zeigen: ein Panel für Bash-Daten und ein zweites Panel für Java-Daten.

## Demo-Ablauf

1. Docker starten: `docker compose up -d`
2. Container zeigen: `docker ps`
3. MQTT-Test mit `test` Topic zeigen.
4. MQTT-Monitor starten: `mosquitto_sub -h localhost -p 1883 -t '#' -v`
5. Bash-Sensoren starten: `bash bash-sensoren/start-all-sensors.sh`
6. Java-Sensoren starten: `bash java-sensoren/start-java-sensoren.sh`
7. Java-Subscriber mit `status`, `pause`, `resume` und `stop` testen.
8. Grafana Datasource zeigen.
9. Grafana Dashboard mit Bash-Panel und Java-Panel zeigen.

## Screenshots für die Abgabe

Die Abgabe-Screenshots liegen im Ordner `screenshots/`. Eine lesbare Übersicht mit direkt eingebetteten Bildern steht in [screenshots/README.md](screenshots/README.md).

| Datei | Was sichtbar sein muss |
| --- | --- |
| `docker-ps.png` | `docker ps` mit laufendem Mosquitto-Container und sichtbaren MQTT-Ports `1883` und `9001`. |
| `mqtt-test.png` | Ein Terminal mit `mosquitto_sub` und ein erfolgreicher Publish/Subscribe-Test, zum Beispiel `test hello mqtt`. |
| `bash-sensor-terminal.png` | `start-all-sensors.sh` läuft; die Ausgaben zeigen `bash/r1`, `bash/r2`, `bash/r3`, Sensorname, Broker und Wert. |
| `java-sensor-terminal.png` | Java-Sensoren laufen; die Ausgaben zeigen `java/r1`, `java/r2`, `java/r3`, Broker und Wert. |
| `java-subscriber-command.png` | Ein Command auf `java/commands` wurde gesendet; im Java-Terminal ist die Reaktion auf `status`, `pause`, `resume` oder `stop` sichtbar. |
| `grafana-datasource.png` | Grafana MQTT Datasource mit URI `tcp://localhost:1883`. |
| `grafana-panel-bash-settings.png` | Die Panel-Einstellungen für das Bash-Panel; sichtbar sind Paneltitel `Bash Sensoren`, Datasource `MQTT` und die Topics `bash/r1`, `bash/r2`, `bash/r3`. |
| `grafana-panel-java-settings.png` | Die Panel-Einstellungen für das Java-Panel; sichtbar sind Paneltitel `Java Sensoren`, Datasource `MQTT` und die Topics `java/r1`, `java/r2`, `java/r3`. |
| `grafana-dashboard-bash-java.png` | Das fertige Dashboard mit zwei Panels: Bash-Daten im ersten Panel und Java-Daten im zweiten Panel. |

## Abgabe-Checkliste

- Docker Compose startet Mosquitto und Grafana.
- Mosquitto ist über Port `1883` und WebSockets über Port `9001` erreichbar.
- Grafana ist über Port `3000` erreichbar.
- Das Grafana MQTT Datasource Plugin ist installiert.
- Bash-Sensoren senden auf `bash/r1`, `bash/r2` und `bash/r3`.
- Java-Sensoren senden auf `java/r1`, `java/r2` und `java/r3`.
- Java-Sensoren subscribed auf `java/commands`.
- Die Befehle `status`, `pause`, `resume` und `stop` funktionieren.
- Grafana zeigt Bash-Daten in einem eigenen Timeline Panel.
- Grafana zeigt Java-Daten in einem zweiten Timeline Panel.
- Alle geforderten Screenshots liegen mit exakt korrekten Dateinamen in `screenshots/`.
- Die Dokumentation ist als GitHub Repository oder als PDF abgabebereit.
