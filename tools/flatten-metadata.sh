#!/bin/bash

# Vérifie si un argument est fourni
if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_to_flatten>"
    exit 1
fi

# Le répertoire à aplatir
base_dir="$1"

# Vérifie si le répertoire à aplatir existe
if [ ! -d "$base_dir" ]; then
    echo "Le répertoire à aplatir n'existe pas: $base_dir"
    exit 1
fi

# Trouve et déplace tous les fichiers avec les extensions spécifiées en ignorant la casse
find "$base_dir" -type f \( -iname "*.db" -o -iname "*.txt" -o -iname "*.nfo" -o -iname "*.xml" \) -exec sh -c '
for file do
    echo "Déplacement de $file vers $0"
    mv "$file" "$0"
done
' "$base_dir" {} +

echo "Opération terminée."
