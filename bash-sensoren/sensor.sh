#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Nutzung: bash bash-sensoren/sensor.sh <sensorname> <topic> <min> <max>"
  echo "Beispiel: bash bash-sensoren/sensor.sh wohnzimmer-temperatur bash/r1 18 30"
  exit 1
fi

SENSOR_NAME="$1"
TOPIC="$2"
MIN="$3"
MAX="$4"

BROKER_HOST="${BROKER_HOST:-localhost}"
BROKER_PORT="${BROKER_PORT:-1883}"

if ! [[ "$MIN" =~ ^-?[0-9]+$ ]] || ! [[ "$MAX" =~ ^-?[0-9]+$ ]]; then
  echo "Fehler: MIN und MAX müssen ganze Zahlen sein." >&2
  exit 1
fi

if [ "$MIN" -gt "$MAX" ]; then
  echo "Fehler: MIN muss kleiner oder gleich MAX sein." >&2
  exit 1
fi

RANGE=$((MAX - MIN + 1))
PUBLISH_MODE=""

if command -v mosquitto_pub >/dev/null 2>&1; then
  PUBLISH_MODE="local"
elif command -v docker >/dev/null 2>&1 && [ "$(docker inspect -f '{{.State.Running}}' mosquitto 2>/dev/null || true)" = "true" ]; then
  PUBLISH_MODE="docker"
else
  echo "Fehler: mosquitto_pub wurde lokal nicht gefunden und der Docker-Container 'mosquitto' läuft nicht." >&2
  echo "Installiere mosquitto-clients oder starte den Broker mit: docker compose up -d" >&2
  exit 1
fi

publish_value() {
  local value="$1"

  if [ "$PUBLISH_MODE" = "local" ]; then
    mosquitto_pub -h "$BROKER_HOST" -p "$BROKER_PORT" -t "$TOPIC" -m "$value"
  else
    docker exec mosquitto mosquitto_pub -h "$BROKER_HOST" -p "$BROKER_PORT" -t "$TOPIC" -m "$value"
  fi
}

echo "[bash] Sensor startet"
echo "[bash] Sensorname: $SENSOR_NAME"
echo "[bash] Topic: $TOPIC"
echo "[bash] Broker: $BROKER_HOST:$BROKER_PORT"
echo "[bash] Wertebereich: $MIN bis $MAX"
echo "[bash] Publisher: $PUBLISH_MODE"
echo "[bash] Stoppen mit Ctrl + C"

while true; do
  VALUE=$((RANDOM % RANGE + MIN))

  if publish_value "$VALUE"; then
    echo "[bash] Sensorname=$SENSOR_NAME Topic=$TOPIC Broker=$BROKER_HOST:$BROKER_PORT Wert=$VALUE"
  else
    echo "[bash] Fehler: $SENSOR_NAME konnte Wert $VALUE nicht an $TOPIC senden." >&2
    exit 2
  fi

  sleep 1
done
