#!/bin/bash

# Script para conectarse a MySQL desde el contenedor
# Uso: ./backup/connect.sh [nombre_usuario] [nombre_contenedor]

# Cargar variables de entorno desde .env
if [ -f ".env" ]; then
    set -a
    source <(cat .env | grep -v '^#' | grep '=')
    set +a
fi

# Variables
DB_USER="${1:-root}"
CONTAINER_NAME="${2:-bbpm_mysql}"
DB_PASSWORD=""

# Obtener contraseña según el usuario
if [ "$DB_USER" = "root" ]; then
    DB_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"
else
    DB_PASSWORD="${DB_PASS:-bbpm_password}"
fi

echo "🔗 Conectando a MySQL..."
echo "👤 Usuario: $DB_USER"
echo "📦 Contenedor: $CONTAINER_NAME"
echo ""

# Verificar si el contenedor está en ejecución
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "❌ Error: El contenedor '$CONTAINER_NAME' no está en ejecución"
    echo "💡 Inicia los contenedores con: docker-compose up -d"
    exit 1
fi

# Determinar si es interactivo
if [ -t 0 ]; then
    # Modo interactivo (TTY disponible)
    docker exec -it "$CONTAINER_NAME" mysql \
        -u "$DB_USER" \
        -p"$DB_PASSWORD"
else
    # Modo no interactivo (sin TTY)
    docker exec "$CONTAINER_NAME" mysql \
        -u "$DB_USER" \
        -p"$DB_PASSWORD"
fi
