#!/bin/bash

# Install the smartctl package first! (apt-get install smartctl)

# Temperature thresholds
TEMP_MAX=50
TEMP_MIN=45

# State file to store alert status
STATE_FILE="/DATA/log/tempalertstate.txt"

# Telegram variables
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"
CHAT_ID="TELEGRAM_CHATID_HERE"

# Read current alert status from the state file
if [[ ! -f "$STATE_FILE" ]]; then
  alert_mode="noalert"
  echo $alert_mode > "$STATE_FILE"
fi

state=$(head -n 1 "$STATE_FILE")
echo "old state = $state"

# Initialize variables for temperatures
max_temp_reached=false
all_below_min=true
overheat_disks=""

# Alert management
for drive in /dev/sd[b-z] /dev/sd[b-z][b-z]
do
   if [[ ! -e $drive ]]; then continue ; fi
   smart=$(sudo smartctl -a $drive 2>/dev/null | grep "Temperature_Celsius" | awk -F' ' '{print $10}')
   [[ "$smart" == "" ]] && smart='unknown'  
   
   if [ "$smart" != "unknown" ]; then
       if ((smart >= TEMP_MAX)); then
           max_temp_reached=true
           mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
           if [[ $mount_point =~ /mnt/disk-([a-zA-Z0-9]+) ]]; then
               disk_number="${BASH_REMATCH[1]}"
           else
               disk_number=$mount_point
           fi
           overheat_disks="$overheat_disks
   $disk_number: $smart°C"
       fi
       if ((smart >= TEMP_MIN)); then
           all_below_min=false
       fi
   fi
done

# Check alert conditions
if [ "$max_temp_reached" = true ]; then
    TELEGRAM="🔥 TEMP ALERT ❗ $overheat_disks"
    alert_mode="alert"
elif [ "$all_below_min" = true ]; then
    TELEGRAM="❄ TEMP ok
   All disks below $TEMP_MIN°C."
    alert_mode="noalert"
fi

# Send Telegram notifications if the alert state has changed
if [ $alert_mode != $state ]; then
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    echo "$alert_mode" > "$STATE_FILE"
    else
    echo "no telegram sent"
fi

# Update the state in the file
echo "new state = $state"

# Fan management
if [ "$alert_mode" = "alert" ]; then
    curl -s -X POST http://192.168.1.10:8123/api/webhook/-uPoJsuS8m8NYWnXPKqqWNsaL 
elif [ "$alert_mode" = "noalert" ]; then
    curl -s -X POST http://192.168.1.10:8123/api/webhook/-Oj9YBLTC-JO-HSjVYAmJdMqW 
fi

exit 0
