#!/bin/bash

# Script para ejecutar comandos MySQL sin problemas de escaping
# Uso: ./backup/mysql-cli.sh "SELECT * FROM database.table;" [usuario] [contenedor]

COMMAND="${1}"
CONTAINER_NAME="${3:-bbpm_mysql}"

# Cargar variables de entorno desde .env
if [ -f ".env" ]; then
    set -a
    source <(cat .env | grep -v '^#' | grep '=')
    set +a
fi

# Asignar usuario después de cargar .env para no sobrescribir
DB_USER="${2:-root}"

# Asignar usuario después de cargar .env para no sobrescribir
DB_USER="${2:-root}"

# Obtener contraseña según el usuario
if [ "$DB_USER" = "root" ]; then
    DB_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"
else
    DB_PASSWORD="${DB_PASS:-bbpm_password}"
fi

echo "🔗 Ejecutando comando en MySQL..."
echo "👤 Usuario: $DB_USER"
echo "📦 Contenedor: $CONTAINER_NAME"
echo ""

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Error: El contenedor '$CONTAINER_NAME' no está en ejecución"
    echo "💡 Inicia los contenedores con: docker-compose up -d"
    exit 1
fi

# Crear archivo temporal con el comando
TEMP_SQL=$(mktemp)
echo "${COMMAND}" > "${TEMP_SQL}"

# Ejecutar el comando desde el archivo temporal
docker exec "$CONTAINER_NAME" mysql \
    -u "${DB_USER}" \
    -p"${DB_PASSWORD}" \
    < "${TEMP_SQL}"

# Limpiar archivo temporal
rm -f "${TEMP_SQL}"
