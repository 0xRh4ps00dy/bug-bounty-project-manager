#!/bin/bash

# Script de Restauración de Base de Datos - Bug Bounty Project Manager
# Este script restaura un backup de la base de datos MySQL

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración
DB_HOST="${2:-db}"
DB_USER="${3:-root}"
DB_PASSWORD="${4:-root_password}"
DB_NAME="${5:-bbpm_db}"
FORCE="${6:-false}"

BACKUP_FILE="$1"

# Mostrar uso
if [ -z "$BACKUP_FILE" ]; then
    echo -e "${RED}[✗]${NC} Uso: $0 <archivo_backup> [host] [usuario] [contraseña] [base_datos] [force]"
    echo -e "  Ejemplo: $0 ./backup/backups/bbpm_db_2024-01-15_10-30-45.sql.gz"
    exit 1
fi

# Validar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}[✗]${NC} El archivo de backup no existe: $BACKUP_FILE"
    exit 1
fi

FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo -e "${CYAN}[*]${NC} Preparando restauración de backup"
echo -e "    Archivo: $(basename "$BACKUP_FILE")"
echo -e "    Tamaño: $FILE_SIZE"
echo -e "    Base de datos: $DB_NAME"

# Confirmar si es necesario
if [ "$FORCE" != "force" ] && [ "$FORCE" != "true" ]; then
    echo -n -e "\n${YELLOW}[!]${NC} ¿Deseas continuar con la restauración? (Esto sobrescribirá los datos actuales) [s/N]: "
    read -r response
    if [ "$response" != "s" ] && [ "$response" != "S" ]; then
        echo -e "${YELLOW}[✗]${NC} Restauración cancelada"
        exit 0
    fi
fi

# Descomprimir si es necesario
SQL_FILE="$BACKUP_FILE"
TEMP_FILE=""

if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo -e "${YELLOW}[*]${NC} Descomprimiendo archivo..."
    
    TEMP_FILE="/tmp/bbpm_restore_$RANDOM.sql"
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
    SQL_FILE="$TEMP_FILE"
    
    echo -e "${GREEN}[✓]${NC} Archivo descomprimido"
fi

# Restaurar la base de datos
echo -e "${YELLOW}[*]${NC} Restaurando base de datos..."

if cat "$SQL_FILE" | docker-compose exec -T db mysql \
    -h "$DB_HOST" \
    -u "$DB_USER" \
    -p"$DB_PASSWORD" \
    "$DB_NAME" 2>/dev/null; then
    
    echo -e "${GREEN}[✓]${NC} Restauración completada exitosamente"
    echo -e "${GREEN}    Base de datos: $DB_NAME${NC}"
    echo -e "${GREEN}    Datos restaurados desde: $(basename "$BACKUP_FILE")${NC}"
    
else
    echo -e "${RED}[✗]${NC} Error durante la restauración"
    # Limpiar archivo temporal
    if [ ! -z "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
    exit 1
fi

# Limpiar archivo temporal
if [ ! -z "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
fi

echo -e "${GREEN}[✓]${NC} Proceso de restauración completado"
