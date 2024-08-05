#!/bin/bash

# Ensure necessary packages like 'df' and 'lsblk' are available

# Configuration parameters
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"  # Telegram bot token
CHAT_ID="TELEGRAM_CHATID_HERE"  # Telegram chat ID

# Initialize variables for categorized disks
system_disks=""
cake_disks=""
borealis_disks=""
other_disks=""

# Define the emoji array from high usage (red) to low usage (purple)
emojis=("🔴" "🟠" "🟡" "🟢" "🟣" "⚪")

# Function to get the appropriate emoji based on disk usage percentage
get_emoji() {
    local percentage=$1
    if [ "$percentage" -ge 95 ]; then
        echo "${emojis[0]}"
    elif [ "$percentage" -ge 90 ]; then
        echo "${emojis[1]}"
    elif [ "$percentage" -ge 75 ]; then
        echo "${emojis[2]}"
    elif [ "$percentage" -ge 50 ]; then
        echo "${emojis[3]}"
    elif [ "$percentage" -ge 25 ]; then
        echo "${emojis[4]}"
    else
        echo "${emojis[5]}"
    fi
}

# Loop through all potential drives
for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   # Get the disk usage information
   usage_info=$(df -h | grep "$drive" | awk '{print $3 "/" $2 " (" $5 ")"}')
   usage_percentage=$(echo "$usage_info" | grep -oP '\d+(?=%)')

   [[ "$usage_info" == "" ]] && usage_info='unavailable'
   [[ "$usage_percentage" == "" ]] && usage_percentage=0

   # Get the corresponding emoji for the usage
   emoji=$(get_emoji "$usage_percentage")

   # Determine the disk mount point or identifier
   mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
   disk_identifier=""

   if [[ $drive == "/dev/sda" ]]; then
      disk_identifier="SYSTEM"
      system_disks="🌀 SYSTEM: $usage_info $emoji"
   elif [[ $mount_point =~ /mnt/disk-A ]]; then
      disk_identifier="${mount_point#/mnt/}"
      cake_disks="$cake_disks\n ⤷${disk_identifier//disk-/}: $usage_info $emoji"
   elif [[ $mount_point =~ /mnt/disk-B ]]; then
      disk_identifier="${mount_point#/mnt/}"
      borealis_disks="$borealis_disks\n ⤷${disk_identifier//disk-/}: $usage_info $emoji"
   else
      disk_identifier="${mount_point#/mnt/}"
      other_disks="$other_disks\n ⤷$disk_identifier: $usage_info $emoji"
   fi
done

# Sorting the disk entries
sorted_cake_disks=$(echo -e "$cake_disks" | sort)
sorted_borealis_disks=$(echo -e "$borealis_disks" | sort)
sorted_other_disks=$(echo -e "$other_disks" | sort)

# Compile the Telegram message
TELEGRAM="💾 DISK USAGE 💽"

if [ -n "$system_disks" ]; then
  TELEGRAM="$TELEGRAM

$system_disks"
fi

if [ -n "$sorted_cake_disks" ]; then
  TELEGRAM="$TELEGRAM

🎂 CAKE:$sorted_cake_disks"
fi

if [ -n "$sorted_borealis_disks" ]; then
  TELEGRAM="$TELEGRAM

🧊 BOREALIS:$sorted_borealis_disks"
fi

if [ -n "$sorted_other_disks" ]; then
  TELEGRAM="$TELEGRAM

Other Disks:$sorted_other_disks"
fi

# Send the Telegram notification
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
