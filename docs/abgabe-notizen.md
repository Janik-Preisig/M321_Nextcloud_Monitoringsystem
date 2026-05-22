# Abgabe-Notizen

## Projekt

Virtuelle Smart-Home Umgebung mit MQTT, Bash-Sensoren, Java-Sensoren und Grafana.

## Personen

Erstellt von: Fionn Laesser  
Sparing-Partner: Janik Preisig

## Kurze Demo-Erklärung

In der Demo laufen mehrere Bash-Sensoren und mehrere Java-Sensoren. Die Bash-Sensoren senden Zufallswerte auf `bash/r1`, `bash/r2` und `bash/r3`. Die Java-Sensoren senden simulierte Kurvenwerte auf `java/r1`, `java/r2` und `java/r3`. Der Mosquitto-Broker empfängt alle Nachrichten. Grafana ist über das MQTT Datasource Plugin verbunden und zeigt Bash- und Java-Daten in zwei getrennten Timeline Panels an.

Jeder Java-Client subscribed zusätzlich auf `java/commands`. Damit können per MQTT die Befehle `status`, `pause`, `resume` und `stop` getestet werden.

## Wichtige Befehle

Broker und Grafana starten:

```bash
docker compose up -d
```

Alle MQTT-Nachrichten anzeigen:

```bash
mosquitto_sub -h localhost -p 1883 -t '#' -v
```

Bash-Sensoren starten:

```bash
bash bash-sensoren/start-all-sensors.sh
```

Java-Sensoren starten:

```bash
bash java-sensoren/start-java-sensoren.sh
```

Java-Subscriber testen:

```bash
mosquitto_pub -h localhost -p 1883 -t java/commands -m status
mosquitto_pub -h localhost -p 1883 -t java/commands -m pause
mosquitto_pub -h localhost -p 1883 -t java/commands -m resume
mosquitto_pub -h localhost -p 1883 -t java/commands -m stop
```

Grafana öffnen:

```text
http://localhost:3000
```

MQTT URI in Grafana bei Docker Compose:

```text
tcp://mosquitto:1883
```

## Demo-Ablauf

1. Docker Container mit `docker ps` zeigen.
2. MQTT-Test mit `test` Topic zeigen.
3. Bash-Sensoren starten und `bash/#` Nachrichten zeigen.
4. Java-Sensoren starten und `java/#` Nachrichten zeigen.
5. Java-Subscriber mit `status`, `pause`, `resume` und `stop` demonstrieren.
6. Grafana Datasource zeigen.
7. Grafana Dashboard mit Bash-Panel und Java-Panel zeigen.
