#!/bin/bash

# Auto-backup Script for Cron
# Run this daily via cron to automatically backup the database
# Add to crontab: 0 2 * * * /path/to/project/backup/auto-backup.sh

set -e

# Load environment variables from .env
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../.env" ]; then
    set -a
    source "$(dirname "${BASH_SOURCE[0]}")/../.env"
    set +a
fi

# Configuration
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/backups"
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}
MAX_BACKUPS=7  # Keep last 7 days of backups

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/bbpm_backup_${TIMESTAMP}.sql"
BACKUP_GZIP="$BACKUP_DIR/bbpm_backup_${TIMESTAMP}.sql.gz"

# Log file
LOG_FILE="$BACKUP_DIR/backup.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting automated backup..." >> "$LOG_FILE"

# Create backup
if mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>> "$LOG_FILE"; then
    # Compress the backup
    gzip "$BACKUP_FILE"
    BACKUP_SIZE=$(du -h "$BACKUP_GZIP" | cut -f1)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Backup completed: $BACKUP_GZIP ($BACKUP_SIZE)" >> "$LOG_FILE"
    
    # Clean up old backups (keep only last MAX_BACKUPS)
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/bbpm_backup_*.sql.gz 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        EXCESS=$((BACKUP_COUNT - MAX_BACKUPS))
        ls -1t "$BACKUP_DIR"/bbpm_backup_*.sql.gz | tail -n "$EXCESS" | while read -r old_backup; do
            rm -f "$old_backup"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleted old backup: $old_backup" >> "$LOG_FILE"
        done
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✗ Backup failed!" >> "$LOG_FILE"
    rm -f "$BACKUP_FILE"
    exit 1
fi
