#!/bin/bash

# Vérifie si trois arguments sont fournis
if [ $# -ne 3 ]; then
    echo "Usage: $0 <directory_to_scan> <string_to_search> <output_file>"
    exit 1
fi

# Le répertoire à scanner, la chaîne à rechercher et le fichier de sortie
base_dir="$1"
search_string="$2"
output_file="$3"

# Vérifie si le répertoire à scanner existe
if [ ! -d "$base_dir" ]; then
    echo "Le répertoire à scanner n'existe pas: $base_dir"
    exit 1
fi

# Initialisation du fichier de sortie
echo "Liste des fichiers et dossiers contenant '$search_string' (ignorant la casse) dans '$base_dir':" > "$output_file"
echo "-------------------------------------------------------------" >> "$output_file"

# Recherche des fichiers et dossiers contenant la chaîne
find "$base_dir" -type f -iname "*$search_string*" -o -type d -iname "*$search_string*" >> "$output_file"

echo "Recherche terminée. Les résultats ont été enregistrés dans '$output_file'."
