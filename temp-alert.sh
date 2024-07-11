#!/bin/bash

# This script monitors the temperature of my external hard drives and sends alerts if the temperature is too high.
# If any drive temperature exceeds the threshold, it triggers the fans to cool them down via webhooks.

# Install the smartctl package first! (apt-get install smartctl)

# Parameters
TEMPERATURE_THRESHOLD=48  # Temperature threshold in Celsius for triggering alerts
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Telegram bot token
CHAT_ID="XXXXXXXXXXX"  # Telegram chat ID
FAN_ON_URL="http://192.168.1.10:8123/api/webhook/xxxxxxxxxxxxxxxx"  # URL to turn on the fans
FAN_OFF_URL="http://192.168.1.10:8123/api/webhook/xxxxxxxxxxxxxxxx"  # URL to turn off the fans

# Manage alerts
for drive in /dev/sd[b-z] /dev/sd[b-z][b-z]
do
   # Skip if the drive does not exist
   if [[ ! -e $drive ]]; then continue ; fi
   
   # Get the temperature of the drive using smartctl
   smart=$(
      sudo smartctl -a $drive 2>/dev/null | grep "Temperature_Celsius" | awk -F' ' '{print $10}' 
   )
   
   # If temperature information is not available, set it to 'unknown'
   [[ "$smart" == "" ]] && smart='unknown'
   
   # Check if the temperature exceeds the threshold
   if (("$smart" >= "$TEMPERATURE_THRESHOLD")); then
      # Get the mount point of the drive
      mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
      if [[ $mount_point =~ /mnt/disk-([a-zA-Z0-9]+) ]]; then
         disk_number="${BASH_REMATCH[1]}"
      else
         disk_number=$mount_point
      fi
      
      # Display the disk number and its temperature
      echo -n "$disk_number "
      echo "$smart°C"
      
      # Concatenate the disk number and temperature for the alert message
      smartconcat="$smartconcat 
$disk_number $smart°C"
      TELEGRAM="🔥 TEMP ALERT ❗ $smartconcat"
   fi
done

# Send Telegram notification if there is an alert
if [ -n "$smartconcat" ]; then
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
fi

# Manage the fans based on the temperature status
if [ -n "$smartconcat" ]; then
    # Turn on the fans if any drive exceeds the temperature threshold
    curl -s -X POST $FAN_ON_URL > /dev/null
else
    # Turn off the fans if no drive exceeds the temperature threshold
    curl -s -X POST $FAN_OFF_URL > /dev/null
fi
