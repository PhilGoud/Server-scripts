#!/bin/bash

# Vérifie si un répertoire a été fourni en argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Fonction pour organiser les fichiers dans des dossiers
organize_files() {
    local dir="$1"
    
    # Trouve tous les fichiers dans le répertoire et ses sous-répertoires
    find "$dir" -type f | while read file; do
        # Obtient le nom du fichier sans l'extension
        filename=$(basename "$file")
        base="${filename%.*}"
        
        # Crée un répertoire avec le nom de base s'il n'existe pas déjà
        mkdir -p "$dir/$base"
        
        # Déplace le fichier dans le répertoire correspondant
        mv "$file" "$dir/$base/"
    done
}

# Appelle la fonction avec le répertoire fourni en argument
organize_files "$1"

echo "Organisation terminée."
