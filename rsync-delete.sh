#!/bin/bash

# This script performs backups using rsync for various directories to a remote storage.
# It logs the progress and errors, and sends a Telegram notification upon completion and/or in case of an error.

# Parameters
BACKUPDIR="/mnt/TRASH/" #Path to where deleted files will be sent
BACKUPAGE="90" #Number of days to keep files in backup directory
BACKUPTESTFILE="/mnt/TRASH/.TRASH" #File to test in the backup folder
LOG_FILE="/DATA/log/rsync/log-delete.txt"  # Path to the main log file
TEMP_LOG_FILE="/DATA/log/rsync/logtemp-delete.txt"  # Path to the temporary log file
TEST_LOG_FILE="/DATA/log/rsync/testlog-delete.txt"  # Path to the test log file
TEST_TEMP_LOG_FILE="/DATA/log/rsync/testlogtemp-delete.txt"  # Path to the temporary test log file
ERRORS="/DATA/log/rsync/errors-delete.txt"
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"  # Telegram bot token
CHAT_ID="TELEGRAM_CHATID_HERE"  # Telegram chat ID

# Directories, destinations, and names in the format: "source_directory|destination_directory|name|min-size(MB)"
	JOBS=(
    	"/scripts|/mnt/BOREALIS/scripts|🛠️ scripts|0,1"
        "/mnt/CAKE/Misc|/mnt/BOREALIS/Misc|🎛️ Misc|0,001"
		"/var/lib/casaos|/mnt/BOREALIS/casaos|🐋 CasaOS|50"
        "/DATA/AppData|/mnt/BOREALIS/AppData|💾 AppData|5000"
		"/mnt/CAKE/Famille|/mnt/BOREALIS/Famille|📽️ Famille|46000"
		"/mnt/CAKE/Photos|/mnt/BOREALIS/Photos|📷 Photos|180000"
		"/mnt/CAKE/Musique|/mnt/BOREALIS/Musique|🎧 Musique|70000"
		"/mnt/CAKE/AudioBooks|/mnt/BOREALIS/AudioBooks|🗣 AudioBooks|20000"
		"/mnt/CAKE/Podcasts|/mnt/BOREALIS/Podcasts|🎙️ Podcast|100000"
		"/mnt/CAKE/ASoundMR|/mnt/BOREALIS/ASoundMR|🪶 ASoundMR|250000"
		"/mnt/CAKE/Documents|/mnt/BOREALIS/Documents|🗃️ Documents|38000"
		"/mnt/CAKE/GDrive|/mnt/BOREALIS/GDrive|☁️ GDrive|8000"
		"/mnt/CAKE/Bibliothèque|/mnt/BOREALIS/Bibliothèque|📚 Bibliothèque|7000"
		"/mnt/CAKE/Vidéos|/mnt/BOREALIS/Vidéos|🎦 Vidéos|3000"
		"/mnt/CAKE/Films|/mnt/BOREALIS/Films|🎬 Films|1000000"
		"/mnt/CAKE/Séries|/mnt/BOREALIS/Séries|📺 Séries|1000000"

	)

