#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/sensor.sh" "wohnzimmer-temperatur" "bash/r1" 18 30
