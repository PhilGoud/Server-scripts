#!/bin/bash

# This script performs backups using rclone for various directories to a remote Wasabi storage.
# It logs the progress and errors, and sends a Telegram notification upon completion.

# Parameters
LOG_FILE="/DATA/log/rclonelog.txt"  # Path to the main log file
TEMP_LOG_FILE="/DATA/log/rclonelogtemp.txt"  # Path to the temporary log file
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Telegram bot token
CHAT_ID="XXXXXXXX"  # Telegram chat ID
DIRECTORIES=(  # Array of directories to back up
    "/mnt/CAKE/Famille"
    "/mnt/CAKE/Photos"
    "/mnt/CAKE/Musique/PlexMusic"
    "/mnt/CAKE/Podcasts"
    "/mnt/CAKE/ASoundMR"
    "/scripts"
)
DESTINATIONS=(  # Corresponding array of remote destinations
    "wasabi:/backupchell/Famille"
    "wasabi:/backupchell/Photos"
    "wasabi:/backupchell/Musique"
    "wasabi:/backupchell/Podcasts"
    "wasabi:/backupchell/ASoundMR"
    "wasabi://backupchell/scripts"
)
NAMES=(  # Array of names for log identification
    "📽️ Famille"
    "📷 Photos"
    "🎧 Musique"
    "🎙️ Podcast"
    "🪶 ASoundMR"
    "🛠️ scripts"
)

# Start of the backup process
echo "📦 BACKUP RCLONE ⬆️" &> "$LOG_FILE"
echo "Start at $(date +"%H:%M:%S")" &>> "$LOG_FILE"

# Loop through each directory and perform the backup
for i in "${!DIRECTORIES[@]}"; do
    SRC=${DIRECTORIES[$i]}
    DEST=${DESTINATIONS[$i]}
    NAME=${NAMES[$i]}
    
    echo "Directory $SRC" &> "$TEMP_LOG_FILE"
    sudo rclone sync -v "$SRC" "$DEST" &>> "$TEMP_LOG_FILE"
    echo "$NAME" &>> "$LOG_FILE"
    grep -e '^Errors' "$TEMP_LOG_FILE" | tail -1 &>> "$LOG_FILE"
    grep -e '^Transferred' "$TEMP_LOG_FILE" | tail -1 &>> "$LOG_FILE"
    grep -e '^Elapsed' "$TEMP_LOG_FILE" | tail -1 &>> "$LOG_FILE"
done

# End of the backup process
echo "End at $(date +"%H:%M:%S")" &>> "$LOG_FILE"

# Telegram notification configuration
TELEGRAM=$(cat "$LOG_FILE")  # Get the content of the log file
LENGTH=${#TELEGRAM}  # Get the length of the log content

# Determine the type of message to send based on length
if ((LENGTH < 1000)); then
    # Send full Telegram notification if the message is less than 1000 characters
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TELEGRAM" > /dev/null
else
    # Send a summary notification if the message is too long
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="📦 BACKUP RCLONE🆗
    /DATA/log/rclonelog.txt contains $LENGTH characters" > /dev/null
fi
