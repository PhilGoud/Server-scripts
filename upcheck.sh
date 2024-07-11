#!/bin/bash

# This script checks the status of multiple websites/services and sends a Telegram notification
# if any of their statuses change. It uses curl to check if each URL is reachable and compares
# the current status with the previous status stored in a log file.

# Define the list of names and URLs to check
declare -A SITES
SITES=(
    ["🎟️ Jellyfin"]="http://192.168.1.10:8096"
    ["🎟️ Plex"]="http://192.168.1.10:32400"
    ["📚 Calibre Web"]="http://192.168.1.10:8083"
    ["🔄 Syncthing"]="http://192.168.1.10:8384"
    ["📷 Immich"]="http://192.168.1.10:2283"
    ["🤝 PairDrop"]="http://192.168.1.10:6473"
    ["🧊 Companion Cube"]="http://192.168.1.10:333"
    ["🌍 JDownloader"]="http://192.168.1.10:5801"
    ["🏴‍☠ Transmission"]="http://192.168.1.10:9091"
    ["🕵🏻 Prowlarr"]="http://192.168.1.10:9696"
    ["🎬 Radarr"]="http://192.168.1.10:7878"
    ["💬 Bazarr"]="http://192.168.1.10:6767"
    ["💿 Lidarr"]="http://192.168.1.10:36975"
    ["📺 Sonarr"]="http://192.168.1.10:8989"
    ["🏚️ Home Automation"]="http://192.168.1.10:8123"
    ["🛡️ Adguard DNS"]="http://192.168.1.10:8080"
)

# File to store the statuses
LOG_FILE="/DATA/log/upcheck.txt"
TEMP_FILE="/DATA/log/upcheck-temp.txt"

# Telegram bot details
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXXXXXXXXX"

# Function to check if a website is up
check_site() {
    local url=$1
    if curl -s --head "$url" | grep "HTTP" > /dev/null
    then
        echo "✅"
    else
        echo "❌"
    fi
}

# Initialize the temp file
: > "$TEMP_FILE" # Ensure we start with an empty temp file

# Check each site and store the status in the temp file
for name in "${!SITES[@]}"
do
    url=${SITES[$name]}
    status=$(check_site "$url")
    clean_name=$(echo "$name" | tr ' ' '_')
    echo "$clean_name $status" >> "$TEMP_FILE" # Write to temp file in order
done

# Initialize a variable to store the Telegram message
TELEGRAM="🛜 UPCHECK
"
changed=false

# Read the previous statuses and compare with the new ones
while IFS= read -r line
do
    clean_name=$(echo "$line" | awk '{print $1}')
    old_status=$(echo "$line" | awk '{print $NF}')
    new_status=$(grep "$clean_name" "$TEMP_FILE" | awk '{print $NF}')
    if [ "$old_status" != "$new_status" ]; then
        name=$(echo "$clean_name" | tr '_' ' ')
        TELEGRAM+="
$name $new_status"
        changed=true
    fi
done < "$LOG_FILE"

# Send the notification if there are any changes
if $changed; then
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TELEGRAM" > /dev/null
fi

# Replace the log file with the temp file
mv "$TEMP_FILE" "$LOG_FILE"
