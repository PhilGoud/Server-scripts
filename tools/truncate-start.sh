#!/bin/bash

# Vérifie si deux arguments sont fournis
if [ $# -ne 2 ]; then
    echo "Usage: $0 <number_of_characters_to_truncate> <directory>"
    exit 1
fi

# Le nombre de caractères à tronquer et le répertoire de base
num_chars="$1"
base_dir="$2"

# Vérifie si le répertoire de base existe
if [ ! -d "$base_dir" ]; then
    echo "Le répertoire de base n'existe pas: $base_dir"
    exit 1
fi

# Fonction pour tronquer les noms des fichiers et répertoires
truncate_names() {
    local dir="$1"
    local num_chars="$2"

    # Renommer les fichiers dans le répertoire courant
    for file in "$dir"/*; do
        if [ -e "$file" ]; then
            local base_name=$(basename "$file")
            local new_name="${base_name:$num_chars}"
            local new_path=$(dirname "$file")/"$new_name"

            # Renommer le fichier ou le répertoire
            mv "$file" "$new_path"

            # Si c'est un répertoire, appliquer récursivement
            if [ -d "$new_path" ]; then
                truncate_names "$new_path" "$num_chars"
            fi
        fi
    done
}

# Troncation des noms des fichiers et répertoires dans le répertoire de base
truncate_names "$base_dir" "$num_chars"

# Renommer les sous-répertoires dans le répertoire de base
for dir in "$base_dir"/*; do
    if [ -d "$dir" ]; then
        local base_name=$(basename "$dir")
        local new_name="${base_name:$num_chars}"
        local new_path=$(dirname "$dir")/"$new_name"
        
        # Renommer le répertoire
        mv "$dir" "$new_path"
    fi
done

# Renommer le répertoire de base lui-même
parent_dir=$(dirname "$base_dir")
base_name=$(basename "$base_dir")
new_base_name="${base_name:$num_chars}"
new_base_dir="$parent_dir/$new_base_name"

mv "$base_dir" "$new_base_dir"

echo "Renommage terminé. Nouveau nom du répertoire de base: $new_base_dir"
