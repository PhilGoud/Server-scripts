#!/bin/bash

# Ensure smartctl package is installed first! (apt-get install smartctl)
# Configuration parameters
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"  # Telegram bot token
CHAT_ID="TELEGRAM_CHATID_HERE"  # Telegram chat ID
# Initialize variables for categorized disks
system_disks=""
cake_disks=""
borealis_disks=""
other_disks=""

# Loop through all potential drives
for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   # Check the SMART temperature of the drive
   smart_temp=$(sudo smartctl -A $drive 2>/dev/null | grep 'Temperature_Celsius' | awk '{ print $10 }')
   [[ "$smart_temp" == "" ]] && smart_temp='unavailable'

   # Determine the disk mount point or identifier
   mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
   disk_identifier=""

   if [[ $drive == "/dev/sda" ]]; then
      disk_identifier="SYSTEM"
      system_disks="🌀 SYSTEM: ${smart_temp}°C"
   elif [[ $mount_point =~ /mnt/disk-A ]]; then
      disk_identifier="${mount_point#/mnt/}"
      cake_disks="$cake_disks\n ⤷${disk_identifier//disk-/}: ${smart_temp}°C"
   elif [[ $mount_point =~ /mnt/disk-B ]]; then
      disk_identifier="${mount_point#/mnt/}"
      borealis_disks="$borealis_disks\n ⤷${disk_identifier//disk-/}: ${smart_temp}°C"
   else
      disk_identifier="${mount_point#/mnt/}"
      other_disks="$other_disks\n ⤷$disk_identifier: ${smart_temp}°C"
   fi
done

# Sorting the disk entries
sorted_cake_disks=$(echo -e "$cake_disks" | sort)
sorted_borealis_disks=$(echo -e "$borealis_disks" | sort)
sorted_other_disks=$(echo -e "$other_disks" | sort)

# Compile the Telegram message
TELEGRAM="🌡️ DISK TEMPERATURES 💽"

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

curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
