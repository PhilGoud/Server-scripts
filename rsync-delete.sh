#!/bin/bash

# This script performs backups using rsync for various directories to a remote storage.
# It logs the progress and errors, and sends a Telegram notification upon completion.

# Parameters
LOG_FILE="/DATA/log/rsync/log.txt"  # Path to the main log file
TEMP_LOG_FILE="/DATA/log/rsync/logtemp.txt"  # Path to the temporary log file
TEST_LOG_FILE="/DATA/log/rsync/testlog.txt"  # Path to the test log file
TEST_TEMP_LOG_FILE="/DATA/log/rsync/testlogtemp.txt"  # Path to the temporary test log file
ERRORS="/DATA/log/rsync/errors.txt"
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Telegram bot token
CHAT_ID="XXXXXXXXXXX"  # Telegram chat ID

# Directories, destinations, and names in the format:
# "source_directory|destination_directory|name"
JOBS=(
    "/mnt/CAKE/Famille|/mnt/BOREALIS/Famille|📽️ Famille"
    "/mnt/CAKE/Photos|/mnt/BOREALIS/Photos|📷 Photos"
    "/mnt/CAKE/Musique|/mnt/BOREALIS/Musique|🎧 Musique"
    "/mnt/CAKE/AudioBooks|/mnt/BOREALIS/AudioBooks|🗣 AudioBooks"
    "/mnt/CAKE/Podcasts|/mnt/BOREALIS/Podcasts|🎙️ Podcast"
    "/mnt/CAKE/ASoundMR|/mnt/BOREALIS/ASoundMR|🪶 ASoundMR"
    "/mnt/CAKE/Documents|/mnt/BOREALIS/Documents|🗃️ Documents"
    "/mnt/CAKE/GDrive|/mnt/BOREALIS/GDrive|☁️ GDrive"
    "/mnt/CAKE/Bibliothèque|/mnt/BOREALIS/Bibliothèque|📚 Bibliothèque"
    "/mnt/CAKE/Vidéos|/mnt/BOREALIS/Vidéos|🎦 Vidéos"
    "/scripts|/mnt/BOREALIS/scripts|🛠️ scripts"
    "/mnt/CAKE/Films|/mnt/BOREALIS/Films|🎬 Films"
)

# Calculate the number of directories
NUMBER_OF_DIRECTORIES=${#JOBS[@]}
echo "" > "$ERRORS"

# Start of the backup process
echo "📦 BACKUP RSYNC 🔄" > "$LOG_FILE"
echo "Start at $(date +"%H:%M:%S")" >> "$LOG_FILE"

# Initialize check
check=0
alert="false"

# Function to convert bytes to human-readable format
convert_bytes() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.0f Go\n" "$(bc <<< "scale=0; $bytes/1073741824")"
    elif (( bytes >= 1048576 )); then
        printf "%.0f Mo\n" "$(bc <<< "scale=0; $bytes/1048576")"
    elif (( bytes >= 1024 )); then
        printf "%.0f Ko\n" "$(bc <<< "scale=0; $bytes/1024")"
    else
        printf "%d octets\n" "$bytes"
    fi
}

# Loop through each job and perform the backup
for job in "${JOBS[@]}"; do
    IFS='|' read -r SRC DEST NAME <<< "$job"

    created_files=""
    deleted_files=""
    transferred_files=""
    echo "Directory $SRC to $DEST" > "$TEMP_LOG_FILE"
    
	# Rsync to backup
    sudo rsync -avP --partial --stats --delete-after "$SRC/" "$DEST" &>> "$TEMP_LOG_FILE"
    echo "$NAME" >> "$LOG_FILE"

    # Extract the relevant statistics
    created_files=$(grep -e '^Number of created files:' "$TEMP_LOG_FILE" | awk -F 'files: ' '{print $2}')
    deleted_files=$(grep -e '^Number of deleted files:' "$TEMP_LOG_FILE" | awk -F 'files: ' '{print $2}')
    transferred_files=$(grep -e '^Number of regular files transferred:' "$TEMP_LOG_FILE" | awk '{print $6}')
    transferred_size_line=$(grep -e '^Total transferred file size:' "$TEMP_LOG_FILE")
    transferred_size=$(echo $transferred_size_line | awk '{print $5}' | tr -d '.')

    # Extract numeric values for comparison
    created_files_num=$(echo $created_files | awk '{print $1}')
    deleted_files_num=$(echo $deleted_files | awk '{print $1}')
    transferred_files_num=$(echo $transferred_files | awk '{print $1}')

    # Log errors and warnings
    grep -e '^error^' "$TEMP_LOG_FILE" | tail -1 >> "$LOG_FILE"
    grep -e '^warning^' "$TEMP_LOG_FILE" | tail -1 >> "$LOG_FILE"

    if [[ "$created_files_num" == "0" ]] && [[ "$deleted_files_num" == "0" ]] && [[ "$transferred_files_num" == "0" ]]; then
        echo "✔️" >> "$LOG_FILE"
        check=$(($check + 1))
        echo "$SRC"
        echo "C $created_files D $deleted_files T $transferred_files"
    else
        echo "Created: $created_files" >> "$LOG_FILE"
        echo "Deleted: $deleted_files" >> "$LOG_FILE"
        echo "Transferred: $transferred_files" >> "$LOG_FILE"
        echo "$SRC"
        echo "C $created_files D $deleted_files T $transferred_files"
        echo "Data: $(convert_bytes $transferred_size)" >> "$LOG_FILE"
    fi

done

# End of the backup process
echo "End at $(date +"%H:%M:%S")" >> "$LOG_FILE"

# Send notification only if something happened
if [ $check != $NUMBER_OF_DIRECTORIES ] || [ $alert == "true" ]; then
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
        $LOG_FILE contains $LENGTH characters" > /dev/null
    fi
else 
    echo "Nothing has changed!"
    echo "$check / $NUMBER_OF_DIRECTORIES"
fi
