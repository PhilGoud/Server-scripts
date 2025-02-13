#!/bin/bash

height=20
width=70
choice=10

msgheight=8
msgwidth=50

# Vérification si le script est exécuté en sudo
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec sudo ou en tant que root." >&2
  exit 1
fi

# Vérification que dialog est installé
if ! command -v dialog &>/dev/null; then
    echo "dialog n'est pas installé. Installation..."
    sudo apt-get install dialog -y
fi

# Fonction pour afficher une boîte de confirmation
demander_confirmation() {
    dialog --title "$1" \
           --backtitle "Install toolkit de Chell" \
           --yesno "$1" $msgheight $msgwidth
    return $?
}

# Fonction pour afficher un menu principal
afficher_menu_principal() {
    choix=$(dialog --clear \
                  --backtitle "Install toolkit de Chell" \
                  --title "Install toolkit de Chell" \
                  --menu "Choisissez une option :" $height $width $choice\
                  1 "Gestion des paquets" \
                  2 "Gestion CasaOS" \
                  3 "Gestion utilisateurs" \
                  4 "Gestion des disques" \
                  5 "Maintenance & restauration" \
                  6 "Editer la configuration" \
                  7 "Analyse des données" 2>&1 >/dev/tty)
    echo "$choix"
}

# Fonction pour afficher un message d'information
afficher_info() {
    dialog --title "Information" \
           --msgbox "$1" $msgheight $msgwidth
}

