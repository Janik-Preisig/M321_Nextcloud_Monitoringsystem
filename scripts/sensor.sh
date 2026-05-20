#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: bash scripts/sensor.sh <sensor-name> <topic> <min> <max>"
  echo "Example: bash scripts/sensor.sh wohnzimmer-temp sensor/wohnzimmer/temp 18 30"
  exit 1
fi

SENSOR_NAME="$1"
TOPIC="$2"
MIN="$3"
MAX="$4"

BROKER_HOST="${BROKER_HOST:-localhost}"
BROKER_PORT="${BROKER_PORT:-1883}"

if ! [[ "$MIN" =~ ^-?[0-9]+$ ]] || ! [[ "$MAX" =~ ^-?[0-9]+$ ]]; then
  echo "MIN and MAX must be integers."
  exit 1
fi

if [ "$MIN" -gt "$MAX" ]; then
  echo "MIN must be smaller than or equal to MAX."
  exit 1
fi

RANGE=$((MAX - MIN + 1))

echo "Starting sensor: $SENSOR_NAME"
echo "Topic: $TOPIC"
echo "Broker: $BROKER_HOST:$BROKER_PORT"
echo "Range: $MIN to $MAX"
echo "Stop with Ctrl + C"

while true; do
  VALUE=$((RANDOM % RANGE + MIN))
  mosquitto_pub -h "$BROKER_HOST" -p "$BROKER_PORT" -t "$TOPIC" -m "$VALUE"
  echo "$SENSOR_NAME -> $TOPIC -> $VALUE"
  sleep 1
done