# INITIALISATION
	# Calculate the number of directories
	NUMBER_OF_DIRECTORIES=${#JOBS[@]}
	echo "" > "$ERRORS"
	check=0
    #remove old files (never folders) from backup
  #  find $BACKUPDIR* -mtime +$BACKUPAGE -exec rm {} \;
	
# Mounting trash volume
	sudo mount $BACKUPDIR &> /dev/null
    sleep 10 
	
    if [ ! -f $BACKUPTESTFILE ]; then
		echo "BACKUP NOT MOUNTED : CANCELLED"
		curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="⚠️ BACKUP RSYNC-DELETE FAILED ⚠️
	FAILED : BACKUP NOT MOUNTED " > /dev/null
		exit
	else
		echo "BACKUP DISK CHECK PASSED"
		echo ""
	fi



# Start of the backup process
	echo "📦 BACKUP RSYNC-DELETE 🔄" > "$LOG_FILE"
	echo "Start at $(date +"%H:%M:%S")" >> "$LOG_FILE"

# Loop through each job and perform the backup
	for job in "${JOBS[@]}"; do
		IFS='|' read -r SRC DEST NAME MIN_SIZE<<< "$job"

		created_files=""
		deleted_files=""
		transferred_files=""
		echo $NAME
		echo "RSYNC from $SRC to $DEST" > "$TEMP_LOG_FILE"
		
		
		# Check if source folder is <1Mo (prevents empty mount point)
		#Get size
		size=$(du -sb "$SRC" | cut -f1)
		# Convert 1 MB in B
		MIN_SIZE_BYTE=$(("$MIN_SIZE"*1024))
	  if [ "$size" -gt "$MIN_SIZE_BYTE" ]; then
			echo "Size check: OK"

			# Rsync to backup
			   echo "Executing RSYNC-DELETE"
			   sudo rsync -avP --partial --stats --delete-after --backup --backup-dir "$BACKUPDIR/$NAME" "$SRC/" "$DEST" &>> "$TEMP_LOG_FILE"

			# Extract the relevant statistics
				created_files=$(grep -e '^Number of created files:' "$TEMP_LOG_FILE" | awk -F 'files: ' '{print $2}')
				deleted_files=$(grep -e '^Number of deleted files:' "$TEMP_LOG_FILE" | awk -F 'files: ' '{print $2}')
				transferred_files=$(grep -e '^Number of regular files transferred:' "$TEMP_LOG_FILE" | awk '{print $6}')
				transferred_size_line=$(grep -e '^Total transferred file size:' "$TEMP_LOG_FILE")
				transferred_size=$(echo $transferred_size_line | awk '{print $5}' | tr -d '.')

			# Extract numeric values for comparison
				created_files_num=$(echo $created_files | awk '{print $1}')
				deleted_files_num=$(echo $deleted_files | awk '{print $1}')
				transferred_files_num=$(echo $transferred_files | awk '{print $1}')

			# Log errors and warnings
				grep -e '^error^' "$TEMP_LOG_FILE" | tail -1 >> "$LOG_FILE"
				grep -e '^warning^' "$TEMP_LOG_FILE" | tail -1 >> "$LOG_FILE"

			# CHANGE OUTPUT MESSAGE IF THERE IS CHANGES OR NOT
			
			if [[ "$created_files_num" == "0" ]] && [[ "$deleted_files_num" == "0" ]] && [[ "$transferred_files_num" == "0" ]]; then
				echo "$NAME ✔️" >> "$LOG_FILE"
				check=$(($check + 1))
				echo "No change"
				echo ""
			else
				echo "C $created_files D $deleted_files T $transferred_files"
				echo "" >> "$LOG_FILE"
                echo "$NAME" >> "$LOG_FILE"
				echo "  C $created_files | D $deleted_files | T $transferred_files" >> "$LOG_FILE"
                # Function to convert bytes to human-readable format
					convert_bytes() {
					local bytes=$1
					if (( bytes >= 1073741824 )); then
						printf "%.0f Go\n" "$(bc <<< "scale=0; $bytes/1073741824")"
					elif (( bytes >= 1048576 )); then
						printf "%.0f Mo\n" "$(bc <<< "scale=0; $bytes/1048576")"
					elif (( bytes >= 1024 )); then
						printf "%.0f Ko\n" "$(bc <<< "scale=0; $bytes/1024")"
					else
						printf "%d octets\n" "$bytes"
					fi
					}
				echo "  Data: $(convert_bytes $transferred_size)" >> "$LOG_FILE"
                echo "" >> "$LOG_FILE"
				echo ""
			fi

		else
			echo "Size check : FAILED"
			echo "⚠️ Source smaller than $MIN_SIZE MB !" >> "$LOG_FILE"
		fi

	done

# End of the backup process
echo "End at $(date +"%H:%M:%S")" >> "$LOG_FILE"

# Send Telegram notification only if something happened
	if [ $check != $NUMBER_OF_DIRECTORIES ]; then
		# Telegram notification configuration
			TELEGRAM=$(cat "$LOG_FILE")  # Get the content of the log file
			LENGTH=${#TELEGRAM}  # Get the length of the log content

		# Determine the type of message to send based on length
			if ((LENGTH < 1000)); then
				# Send full Telegram notification if the message is less than 1000 characters
				curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$TELEGRAM" > /dev/null
			else
				# Send a summary notification if the message is too long
				curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="📦 BACKUP RSYNC 🆗
				$LOG_FILE contains $LENGTH characters" > /dev/null
			fi
	else 
		echo "Nothing has changed!"
		echo "$check / $NUMBER_OF_DIRECTORIES DIRECTORIES IN SYNC"
	fi
