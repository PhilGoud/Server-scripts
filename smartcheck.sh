#!/bin/bash

# Ensure smartctl package is installed first! (apt-get install smartctl)

# Initialize variables for categorized disks
system_disks=""
cake_disks=""
borealis_disks=""
other_disks=""

# Loop through all potential drives
for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   # Check the SMART status of the drive
   smart_status=$(sudo smartctl -H $drive 2>/dev/null | grep '^SMART overall' | awk '{ print $6 }')
   [[ "$smart_status" == "" ]] && smart_status='unavailable'

   # Determine the disk mount point or identifier
   mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
   disk_identifier=""

   if [[ $drive == "/dev/sda" ]]; then
      disk_identifier="SYSTEM"
      system_disks="🌀 SYSTEM: $smart_status"
   elif [[ $mount_point =~ /mnt/disk-A ]]; then
      disk_identifier="${mount_point#/mnt/}"
      cake_disks="$cake_disks\n ⤷${disk_identifier//disk-/}: $smart_status"
   elif [[ $mount_point =~ /mnt/disk-B ]]; then
      disk_identifier="${mount_point#/mnt/}"
      borealis_disks="$borealis_disks\n ⤷${disk_identifier//disk-/}: $smart_status"
   else
      disk_identifier="${mount_point#/mnt/}"
      other_disks="$other_disks\n ⤷$disk_identifier: $smart_status"
   fi
done

# Sorting the disk entries
sorted_cake_disks=$(echo -e "$cake_disks" | sort)
sorted_borealis_disks=$(echo -e "$borealis_disks" | sort)
sorted_other_disks=$(echo -e "$other_disks" | sort)

# Compile the Telegram message
TELEGRAM="📊 SMART STATE 💽"

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

❄️ BOREALIS:$sorted_borealis_disks"
fi

if [ -n "$sorted_other_disks" ]; then
  TELEGRAM="$TELEGRAM

Other Disks:$sorted_other_disks"
fi

# Send the Telegram notification
TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
CHAT_ID="HERE_YOUR_CHATID"
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
