#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME=${DB_CONTAINER:-bbpm_mysql}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}
BACKUP_DIR=${BACKUP_DIR:-./backup/backups}
INPUT_PATH=${1:-}

if [ -z "$INPUT_PATH" ]; then
  echo "Usage: $0 <backup_file.sql>"
  exit 1
fi

if [ ! -f "$INPUT_PATH" ]; then
  CANDIDATE="${BACKUP_DIR}/$(basename "$INPUT_PATH")"
  if [ -f "$CANDIDATE" ]; then
    INPUT_PATH="$CANDIDATE"
  else
    echo "Backup file not found: $INPUT_PATH"
    exit 1
  fi
fi

if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "Container $CONTAINER_NAME is not running. Start it or adjust DB_CONTAINER."
  exit 1
fi

FILE_BASENAME=$(basename "$INPUT_PATH")

docker cp "$INPUT_PATH" "${CONTAINER_NAME}:/backups/${FILE_BASENAME}"

docker exec "$CONTAINER_NAME" sh -c "mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} < /backups/${FILE_BASENAME}"

echo "Restore completed from ${INPUT_PATH}"
