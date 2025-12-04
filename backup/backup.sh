#!/bin/bash
# Script de Backup para Bug Bounty Project Manager
# Crea copias de seguridad de la base de datos MySQL y archivos del proyecto

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="bbpm_backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de output
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_info() { echo -e "${CYAN}$1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║      Bug Bounty Project Manager - Backup System     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que Docker esté corriendo
log_info "Verificando estado de Docker..."
if ! docker ps > /dev/null 2>&1; then
    log_error "Docker no está disponible o no tienes permisos suficientes"
    log_info "Intenta: sudo $0"
    exit 1
fi
log_success "Docker está corriendo"

# Verificar que el contenedor MySQL existe y está corriendo
if ! docker ps --format '{{.Names}}' | grep -q "bbpm_mysql"; then
    log_error "El contenedor bbpm_mysql no está corriendo"
    log_info "Inicia los contenedores con: docker-compose up -d"
    exit 1
fi

# Crear directorio de backup
log_info "\nCreando directorio de backup..."
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_PATH"
log_success "Directorio creado: $BACKUP_PATH"

# 1. Backup de la Base de Datos MySQL
log_info "\n=== Backup de Base de Datos ==="
DB_BACKUP_FILE="$BACKUP_PATH/database_$TIMESTAMP.sql"

log_info "Exportando base de datos..."
if docker exec bbpm_mysql mysqldump -u root -proot_password \
    --databases bbpm_db \
    --routines \
    --triggers \
    --events \
    --single-transaction \
    --quick \
    --lock-tables=false > "$DB_BACKUP_FILE" 2>/dev/null; then
    
    DB_SIZE=$(du -h "$DB_BACKUP_FILE" | cut -f1)
    log_success "Base de datos exportada: $DB_SIZE"
else
    log_error "Error al exportar base de datos"
    rm -rf "$BACKUP_PATH"
    exit 1
fi

# 2. Backup de Archivos del Proyecto
log_info "\n=== Backup de Archivos del Proyecto ==="
FILES_BACKUP_PATH="$BACKUP_PATH/files"
mkdir -p "$FILES_BACKUP_PATH"

# Lista de carpetas a respaldar
FOLDERS_TO_BACKUP=("www" "public" "app" "config" "routes" "mysql")

log_info "Copiando archivos del proyecto..."
for folder in "${FOLDERS_TO_BACKUP[@]}"; do
    if [ -d "$PROJECT_DIR/$folder" ]; then
        cp -r "$PROJECT_DIR/$folder" "$FILES_BACKUP_PATH/"
        log_success "  $folder copiado"
    fi
done

# Copiar archivos importantes de la raíz
ROOT_FILES=("docker-compose.yml" "composer.json" "composer.lock" ".gitignore" "README.md")
for file in "${ROOT_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        cp "$PROJECT_DIR/$file" "$FILES_BACKUP_PATH/"
        log_success "  $file copiado"
    fi
done

# 3. Crear archivo comprimido
log_info "\n=== Comprimiendo Backup ==="
ZIP_FILE="$BACKUP_PATH.tar.gz"

cd "$BACKUP_DIR" || exit 1
if tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME" 2>/dev/null; then
    ZIP_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
    log_success "Backup comprimido: $ZIP_SIZE"
    
    # Eliminar carpeta temporal
    rm -rf "$BACKUP_PATH"
    log_info "  Carpeta temporal eliminada"
else
    log_error "Error al comprimir backup"
    exit 1
fi

# 4. Limpiar backups antiguos
log_info "\n=== Limpieza de Backups Antiguos ==="
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "bbpm_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS)

if [ -n "$OLD_BACKUPS" ]; then
    COUNT=0
    while IFS= read -r backup; do
        rm -f "$backup"
        log_warning "  Eliminado: $(basename "$backup")"
        ((COUNT++))
    done <<< "$OLD_BACKUPS"
    log_success "$COUNT backup(s) antiguo(s) eliminado(s)"
else
    log_info "No hay backups antiguos para eliminar"
fi

# 5. Resumen Final
log_info "\n=== Resumen del Backup ==="
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "bbpm_backup_*.tar.gz" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log_success "Backup completado exitosamente"
log_info "  Ubicación: $ZIP_FILE"
log_info "  Total de backups: $TOTAL_BACKUPS"
log_info "  Espacio total usado: $TOTAL_SIZE"
log_info "  Retención configurada: $RETENTION_DAYS días"

# 6. Información adicional
echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"
log_info "Para restaurar este backup ejecuta:"
echo -e "  ${YELLOW}./restore.sh $ZIP_FILE${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
