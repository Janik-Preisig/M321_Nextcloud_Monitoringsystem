# Nextcloud und Infrastruktur-Monitoring

## Architektur

Alle Dienste verwenden das bereits im Projekt etablierte Compose-Netz
`m321-sensors`. Es gibt weiterhin genau einen Prometheus- und einen
Grafana-Service. Nextcloud veröffentlicht nur den HTTP-Port 8080; MariaDB und
die Exporter sind ausschließlich innerhalb des Docker-Netzes erreichbar.

| Dienst | Aufgabe | Host-Port |
| --- | --- | --- |
| `nextcloud` | Nextcloud mit Apache | `8080` |
| `mariadb` | persistente Nextcloud-Datenbank | keiner |
| `mariadb-exporter` | MariaDB-Metriken | keiner |
| `cadvisor` | Metriken aller Docker-Container | `18080` |
| `node-exporter` | Ressourcen des Docker-Hosts | keiner |
| `prometheus` | bestehende Metriksammlung | `9090` |
| `grafana` | bestehende Visualisierung | `3001` |

Persistente Daten liegen in den benannten Volumes `nextcloud-data`,
`mariadb-data`, `prometheus-data`, `grafana-data`, `mosquitto-data` und
`mosquitto-log`. Ein `docker compose down` löscht diese Daten nicht.

## Start

Die lokale Demo enthält bereits eine von Git ignorierte `.env`. Für eine neue
Arbeitskopie kann die Vorlage verwendet werden:

```bash
cp .env.example .env
```

Vor einem produktiven Einsatz müssen insbesondere alle Passwörter geändert
werden. Danach:

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
```

Die erste Nextcloud-Installation kann einige Minuten benötigen. MariaDB besitzt
einen Healthcheck; Nextcloud und der Exporter starten erst, sobald die Datenbank
bereit ist. Die Admin-Anmeldung wird aus `NEXTCLOUD_ADMIN_USER` und
`NEXTCLOUD_ADMIN_PASSWORD` angelegt.

## Prometheus-Ziele

`prom_conf/prometheus.yaml` ergänzt ausschließlich diese Infrastruktur-Ziele:

- `cadvisor:8080` für Docker- und Nextcloud-Container
- `node-exporter:9100` für CPU, RAM, Dateisysteme und Netzwerk des Hosts
- `mariadb-exporter:9104` für MariaDB

Nextcloud stellt standardmäßig keinen Prometheus-Endpunkt bereit. Statt einer
zusätzlichen Bridge oder einer automatisch installierten Drittanbieter-App
werden Verfügbarkeit, CPU und RAM des Nextcloud-Containers über cAdvisor
überwacht. Dadurch bleibt der geforderte Stack ohne unnötigen Dienst und ohne
Redis. Die Zielzustände sind unter `http://localhost:9090/targets` sichtbar.

Der MariaDB-Benutzer `exporter` wird nur bei der ersten Initialisierung durch
`mariadb/init-exporter.sh` angelegt und besitzt ausschließlich `PROCESS`,
`REPLICATION CLIENT` und `SELECT`. Wird das Exporter-Passwort bei einem bereits
vorhandenen Daten-Volume geändert, muss das Passwort auch manuell in MariaDB
aktualisiert oder das lokale Demo-Volume bewusst neu initialisiert werden.

## Grafana

Grafana provisioniert die vorhandenen MQTT- und Prometheus-Datenquellen sowie
vier zusätzliche Dashboards im Ordner **Smart Home**:

- Docker Container
- Nextcloud
- MariaDB
- Systemressourcen

Dashboard-Dateien werden ergänzt und vorhandene Grafana-Daten im Volume nicht
gelöscht. Zugangsdaten kommen aus `GRAFANA_ADMIN_USER` und
`GRAFANA_ADMIN_PASSWORD`.

## Prüfung und Betrieb

```bash
docker compose ps
curl -fsS http://localhost:8080/status.php
curl -fsS http://localhost:9090/-/ready
curl -fsS http://localhost:18080/healthz
```

Nach Konfigurationsänderungen kann Prometheus ohne Container-Neustart neu laden:

```bash
curl -X POST http://localhost:9090/-/reload
```

Logs für die wichtigsten Dienste:

```bash
docker compose logs --tail=100 nextcloud mariadb mariadb-exporter prometheus
```

Zum Stoppen ohne Datenverlust:

```bash
docker compose down
```

`docker compose down -v` löscht dagegen sämtliche genannten Volumes und darf
nur verwendet werden, wenn ein vollständiger Datenverlust beabsichtigt ist.
