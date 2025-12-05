#!/bin/bash

# Migration script for bug-bounty-project-manager database
# This script runs all SQL migrations in numerical order

MIGRATIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-bbpm_db}
DB_USER=${DB_USER:-bbpm_user}
DB_PASS=${DB_PASS:-bbpm_password}

echo "Starting database migrations..."
echo "Database: $DB_NAME on $DB_HOST:$DB_PORT"
echo ""

# Run migrations in numerical order
for migration_file in $(find "$MIGRATIONS_DIR" -name "*.sql" | sort); do
    filename=$(basename "$migration_file")
    
    echo "Running: $filename"
    
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$migration_file"
    
    if [ $? -eq 0 ]; then
        echo "✓ $filename completed successfully"
    else
        echo "✗ $filename failed"
        exit 1
    fi
    echo ""
done

echo "All migrations completed successfully!"
