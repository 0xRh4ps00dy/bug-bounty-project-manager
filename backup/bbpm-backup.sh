#!/bin/bash
# BBPM Backup Manager - Sistema Simplificado de Copias de Seguridad
# Uso: ./bbpm-backup.sh [comando]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$SCRIPT_DIR/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_info() { echo -e "${CYAN}→ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

show_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       🔒 BBPM BACKUP MANAGER - Sistema Simplificado      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

test_docker() {
    if ! docker ps > /dev/null 2>&1; then
        log_error "Docker no está corriendo o no tienes permisos"
        return 1
    fi
    if ! docker ps --format '{{.Names}}' | grep -q "bbpm_mysql"; then
        log_error "El contenedor bbpm_mysql no está corriendo"
        return 1
    fi
    return 0
}

create_backup() {
    show_banner
    echo -e "${BLUE}════════════════ CREAR BACKUP ════════════════${NC}"
    echo ""
    
    if ! test_docker; then
        echo ""
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    log_info "Iniciando proceso de backup..."
    BACKUP_NAME="bbpm_backup_$TIMESTAMP"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    mkdir -p "$BACKUP_PATH"
    
    # Backup BD
    log_info "Exportando base de datos..."
    DB_FILE="$BACKUP_PATH/database.sql"
    if docker exec bbpm_mysql mysqldump -u root -proot_password \
        --databases bbpm_db --routines --triggers --events \
        --single-transaction --quick > "$DB_FILE" 2>/dev/null; then
        SIZE=$(du -h "$DB_FILE" | cut -f1)
        log_success "Base de datos exportada ($SIZE)"
    else
        log_error "Error al exportar base de datos"
        rm -rf "$BACKUP_PATH"
        echo ""
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    # Backup archivos
    log_info "Copiando archivos del proyecto..."
    FILES_PATH="$BACKUP_PATH/files"
    mkdir -p "$FILES_PATH"
    
    for folder in www public app config routes mysql; do
        [ -d "$PROJECT_DIR/$folder" ] && cp -r "$PROJECT_DIR/$folder" "$FILES_PATH/"
    done
    
    for file in docker-compose.yml composer.json; do
        [ -f "$PROJECT_DIR/$file" ] && cp "$PROJECT_DIR/$file" "$FILES_PATH/"
    done
    log_success "Archivos copiados"
    
    # Comprimir
    log_info "Comprimiendo backup..."
    cd "$BACKUP_DIR" || exit 1
    tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME" 2>/dev/null
    rm -rf "$BACKUP_PATH"
    
    ZIP_SIZE=$(du -h "$BACKUP_NAME.tar.gz" | cut -f1)
    log_success "Backup creado: $ZIP_SIZE"
    log_info "Ubicación: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
    
    # Limpiar antiguos
    OLD=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -type f)
    if [ -n "$OLD" ]; then
        COUNT=$(echo "$OLD" | wc -l)
        echo "$OLD" | xargs rm -f
        log_info "Eliminados $COUNT backup(s) antiguo(s)"
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

restore_backup() {
    show_banner
    echo -e "${YELLOW}════════════════ RESTAURAR BACKUP ════════════════${NC}"
    echo ""
    
    if ! test_docker; then
        echo ""
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    mapfile -t BACKUPS < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f | sort -r)
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        log_warn "No hay backups disponibles"
        echo ""
        read -p "Presiona Enter para continuar..."
        return
    fi
    
    echo "Backups disponibles:"
    echo ""
    for i in "${!BACKUPS[@]}"; do
        backup="${BACKUPS[$i]}"
        name=$(basename "$backup")
        size=$(du -h "$backup" | cut -f1)
        date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "  $((i+1)). ${CYAN}$name${NC}"
        echo -e "     $date - $size"
    done
    
    echo ""
    read -p "Selecciona número (o Enter para cancelar): " selection
    
    if [ -z "$selection" ]; then
        log_info "Operación cancelada"
        sleep 1
        return
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#BACKUPS[@]}" ]; then
        log_error "Selección inválida"
        sleep 2
        return
    fi
    
    BACKUP_FILE="${BACKUPS[$((selection-1))]}"
    
    echo ""
    log_warn "⚠ ADVERTENCIA: Esto sobrescribirá los datos actuales"
    read -p "¿Continuar? (escribe SI en mayúsculas): " confirm
    
    if [ "$confirm" != "SI" ]; then
        log_info "Operación cancelada"
        sleep 1
        return
    fi
    
    echo ""
    log_info "Restaurando backup..."
    
    # Extraer
    TEMP_DIR="$SCRIPT_DIR/temp_restore"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" 2>/dev/null
    
    RESTORE_PATH=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "bbpm_backup_*" | head -n 1)
    
    # Restaurar BD
    log_info "Restaurando base de datos..."
    SQL_FILE=$(find "$RESTORE_PATH" -name "*.sql" -type f | head -n 1)
    if [ -n "$SQL_FILE" ]; then
        docker cp "$SQL_FILE" bbpm_mysql:/tmp/restore.sql
        docker exec bbpm_mysql mysql -u root -proot_password -e "DROP DATABASE IF EXISTS bbpm_db; CREATE DATABASE bbpm_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
        docker exec bbpm_mysql mysql -u root -proot_password -e "source /tmp/restore.sql" 2>/dev/null
        docker exec bbpm_mysql rm /tmp/restore.sql
        log_success "Base de datos restaurada"
    fi
    
    # Restaurar archivos
    log_info "Restaurando archivos..."
    FILES_PATH="$RESTORE_PATH/files"
    if [ -d "$FILES_PATH" ]; then
        for folder in www public app config routes mysql; do
            [ -d "$FILES_PATH/$folder" ] && {
                rm -rf "$PROJECT_DIR/$folder"
                cp -r "$FILES_PATH/$folder" "$PROJECT_DIR/"
            }
        done
        log_success "Archivos restaurados"
    fi
    
    # Limpiar
    rm -rf "$TEMP_DIR"
    
    # Reiniciar
    log_info "Reiniciando contenedores..."
    cd "$PROJECT_DIR" && docker-compose restart > /dev/null 2>&1
    
    log_success "¡Restauración completada!"
    echo ""
    read -p "Presiona Enter para continuar..."
}

