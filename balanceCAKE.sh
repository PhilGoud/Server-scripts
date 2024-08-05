#!/bin/bash

# This script performs backups using rclone for various directories to a remote Wasabi storage.
# It logs the progress and errors, and sends a Telegram notification upon completion.

# Parameters
LOG_FILE="/DATA/log/balancecake.txt"  # Path to the main log file
TEMP_LOG_FILE="/DATA/log/balancecaketemp.txt"  # Path to the temporary log file
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"  # Telegram bot token
CHAT_ID="TELEGRAM_CHATID_HERE"  # Telegram chat ID
FOLDER="/mnt/CAKE/"
NAME="🎂 CAKE"
NUMBER_OF_DISKS=4

# Start of the backup process
echo "⚖ BALANCE $NAME 💽" &> "$LOG_FILE"
echo "Start at $(date +"%H:%M:%S")" &>> "$LOG_FILE"

# Loop through each directory and perform the backup
    sudo mergerfs.balance  "$FOLDER" &> "$TEMP_LOG_FILE"
    grep -e '^Branches' "$TEMP_LOG_FILE" | tail -1 &>> "$LOG_FILE"
    grep -e ' \* \/' "$TEMP_LOG_FILE"| tail -$NUMBER_OF_DISKS &>> "$LOG_FILE"

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
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="📦 BACKUP RSYNC 🆗
    $LOG_File contains $LENGTH characters" > /dev/null
fi