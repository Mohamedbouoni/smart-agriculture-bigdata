# Smart Agriculture Restore Script
# Usage: ./restore.ps1 -Timestamp yyyyMMdd_HHmmss

param (
    [Parameter(Mandatory=$true)]
    [string]$Timestamp
)

$BackupDir = ".\backups"
$PgBackupFile = "$BackupDir\postgres_backup_$Timestamp.sql"
$MongoBackupDir = "$BackupDir\mongo_backup_$Timestamp\smart_agri"

if (-not (Test-Path $PgBackupFile) -or -not (Test-Path $MongoBackupDir)) {
    Write-Error "Backup files for timestamp '$Timestamp' not found in $BackupDir."
    exit 1
}

Write-Host "Starting Restore Process for Timestamp: $Timestamp" -ForegroundColor Yellow
Write-Host "WARNING: This will overwrite current data!" -ForegroundColor Red
Start-Sleep -Seconds 3

# 1. PostgreSQL Restore
Write-Host "Restoring PostgreSQL..."
try {
    # Copy backup to container
    docker cp $PgBackupFile postgres:/tmp/restore.sql
    
    # Drop and Re-create DB (Clean Restore)
    docker exec postgres psql -U admin -d postgres -c "DROP DATABASE IF EXISTS smart_agri WITH (FORCE);"
    docker exec postgres psql -U admin -d postgres -c "CREATE DATABASE smart_agri;"
    
    # Restore dump
    docker exec postgres pg_restore -U admin -d smart_agri -v "/tmp/restore.sql"
    
    Write-Host "PostgreSQL Restore Successful!" -ForegroundColor Green
} catch {
    Write-Error "PostgreSQL Restore Failed. Check logs."
}

# 2. MongoDB Restore
Write-Host "Restoring MongoDB..."
try {
    # Copy backup to container
    # Note: docker cp needs the parent folder structure or just the files. 
    # We copy the specific db folder dump to /tmp/restore_mongo
    docker exec mongodb rm -rf /tmp/restore_mongo
    docker cp $MongoBackupDir mongodb:/tmp/restore_mongo
    
    # Restore using mongorestore
    docker exec mongodb mongorestore --db smart_agri --drop /tmp/restore_mongo
    
    Write-Host "MongoDB Restore Successful!" -ForegroundColor Green
} catch {
    Write-Error "MongoDB Restore Failed. Check logs."
}

Write-Host "Restore Completed." -ForegroundColor Cyan
