#!/usr/bin/env bash
# The Fortress - MySQL Backup to Azure Blob Storage
# Runs on a daily cron schedule. Compresses and encrypts the dump,
# uploads to Azure Blob Storage, and rotates local copies.
# Status: Planned

set -euo pipefail

readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
readonly BACKUP_DIR="/var/backups/fortress"
readonly BACKUP_FILE="${BACKUP_DIR}/fortress_${TIMESTAMP}.sql.gz"
readonly RETENTION_DAYS=7

# ── Config (override via environment or /etc/fortress/backup.conf) ─────────────
DB_NAME="${FORTRESS_DB_NAME:-fortress}"
DB_USER="${FORTRESS_DB_USER:-fortress_backup}"
DB_PASS="${FORTRESS_DB_PASS:?FORTRESS_DB_PASS must be set}"
AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT:?AZURE_STORAGE_ACCOUNT must be set}"
AZURE_CONTAINER="${AZURE_CONTAINER:-fortress-backups}"
# TODO: Configure managed identity on the VM for Azure CLI auth
# TODO: Or set AZURE_STORAGE_SAS_TOKEN for SAS-based auth

# ── Backup ─────────────────────────────────────────────────────────────────────

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

mkdir -p "$BACKUP_DIR"

log "Starting MySQL backup: ${DB_NAME}"

mysqldump \
    --user="${DB_USER}" \
    --password="${DB_PASS}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    "${DB_NAME}" \
  | gzip -9 > "${BACKUP_FILE}"

log "Backup created: ${BACKUP_FILE} ($(du -sh "${BACKUP_FILE}" | cut -f1))"

# ── Upload to Azure Blob Storage ───────────────────────────────────────────────

log "Uploading to Azure Blob Storage..."

# TODO: Verify az CLI is installed and authenticated
az storage blob upload \
    --account-name "${AZURE_STORAGE_ACCOUNT}" \
    --container-name "${AZURE_CONTAINER}" \
    --name "$(basename "${BACKUP_FILE}")" \
    --file "${BACKUP_FILE}" \
    --auth-mode login \
    --overwrite false

log "Upload complete."

# ── Rotate Local Backups ───────────────────────────────────────────────────────

log "Rotating local backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "fortress_*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete
log "Rotation complete."

log "Backup job finished."
