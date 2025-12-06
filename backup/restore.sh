#!/bin/bash

# Script de restauración para la base de datos MySQL en Docker
# Uso: ./backup/restore.sh archivo_backup.sql.gz [nombre_contenedor]

set -e

# Verificar argumentos
if [ -z "$1" ]; then
    echo "❌ Error: Debes especificar el archivo de backup"
    echo "Uso: ./backup/restore.sh archivo_backup.sql.gz [nombre_contenedor]"
    echo ""
    echo "Backups disponibles:"
    ls -lh ./backup/backups/ 2>/dev/null || echo "No hay backups disponibles"
    exit 1
fi

# Variables
BACKUP_FILE="$1"
CONTAINER_NAME="${2:-bbpm_mysql}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: El archivo $BACKUP_FILE no existe"
    exit 1
fi

echo "🔄 Iniciando restauración de la base de datos..."
echo "📦 Contenedor: $CONTAINER_NAME"
echo "📂 Archivo de backup: $BACKUP_FILE"

# Preparar el archivo
TEMP_FILE="/tmp/restore_temp.sql"

# Descomprimir si es necesario
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "📦 Descomprimiendo archivo..."
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
else
    cp "$BACKUP_FILE" "$TEMP_FILE"
fi

# Restaurar la base de datos
echo "⏳ Restaurando base de datos..."
docker exec -i "$CONTAINER_NAME" mysql \
    -u root \
    -p"$DB_ROOT_PASSWORD" \
    < "$TEMP_FILE"

# Limpiar archivo temporal
rm "$TEMP_FILE"

echo "✅ Restauración completada exitosamente"
