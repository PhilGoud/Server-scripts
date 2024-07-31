#!/bin/bash

# Configuration parameters
LOG_FILE="/DATA/log/disk_usage_log.txt"  # Path to the log file to store disk usage states
TEMP_FILE="/DATA/log/disk_usage_temp.txt"  # Path to the temporary log file
THRESHOLD=90  # Disk usage percentage threshold for alert
TOKEN="HERE_YOUR_TELEGRAM_TOKEN"  # Telegram bot token
CHAT_ID="HERE_YOUR_CHATID"  # Telegram chat ID

# Disks to monitor (add specific disks along with generic ones)
DISKS=("/mnt/CAKE" "/mnt/BOREALIS" "/dev/sda1" $(ls /dev/sd[b-z] /dev/sd[b-z][b-z] 2>/dev/null))

# Function to check disk usage
check_disk_usage() {
    local disk=$1
    df -h | grep "$disk" | awk '{print $(NF-1)}' | sed 's/%//g'
}

# Function to format disk names
format_disk_name() {
    local disk=$1
    if [[ "$disk" == "/dev/sda1" ]]; then
        echo "SYSTEM"
    else
        local mount_point=$(df -h | grep "$disk" | awk '{print $NF}')
        echo "${mount_point#/mnt/}"
    fi
}

# Initialize the temp file
: > "$TEMP_FILE" # Ensure we start with an empty temp file

# Check each disk and store the status in the temp file
for disk in "${DISKS[@]}"
do
    if [[ -e $disk || -d $disk ]]; then
        usage=$(check_disk_usage "$disk")
        if [ ! -z "$usage" ]; then
            echo "$disk $usage" >> "$TEMP_FILE"
        fi
    fi
done

# Initialize a variable to store the Telegram message
TELEGRAM="🚨 DISK USAGE ALERT 💽"
changed=false

# Read the previous statuses and compare with the new ones
if [[ -e "$LOG_FILE" ]]; then
    while IFS= read -r line
    do
        disk=$(echo "$line" | awk '{print $1}')
        old_usage=$(echo "$line" | awk '{print $NF}')
        new_usage=$(grep "$disk" "$TEMP_FILE" | awk '{print $NF}')
        
        if [ ! -z "$new_usage" ]; then
            disk_name=$(format_disk_name "$disk")
            if [ "$new_usage" -ge "$THRESHOLD" ] && [ "$old_usage" -lt "$THRESHOLD" ]; then
                TELEGRAM+="
$disk_name usage is at ${new_usage}%"
                changed=true
            elif [ "$new_usage" -lt "$THRESHOLD" ] && [ "$old_usage" -ge "$THRESHOLD" ]; then
                TELEGRAM+="
$disk_name usage is now at ${new_usage}% - resolved"
                changed=true
            fi
        fi
    done < "$LOG_FILE"
fi

# Debugging output
echo "Telegram message content:"
echo "$TELEGRAM"

# Send the notification if there are any changes
if $changed; then
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TELEGRAM" > /dev/null
fi

# Replace the log file with the temp file
mv "$TEMP_FILE" "$LOG_FILE"
