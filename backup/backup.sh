#!/bin/bash

# Script de backup para la base de datos MySQL en Docker
# Uso: ./backup/backup.sh [nombre_contenedor]

set -e

# Cargar variables de entorno desde .env
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Variables
CONTAINER_NAME="${1:-bbpm_mysql}"
DB_NAME="${DB_NAME:-bbpm_db}"
DB_USER="${DB_USER:-bbpm_user}"
DB_PASS="${DB_PASS:-bbpm_password}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"
BACKUP_DIR="./backup/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/bbpm_db_${TIMESTAMP}.sql"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando backup de la base de datos..."
echo "📦 Contenedor: $CONTAINER_NAME"
echo "💾 Base de datos: $DB_NAME"
echo "📂 Ubicación de backup: $BACKUP_FILE"
echo ""

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Error: El contenedor '$CONTAINER_NAME' no está en ejecución"
    echo "💡 Inicia los contenedores con: docker-compose up -d"
    exit 1
fi

# Realizar backup usando mysqldump
docker exec "$CONTAINER_NAME" mysqldump \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    --all-databases \
    --single-transaction \
    --quick \
    --lock-tables=false \
    > "$BACKUP_FILE"

# Comprimir el archivo de backup
gzip "$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Obtener tamaño del backup
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup completado exitosamente"
echo "📦 Tamaño del archivo: $SIZE"
echo "🔗 Ubicación: $BACKUP_FILE"

# Mostrar los últimos 5 backups
echo ""
echo "📋 Últimos 5 backups disponibles:"
ls -lh "$BACKUP_DIR" | tail -6 | head -5
