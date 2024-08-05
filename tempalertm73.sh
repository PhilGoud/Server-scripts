#!/bin/bash

# Install the smartctl package and cpufrequtils! (apt-get install smartctl / apt-get install cpufrequtils) 
 
# Define the single drive
drive="/dev/sda"
name="SSD"
 
# Temperature thresholds
TEMP_MAX=60
TEMP_MIN=45

# State file to store alert status
STATE_FILE="/DATA/log/tempalertstatem73.txt"

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
if [[ -e $drive ]]; then
    smart=$(sudo smartctl -a $drive 2>/dev/null | grep "Temperature_Celsius" | awk -F' ' '{print $10}')
    [[ "$smart" == "" ]] && smart='unknown'  

    if [ "$smart" != "unknown" ]; then
        if ((smart >= TEMP_MAX)); then
            max_temp_reached=true
            overheat_disk="$name: $smart°C"
        fi
        if ((smart >= TEMP_MIN)); then
            all_below_min=false
        fi
    fi
fi

# Check alert conditions
if [ "$max_temp_reached" = true ]; then
    alert_mode="max"
    GOVERNOR=powersave
    TELEGRAM="🔥 TEMP ALERT ❗ 
$overheat_disk
CPU switched to $GOVERNOR"
elif [ "$all_below_min" = true ]; then
    alert_mode="min"
    GOVERNOR=ondemand
    TELEGRAM="❄ TEMP OK
$name below $TEMP_MIN°C
CPU switched to $GOVERNOR"
else
    alert_mode="mid"
    GOVERNOR=conservative
    TELEGRAM="🌡️ TEMP INFO
$name between $TEMP_MIN°C and $TEMP_MAX°C
CPU switched to $GOVERNOR"
fi

# Send Telegram notifications if the alert state has changed
if [ "$alert_mode" != "$state" ]; then
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    echo "$alert_mode" > "$STATE_FILE"
    echo "[SENT] $TELEGRAM"
    else
    echo "[NOT SENT] $TELEGRAM"
fi

# Update the state in the file
newstate=$(head -n 1 "$STATE_FILE")
echo "new state = $newstate"

# Apply the CPU frequency governor to all cores
for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
  sudo cpufreq-set -c "${CPU##*/cpu}" -g $GOVERNOR
done

# Check if the command was successful
if [ $? -eq 0 ]; then
  echo "The CPU power mode has been changed to '$GOVERNOR'."
else
  echo "Error changing the CPU power mode."
  exit 1
fi

exit 0
