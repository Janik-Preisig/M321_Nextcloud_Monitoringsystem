#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/sensor.sh" "bad-luftfeuchtigkeit" "bash/r2" 30 80