show_backups() {
    show_banner
    echo -e "${CYAN}════════════════ BACKUPS DISPONIBLES ════════════════${NC}"
    echo ""
    
    mapfile -t BACKUPS < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f | sort -r)
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        log_warn "No hay backups disponibles"
    else
        TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
        echo -e "${YELLOW}Total: ${#BACKUPS[@]} backup(s) - $TOTAL_SIZE${NC}"
        echo ""
        
        for backup in "${BACKUPS[@]}"; do
            name=$(basename "$backup")
            size=$(du -h "$backup" | cut -f1)
            date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            age=$(( ($(date +%s) - $(stat -c %Y "$backup")) / 86400 ))
            
            echo -e "  📦 ${CYAN}$name${NC}"
            echo -e "     $date - $size - $age días"
            echo ""
        done
    fi
    
    echo ""
    read -p "Presiona Enter para continuar..."
}

setup_auto() {
    show_banner
    echo -e "${MAGENTA}════════════════ BACKUPS AUTOMÁTICOS ════════════════${NC}"
    echo ""
    echo "Opciones de programación:"
    echo ""
    echo "  1. Diario a las 2:00 AM"
    echo "  2. Cada 12 horas"
    echo "  3. Cada 6 horas"
    echo "  4. Semanal (Domingos 2:00 AM)"
    echo "  5. Desactivar backups automáticos"
    echo ""
    
    read -p "Selecciona opción (o Enter para cancelar): " choice
    
    if [ -z "$choice" ]; then
        log_info "Operación cancelada"
        sleep 1
        return
    fi
    
    # Eliminar tareas anteriores
    crontab -l 2>/dev/null | grep -v "bbpm-backup.sh" | crontab - 2>/dev/null
    
    if [ "$choice" = "5" ]; then
        log_success "Backups automáticos desactivados"
        sleep 2
        return
    fi
    
    SCRIPT="$SCRIPT_DIR/bbpm-backup.sh"
    chmod +x "$SCRIPT"
    
    case $choice in
        1) 
            CRON="0 2 * * * cd $SCRIPT_DIR && $SCRIPT backup >> $SCRIPT_DIR/backup.log 2>&1"
            DESC="Diario a las 2:00 AM"
            ;;
        2) 
            CRON="0 */12 * * * cd $SCRIPT_DIR && $SCRIPT backup >> $SCRIPT_DIR/backup.log 2>&1"
            DESC="Cada 12 horas"
            ;;
        3) 
            CRON="0 */6 * * * cd $SCRIPT_DIR && $SCRIPT backup >> $SCRIPT_DIR/backup.log 2>&1"
            DESC="Cada 6 horas"
            ;;
        4) 
            CRON="0 2 * * 0 cd $SCRIPT_DIR && $SCRIPT backup >> $SCRIPT_DIR/backup.log 2>&1"
            DESC="Semanal (Domingos 2:00 AM)"
            ;;
        *)
            log_error "Opción inválida"
            sleep 2
            return
            ;;
    esac
    
    (crontab -l 2>/dev/null; echo "# BBPM Auto Backup - $DESC"; echo "$CRON") | crontab -
    
    echo ""
    log_success "¡Backups automáticos configurados!"
    log_info "Frecuencia: $DESC"
    echo ""
    read -p "Presiona Enter para continuar..."
}

show_menu() {
    while true; do
        show_banner
        
        echo -e "  ${GREEN}1. 💾 Crear Backup${NC}"
        echo -e "  ${YELLOW}2. ♻️  Restaurar Backup${NC}"
        echo -e "  ${CYAN}3. 📋 Ver Backups${NC}"
        echo -e "  ${MAGENTA}4. ⏰ Configurar Automático${NC}"
        echo -e "  ${RED}5. ❌ Salir${NC}"
        echo ""
        
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1) create_backup ;;
            2) restore_backup ;;
            3) show_backups ;;
            4) setup_auto ;;
            5) 
                echo ""
                log_info "¡Hasta luego!"
                exit 0
                ;;
            *)
                log_warn "Opción inválida"
                sleep 1
                ;;
        esac
    done
}

# Punto de entrada
case "${1:-menu}" in
    backup) 
        create_backup
        exit 0
        ;;
    restore) 
        restore_backup
        exit 0
        ;;
    list) 
        show_backups
        exit 0
        ;;
    auto) 
        setup_auto
        exit 0
        ;;
    *)
        show_menu
        ;;
esac
