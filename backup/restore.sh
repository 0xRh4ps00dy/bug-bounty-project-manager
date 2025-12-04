#!/bin/bash
# Script de Restauración para Bug Bounty Project Manager
# Restaura backups de la base de datos y archivos del proyecto

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$SCRIPT_DIR/backups"
TEMP_RESTORE_DIR="$SCRIPT_DIR/temp_restore"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de output
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_info() { echo -e "${CYAN}$1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# Flags
DATABASE_ONLY=false
FILES_ONLY=false
BACKUP_FILE=""

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --database-only)
            DATABASE_ONLY=true
            shift
            ;;
        --files-only)
            FILES_ONLY=true
            shift
            ;;
        *)
            BACKUP_FILE="$1"
            shift
            ;;
    esac
done

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║     Bug Bounty Project Manager - Restore System     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Si no se especificó archivo, mostrar lista de backups disponibles
if [ -z "$BACKUP_FILE" ]; then
    log_info "=== Backups Disponibles ===\n"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        log_error "No se encontraron backups en: $BACKUP_DIR"
        exit 1
    fi
    
    # Listar backups con numeración
    mapfile -t BACKUPS < <(find "$BACKUP_DIR" -name "bbpm_backup_*.tar.gz" -type f | sort -r)
    
    for i in "${!BACKUPS[@]}"; do
        backup="${BACKUPS[$i]}"
        filename=$(basename "$backup")
        size=$(du -h "$backup" | cut -f1)
        date=$(stat -c %y "$backup" 2>/dev/null || stat -f "%Sm" "$backup")
        date_formatted=$(echo "$date" | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "${YELLOW}$((i+1)).${NC} $filename - ${GREEN}$size${NC} - $date_formatted"
    done
    
    echo ""
    read -p "Selecciona el número del backup a restaurar (o 'q' para salir): " selection
    
    if [ "$selection" = "q" ]; then
        log_info "Operación cancelada"
        exit 0
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#BACKUPS[@]}" ]; then
        log_error "Selección inválida"
        exit 1
    fi
    
    BACKUP_FILE="${BACKUPS[$((selection-1))]}"
    log_success "Seleccionado: $(basename "$BACKUP_FILE")"
fi

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "El archivo de backup no existe: $BACKUP_FILE"
    exit 1
fi

# Confirmar restauración
log_warning "\n⚠️  ADVERTENCIA: Esta operación sobrescribirá los datos actuales"
read -p "¿Estás seguro de continuar? (si/no): " confirm

if [ "$confirm" != "si" ]; then
    log_info "Operación cancelada"
    exit 0
fi

# Verificar que Docker esté corriendo
log_info "\nVerificando estado de Docker..."
if ! docker ps > /dev/null 2>&1; then
    log_error "Docker no está disponible o no tienes permisos suficientes"
    exit 1
fi
log_success "Docker está corriendo"

# Verificar que el contenedor MySQL existe
if ! docker ps --format '{{.Names}}' | grep -q "bbpm_mysql"; then
    log_error "El contenedor bbpm_mysql no está corriendo"
    log_info "Inicia los contenedores con: docker-compose up -d"
    exit 1
fi

# Extraer backup
log_info "\n=== Extrayendo Backup ==="
rm -rf "$TEMP_RESTORE_DIR"
mkdir -p "$TEMP_RESTORE_DIR"

if tar -xzf "$BACKUP_FILE" -C "$TEMP_RESTORE_DIR" 2>/dev/null; then
    log_success "Backup extraído"
    
    # Buscar la carpeta del backup
    RESTORE_PATH=$(find "$TEMP_RESTORE_DIR" -maxdepth 1 -type d -name "bbpm_backup_*" | head -n 1)
    
    if [ -z "$RESTORE_PATH" ]; then
        log_error "No se encontró la carpeta del backup"
        exit 1
    fi
else
    log_error "Error al extraer backup"
    exit 1
fi

# Restaurar Base de Datos
if [ "$FILES_ONLY" = false ]; then
    log_info "\n=== Restaurando Base de Datos ==="
    
    SQL_FILE=$(find "$RESTORE_PATH" -name "*.sql" -type f | head -n 1)
    
    if [ -n "$SQL_FILE" ]; then
        log_info "Importando base de datos..."
        
        # Copiar archivo SQL al contenedor
        docker cp "$SQL_FILE" bbpm_mysql:/tmp/restore.sql
        
        # Ejecutar restauración
        docker exec bbpm_mysql mysql -u root -proot_password -e "DROP DATABASE IF EXISTS bbpm_db; CREATE DATABASE bbpm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
        docker exec bbpm_mysql mysql -u root -proot_password -e "source /tmp/restore.sql" 2>/dev/null
        
        # Limpiar archivo temporal
        docker exec bbpm_mysql rm /tmp/restore.sql
        
        log_success "Base de datos restaurada"
    else
        log_warning "No se encontró archivo SQL en el backup"
    fi
fi

# Restaurar Archivos
if [ "$DATABASE_ONLY" = false ]; then
    log_info "\n=== Restaurando Archivos ==="
    
    FILES_PATH="$RESTORE_PATH/files"
    
    if [ -d "$FILES_PATH" ]; then
        # Lista de carpetas a restaurar
        FOLDERS_TO_RESTORE=("www" "public" "app" "config" "routes" "mysql")
        
        for folder in "${FOLDERS_TO_RESTORE[@]}"; do
            source_path="$FILES_PATH/$folder"
            dest_path="$PROJECT_DIR/$folder"
            
            if [ -d "$source_path" ]; then
                # Crear backup de carpeta actual antes de sobrescribir
                if [ -d "$dest_path" ]; then
                    backup_current_path="${dest_path}.backup_$(date +%Y%m%d_%H%M%S)"
                    cp -r "$dest_path" "$backup_current_path"
                    log_info "  Backup actual guardado: ${folder}.backup_*"
                fi
                
                # Restaurar carpeta
                rm -rf "$dest_path"
                cp -r "$source_path" "$dest_path"
                log_success "  $folder restaurado"
            fi
        done
        
        # Restaurar archivos de la raíz
        ROOT_FILES=("docker-compose.yml" "composer.json" "composer.lock" ".gitignore")
        for file in "${ROOT_FILES[@]}"; do
            if [ -f "$FILES_PATH/$file" ]; then
                cp "$FILES_PATH/$file" "$PROJECT_DIR/"
                log_success "  $file restaurado"
            fi
        done
        
        log_success "Archivos restaurados"
    else
        log_warning "No se encontró carpeta 'files' en el backup"
    fi
fi

# Limpiar directorio temporal
log_info "\n=== Limpieza ==="
rm -rf "$TEMP_RESTORE_DIR"
log_success "Archivos temporales eliminados"

# Reiniciar contenedores
log_info "\n=== Reiniciando Contenedores ==="
cd "$PROJECT_DIR" || exit 1
if docker-compose restart > /dev/null 2>&1; then
    log_success "Contenedores reiniciados"
else
    log_warning "Error al reiniciar contenedores. Reinícialos manualmente con: docker-compose restart"
fi

# Resumen
echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"
log_success "El sistema ha sido restaurado desde el backup"
log_info "  Accede a la aplicación: http://localhost"
log_info "  Accede a phpMyAdmin: http://localhost:8080"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
