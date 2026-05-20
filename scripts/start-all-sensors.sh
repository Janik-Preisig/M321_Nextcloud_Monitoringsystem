#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Starting all sensors..."
echo "Stop all sensors with Ctrl + C"

bash "$SCRIPT_DIR/sensor.sh" "sensor1-temperature" "sensor/sensor1" 18 30 &
PID1=$!

bash "$SCRIPT_DIR/sensor.sh" "sensor2-humidity" "sensor/sensor2" 30 80 &
PID2=$!

bash "$SCRIPT_DIR/sensor.sh" "sensor3-light" "sensor/sensor3" 0 100 &
PID3=$!

cleanup() {
  echo
  echo "Stopping sensors..."
  kill "$PID1" "$PID2" "$PID3" 2>/dev/null || true
  pkill -P "$PID1" 2>/dev/null || true
  pkill -P "$PID2" 2>/dev/null || true
  pkill -P "$PID3" 2>/dev/null || true
  exit 0
}

trap cleanup INT TERM

wait
