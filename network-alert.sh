#!/bin/bash

#THIS SCRIPT WILL NOTIFY YOU WHEN YOUR INTERNET CONSUMPTION (EXCLUDING LOCAL DATA) IS ABOVE A CERTAIN LIMIT, AND WILL GIVE YOU THE IP COMMUNICATING WITH YOU

# Network interface to monitor
INTERFACE="eno1"
DURATION=10  # Duration in seconds to capture traffic
WHITELIST_IP=("192.168.1" "10.8.0")  # Add other IP prefixes to ignore if necessary LOCAL | VPN 
downloadlimit=6144 # Download limit in KB
uploadlimit=1024 # Upload limit in KB
STATE_FILE="/DATA/log/networkalertstate.txt" # File to store the alert state

# Telegram Bot configuration
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXXXXX"

# Read the current alert state from the file if it exists, otherwise initialize the state
if [[ -f "$STATE_FILE" ]]; then
  source "$STATE_FILE"
else
  alertmodedown=false
  alertmodeup=false
fi

# Run iftop to monitor network traffic and capture the output
IFTOP_LOG=$(sudo iftop -t -n -i $INTERFACE -B -s $DURATION 2>&1)

# Read the content of IFTOP_LOG and process the lines
IFS=$'\n' read -d '' -r -a lines <<< "$IFTOP_LOG"

# Iterate through the lines to modify IP addresses on lines with '=>'
for ((i = 0; i < ${#lines[@]}; i++)); do
  if [[ "${lines[$i]}" =~ "=>" ]]; then
    if [[ $i -lt $((${#lines[@]} - 1)) ]]; then
      next_line="${lines[$i + 1]}"
      ip=$(echo "$next_line" | awk '{print $1}')
      modified_line=$(echo "${lines[$i]}" | sed -E "s/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/$ip/")
      lines[$i]="$modified_line"
    fi
  fi
done

# Concatenate the modified lines
IFTOP_IP=$(printf "%s\n" "${lines[@]}")

# Filter lines where the IP starts with one of the IPs in WHITELIST_IP
IFTOP_IP_FILTERED="$IFTOP_IP"
for whitelist_ip in "${WHITELIST_IP[@]}"; do
  IFTOP_IP_FILTERED=$(echo "$IFTOP_IP_FILTERED" | grep -v "$whitelist_ip")
done

# Separate download (=>) and upload (<=) lines
IFTOP_IP_DOWNLOAD=$(echo "$IFTOP_IP_FILTERED" | grep "<=")
IFTOP_IP_UPLOAD=$(echo "$IFTOP_IP_FILTERED" | grep "=>")

# Function to convert sizes to KB
convert_to_kb() {
  local size=$1
  local unit=$2
  local size_kb=0

  # Convert sizes based on the unit (MB, KB, or B)
  if [[ "$unit" =~ ^MB ]]; then
    size_kb=$(echo "$size * 1024" | bc)
  elif [[ "$unit" =~ ^B ]]; then
    size_kb=$(echo "$size / 1024" | bc)
  elif [[ "$unit" =~ ^KB ]]; then
    size_kb=$size
  fi

  echo "$size_kb"
}

# Convert download sizes to KB and calculate the total sum
total_download_kb=0
while IFS= read -r line; do
  line=$(echo "$line" | sed 's/,/./g')
  size=$(echo "$line" | awk '{print $NF}' | grep -oE '[0-9]+(\.[0-9]+)?')
  unit=$(echo "$line" | awk '{print $NF}' | grep -oE '[a-zA-Z]+')
  size_kb=$(convert_to_kb "$size" "$unit")
  total_download_kb=$(echo "$total_download_kb + $size_kb" | bc)
done <<< "$IFTOP_IP_DOWNLOAD"

# Convert upload sizes to KB and calculate the total sum
total_upload_kb=0
while IFS= read -r line; do
  line=$(echo "$line" | sed 's/,/./g')
  size=$(echo "$line" | awk '{print $NF}' | grep -oE '[0-9]+(\.[0-9]+)?')
  unit=$(echo "$line" | awk '{print $NF}' | grep -oE '[a-zA-Z]+')
  size_kb=$(convert_to_kb "$size" "$unit")
  total_upload_kb=$(echo "$total_upload_kb + $size_kb" | bc)
done <<< "$IFTOP_IP_UPLOAD"

# Calculate speeds in KB/s
download_speed_kbps=$(echo "$total_download_kb / $DURATION" | bc)
upload_speed_kbps=$(echo "$total_upload_kb / $DURATION" | bc)

# Display the final result
echo "Total download: ${download_speed_kbps} KB/s"
echo "Total upload: ${upload_speed_kbps} KB/s"

# Alert triggering conditions
if (( $(echo "$download_speed_kbps > $downloadlimit" | bc -l) )); then
  # Extract the IPs and the amount of data consumed
  SUMMARY=$(echo "$IFTOP_IP_DOWNLOAD" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}.*([0-9]+[a-zA-Z]{1,2})$' | awk '{print $1, $(NF-1)}')
  TELEGRAMDOWN=$(echo "🚨 Alert 🛜 
Download: $download_speed_kbps KB/s
$SUMMARY")
  alertmodedown=true 
else
  alertmodedown=false
  TELEGRAMDOWN=$(echo "✅ Alert ended 🛜 
Download: $download_speed_kbps KB/s")
fi

if (( $(echo "$upload_speed_kbps > $uploadlimit" | bc -l) )); then
  # Extract the IPs and the amount of data consumed
  SUMMARY=$(echo "$IFTOP_IP_UPLOAD" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}.*([0-9]+[a-zA-Z]{1,2})$' | awk '{print $1, $(NF-1)}')
  # Send the alert
  TELEGRAMUP=$(echo "🚨 Alert 🛜 
Upload: $upload_speed_kbps KB/s
$SUMMARY")
  alertmodeup=true
else
  alertmodeup=false
  TELEGRAMUP=$(echo "✅ Alert ended 🛜 
Upload: $upload_speed_kbps KB/s")
fi

# Check if there was a change in state
if [[ "$alertmodedown" != "$ALERT_MODE_DOWN" ]]; then
  echo "State change detected for alertmodedown."
  if [[ "$alertmodedown" == true ]]; then
    # Send the Telegram notification for alertmodedown
    echo "Sending Telegram notification for alertmodedown."
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMDOWN" > /dev/null
  else
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMDOWN" > /dev/null
  fi
fi

if [[ "$alertmodeup" != "$ALERT_MODE_UP" ]]; then
  echo "State change detected for alertmodeup."
  if [[ "$alertmodeup" == true ]]; then
    # Send the Telegram notification for alertmodeup
    echo "Sending Telegram notification for alertmodeup."
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMUP" > /dev/null
  else 
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMUP" > /dev/null
  fi
fi

# Update the state in the file
echo "ALERT_MODE_DOWN=$alertmodedown" > "$STATE_FILE"
echo "ALERT_MODE_UP=$alertmodeup" >> "$STATE_FILE"

exit 0
