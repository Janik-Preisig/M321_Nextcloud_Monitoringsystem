#!/bin/sh
set -eu

# Der Exporter erhält nur die für Statusmetriken erforderlichen Leserechte.
mariadb --protocol=socket -uroot -p"${MARIADB_ROOT_PASSWORD}" <<-EOSQL
	CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY '${MARIADB_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
	GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
	FLUSH PRIVILEGES;
EOSQL
