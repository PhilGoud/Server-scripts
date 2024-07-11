#!/bin/bash

# This script monitors memory usage and restarts non-essential Docker containers if memory usage exceeds 90%. 
# It sends a Telegram notification when this action is taken.

# Parameters
MEMORY_THRESHOLD=90  # Memory usage percentage threshold
NON_ESSENTIAL_DOCKERS=("container1" "container2" "container3")  # List of non-essential Docker containers
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Telegram bot token
CHAT_ID="XXXXXXX"  # Telegram chat ID

# Check memory usage in percentage
memory_usage=$(free | awk '/Mem:/ { printf("%.0f"), $3/$2*100 }')

# Function to stop non-essential Docker containers
stop_dockers() {
    for container in "${NON_ESSENTIAL_DOCKERS[@]}"; do
        docker stop "$container"
    done
}

# Function to start non-essential Docker containers
start_dockers() {
    for container in "${NON_ESSENTIAL_DOCKERS[@]}"; do
        docker start "$container"
    done
}

# If memory usage is greater than the threshold
if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
    echo "Memory usage: $memory_usage%. Stopping and restarting non-essential Docker containers."
    
    # Stop non-essential Docker containers
    stop_dockers
    
    # Start non-essential Docker containers
    start_dockers
    
    # Telegram notification
    TELEGRAM_MESSAGE="RAM at $memory_usage%
Non-essential Docker containers have been restarted."
    
    # Send a Telegram message with the memory usage and action taken
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM_MESSAGE" > /dev/null
    
else
    echo "Memory usage: $memory_usage%. No action taken."
fi
