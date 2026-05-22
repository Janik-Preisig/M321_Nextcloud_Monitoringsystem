#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

JAR_FILE="target/m321-sq3-1.0-SNAPSHOT-jar-with-dependencies.jar"

if [ ! -f "$JAR_FILE" ] || [ -n "$(find pom.xml src -type f -newer "$JAR_FILE" -print -quit)" ]; then
  echo "[java] Baue Java-Sensoren mit: mvn package"
  mvn package
else
  echo "[java] JAR ist aktuell: $JAR_FILE"
fi

echo "[java] Starte JAR: $JAR_FILE"
exec java -jar "$JAR_FILE" "$@"
