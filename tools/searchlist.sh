#!/bin/bash

# Vérifie si les arguments nécessaires ont été fournis
if [ $# -ne 2 ]; then
    echo "Usage: $0 <string> <directory>"
    exit 1
fi

search_string=$1
target_directory=$2

# Vérifie si le répertoire cible existe
if [ ! -d "$target_directory" ]; then
    echo "Le répertoire spécifié n'existe pas: $target_directory"
    exit 1
fi

# Fonction pour lister les fichiers contenant la chaîne de caractères
list_files() {
    local string=$1
    local directory=$2

    # Trouver les fichiers et stocker les résultats dans un tableau
    IFS=$'\n' read -d '' -r -a files < <(find "$directory" -type f -iname "*$string*" && printf '\0')

    # Afficher les fichiers trouvés avec le chemin relatif
    for file in "${files[@]}"; do
        echo "${file#$directory/}"
    done

    # Afficher le nombre total de fichiers trouvés
    echo "Nombre total de fichiers trouvés: ${#files[@]}"
}

echo "Recherche des fichiers contenant '$search_string' dans le répertoire: $target_directory"

# Appelle la fonction avec la chaîne de caractères et le répertoire cible
list_files "$search_string" "$target_directory"

echo "Recherche terminée."
