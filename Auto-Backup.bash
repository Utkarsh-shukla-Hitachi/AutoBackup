#!/bin/bash

# Set variables
DB2_POD_NAME="c-mas-masprod-maxprod-manage-db2u-0"   # The name of the DB2 pod
DB2_BACKUP_DIR="/mnt/bludata0/db2/archive_log"       # The directory in the pod where backups are stored
BASTION_BACKUP_DIR="/root/db2backup"                 # The directory on the bastion where backups will be copied
LOG_FILE="/root/db2_backup.log"                      # The log file location
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")                   # Timestamp for backup folder to avoid overwriting

# Create a backup folder on the bastion node with timestamp
BACKUP_FOLDER="$BASTION_BACKUP_DIR/backup_$TIMESTAMP"
mkdir -p "$BACKUP_FOLDER"

# Log start of the backup process
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting backup process from DB2 pod to bastion node..." >> "$LOG_FILE"

# Perform rsync to copy backup files from DB2 pod to the bastion node
oc rsync "$DB2_POD_NAME:$DB2_BACKUP_DIR" "$BACKUP_FOLDER" >> "$LOG_FILE" 2>&1

# Check if the rsync command was successful and log the outcome
if [ $? -eq 0 ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup completed successfully! Files copied to $BACKUP_FOLDER" >> "$LOG_FILE"
else
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup failed. Please check the logs." >> "$LOG_FILE"
    exit 1
fi

# Log end of the backup process
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup process finished." >> "$LOG_FILE"