clear
while true; do
    choix=$(afficher_menu_principal)
    clear
    case "$choix" in
        1) # PACKETS
            choix_action=$(dialog --clear \
                --backtitle "Restaurer les données système" \
                --menu "Choisissez une option :" $height $width $choice \
                1 "Mettre à jour le système" \
                2 "Installer des paquets" \
                2>&1 >/dev/tty)
            case "$choix_action" in

            1) # UPDATE SYSTEM PACKETS
                if demander_confirmation "Voulez-vous mettre à jour le système ?"; then
                    sudo apt-get update && sudo apt-get upgrade -y && afficher_info "Mise à jour réussie."
                fi
            ;;
            2) #INSTALL PACKETS
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                PACKET_FILE="$SCRIPT_DIR/installpackets.list"

                if [[ ! -f "$PACKET_FILE" ]]; then
                    afficher_info "Fichier $PACKET_FILE introuvable. Veuillez créer ce fichier avec la liste des paquets."
                    continue
                fi

                mapfile -t paquets < <(grep -Ev '^\s*$|^\s*#' "$PACKET_FILE")

                if [[ ${#paquets[@]} -eq 0 ]]; then
                    afficher_info "Le fichier $PACKET_FILE est vide."
                    continue
                fi

                checklist_args=( "ALL" "Tout sélectionner" off )
                for paquet in "${paquets[@]}"; do
                    checklist_args+=( "$paquet" "" off )
                done

                paquet_selection=$(dialog --clear \
                    --backtitle "Install toolkit de Chell" \
                    --checklist "Sélectionnez les paquets à installer :" 20 60 ${#checklist_args[@]} \
                    "${checklist_args[@]}" 2>&1 >/dev/tty)

                if [[ -n "$paquet_selection" ]]; then
                    paquet_install=""
                    if [[ "$paquet_selection" == *"ALL"* ]]; then
                        paquet_install="${paquets[*]}"
                    else
                        paquet_install=$(echo "$paquet_selection" | sed 's/"ALL"//g' | tr -d '"')
                    fi

                    if [[ -n "$paquet_install" ]]; then
                        sudo apt-get update
                        sudo apt-get install -y $paquet_install && afficher_info "Installation terminée."
                    fi
                fi
            
            ;;
        esac
        ;;
        2) #CASOS
            casaos_choix=$(dialog --clear \
                      --backtitle "Install toolkit de Chell" \
                      --menu "Options CasaOS" $height $width $choice \
                      1 "Installer CasaOS" \
                      2 "Mettre à jour CasaOS" \
                      3 "Supprimer CasaOS" \
                      4 "Redémarrer CasaOS" \
                      5 "Retour" 2>&1 >/dev/tty)

            case "$casaos_choix" in
                1) 
                    dialog --yesno "Voulez-vous vraiment installer CasaOS ?" 7 50
                    if [ $? -eq 0 ]; then
                        sudo curl -fsSL https://get.casaos.io | sudo bash && afficher_info "CasaOS installé."
                    fi
                    ;;
                2) 
                    dialog --yesno "Voulez-vous vraiment mettre à jour CasaOS ?" 7 50
                    if [ $? -eq 0 ]; then
                        curl -fsSL https://get.casaos.io/update | sudo bash && afficher_info "CasaOS mis à jour."
                    fi
                    ;;
                3) 
                    dialog --yesno "Voulez-vous vraiment supprimer CasaOS ?" 7 50
                    if [ $? -eq 0 ]; then
                        sudo casaos-uninstall && afficher_info "CasaOS supprimé."
                    fi
                    ;;
                4) 
                    sudo systemctl stop casaos
                    sudo systemctl start casaos && afficher_info "CasaOS redémarré."
                    ;;
            esac
            ;;
        3) #USERS
            utilisateur_action=$(dialog --clear \
                                        --backtitle "Install toolkit de Chell" \
                                        --menu "Gestion des utilisateurs" $height $width $choice \
                                        1 "Voir la liste des utilisateurs" \
                                        2 "Créer un nouvel utilisateur" \
                                        3 "Gérer les administrateurs" \
                                        4 "Supprimer un utilisateur" \
                                        5 "Modifier le mot de passe d'un utilisateur" \
                                        6 "Activer/désactiver root"\
                                        7 "Retour" 2>&1 >/dev/tty)
            case "$utilisateur_action" in
            1) #LIST USERS
                # Extraction de la liste des utilisateurs non systèmes
                liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

                if [[ -z "$liste_utilisateurs" ]]; then
                    afficher_info "Aucun utilisateur disponible."
                else
                    # Préparer la liste des utilisateurs avec indication sudo ou non
                    liste_menu=""
                    for utilisateur in $liste_utilisateurs; do
                        if groups "$utilisateur" | grep -qw "sudo"; then
                            statut_sudo="[sudo]"
                        else
                            statut_sudo="[non-sudo]"
                        fi
                        liste_menu+="$utilisateur $statut_sudo "
                    done

                    # Affichage sous forme de menu sans action
                    dialog --menu "Liste des utilisateurs disponibles :" $height $width $choice $liste_menu 2>&1 >/dev/tty
                fi

                ;;

            2) #CREATE USER
                nouvel_utilisateur=$(dialog --inputbox "Entrez le nom du nouvel utilisateur :" 8 40 2>&1 >/dev/tty)

                if [[ -n "$nouvel_utilisateur" ]]; then
                    # Vérifie si l'utilisateur existe déjà
                    if id "$nouvel_utilisateur" &>/dev/null; then
                        afficher_info "L'utilisateur $nouvel_utilisateur existe déjà."
                    else
                        # Saisie du mot de passe dans dialog
                        mot_de_passe=$(dialog --passwordbox "Entrez le mot de passe pour $nouvel_utilisateur :" 8 40 2>&1 >/dev/tty)
                        
                        if [[ -n "$mot_de_passe" ]]; then
                            # Création simplifiée de l'utilisateur sans les informations superflues
                            sudo useradd -m -s /bin/bash "$nouvel_utilisateur"
                            
                            # Définition du mot de passe avec chpasswd
                            echo "$nouvel_utilisateur:$mot_de_passe" | sudo chpasswd

                            afficher_info "L'utilisateur $nouvel_utilisateur a été créé avec succès."

                            dialog --yesno "Voulez-vous rendre l'utilisateur $nouvel_utilisateur administrateur (sudo) ?" 8 40
                            response=$?
                            if [[ $response -eq 0 ]]; then
                                sudo usermod -aG sudo "$nouvel_utilisateur"
                                afficher_info "L'utilisateur $nouvel_utilisateur a été ajouté au groupe sudo."
                            else
                                afficher_info "L'utilisateur $nouvel_utilisateur n'a pas été ajouté au groupe sudo."
                            fi
                        else
                            afficher_info "Mot de passe non défini, création annulée."
                        fi
                    fi
                fi
                ;;


            3) #EDIT SUDO
                # Récupération de la liste des utilisateurs non systèmes
                liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

                if [[ -z "$liste_utilisateurs" ]]; then
                    afficher_info "Aucun utilisateur disponible."
                else
                    # Sélection de l'utilisateur
                    utilisateur_existant=$(dialog --menu "Sélectionnez un utilisateur pour la gestion sudo :" $height $width $choice $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty)

                    if [[ -n "$utilisateur_existant" ]]; then
                        utilisateur_selectionne=$(echo "$liste_utilisateurs" | sed -n "${utilisateur_existant}p")

                        # Vérification de l'appartenance au groupe sudo
                        if id -nG "$utilisateur_selectionne" | grep -qw "sudo"; then
                            action="Retirer du groupe sudo"
                            commande="sudo deluser $utilisateur_selectionne sudo"
                            message="L'utilisateur $utilisateur_selectionne a été retiré du groupe sudo."

                            # Confirmation de suppression avec saisie du nom de l'utilisateur
                            confirmation=$(dialog --inputbox "Pour confirmer, entrez le nom exact de l'utilisateur à retirer de sudo ($utilisateur_selectionne) :" 8 50 2>&1 >/dev/tty)
                            
                            if [[ "$confirmation" == "$utilisateur_selectionne" ]]; then
                                eval "$commande" && afficher_info "$message"
                            else
                                afficher_info "Confirmation échouée. Aucune modification effectuée."
                            fi
                        else
                            dialog --yesno "Voulez-vous ajouter $utilisateur_selectionne au groupe sudo ?" 8 50
                            response=$?
                            if [[ $response -eq 0 ]]; then
                                sudo usermod -aG sudo "$utilisateur_selectionne"
                                afficher_info "L'utilisateur $utilisateur_selectionne a été ajouté au groupe sudo."
                            else
                                afficher_info "Aucune modification effectuée pour $utilisateur_selectionne."
                            fi
                        fi
                    fi
                fi
                ;;
            4) #DELETE USER
                # Récupération de la liste des utilisateurs non systèmes
                liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

                    if [[ -z "$liste_utilisateurs" ]]; then
                        afficher_info "Aucun utilisateur disponible."
                    else
                    # Sélection de l'utilisateur dans une liste
                    utilisateur_selectionne=$(dialog --menu "Sélectionnez l'utilisateur à supprimer :" 15 50 10 $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty)

                        if [[ -n "$utilisateur_selectionne" ]]; then
                            utilisateur_a_supprimer=$(echo "$liste_utilisateurs" | sed -n "${utilisateur_selectionne}p")

                            # Confirmation stricte par saisie du nom exact
                            confirmation=$(dialog --inputbox "Pour confirmer, entrez le nom exact de l'utilisateur à supprimer ($utilisateur_a_supprimer) :" 8 50 2>&1 >/dev/tty)

                            if [[ "$confirmation" == "$utilisateur_a_supprimer" ]]; then
                                dialog --yesno "Voulez-vous supprimer également les fichiers de l'utilisateur $utilisateur_a_supprimer ?" 8 50
                                response=$?

                                if [[ $response -eq 0 ]]; then
                                    sudo deluser --remove-home "$utilisateur_a_supprimer"
                                    afficher_info "L'utilisateur $utilisateur_a_supprimer et ses fichiers ont été supprimés."
                                else
                                    sudo deluser "$utilisateur_a_supprimer"
                                    afficher_info "L'utilisateur $utilisateur_a_supprimer a été supprimé sans toucher à ses fichiers."
                                fi
                            else
                                afficher_info "Confirmation échouée. Aucune action effectuée."
                            fi
                        fi
                    fi
                ;;

            5) #CHANGE USER PASSWORD
                # Récupération de la liste des utilisateurs non systèmes
                liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

                if [[ -z "$liste_utilisateurs" ]]; then
                    afficher_info "Aucun utilisateur disponible."
                else
                    # Sélection de l'utilisateur dans une liste
                    utilisateur_selectionne=$(dialog --menu "Sélectionnez l'utilisateur pour changer le mot de passe :" $height $width $choice $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty)

                    if [[ -n "$utilisateur_selectionne" ]]; then
                        utilisateur_changement=$(echo "$liste_utilisateurs" | sed -n "${utilisateur_selectionne}p")

                        # Demande du nouveau mot de passe
                        nouveau_mdp=$(dialog --passwordbox "Entrez le nouveau mot de passe pour l'utilisateur $utilisateur_changement :" 8 50 2>&1 >/dev/tty)

                        confirmation_mdp=$(dialog --passwordbox "Confirmez le nouveau mot de passe :" 8 50 2>&1 >/dev/tty)

                        if [[ "$nouveau_mdp" == "$confirmation_mdp" && -n "$nouveau_mdp" ]]; then
                            echo -e "$nouveau_mdp\n$nouveau_mdp" | sudo passwd "$utilisateur_changement" >/dev/null 2>&1
                            afficher_info "Le mot de passe de l'utilisateur $utilisateur_changement a été modifié."
                        else
                            afficher_info "Le mot de passe n'a pas été modifié (mots de passe différents ou vide)."
                        fi
                    else
                        afficher_info "Aucune sélection effectuée."
                    fi
                fi
                ;; 
            6) # ROOT LOGIN
                    # Vérification de l'état actuel
                    if sudo passwd -S root | grep -q "L"; then
                        current_status="Désactivé"
                        new_action="Déverrouiller"
                        message="Le login root est actuellement désactivé. Voulez-vous l'activer ?"
                        command="sudo passwd -u root"
                    else
                        current_status="Activé"
                        new_action="Verrouiller"
                        message="Le login root est actuellement activé. Voulez-vous le désactiver ?"
                        command="sudo passwd -l root"
                    fi

                    dialog --yesno "$message" 8 50

                    if [[ $? -eq 0 ]]; then
                        # Exécuter la commande pour (dés)activer le login root
                        $command
                        dialog --msgbox "Le login root a été mis à jour : $new_action" $msgheight $msgwidth
                    else
                        dialog --msgbox "Aucune modification effectuée." $msgheight $msgwidth
                    fi
                    ;;
            esac
            ;;


        4) #FSTAB
            choix_action=$(dialog --clear \
                --backtitle "Disques et volumes" \
                --menu "Choisissez une option :" $height $width $choice \
                1 "Remonter tous les disques" \
                2 "Afficher les disques du système" \
                3 "Restaurer fstab depuis un fichier" \
                2>&1 >/dev/tty)

            case "$choix_action" in
            1) #Remonter
                sudo systemctl daemon-reload 
                sudo umount -a 
                sudo mount -a 
                afficher_info "Points de montage réinitialisés."
                ;;
            2) #Disques du système

                    # Fonction pour afficher les détails d'un disque
                    show_disk_info() {
                        local DISK=$1

                        # Récupération des infos SMART
                        local SMART_DATA=$(sudo smartctl -A -H /dev/$DISK)
                        local HEALTH=$(echo "$SMART_DATA" | grep -i "SMART overall" | awk '{print $NF}')
                        local HOURS=$(echo "$SMART_DATA" | grep -i "Power_On_Hours" | awk '{print int($NF)}')
                        local REALLOCATED=$(echo "$SMART_DATA" | grep -i "Reallocated_Sector_Ct" | awk '{print $NF}')
                        local PENDING=$(echo "$SMART_DATA" | grep -i "Current_Pending_Sector" | awk '{print $NF}')
                        local STARTS=$(echo "$SMART_DATA" | grep -i "Power_Cycle_Count" | awk '{print $NF}')

                        # Convertir état SMART en icône
                        local HEALTH_STATUS="❓ Inconnu"
                        case "$HEALTH" in
                            PASSED) HEALTH_STATUS="OK" ;;
                            FAILED) HEALTH_STATUS="ECHEC" ;;
                            WARNING) HEALTH_STATUS="PRUDENCE" ;;
                        esac

                        # Vérification température
                        local TEMP_STATUS=" ${TEMP}°C"
                        if [[ "$TEMP" -ge 50 ]]; then
                            TEMP_STATUS=" ${TEMP}°C (Élevée)"
                        fi

                        # Vérification des secteurs réalloués
                        local REALLOC_STATUS="$REALLOCATED"
                        if [[ "$REALLOCATED" -ge 10 ]]; then
                            REALLOC_STATUS="⚠ $REALLOCATED (Problème)"
                        fi

                        # Vérification des secteurs en attente
                        local PENDING_STATUS="$PENDING"
                        if [[ "$PENDING" -ge 1 ]]; then
                            PENDING_STATUS="⚠ $PENDING (Potentiel souci)"
                        fi


                        # Construction du message final
                        local INFO="=== État SMART du disque /dev/$DISK ===\n\n"
                        INFO+="État général       : $HEALTH_STATUS\n"
                        INFO+="Heures actives     : $HOURS h\n"
                        INFO+="Démarrages         : $STARTS fois\n"
                        INFO+="Secteurs réalloués : $REALLOC_STATUS\n"
                        INFO+="Secteurs en attente: $PENDING_STATUS\n\n"

                        # Affichage dans dialog
                        dialog --title "Informations du disque /dev/$DISK" --msgbox "$INFO" 20 $msgwidth
                    }


                    # Fonction pour afficher les détails d'une partition
                    show_partition_info() {
                        local PART=$1
                        local MOUNTPOINT=$(lsblk -o NAME,MOUNTPOINT -r | awk -v part="$PART" '$1 == part {print $2}')
                        local FSTYPE=$(lsblk -o NAME,FSTYPE -r | awk -v part="$PART" '$1 == part {print $2}')
                        local UUID=$(blkid /dev/$PART | grep -o 'UUID="[^"]*"' | cut -d '"' -f2)

                        if [[ -n "$MOUNTPOINT" ]]; then
                            local USAGE=$(df -h "$MOUNTPOINT" | awk 'NR==2 {print $3 "/" $2}')
                        else
                            local USAGE="Non monté"
                        fi

                        local INFO="=== Partition $PART ===\n\n"
                        INFO+="Type          : $FSTYPE\n"
                        INFO+="UUID          : $UUID\n"
                        INFO+="Montage       : ${MOUNTPOINT:-Non monté}\n"
                        INFO+="Utilisation   : $USAGE\n"

                        dialog --title "Détails de $PART" --msgbox "$INFO" 12 60
                    }

                    # Récupérer la liste des disques et partitions
                    DISK_INFO=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT -r | awk '{print $1, $2, $3, ($4 == "" ? "-" : $4)}')

                    # Construire le menu pour dialog
                    MENU=()
                    while IFS= read -r line; do
                        DEVICE=$(echo "$line" | awk '{print $1}')
                        SIZE=$(echo "$line" | awk '{print $2}')
                        TYPE=$(echo "$line" | awk '{print $3}')
                        MOUNTPOINT=$(echo "$line" | awk '{print $4}')

                        if [[ "$TYPE" == "disk" ]]; then
                            MENU+=("$DEVICE" "$DEVICE ($SIZE)")
                        elif [[ "$TYPE" == "part" ]]; then
                            if [[ "$MOUNTPOINT" != "-" ]]; then
                                PART_USAGE=$(df -h "$MOUNTPOINT" --output=used,size 2>/dev/null | tail -1 | awk '{print $1 "/" $2}')
                                MOUNT_DISPLAY=": $MOUNTPOINT"
                            else
                                PART_USAGE="Non monté"
                                MOUNT_DISPLAY=""
                            fi
                            MENU+=("$DEVICE" " ├─ $DEVICE$MOUNT_DISPLAY - $PART_USAGE")
                        fi
                    done <<< "$DISK_INFO"

                    # Afficher le menu principal
                    CHOICE=$(dialog --clear --title "Liste des disques et volumes" --menu "Sélectionnez un disque/volume :" 20 60 10 "${MENU[@]}" 2>&1 >/dev/tty)

                    clear
                    if [ -n "$CHOICE" ]; then
                        if [[ "$CHOICE" =~ ^[a-z]+$ ]]; then
                            show_disk_info "$CHOICE"
                        else
                            choix_action=$(dialog --clear \
                            --backtitle "Infos partition" \
                            --menu "Choisissez une option :" $height $width $choice \
                            1 "Informations de la partition" \
                            2 "Analyser avec ncdu" \
                            2>&1 >/dev/tty)

                            case "$choix_action" in
                                1) #infos
                                    show_partition_info "$CHOICE"
                                ;;

                                2) #ncdu
                                    mount=$(lsblk -o NAME,MOUNTPOINT | grep "$CHOICE" | awk '{print $2}')
                                    sudo ncdu -x $mount
                                ;;
                            esac
                        fi
                    else
                        echo "Aucune sélection effectuée."
                    fi
                ;;
            esac
            ;;
            2)  # FSTAB
                if demander_confirmation "Voulez-vous restaurer les points de montage (fstab) ?"; then
                    fstab_path=$(dialog --title "Choisissez le chemin du fichier fstab" --fselect / 10 60 2>&1 >/dev/tty)
                    if [ -f "$fstab_path" ]; then
                        first_line=$(head -n 1 "$fstab_path")
                        if [ "$first_line" == "# /etc/fstab: static file system information." ]; then
                            # Exclure les lignes contenant /, /boot et swap
                            grep -Ev '^[^#]*\s+/\s|^[^#]*\s+/boot|^[^#]*\s+none\s+swap' "$fstab_path" > /tmp/fstab_filtered
                            cat /etc/fstab | grep -E '/\s|/boot|none\s+swap' >> /tmp/fstab_filtered
                            sudo cp /tmp/fstab_filtered /etc/fstab
                            rm /tmp/fstab_filtered

                            afficher_info "fstab mis à jour (sans modifier /, boot et swap)."
                            sudo systemctl daemon-reload

                            # Création des dossiers de montage si inexistants
                            awk '$2 ~ /^\// {print $2}' /tmp/fstab_filtered | while read -r mountpoint; do
                                if [ ! -d "$mountpoint" ]; then
                                    sudo mkdir -p "$mountpoint"
                                    afficher_info "Création du dossier de montage : $mountpoint"
                                fi
                            done

                            # Montage des volumes
                            sudo umount -a &>/dev/null
                            sudo mount -a &>/dev/null
                            afficher_info "Points de montage créés et montés."
                        else
                            afficher_info "Erreur : La première ligne du fichier n'est pas conforme."
                        fi
                    else
                        afficher_info "Chemin invalide. Aucun fichier copié."
                    fi
                fi

                ;;

        5) # BACKUP and RESTORE
            if [ ! -d "/mnt/CAKE/Misc" ] || [ ! "$(ls -A /mnt/CAKE/Misc)" ]; then
                dialog --title "Erreur" --msgbox "Le disque CAKE est vide ou inexistant. Il est essentiel pour la suite. Vérifiez le montage." $msgheight $msgwidth
                continue
            fi

            choix_action=$(dialog --clear \
                --backtitle "Maintenance & restauration" \
                --menu "Choisissez une option :" $height $width $choice \
                1 "Lancer une maintenance + backup SYSTEM" \
                2 "Lancer un backup CAKE>BOREALIS" \
                3 "Restaurer des fichiers système" \
                4 "Restaurer des données système" \
                2>&1 >/dev/tty)

            case "$choix_action" in
            1) #MAINTAIN & BACKUP
                first_line=$(head -n 1 "/scripts/maintenance.sh")
                if [ "$first_line" == "#!/bin/bash" ]; then
                    first_line2=$(head -n 1 "/scripts/permissionbck.sh")
                    if [ "$first_line2" == "#!/bin/bash" ]; then
                        first_line3=$(head -n 1 "/scripts/dockerscontrol.sh")
                        if [ "$first_line3" == "#!/bin/bash" ]; then
                            nohup /scripts/maintenance.sh &
                            afficher_info "Maintenance lancée."
                        else
                            afficher_info "Erreur : La première ligne du script dockerscontrol n'est pas conforme."
                        fi
                    else
                        afficher_info "Erreur : La première ligne du script permissionbck n'est pas conforme."
                    fi
                else
                        afficher_info "Erreur : La première ligne du script maintenance n'est pas conforme."
                fi
            ;;
            2) #BACKUP CAKE > BOREALIS
                first_line=$(head -n 1 "/scripts/rsync-delete.sh")
                if [ "$first_line" == "#!/bin/bash" ]; then
                        nohup /scripts/rsync-delete.sh &
                        afficher_info "Maintenance lancée."
                else
                        afficher_info "Erreur : La première ligne du script n'est pas conforme."
                fi
            ;;
            3) #RESTORE SYSTEM
                restauration_action=$(dialog --clear \
                                            --backtitle "Install toolkit de Chell" \
                                            --menu "Restauration des fichiers système" $height $width $choice \
                                            1 "Restaurer sudoers" \
                                            2 "Restaurer crontab" \
                                            3 "Restaurer les alias" \
                                            4 "Restaurer login ASCII" \
                                            5 "Restaurer sudo ASCII" \
                                            6 "Retour" 2>&1 >/dev/tty)
                case "$restauration_action" in
                1)
                    sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/etc/sudoers /etc/sudoers &>/dev/null && afficher_info "sudoers restauré."
                    ;;
                2)
                    sudo mkdir -p /var/spool/cron/crontabs/
                    sudo rsync -avP /mnt/CAKE/SYSTEM/var/spool/cron/crontabs/root /var/spool/cron/crontabs/root &>/dev/null
                    afficher_info "Crontab restauré."
                    ;;
                3)
                    sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/home/phil_goud/.bashrc /home/phil_goud/.bashrc &>/dev/null
                    afficher_info "alias restaurés. Veuillez démarrer une nouvelle session pour bénéficier des changements."
                    ;;
                4)
                    sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/etc/motd /etc/motd &>/dev/null
                    afficher_info "login ASCII restauré"
                    ;;
                5)
                    sudo rsync -avP  /mnt/CAKE/Misc/SYSTEM/etc/sudoers.d/privacy /etc/sudoers.d/privacy &>/dev/null
                    sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/etc/sudoers.lecture /etc/sudoers.lecture &>/dev/null
                    afficher_info "sudo ASCII restauré"
                    ;;
                esac
                ;;
            4) #RESTORE DATAS
                choix_action=$(dialog --clear \
                                    --backtitle "Restaurer les données système" \
                                    --menu "Choisissez une option :" $height $width $choice \
                                    1 "Restaurer les scripts" \
                                    2 "Restaurer les données des apps" \
                                    3 "Restaurer les données de CasaOS" \
                                    4 "Restaurer les données de Docker" \
                                    2>&1 >/dev/tty)

                    case "$choix_action" in
                        1) #RESTORE SCRIPTS
                            if demander_confirmation "Voulez-vous restaurer les scripts ?"; then
                                afficher_info "Démarrage de la copie"
                                sudo mkdir -p /scripts/
                                sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/scripts/ /scripts/ &>/dev/null
                                sudo chmod 777 -R /scripts/
                                afficher_info "Scripts restaurés avec succès."
                            fi
                            ;;
                        2) #RESTORE DATA
                            if demander_confirmation "Voulez-vous restaurer le /DATA (ATTENTION : LONG !) ?"; then
                            sudo systemctl stop casaos
                            sudo systemctl stop docker

                            
                            # Créer le répertoire si nécessaire
                            sudo mkdir -p /DATA/

                            # Commande rsync avec un affichage en temps réel dans dialog
                            sudo rsync -avP --progress /mnt/CAKE/Misc/SYSTEM/DATA/ /DATA/ | dialog --title "Progression de la copie" --programbox 30 100

                            sudo systemctl start docker
                            sudo systemctl start casaos
                            afficher_info "Copie terminée et CasaOS redémarré."
                            fi
                            ;;

                        3) #RESTORE CASAOS DATA
                            if demander_confirmation "Voulez-vous restaurer les données de CasaOS ?"; then
                            sudo systemctl stop casaos
                            
                            # Créer le répertoire si nécessaire
                            sudo mkdir -p /var/lib/casaos/

                            # Commande rsync avec un affichage en temps réel dans dialog
                            sudo rsync -avP --progress /mnt/CAKE/Misc/SYSTEM/var/lib/casaos/ /var/lib/casaos/ | dialog --title "Progression de la copie" --programbox 30 100

                            sudo systemctl start casaos
                            afficher_info "Copie terminée et CasaOS redémarré."
                            fi
                            ;;
                        4) #RESTORE DOCKER DATA
                            if demander_confirmation "Voulez-vous restaurer les données Docker (conseillé uniquement si hors-ligne) ?"; then
                            sudo systemctl stop casaos
                            sudo systemctl stop docker

                            
                            # Créer le répertoire si nécessaire
                            sudo mkdir -p /var/lib/docker/

                            # Commande rsync avec un affichage en temps réel dans dialog
                            sudo rsync -avP --progress /mnt/CAKE/Misc/SYSTEM/var/lib/docker/ /var/lib/docker/ | dialog --title "Progression de la copie" --programbox 30 100
                            
                            sudo systemctl start docker
                            sudo systemctl start casaos
                            afficher_info "Copie terminée et CasaOS redémarré."
                            fi
                            ;;
                        *)    
                        ;;
                    esac
                    ;;
                esac
                ;;
                    
        6) # EDIT CONFIG
            choix_action=$(dialog --clear \
                --backtitle "Editer la config système" \
                --menu "Choisissez une option :" $height $width $choice \
                1 "Editer le fstab" \
                2 "Editer le crontab" \
                3 "Editer les alias (bashrc)" \
                4 "Editer l'ASCII de login" \
                5 "Editer l'ASCII de sudo" \
                6 "Editer le grub"\
                7 "Editer les sources des dépôts"\
                8 "Changer le nom du système" \
                2>&1 >/dev/tty)

            case "$choix_action" in
                1) #FSTAB
                    if demander_confirmation "Voulez-vous éditer le fstab ?"; then
                        sudo nano /etc/fstab
                        dialog --title "En cours..." --infobox "Mise à jour des volumes" 6 50
                        sudo systemctl daemon-reload

                        # Créer les points de montage définis dans fstab, en ignorant certaines lignes
                        while read -r line; do
                            # Ignorer les lignes vides, les commentaires ou les lignes spécifiques à exclure
                            [[ -z "$line" || "$line" =~ ^# ]] && continue
                            
                            # Exclure les lignes contenant les points de montage /, /boot/efi et swap
                            if echo "$line" | grep -q -E '^\s*/($|boot/efi|swap)'; then
                                continue
                            fi

                            # Extraire le point de montage de la ligne fstab
                            mount_point=$(echo "$line" | awk '{print $2}')

                            # Vérifier si le répertoire de montage existe, sinon le créer
                            if [ ! -d "$mount_point" ]; then
                                echo "Création du point de montage : $mount_point"
                                sudo mkdir -p "$mount_point"
                            fi
                        done < /etc/fstab

                        sudo umount -a &>/dev/null
                        sudo mount -a &>/dev/null
                        afficher_info "fstab édité, c (vérifier les anciens montages !)"
                    fi


                    ;;
                2) #CRONTAB
                    if demander_confirmation "Voulez-vous éditer le crontab ?"; then
                        sudo crontab -e
                        sudo systemctl restart cron
                        afficher_info "crontab édité et redémarré"
                    fi
                    ;;

                3) #ALIAS
                    if demander_confirmation "Voulez-vous éditer les alias ?"; then
                        sudo nano /home/phil_goud/.bashrc
                        dialog --title "En cours..." --infobox "Mise à jour du bash" 6 50
                        source ~/.bashrc
                        afficher_info "alias édités et bashrc rechargé. Veuillez démarrer une nouvelle session pour bénéficier des changements."

                    fi
                    ;;
                4) #LOGIN SCREEN
                    choix_action=$(dialog --clear \
                                --backtitle "Editer l'ASCII de login" \
                                --menu "Choisissez une option :" 15 50 3 \
                                1 "Editer l'ASCII de login" \
                                2 "Remplacer l'ASCII de login" \
                                2>&1 >/dev/tty)
                    case "$choix_action" in
                        1)  sudo nano /etc/motd
                            afficher_info "ASCII de login édité"
                            ;;
                        2) sudo nano /etc/motdtemp
                        sudo rsync /etc/motdtemp /etc/motd
                        sudo rm /etc/motdtemp 
                        afficher_info "ASCII de login remplacé"
                            ;;
                    esac
                    ;;
                5) #SUDO SCREEN
                    choix_action=$(dialog --clear \
                                --backtitle "Editer l'ASCII de sudo" \
                                --menu "Choisissez une option :" 15 50 3 \
                                1 "Editer l'ASCII de sudo" \
                                2 "Remplacer l'ASCII de sudo" \
                                2>&1 >/dev/tty)
                    case "$choix_action" in
                        1)  sudo nano /etc/sudoers.lecture
                            afficher_info "ASCII de sudo édité"
                            ;;
                        2) sudo nano /etc/sudoers.lecturetemp
                        sudo rsync /etc/sudoers.lecturetemp /etc/sudoers.lecture
                        sudo rm /etc/sudoers.lecturetemp 
                        afficher_info "ASCII de sudo remplacé"
                            ;;
                    esac
                    ;;
                6) #GRUB

                    GRUB_FILE="/etc/default/grub"

                    # Vérifier si le fichier existe
                    if [[ ! -f $GRUB_FILE ]]; then
                        echo "Le fichier $GRUB_FILE n'existe pas."
                        exit 1
                    fi

                    # Extraire les valeurs actuelles
                    GRUB_DEFAULT=$(grep "^GRUB_DEFAULT=" $GRUB_FILE | cut -d '=' -f2)
                    GRUB_TIMEOUT=$(grep "^GRUB_TIMEOUT=" $GRUB_FILE | cut -d '=' -f2)
                    GRUB_HIDDEN_TIMEOUT=$(grep "^GRUB_HIDDEN_TIMEOUT=" $GRUB_FILE | cut -d '=' -f2)
                    GRUB_HIDDEN_TIMEOUT_QUIET=$(grep "^GRUB_HIDDEN_TIMEOUT_QUIET=" $GRUB_FILE | cut -d '=' -f2)
                    GRUB_CMDLINE_LINUX_DEFAULT=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" $GRUB_FILE | cut -d '=' -f2 | tr -d '"')

                    # Définir des valeurs par défaut si elles ne sont pas trouvées
                    GRUB_HIDDEN_TIMEOUT=${GRUB_HIDDEN_TIMEOUT:-"Non défini"}
                    GRUB_HIDDEN_TIMEOUT_QUIET=${GRUB_HIDDEN_TIMEOUT_QUIET:-"Non défini"}

                    # Afficher les explications avant modification
                    dialog --msgbox "Ce script vous permet de modifier les paramètres de GRUB.\n\n\
                    GRUB_DEFAULT : Choix du système par défaut (0 = premier menu, 1 = deuxième, etc.).\n\
                    GRUB_TIMEOUT : Délai avant démarrage automatique en secondes.\n\
                    GRUB_HIDDEN_TIMEOUT : Temps avant d'afficher le menu si une touche est pressée.\n\
                    GRUB_HIDDEN_TIMEOUT_QUIET : true = cache le compte à rebours, false = l'affiche.\n\
                    CMDLINE_LINUX : Options du noyau (ex: quiet splash pour un démarrage silencieux).\n" 15 60

                    # Demander les nouvelles valeurs avec descriptions
                    exec 3>&1
                    VALUES=$(dialog --form "Modifier les paramètres de GRUB" 20 70 7 \
                        "GRUB_DEFAULT (0 = 1er OS) :"              1 1 "$GRUB_DEFAULT"              1 40 10 0 \
                        "GRUB_TIMEOUT (secondes) :"                2 1 "$GRUB_TIMEOUT"              2 40 10 0 \
                        "GRUB_HIDDEN_TIMEOUT (attente touche) :"   3 1 "$GRUB_HIDDEN_TIMEOUT"       3 40 10 0 \
                        "GRUB_HIDDEN_TIMEOUT_QUIET (true/false) :" 4 1 "$GRUB_HIDDEN_TIMEOUT_QUIET" 4 40 10 0 \
                        "CMDLINE_LINUX (ex: quiet splash) :"       5 1 "$GRUB_CMDLINE_LINUX_DEFAULT" 5 40 40 0 \
                        2>&1 1>&3)
                    exec 3>&-

                    # Vérifier si l'utilisateur a annulé
                    if [[ -z "$VALUES" ]]; then
                        echo "Modification annulée."
                        exit 0
                    fi

                    # Séparer les valeurs
                    NEW_DEFAULT=$(echo "$VALUES" | sed -n '1p')
                    NEW_TIMEOUT=$(echo "$VALUES" | sed -n '2p')
                    NEW_HIDDEN_TIMEOUT=$(echo "$VALUES" | sed -n '3p')
                    NEW_HIDDEN_TIMEOUT_QUIET=$(echo "$VALUES" | sed -n '4p')
                    NEW_CMDLINE_LINUX=$(echo "$VALUES" | sed -n '5p')

                    # Sauvegarder une copie de sécurité
                    cp $GRUB_FILE $GRUB_FILE.bak

                    # Modifier le fichier grub
                    sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=$NEW_DEFAULT/" $GRUB_FILE
                    sed -i "s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$NEW_TIMEOUT/" $GRUB_FILE
                    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$NEW_CMDLINE_LINUX\"|" $GRUB_FILE

                    # Mettre à jour GRUB_HIDDEN_TIMEOUT seulement si la valeur est définie
                    if [[ "$NEW_HIDDEN_TIMEOUT" != "Non défini" ]]; then
                        sed -i "/^GRUB_HIDDEN_TIMEOUT=/d" $GRUB_FILE
                        echo "GRUB_HIDDEN_TIMEOUT=$NEW_HIDDEN_TIMEOUT" >> $GRUB_FILE
                    fi

                    # Mettre à jour GRUB_HIDDEN_TIMEOUT_QUIET seulement si la valeur est définie
                    if [[ "$NEW_HIDDEN_TIMEOUT_QUIET" != "Non défini" ]]; then
                        sed -i "/^GRUB_HIDDEN_TIMEOUT_QUIET=/d" $GRUB_FILE
                        echo "GRUB_HIDDEN_TIMEOUT_QUIET=$NEW_HIDDEN_TIMEOUT_QUIET" >> $GRUB_FILE
                    fi

                    # Appliquer les changements
                    update-grub

                    dialog --msgbox "Les modifications ont été appliquées.\n\nRedémarrez pour voir les changements." 10 50

                    echo "Les modifications ont été appliquées. Redémarrez pour voir les changements."
                    ;;
                7) #SOURCES
                    sudo nano /etc/apt/sources.list
                    sudo apt-get update
                    dialog --msgbox "Les modifications ont été appliquées." 10 50

                    ;;

                8) #SYSTEM NAME
                    # Récupération du nom actuel
                    current_hostname=$(hostnamectl --static)

                    # Affichage de la boîte avec le nom actuel pré-rempli
                    dialog --inputbox "Entrez le nouveau nom :" 8 50 "$current_hostname" 2> /tmp/new_hostname.txt

                    # Lecture du nom saisi
                    new_hostname=$(cat /tmp/new_hostname.txt)
                    rm -f /tmp/new_hostname.txt

                    if [[ -n "$new_hostname" ]]; then
                        # Définir le hostname
                        sudo hostnamectl set-hostname "$new_hostname"

                        # Mise à jour automatique de /etc/hosts
                        if grep -q "127.0.1.1" /etc/hosts; then
                            sudo sed -i "s/127.0.1.1 .*/127.0.1.1 $new_hostname/" /etc/hosts
                        else
                            echo "127.0.1.1 $new_hostname" | sudo tee -a /etc/hosts >/dev/null
                        fi

                        # Vérification et confirmation
                        hostname_info=$(hostnamectl)
                        echo "$hostname_info" | dialog --title "Vérification nom" --textbox /dev/stdin 20 70
                    else
                        dialog --msgbox "Aucun nom fourni, opération annulée." $msgheight $msgwidth
                    fi
                    ;;
                


                *)
                            
                ;;
            esac
            ;;

        7) # FILES
            
            # Sous-menu pour choisir entre recherche et ncdu
            operation=$(dialog --clear --title "Choisissez une opération" \
                --menu "Que voulez-vous faire ?" $height $width $choice \
                1 "Recherche de fichiers contenant une chaîne" \
                2 "Explorer l'espace disque avec ncdu" 2>&1 >/dev/tty)

            case "$operation" in
                1) # SEARCH
                    # Fenêtre pour sélectionner le répertoire
                    base_dir=$(dialog --title "Sélectionnez un répertoire" --dselect "/" 15 50 2>&1 >/dev/tty)

                    if [ -z "$base_dir" ] || [ ! -d "$base_dir" ]; then
                        dialog --msgbox "Le répertoire sélectionné n'existe pas ou est invalide." $msgheight $msgwidth
                        continue
                    fi

                    # Fenêtre pour entrer la chaîne à rechercher
                    search_string=$(dialog --inputbox "Entrez la chaîne à rechercher (ignorant la casse) :" $msgheight $msgwidth 2>&1 >/dev/tty)

                    if [ -z "$search_string" ]; then
                        dialog --msgbox "La chaîne de recherche ne peut pas être vide." $msgheight $msgwidth
                        continue
                    fi

                    # Choix pour la gestion des montages système
                    fs_option=$(dialog --clear --title "Limitation système de fichiers" \
                        --menu "Voulez-vous ignorer les montages et rester sur le même système de fichiers ?" \
                        10 70 2 \
                        1 "Oui, ignorer les montages (-xdev)" \
                        2 "Non, suivre les montages" 2>&1 >/dev/tty)

                    case "$fs_option" in
                        1) fs_option="-xdev" ;;
                        2) fs_option="" ;;
                        *) dialog --msgbox "Choix invalide, opération annulée." $msgheight $msgwidth; continue ;;
                    esac
                    # Création de fichiers temporaires
                    temp_result_file=$(mktemp)
                    temp_progress_file=$(mktemp)

                    # Recherche avec affichage dynamique des dossiers
                    {
                        find "$base_dir" -type d $fs_option 2>/dev/null | while IFS= read -r dir; do
                            echo "Scan de : $dir" > "$temp_progress_file"
                        done

                        find "$base_dir" -iname "*$search_string*" $fs_option 2>/dev/null > "$temp_result_file"
                    } &

                    # Affiche la progression avec les dossiers scannés
                    while kill -0 $! 2>/dev/null; do
                        dialog --title "Recherche en cours..." --tailbox "$temp_progress_file" $msgheight $msgwidth
                    done

                    # Affichage des résultats
                    if [ ! -s "$temp_result_file" ]; then
                        dialog --msgbox "Aucun résultat trouvé pour '$search_string'." 7 50
                    else
                        dialog --title "Résultats de la recherche" --textbox "$temp_result_file" 20 70
                    fi

                    # Nettoyage
                    rm -f "$temp_result_file" "$temp_progress_file"
                    ;;
                2) # SIZES
                    # Fenêtre pour sélectionner le répertoire
                    base_dir=$(dialog --title "Sélectionnez un répertoire" --dselect "/" $msgheight $msgwidth 2>&1 >/dev/tty)

                    if [ -z "$base_dir" ] || [ ! -d "$base_dir" ]; then
                        dialog --msgbox "Le répertoire sélectionné n'existe pas ou est invalide." $msgheight $msgwidth
                        continue
                    fi
                    # Choix pour la gestion des montages système
                    fs_option=$(dialog --clear --title "Limitation système de fichiers" \
                        --menu "Voulez-vous ignorer les montages et rester sur le même système de fichiers ?" $height $width $choice \
                        1 "Oui, ignorer les montages (-xdev)" \
                        2 "Non, suivre les montages" 2>&1 >/dev/tty)

                    case "$fs_option" in
                        1) fs_option="-x" ;;
                        2) fs_option="" ;;
                        *) dialog --msgbox "Choix invalide, opération annulée." $msgheight $msgwidth; continue ;;
                    esac
                    sudo ncdu $fs_option $base_dir
                    ;;
                *)
                    dialog --msgbox "Choix invalide, opération annulée." $msgheight $msgwidth
                    ;;
                esac
                ;;
        *)
        clear
        exit 0
        ;;
    esac
done
clear
