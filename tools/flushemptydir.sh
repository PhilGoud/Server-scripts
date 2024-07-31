#!/bin/bash

# Vérifie si un répertoire a été fourni en argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

target_directory=$1

# Fonction pour supprimer les dossiers vides
remove_empty_dirs() {
    find "$1" -type d -empty -delete
}

echo "Suppression des dossiers et sous-dossiers vides dans: $target_directory"

# Appelle la fonction avec le répertoire fourni en argument
remove_empty_dirs "$target_directory"

echo "Suppression terminée."
