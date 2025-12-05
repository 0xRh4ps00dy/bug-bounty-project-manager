#!/bin/bash

# Database Restore Script
# Restores the MySQL database from a backup file

set -e

# Configuration
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backups"
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "Usage: ./restore.sh <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/bbpm_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "✗ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Database Restore"
echo "==============="
echo "Database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Are you sure you want to restore from this backup? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Starting database restore..."

# Check if file is gzipped
if [[ "$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
else
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$BACKUP_FILE"
fi

if [ $? -eq 0 ]; then
    echo "✓ Database restore completed successfully!"
else
    echo "✗ Database restore failed!"
    exit 1
fi
