#!/bin/bash
# Script para exportar la base de datos MySQL desde el contenedor
# Uso: ./export-database.sh
# Uso con archivo específico: ./export-database.sh mi-export.sql

OUTPUT_FILE="${1:-bbpm_db_$(date +%Y-%m-%d_%H-%M-%S).sql}"

echo "=== Exportar Base de Datos MySQL ===" 
echo "Contenedor: bbpm_mysql"
echo "Base de datos: bbpm_db"
echo "Archivo de salida: $OUTPUT_FILE"
echo ""

echo "[*] Exportando base de datos..." 

if docker-compose exec -T db mysqldump \
    -h db \
    -u bbpm_user \
    -pbbpm_password \
    bbpm_db > "$OUTPUT_FILE" 2>/dev/null; then
    
    FILE_SIZE=$(du -sh "$OUTPUT_FILE" | cut -f1)
    
    echo "[OK] Base de datos exportada correctamente"
    echo "    Archivo: $OUTPUT_FILE"
    echo "    Tamaño: $FILE_SIZE"
    echo ""
    echo "[!] El archivo SQL está listo para descargar"
    exit 0
else
    echo "[ERROR] Error durante la exportación"
    exit 1
fi
