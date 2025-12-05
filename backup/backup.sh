#!/bin/bash

# Database Backup Script
# Backs up the MySQL database to a timestamped SQL file

set -e

# Configuration
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backups"
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/bbpm_backup_${TIMESTAMP}.sql"
BACKUP_GZIP="$BACKUP_DIR/bbpm_backup_${TIMESTAMP}.sql.gz"

echo "Starting database backup..."
echo "Database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"
echo ""

# Create backup
mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # Compress the backup
    gzip -v "$BACKUP_FILE"
    BACKUP_SIZE=$(du -h "$BACKUP_GZIP" | cut -f1)
    echo "✓ Backup completed successfully!"
    echo "File: $BACKUP_GZIP"
    echo "Size: $BACKUP_SIZE"
    
    # Show last 5 backups
    echo ""
    echo "Recent backups:"
    ls -lh "$BACKUP_DIR" | tail -6 | head -5
    
    # Clean up backups older than 30 days
    echo ""
    echo "Cleaning up old backups (older than 30 days)..."
    find "$BACKUP_DIR" -name "bbpm_backup_*.sql.gz" -mtime +30 -delete
    echo "✓ Cleanup completed"
else
    echo "✗ Backup failed!"
    rm -f "$BACKUP_FILE"
    exit 1
fi
