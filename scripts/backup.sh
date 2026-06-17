#!/usr/bin/env bash

set -euo pipefail

BACKUP_DIR="/opt/backups"
METRICS_DIR="/var/lib/node_exporter/textfile_collector"
DB_NAME="${DB_NAME:-notes}"
DB_USER="${DB_USER:-notes}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD="${DB_PASSWORD:-changeme}"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR" "$METRICS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/notes_${TIMESTAMP}.sql.gz"

if PGPASSWORD="$PGPASSWORD" pg_dump \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
    | gzip > "$BACKUP_FILE"; then
    STATUS=1
    echo "backup OK: $BACKUP_FILE"
else
    STATUS=0
    echo "backup FAILED" >&2
fi

find "$BACKUP_DIR" -name "notes_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

cat > "$METRICS_DIR/backup.prom" <<EOF
# HELP backup_last_success_timestamp_seconds Unix timestamp последнего успешного бэкапа
# TYPE backup_last_success_timestamp_seconds gauge
backup_last_success_timestamp_seconds $([ $STATUS -eq 1 ] && date +%s || echo 0)
# HELP backup_success Последний бэкап успешен (1) или нет (0)
# TYPE backup_success gauge
backup_success $STATUS
EOF
