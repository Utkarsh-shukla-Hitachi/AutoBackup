#!/bin/bash

# Set variables
DB2_POD_NAME="my-db2-pod"           # The name of your DB2 pod
DATABASE_NAME="MYDATABASE"          # The name of your DB2 database
BACKUP_DIR="/mnt/db2backups"        # Directory inside the pod where backups will be stored
BACKUP_DEST="/root/db2backups"      # The local backup destination (e.g., mounted PVC or external storage)
BACKUP_RETENTION_COUNT=5            # Number of backups to retain (oldest backups will be deleted after this number)

# Timestamp for unique backup naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${DATABASE_NAME}_backup_${TIMESTAMP}.bak"

# Step 1: Take a DB2 backup
echo "[$(date)] Starting backup for database $DATABASE_NAME..."
oc rsh "$DB2_POD_NAME" "db2 backup db $DATABASE_NAME to $BACKUP_DIR/$BACKUP_FILE online"

# Check if the backup command was successful
if [ $? -eq 0 ]; then
    echo "[$(date)] Backup completed successfully: $BACKUP_FILE"
else
    echo "[$(date)] DB2 backup failed."
    exit 1
fi

# Step 2: Copy the backup file from the pod to the local backup directory
echo "[$(date)] Copying backup from pod to local destination..."
oc cp "$DB2_POD_NAME:$BACKUP_DIR/$BACKUP_FILE" "$BACKUP_DEST/$BACKUP_FILE"

# Check if the copy command was successful
if [ $? -eq 0 ]; then
    echo "[$(date)] Backup copied to $BACKUP_DEST/$BACKUP_FILE"
else
    echo "[$(date)] Failed to copy backup to local destination."
    exit 1
fi

# Step 3: Delete the oldest backup if there are more than the retention count
echo "[$(date)] Checking backup directory for cleanup..."
cd "$BACKUP_DEST"

# Count the number of backup files
BACKUP_COUNT=$(ls -1 | grep "$DATABASE_NAME" | wc -l)

if [ $BACKUP_COUNT -gt $BACKUP_RETENTION_COUNT ]; then
    # List backups sorted by timestamp (oldest first) and delete the oldest one
    OLDEST_BACKUP=$(ls -1t | grep "$DATABASE_NAME" | tail -n 1)
    echo "[$(date)] Deleting oldest backup: $OLDEST_BACKUP"
    rm "$OLDEST_BACKUP"

    # Verify deletion
    if [ $? -eq 0 ]; then
        echo "[$(date)] Successfully deleted the oldest backup: $OLDEST_BACKUP"
    else
        echo "[$(date)] Failed to delete the oldest backup."
    fi
fi

echo "[$(date)] Backup process completed."
