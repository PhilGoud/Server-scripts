#!/bin/bash

# Check if directory is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Base directory to start renaming files
BASE_DIR="$1"

# Iterate through all files in the directory and its subdirectories
find "$BASE_DIR" -type f | while read -r FILE; do
  # Get the directory name (one level up)
  DIR_NAME=$(basename "$(dirname "$FILE")")

  # Get the file name and extension
  FILE_NAME=$(basename "$FILE")
  
  # New file name with directory name prefix
  NEW_NAME="${DIR_NAME}-${FILE_NAME}"

  # Full path to the new file
  NEW_FILE_PATH="$(dirname "$FILE")/$NEW_NAME"

  # Rename the file
  mv "$FILE" "$NEW_FILE_PATH"
done
