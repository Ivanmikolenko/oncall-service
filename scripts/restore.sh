#!/usr/bin/env bash
# restore.sh — восстановление БД из бэкапа
# Использование: ./scripts/restore.sh /opt/backups/notes_20260617_120000.sql.gz
# Или без аргумента — возьмёт последний бэкап

set -euo pipefail

BACKUP_DIR="/opt/backups"
DB_NAME="${DB_NAME:-notes}"
DB_USER="${DB_USER:-notes}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD="${DB_PASSWORD:-changeme}"

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE=$(ls -t "$BACKUP_DIR"/notes_*.sql.gz 2>/dev/null | head -1)
    if [ -z "$BACKUP_FILE" ]; then
        echo "Нет доступных бэкапов в $BACKUP_DIR" >&2
        exit 1
    fi
fi

echo "Восстанавливаем из: $BACKUP_FILE"
echo "ВНИМАНИЕ: существующие данные в БД '$DB_NAME' будут перезаписаны!"
read -r -p "Продолжить? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Отменено."; exit 0; }

# Удаляем и пересоздаём схему, затем льём дамп
PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres <<SQL
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME OWNER $DB_USER;
SQL

zcat "$BACKUP_FILE" | PGPASSWORD="$PGPASSWORD" psql \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"

echo "Восстановление завершено."
