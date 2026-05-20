# Abgabe-Notizen

## Projekt

Virtuelle Smart-Home Umgebung mit MQTT, Bash-Sensoren und Grafana.

## Personen

Erstellt von: Fionn Lässer  
Sparing-Partner: Janik Preisig

## Kurze Demo-Erklärung

In der Demo laufen mehrere Bash-Sensoren. Jeder Sensor sendet jede Sekunde eine Zufallszahl an ein eigenes MQTT-Topic. Der Mosquitto-Broker empfängt diese Nachrichten. Grafana ist über das MQTT-Plugin mit dem Broker verbunden und zeigt die Werte live als Kurve an.

## Wichtige Befehle

Broker starten:

```bash
docker compose up -d
```
Alle MQTT-Nachrichten anzeigen:

```bash
mosquitto_sub -h localhost -p 1883 -t 'sensor/#' -v
```

Alle Sensoren starten:

```bash
bash scripts/start-all-sensors.sh
```


Grafana öffnen:

```text
http://localhost:3000
```

MQTT URI in Grafana:

```text
tcp://localhost:1883
```

## Demo-Ablauf

1. Docker Container zeigen mit `docker ps`
2. Sensoren starten
3. MQTT-Nachrichten mit `mosquitto_sub` zeigen
4. Grafana Datasource zeigen
5. Grafana Dashboard mit Live-Kurve zeigen
