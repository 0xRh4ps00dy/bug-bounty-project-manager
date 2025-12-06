#!/bin/bash

# Script de backup automático con rotación
# Este script realiza backups diarios y mantiene una política de retención

set -e

# Variables de configuración
CONTAINER_NAME="${1:-bbpm_mysql}"
BACKUP_DIR="./backup/backups"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"
RETENTION_DAYS=7
RETENTION_WEEKS=4
RETENTION_MONTHS=12

# Crear directorio si no existe
mkdir -p "$BACKUP_DIR"

# Obtener fecha
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATE_ONLY=$(date +"%Y%m%d")
BACKUP_FILE="$BACKUP_DIR/bbpm_db_${TIMESTAMP}.sql"

echo "==================================================="
echo "🔄 BACKUP AUTOMÁTICO DE BASE DE DATOS"
echo "==================================================="
echo "📅 Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
echo "📦 Contenedor: $CONTAINER_NAME"
echo "💾 Base de datos: bbpm_db"
echo "📂 Ubicación: $BACKUP_FILE.gz"
echo ""

# Realizar backup
echo "⏳ Realizando backup..."
docker exec "$CONTAINER_NAME" mysqldump \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    --all-databases \
    --single-transaction \
    --quick \
    --lock-tables=false \
    > "$BACKUP_FILE"

# Comprimir
gzip "$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Obtener tamaño
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup completado"
echo "📦 Tamaño: $SIZE"
echo ""

# Política de rotación
echo "🧹 Aplicando política de retención..."

# Eliminar backups más antiguos de RETENTION_DAYS
echo "Eliminando backups más antiguos de $RETENTION_DAYS días..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -delete

# Mostrar estadísticas
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)

echo ""
echo "==================================================="
echo "📊 ESTADÍSTICAS DE BACKUPS"
echo "==================================================="
echo "📈 Total de backups: $BACKUP_COUNT"
echo "💾 Tamaño total: $TOTAL_SIZE"
echo "🗓️ Retención: $RETENTION_DAYS días"
echo ""
echo "📋 Últimos 5 backups:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -5 | awk '{print "   " $9, "(" $5 ")"}'
echo ""
echo "✅ Proceso completado exitosamente"
echo "==================================================="

# Log en archivo
LOG_FILE="$BACKUP_DIR/backup.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completado - Archivo: $BACKUP_FILE - Tamaño: $SIZE" >> "$LOG_FILE"
