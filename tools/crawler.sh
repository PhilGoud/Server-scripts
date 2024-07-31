#!/bin/bash

# Vérification du nombre d'arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <URL> <destination_directory>"
    exit 1
fi

# Assignation des arguments à des variables
base_url="$1"
destination_directory="$2"

echo "Démarrage de l'exploration du site : $base_url"
echo "Les données seront enregistrées dans : $destination_directory"

# Vérification de l'existence du dossier de destination
if [ ! -d "$destination_directory" ]; then
    echo "Le dossier de destination n'existe pas. Création du dossier..."
    mkdir -p "$destination_directory"
    if [ $? -ne 0 ]; then
        echo "Erreur : Impossible de créer le dossier de destination."
        exit 1
    fi
fi

# Utilisation de wget pour télécharger le site
echo "Téléchargement des données du site..."
sudo wget --recursive --no-parent --adjust-extension --convert-links --backup-converted --no-clobber --page-requisites --restrict-file-names=windows --directory-prefix="$destination_directory" --no-check-certificate "$base_url"

# Vérification du succès du téléchargement
if [ $? -ne 0 ]; then
    echo "Erreur : Le téléchargement des données a échoué."
    exit 1
fi

echo "Téléchargement terminé. Les données ont été enregistrées dans $destination_directory."
