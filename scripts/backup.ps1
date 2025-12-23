# Smart Agriculture Backup Script
# Usage: ./backup.ps1

$BackupDir = ".\backups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create backup directory if it doesn't exist
if (-not (Test-Path -Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
    Write-Host "Created backup directory: $BackupDir"
}

Write-Host "Starting Backup Process..." -ForegroundColor Cyan

# 1. PostgreSQL Backup
$PgBackupFile = "$BackupDir\postgres_backup_$Timestamp.sql"
Write-Host "Backing up PostgreSQL to $PgBackupFile..."
try {
    docker exec -t postgres pg_dump -U admin -d smart_agri -F c -b -v -f "/tmp/pg_dump.sql"
    docker cp postgres:/tmp/pg_dump.sql $PgBackupFile
    Write-Host "PostgreSQL Backup Successful!" -ForegroundColor Green
} catch {
    Write-Error "PostgreSQL Backup Failed!"
}

# 2. MongoDB Backup
$MongoBackupDir = "$BackupDir\mongo_backup_$Timestamp"
Write-Host "Backing up MongoDB to $MongoBackupDir..."
try {
    # Dump to a temporary folder inside container
    docker exec mongodb mongodump --db smart_agri --out /tmp/mongo_dump
    
    # Copy to host
    docker cp mongodb:/tmp/mongo_dump $MongoBackupDir
    
    # Cleanup inside container
    docker exec mongodb rm -rf /tmp/mongo_dump
    
    Write-Host "MongoDB Backup Successful!" -ForegroundColor Green
} catch {
    Write-Error "MongoDB Backup Failed!"
}

Write-Host "All backups completed." -ForegroundColor Cyan
