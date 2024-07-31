#!/bin/bash

# Vérifie si un fichier a été fourni en argument
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

file=$1

# Vérifie si le fichier existe
if [ ! -f "$file" ]; then
    echo "Le fichier $file n'existe pas."
    exit 1
fi

last_line=""

while true; do
    # Lis la dernière ligne du fichier
    current_last_line=$(tail -n 5 "$file")

    # Si la dernière ligne a changé, met à jour et affiche la nouvelle ligne
    if [ "$current_last_line" != "$last_line" ]; then
        # Efface la ligne précédente et affiche la nouvelle
        printf "\r%s" "$current_last_line"
        last_line="$current_last_line"
    fi

    # Attends 1 seconde avant de vérifier à nouveau
    sleep 1
done
