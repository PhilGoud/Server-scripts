#!/bin/bash

# Check if a directory is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

DIR=$1

# Check if the provided argument is a directory
if [ ! -d "$DIR" ]; then
  echo "Error: $DIR is not a directory."
  exit 1
fi

# Get the size of the directory
DIR_SIZE=$(du -sh "$DIR" | cut -f1)

# Get the number of files in the directory
FILE_COUNT=$(find "$DIR" -type f | wc -l)

# Get the number of directories in the directory
DIR_COUNT=$(find "$DIR" -type d | wc -l)

# Output the results
echo "Directory: $DIR"
echo "Size: $DIR_SIZE"
echo "Number of files: $FILE_COUNT"
echo "Number of directories: $DIR_COUNT"
