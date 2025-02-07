#!/bin/bash

#!/bin/bash

# Vérification si le script est exécuté en sudo
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo ou en tant que root." >&2
  exit 1
fi

# Fonction pour demander confirmation
demander_confirmation() {
    while true; do
        read -p "$1 (O/n) : " reponse
        case "$reponse" in
            [O]|"") return 0 ;;  # Par défaut, on considère "O" ou entrée comme "Oui"
            [nN]) return 1 ;;
            *) echo "Réponse invalide, entrez 'O' pour Oui ou 'N' pour Non." ;;
        esac
    done
}

# test initial
if demander_confirmation "Est-ce que tu es inattentif ?"; then
    exit 0
fi

# Mise à jour du système
if demander_confirmation "Voulez-vous mettre à jour le système ?"; then
    sudo apt-get update && sudo apt-get upgrade -y
fi

if demander_confirmation "Voulez-vous installer des packets ?"; then
    # Vérification de l'existence du fichier packets.list
    # Chemin du répertoire du script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PACKET_FILE="$SCRIPT_DIR/installpackets.list"

    if [[ ! -f "$PACKET_FILE" ]]; then
        echo "Fichier $PACKET_FILE introuvable. Veuillez créer ce fichier avec la liste des paquets."
        exit 1
    fi

    # Lecture du fichier, suppression des lignes vides et des commentaires
    mapfile -t paquets < <(grep -Ev '^\s*$|^\s*#' "$PACKET_FILE")

    if [[ ${#paquets[@]} -eq 0 ]]; then
        echo "Le fichier $PACKET_FILE est vide."
        exit 1
    fi

    echo "Voici les paquets disponibles pour l'installation :"
    printf "%s\n" "${paquets[@]}"

    # Demande à l'utilisateur de choisir l'option
    read -p "Voulez-vous installer tous les paquets (O/n) ? " choix

    if [[ "$choix" =~ ^[Oo]$|^$ ]]; then
        echo "Installation de tous les paquets..."
        sudo apt-get update
        sudo apt-get install -y "${paquets[@]}"
    else
        echo "Installation des paquets un par un."
        for paquet in "${paquets[@]}"; do
            read -p "Voulez-vous installer $paquet (O/n) ? " reponse
            if [[ "$reponse" =~ ^[Oo]$|^$ ]]; then
                sudo apt-get install -y "$paquet"
            fi
        done
    fi
fi

# test initial
if demander_confirmation "Est-ce que tu veux toucher à CASAOS ?"; then
    # Suppression de CasaOS
    if demander_confirmation "Voulez-vous supprimer CasaOS ?"; then
        sudo casaos-uninstall
    fi

    # Installation de CasaOS
    if demander_confirmation "Voulez-vous installer CasaOS ?"; then
        sudo curl -fsSL https://get.casaos.io | sudo bash
    fi

    # MaJ de CasaOS
    if demander_confirmation "Voulez-vous mettre à jour CasaOS ?"; then
        curl -fsSL https://get.casaos.io/update | sudo bash
    fi

fi

if demander_confirmation "Voulez-vous modifier les utilisateurs ?"; then

    # Ajout de phil_goud au groupe sudo
    if demander_confirmation "Voulez-vous ajouter phil_goud au groupe sudo ?"; then
        sudo usermod -aG sudo phil_goud
        echo "L'utilisateur phil_goud a été ajouté au groupe sudo."
    fi

    # Création d'un nouvel utilisateur et attribution des droits sudo
    if demander_confirmation "Voulez-vous créer un nouvel utilisateur avec les droits sudo ?"; then
        read -p "Entrez le nom du nouvel utilisateur : " nouvel_utilisateur
        sudo adduser "$nouvel_utilisateur"
        sudo usermod -aG sudo "$nouvel_utilisateur"
        echo "L'utilisateur $nouvel_utilisateur a été créé et ajouté au groupe sudo."
    fi

fi

# fstab
if demander_confirmation "Voulez-vous restaurer le fstab et les montages ?"; then
    echo "La suite nécessite un /mnt/CAKE/Misc en place."
    if demander_confirmation "Voulez-vous indiquer un fstab ?"; then
        # Activer la complétion des fichiers pour read
        read -e -p "Chemin : " fstab_path

        if [ -f "$fstab_path" ]; then
            # Vérification du contenu de la première ligne
                first_line=$(head -n 1 "$fstab_path")
                if [ "$first_line" == "# /etc/fstab: static file system information." ]; then
                    echo "Copie du fstab..."
                    sudo cp "$fstab_path" /etc/fstab
                else
                    echo "Erreur : La première ligne du fichier n'est pas conforme."
                    exit 1
                fi
            echo "Le fichier fstab a été mis à jour."
            echo "création des points de montage mergerfs et TRASH"
            sudo mkdir -p /mnt/CAKE/
            sudo mkdir -p /mnt/BOREALIS/
            sudo mkdir -p /mnt/TRASH/
            echo "création des points de montage des disk-## (A et B, de 1 à 4)"
            for lettre in A B; do
                for numero in {1..4}; do
                    mkdir -p "/mergerfs/disk-${lettre}${numero}"
                done
            done
            # Proposition de démonter et remonter les points de montage
            if demander_confirmation "Voulez-vous remonter les points définis dans le fstab sans redémarrer ?"; then
                echo "Démontage des points de montage..."
                sudo systemctl daemon-reload
                sudo umount -a &>/dev/null
                echo "Remontage des points de montage..."
                sudo mount -a &>/dev/null
                echo "Les points de montage ont été réinitialisés avec succès."
            else
                echo "Opération annulée. Pensez à exécuter 'sudo mount -a' plus tard."
                exist 0
            fi
        else
            echo "Chemin invalide. Aucun fichier copié."
            exit 1
        fi
    fi
fi

# Vérification si /mnt/CAKE/Misc n'est pas vide
if [ -d "/mnt/CAKE/Misc" ] && [ "$(ls -A /mnt/CAKE/Misc)" ]; then
    echo "Le disque CAKE est OK !"
else
    echo "Erreur : /mnt/CAKE/Misc est vide ou inexistant. Il est essentiel pour la suite. Vérifiez le montage."
    exit 1
fi

# Vérification si /mnt/BOREALIS n'est pas vide
if [ -d "/mnt/BOREALIS" ] && [ "$(ls -A /mnt/BOREALIS)" ]; then
    echo "Le disque BOREALIS est OK !"
else
    echo "INFO  : /mnt/BOREALIS est vide ou inexistant."
fi

# Vérification si /mnt/TRASH n'est pas vide
if [ -d "/mnt/TRASH" ] && [ "$(ls -A /mnt/TRASH)" ]; then
    echo "Le disque TRASH est OK !"
else
    echo "INFO : /mnt/TRASH est vide ou inexistant."
fi

if demander_confirmation "Voulez-vous restaurer des fichiers de config ?"; then

    # Personnalisation du terminal
    if demander_confirmation "Voulez-vous restaurer les sudoers ?"; then
        sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/etc/sudoers /etc/sudoers &>/dev/null
    fi

    if demander_confirmation "Voulez-vous restaurer les messages terminal ?"; then
        sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/etc/sudoers.d/privacy /etc/sudoers.d/privacy &>/dev/null
        sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/etc/sudoers.lecture /etc/sudoers.lecture &>/dev/null
    fi

    # Crontab
    if demander_confirmation "Voulez-vous restaurer le crontab ?"; then
        sudo mkdir -p /var/spool/cron/crontabs/
        sudo rsync -avP  /mnt/CAKE/SYSTEM/var/spool/cron/crontabs/root /var/spool/cron/crontabs/root &>/dev/null
    fi

    # Alias
    if demander_confirmation "Voulez-vous restaurer le bashrc ? (les alias)"; then
        sudo mkdir -p /home/phil_goud/
        sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/home/phil_goud/.bashrc /home/phil_goud/.bashrc &>/dev/null
    fi
fi 

#Scripts 
if demander_confirmation "Voulez-vous restaurer les scripts?"; then
        sudo mkdir -p /scripts/
        sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/scripts/ /scripts/ &>/dev/null
        sudo chmod 777 -R /scripts/
fi


#DATA
if demander_confirmation "Voulez-vous restaurer le /DATA dont /DATA/AppDATA/ ? (ATTENTION : LONG !)"; then
    sudo systemctl stop casaos
    echo "CasaOS stoppé, démarrage de la copie"
    sudo mkdir -p /DATA/
    sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/DATA/ /DATA/
    sudo systemctl start casaos
    echo "Copie terminée et CasaOS redémarré"
fi

#DATA
if demander_confirmation "Voulez-vous restaurer la config CasaOS ?"; then
    sudo systemctl stop casaos
    echo "CasaOS stoppé, démarrage de la copie"
    sudo mkdir -p /var/lib/casaos/
    sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/var/lib/casaos/ /var/lib/casaos &>/dev/null
    sudo systemctl start casaos
    echo "Copie terminée et CasaOS redémarré"
fi

echo "Script terminé."
