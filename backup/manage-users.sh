#!/bin/bash

# Script para gestionar acceso múltiple a MySQL
# Permite crear usuarios adicionales con diferentes permisos

set -e

CONTAINER_NAME="${1:-bbpm_mysql}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root_password}"

show_usage() {
    echo "Gestor de Usuarios MySQL"
    echo ""
    echo "Uso: ./backup/manage-users.sh [comando] [argumentos]"
    echo ""
    echo "Comandos disponibles:"
    echo ""
    echo "  list                          Listar todos los usuarios"
    echo "  create <usuario> <password>   Crear nuevo usuario"
    echo "  delete <usuario>              Eliminar usuario"
    echo "  password <usuario> <pass>     Cambiar contraseña"
    echo "  grants <usuario>              Ver permisos de usuario"
    echo ""
    echo "Ejemplos:"
    echo "  ./backup/manage-users.sh create reports_user password123"
    echo "  ./backup/manage-users.sh list"
    echo "  ./backup/manage-users.sh password bbpm_user newpass123"
}

if [ -z "$1" ]; then
    show_usage
    exit 0
fi

COMMAND="$1"

case "$COMMAND" in
    list)
        echo "👥 Usuarios MySQL:"
        docker exec "$CONTAINER_NAME" mysql \
            -u root \
            -p"$DB_ROOT_PASSWORD" \
            -e "SELECT user, host FROM mysql.user;"
        ;;
    
    create)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "❌ Error: Debes especificar usuario y contraseña"
            echo "Uso: ./backup/manage-users.sh create <usuario> <contraseña>"
            exit 1
        fi
        USER=$2
        PASS=$3
        echo "👤 Creando usuario $USER..."
        docker exec "$CONTAINER_NAME" mysql \
            -u root \
            -p"$DB_ROOT_PASSWORD" \
            -e "CREATE USER '$USER'@'%' IDENTIFIED BY '$PASS'; GRANT ALL PRIVILEGES ON *.* TO '$USER'@'%'; FLUSH PRIVILEGES;"
        echo "✅ Usuario $USER creado exitosamente"
        ;;
    
    delete)
        if [ -z "$2" ]; then
            echo "❌ Error: Debes especificar el usuario a eliminar"
            echo "Uso: ./backup/manage-users.sh delete <usuario>"
            exit 1
        fi
        USER=$2
        echo "❌ Eliminando usuario $USER..."
        docker exec "$CONTAINER_NAME" mysql \
            -u root \
            -p"$DB_ROOT_PASSWORD" \
            -e "DROP USER '$USER'@'%'; FLUSH PRIVILEGES;"
        echo "✅ Usuario $USER eliminado exitosamente"
        ;;
    
    password)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "❌ Error: Debes especificar usuario y contraseña"
            echo "Uso: ./backup/manage-users.sh password <usuario> <nueva_contraseña>"
            exit 1
        fi
        USER=$2
        PASS=$3
        echo "🔐 Cambiando contraseña de $USER..."
        docker exec "$CONTAINER_NAME" mysql \
            -u root \
            -p"$DB_ROOT_PASSWORD" \
            -e "ALTER USER '$USER'@'%' IDENTIFIED BY '$PASS'; FLUSH PRIVILEGES;"
        echo "✅ Contraseña de $USER actualizada exitosamente"
        ;;
    
    grants)
        if [ -z "$2" ]; then
            echo "❌ Error: Debes especificar el usuario"
            echo "Uso: ./backup/manage-users.sh grants <usuario>"
            exit 1
        fi
        USER=$2
        echo "🔐 Permisos de $USER:"
        docker exec "$CONTAINER_NAME" mysql \
            -u root \
            -p"$DB_ROOT_PASSWORD" \
            -e "SHOW GRANTS FOR '$USER'@'%';"
        ;;
    
    *)
        echo "❌ Comando desconocido: $COMMAND"
        show_usage
        exit 1
        ;;
esac
