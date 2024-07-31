#!/bin/bash

# Check if the user provided a directory

if [ -z "$1" ]; then

    echo "Usage: $0 <directory>"

    exit 1

fi

# Directory to process

DIRECTORY="$1"

# Function to remove accents

remove_accents() {

    echo "$1" | iconv -f utf8 -t ascii//TRANSLIT

}

# Process each file in the directory

for file in "$DIRECTORY"/*; do

    # Check if it's a file (not a directory)

    if [ -f "$file" ]; then

        # Get the base name of the file

        base_name=$(basename "$file")

        # Replace spaces with underscores, remove accents, and remove parentheses

        new_name=$(echo "$base_name" | tr ' ' '_' | remove_accents | tr -d '()')

        # Only rename if the name has changed

        if [ "$base_name" != "$new_name" ]; then

            mv "$file" "$DIRECTORY/$new_name"

        fi

    fi

done