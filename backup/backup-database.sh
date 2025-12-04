#!/bin/bash

# Script de Backup de Base de Datos - Bug Bounty Project Manager
# Este script realiza un backup solo de la base de datos MySQL

# Configuración
BACKUP_DIR="${1:-.}/backup/backups"
RETENTION_DAYS="${2:-7}"
COMPRESSION_FORMAT="${3:-gzip}"  # gzip o zip

DB_HOST="db"
DB_USER="root"
DB_PASSWORD="root_password"
DB_NAME="bbpm_db"
CONTAINER_NAME="bbpm_mysql"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Crear directorio de backup si no existe
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo -e "${GREEN}[✓]${NC} Directorio de backup creado: $BACKUP_DIR"
fi

# Generar nombre del archivo con timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILENAME="${DB_NAME}_${TIMESTAMP}.sql"
BACKUP_FILEPATH="$BACKUP_DIR/$BACKUP_FILENAME"

# Realizar el dump de la base de datos
echo -e "${CYAN}[*]${NC} Iniciando backup de la base de datos: $DB_NAME"
echo -e "${CYAN}[*]${NC} Timestamp: $TIMESTAMP"

# Ejecutar mysqldump
if docker-compose exec -T db mysqldump \
    -h "$DB_HOST" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    "$DB_NAME" > "$BACKUP_FILEPATH" 2>/dev/null; then
    
    # Obtener tamaño del archivo
    FILE_SIZE=$(du -h "$BACKUP_FILEPATH" | cut -f1)
    
    echo -e "${GREEN}[✓]${NC} Backup completado exitosamente"
    echo -e "${GREEN}    Archivo: $BACKUP_FILENAME${NC}"
    echo -e "${GREEN}    Tamaño: $FILE_SIZE${NC}"
    echo -e "${GREEN}    Ruta: $BACKUP_FILEPATH${NC}"
    
    # Comprimir el archivo si se especifica
    if [ "$COMPRESSION_FORMAT" = "gzip" ]; then
        echo -e "${YELLOW}[*]${NC} Comprimiendo archivo con gzip..."
        
        gzip "$BACKUP_FILEPATH"
        COMPRESSED_FILE="${BACKUP_FILEPATH}.gz"
        COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
        
        echo -e "${GREEN}[✓]${NC} Archivo comprimido"
        echo -e "${GREEN}    Archivo: ${BACKUP_FILENAME}.gz${NC}"
        echo -e "${GREEN}    Tamaño comprimido: $COMPRESSED_SIZE${NC}"
    fi
    
    # Limpiar backups antiguos
    echo -e "${YELLOW}[*]${NC} Limpiando backups antiguos (retención: $RETENTION_DAYS días)..."
    CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y-%m-%d)
    
    OLD_BACKUPS=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -newermt "$CUTOFF_DATE" -prune -o -type f -print | grep -v "^$")
    
    if [ ! -z "$OLD_BACKUPS" ]; then
        while IFS= read -r old_backup; do
            if [ ! -z "$old_backup" ]; then
                rm -f "$old_backup"
                echo -e "${CYAN}    [✓] Eliminado: $(basename "$old_backup")${NC}"
            fi
        done <<< "$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$RETENTION_DAYS)"
        echo -e "${GREEN}[✓]${NC} Backups antiguos eliminados"
    else
        echo -e "${CYAN}[ℹ]${NC} No hay backups antiguos para eliminar"
    fi
    
else
    echo -e "${RED}[✗]${NC} Error durante el backup"
    exit 1
fi

echo -e "${GREEN}[✓]${NC} Proceso de backup completado"
