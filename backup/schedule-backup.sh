#!/bin/bash
# Script para Programar Backups Automáticos en Crontab (Linux)
# Configura tareas cron para ejecutar backups automáticamente

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
LOG_FILE="$SCRIPT_DIR/backup.log"

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

# Valores por defecto
FREQUENCY="daily"
TIME="02:00"

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --frequency)
            FREQUENCY="$2"
            shift 2
            ;;
        --time)
            TIME="$2"
            shift 2
            ;;
        --help)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --frequency <daily|hourly|weekly|monthly>  Frecuencia del backup (default: daily)"
            echo "  --time <HH:MM>                              Hora de ejecución (default: 02:00)"
            echo "  --help                                      Muestra esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  $0 --frequency daily --time 03:00"
            echo "  $0 --frequency hourly"
            echo "  $0 --frequency weekly --time 01:00"
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            echo "Usa --help para ver las opciones disponibles"
            exit 1
            ;;
    esac
done

# Banner
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Bug Bounty Project Manager - Schedule Backups     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

log_info "Script: $BACKUP_SCRIPT"
log_info "Frecuencia: $FREQUENCY"
log_info "Hora: $TIME"
log_info "Log: $LOG_FILE"

# Verificar que el script de backup existe
if [ ! -f "$BACKUP_SCRIPT" ]; then
    log_error "No se encontró el script de backup en: $BACKUP_SCRIPT"
    exit 1
fi

# Hacer el script ejecutable
chmod +x "$BACKUP_SCRIPT"
log_success "Script de backup configurado como ejecutable"

# Convertir tiempo a formato cron
IFS=':' read -r HOUR MINUTE <<< "$TIME"

# Generar línea de cron según frecuencia
case $FREQUENCY in
    hourly)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="cada hora"
        ;;
    daily)
        CRON_SCHEDULE="$MINUTE $HOUR * * *"
        DESCRIPTION="diariamente a las $TIME"
        ;;
    weekly)
        CRON_SCHEDULE="$MINUTE $HOUR * * 0"
        DESCRIPTION="semanalmente los domingos a las $TIME"
        ;;
    monthly)
        CRON_SCHEDULE="$MINUTE $HOUR 1 * *"
        DESCRIPTION="mensualmente el día 1 a las $TIME"
        ;;
    *)
        log_error "Frecuencia no válida: $FREQUENCY"
        echo "Usa: daily, hourly, weekly, o monthly"
        exit 1
        ;;
esac

# Crear línea de cron
CRON_JOB="$CRON_SCHEDULE cd $SCRIPT_DIR && $BACKUP_SCRIPT >> $LOG_FILE 2>&1"
CRON_COMMENT="# BBPM Auto Backup - $DESCRIPTION"

# Eliminar entradas anteriores de BBPM
log_info "\nEliminando tareas anteriores de BBPM..."
crontab -l 2>/dev/null | grep -v "BBPM Auto Backup" | grep -v "$BACKUP_SCRIPT" | crontab -

# Agregar nueva tarea
log_info "Agregando nueva tarea cron..."
(crontab -l 2>/dev/null; echo "$CRON_COMMENT"; echo "$CRON_JOB") | crontab -

if [ $? -eq 0 ]; then
    log_success "\nTarea cron creada exitosamente"
    log_info "  Frecuencia: $DESCRIPTION"
    log_info "  Comando: $BACKUP_SCRIPT"
    log_info "  Log: $LOG_FILE"
    
    # Mostrar crontab actual
    echo -e "\n${CYAN}=== Tareas Cron Actuales ===${NC}"
    crontab -l | grep -A1 "BBPM Auto Backup"
    
    # Información útil
    echo -e "\n${CYAN}=== Comandos Útiles ===${NC}"
    echo -e "  Ver tareas cron: ${YELLOW}crontab -l${NC}"
    echo -e "  Editar tareas: ${YELLOW}crontab -e${NC}"
    echo -e "  Ver logs: ${YELLOW}tail -f $LOG_FILE${NC}"
    echo -e "  Ejecutar ahora: ${YELLOW}$BACKUP_SCRIPT${NC}"
    echo -e "  Eliminar tarea: ${YELLOW}crontab -e${NC} (elimina la línea de BBPM)"
    
    # Verificar que cron está corriendo
    echo -e "\n${CYAN}=== Estado del Servicio Cron ===${NC}"
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        log_success "Servicio cron está activo"
    else
        log_warning "No se pudo verificar el estado de cron"
        log_info "Asegúrate de que el servicio cron esté corriendo:"
        echo -e "  ${YELLOW}sudo systemctl status cron${NC}  (Debian/Ubuntu)"
        echo -e "  ${YELLOW}sudo systemctl status crond${NC} (RHEL/CentOS)"
    fi
    
    # Crear archivo de log si no existe
    touch "$LOG_FILE"
    log_info "\nArchivo de log creado: $LOG_FILE"
    
else
    log_error "Error al crear tarea cron"
    exit 1
fi

echo -e "\n${CYAN}═══════════════════════════════════════════════════════${NC}"
log_success "¡Backups automáticos configurados!"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
