#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIDS=()

cleanup() {
  trap - INT TERM EXIT
  echo
  echo "[bash] Stoppe alle Bash-Sensoren..."

  if [ "${#PIDS[@]}" -gt 0 ]; then
    kill "${PIDS[@]}" 2>/dev/null || true
    wait "${PIDS[@]}" 2>/dev/null || true
  fi

  echo "[bash] Bash-Sensoren gestoppt."
}

handle_signal() {
  cleanup
  exit 0
}

start_sensor() {
  local script_name="$1"
  bash "$SCRIPT_DIR/$script_name" &
  local pid=$!
  PIDS+=("$pid")
  echo "[bash] Gestartet: $script_name PID=$pid"
}

trap handle_signal INT TERM
trap cleanup EXIT

echo "[bash] Starte alle Bash-Sensoren..."
echo "[bash] Topics: bash/r1, bash/r2, bash/r3"
echo "[bash] Stoppen mit Ctrl + C"

start_sensor "wohnzimmer-temperatur.sh"
start_sensor "bad-luftfeuchtigkeit.sh"
start_sensor "flur-helligkeit.sh"

wait "${PIDS[@]}"
