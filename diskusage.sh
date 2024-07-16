#!/bin/bash

# Configuration parameters
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXX"  # Telegram bot token
CHAT_ID="XXXXXXXX"  # Telegram chat ID


# Disks to monitor (add specific disks along with generic ones)
DISKS=("/mnt/CAKE" "/mnt/BOREALIS" "/dev/sda1" $(ls /dev/sd[b-z] /dev/sd[b-z][b-z] 2>/dev/null))

# Function to check disk usage
check_disk_usage() {
    local disk=$1
    if [[ "$disk" == "/mnt/CAKE" || "$disk" == "/mnt/BOREALIS" ]]; then
        df -h --output=pcent "$disk" | tail -n 1 | sed 's/%//g'
    else
        df -h | grep "$disk" | awk '{print $(NF-1)}' | sed 's/%//g'
    fi
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

# Initialize variables to store disk usage for SYSTEM, CAKE, and BOREALIS
SYSTEM_DISK=""
CAKE_DISK=""
BOREALIS_DISK=""
OTHER_DISKS=""

# Check each disk and categorize by SYSTEM, CAKE, or BOREALIS
for disk in "${DISKS[@]}"
do
    if [[ -e $disk || -d $disk ]]; then
        usage=$(check_disk_usage "$disk")
        if [ ! -z "$usage" ]; then
            disk_name=$(format_disk_name "$disk")
            if [[ "$disk_name" == "SYSTEM" ]]; then
                SYSTEM_DISK="$disk_name: ${usage}%"
            elif [[ "$disk_name" == "CAKE" ]]; then
                CAKE_DISK="${usage}%"
            elif [[ "$disk_name" == "BOREALIS" ]]; then
                BOREALIS_DISK="${usage}%"
            elif [[ "$disk_name" =~ ^disk-A ]]; then
                CAKE_DISK="$CAKE_DISK
 ⤷$disk_name: ${usage}%"
            elif [[ "$disk_name" =~ ^disk-B ]]; then
                BOREALIS_DISK="$BOREALIS_DISK
 ⤷$disk_name: ${usage}%"
            else
                OTHER_DISKS="$OTHER_DISKS
 ⤷$disk_name: ${usage}%"
            fi
        fi
    fi
done

# Construct Telegram message
TELEGRAM="📊 CURRENT DISK USAGE 💽

🌀 $SYSTEM_DISK"

if [ -n "$CAKE_DISK" ]; then
    TELEGRAM="$TELEGRAM

🎂 CAKE: $CAKE_DISK"
fi

if [ -n "$BOREALIS_DISK" ]; then
    TELEGRAM="$TELEGRAM

❄️ BOREALIS: $BOREALIS_DISK"
fi

if [ -n "$OTHER_DISKS" ]; then
    TELEGRAM="$TELEGRAM

Other Disks$OTHER_DISKS"
fi

# Debugging output
echo "Telegram message content:"
echo "$TELEGRAM"

# Send the notification
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TELEGRAM" > /dev/null
