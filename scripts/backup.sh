#!/bin/bash
# Simple backup script for the Linkding PostgreSQL database

# Ensure script is run from the project root directory relative to the script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found in $PROJECT_ROOT. Make sure you are in the project directory or the script can find it."
    exit 1
fi

# Load .env variables (needed for POSTGRES_USER)
set -a
source .env
set +a

# Create backup directory if it doesn't exist (will be ignored by git)
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# Timestamp for the backup file
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/linkding_db_$TIMESTAMP.sql"
ERROR_LOG="$BACKUP_DIR/backup_error_$TIMESTAMP.log"

echo "Creating backup of 'linkding' database for user '$POSTGRES_USER'..."

# Execute pg_dump inside the 'db' container using docker compose exec
# -T disables pseudo-tty allocation, better for non-interactive scripts
# stderr is redirected to an error log file
if docker compose exec -T db pg_dump -U "$POSTGRES_USER" linkding > "$BACKUP_FILE" 2> "$ERROR_LOG"; then
  echo "Backup successfully created: $BACKUP_FILE"
  # Remove the empty error log file on success
  rm -f "$ERROR_LOG"
  # Optional: Clean up old backups (e.g., older than 7 days)
  # echo "Cleaning up old backups..."
  # find "$BACKUP_DIR" -name 'linkding_db_*.sql' -mtime +7 -exec rm -v {} \;
  exit 0
else
  echo "Error creating database backup! Check $ERROR_LOG for details."
  # Remove potentially empty or partial backup file on error
  rm -f "$BACKUP_FILE"
  exit 1
fi
