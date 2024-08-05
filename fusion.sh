#!/bin/bash

# Vérifie si un argument est fourni
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Le répertoire de base à traiter
base_dir="$1"

# Vérifie si le répertoire de base existe
if [ ! -d "$base_dir" ]; then
    echo "Le répertoire de base n'existe pas: $base_dir"
    exit 1
fi

echo "Début du traitement des sous-répertoires dans: $base_dir"

# Boucle sur chaque sous-répertoire du répertoire de base
for sub_base in "$base_dir"/*; do
    if [ -d "$sub_base" ]; then
        echo "Traitement du sous-répertoire: $sub_base"

        # Le nom du sous-répertoire sans le chemin
        sub_base_name=$(basename "$sub_base")

        # Boucle sur les répertoires qui commencent par le nom du sous-répertoire de base
        for dir in "${sub_base}"*; do
            if [ -d "$dir" ] && [ "$dir" != "$sub_base" ]; then
                echo "Déplacement du contenu de $dir vers $sub_base"
                mv "$dir"/* "$sub_base"/
                rmdir "$dir"
            fi
        done

        echo "Fusion des répertoires terminée dans: $sub_base"

        # Supprimer les répertoires vides
        echo "Suppression des répertoires vides dans: $sub_base"
        find "$sub_base" -type d -empty -delete

        echo "Suppression des répertoires vides terminée dans: $sub_base"
    fi
done

echo "Traitement terminé pour tous les sous-répertoires dans: $base_dir"
