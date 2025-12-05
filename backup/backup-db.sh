#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME=${DB_CONTAINER:-bbpm_mysql}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}
BACKUP_DIR=${BACKUP_DIR:-./backup/backups}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME=${1:-"${DB_NAME}_${TIMESTAMP}.sql"}
CONTAINER_BACKUP_PATH="/backups/${FILENAME}"

mkdir -p "$BACKUP_DIR"

if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "Container $CONTAINER_NAME is not running. Start it or adjust DB_CONTAINER."
  exit 1
fi

docker exec "$CONTAINER_NAME" sh -c "mysqldump -u${DB_USER} -p${DB_PASS} ${DB_NAME} > ${CONTAINER_BACKUP_PATH}"

if [ -f "${BACKUP_DIR}/${FILENAME}" ]; then
  echo "Backup stored at ${BACKUP_DIR}/${FILENAME}"
else
  echo "Backup command ran but file not found at ${BACKUP_DIR}/${FILENAME}"
  exit 1
fi
