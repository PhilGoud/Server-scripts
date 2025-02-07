#!/bin/bash

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
           --backtitle "Installation Interactive" \
           --yesno "$1" 8 50
    return $?
}

# Fonction pour afficher un menu principal
afficher_menu_principal() {
    choix=$(dialog --clear \
                  --backtitle "Installation Interactive" \
                  --title "Install toolkit de Chell" \
                  --menu "Choisissez une option :" 15 60 8 \
                  1 "Mettre à jour le système" \
                  2 "Installer des paquets" \
                  3 "Gestion CasaOS" \
                  4 "Gestion utilisateurs" \
                  5 "Gestion des volumes (fstab)" \
                  6 "Restaurer les fichiers système" \
                  7 "Restaurer les données système" 2>&1 >/dev/tty)
    echo "$choix"
}

# Fonction pour afficher un message d'information
afficher_info() {
    dialog --title "Information" \
           --msgbox "$1" 8 50
}

clear
while true; do
    choix=$(afficher_menu_principal)
    clear
    case "$choix" in
        1)
            if demander_confirmation "Voulez-vous mettre à jour le système ?"; then
                sudo apt-get update && sudo apt-get upgrade -y && afficher_info "Mise à jour réussie."
            fi
            ;;
        2)
            
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
                                         --backtitle "Installation Interactive" \
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
        3)
            casaos_choix=$(dialog --clear \
                                      --backtitle "Installation Interactive" \
                                      --menu "Options CasaOS" 15 50 4 \
                                      1 "Installer CasaOS" \
                                      2 "Mettre à jour CasaOS" \
                                      3 "Supprimer CasaOS" \
                                      4 "Retour" 2>&1 >/dev/tty)

                case "$casaos_choix" in
                    1) sudo curl -fsSL https://get.casaos.io | sudo bash && afficher_info "CasaOS installé." ;;
                    2) curl -fsSL https://get.casaos.io/update | sudo bash && afficher_info "CasaOS mis à jour." ;;
                    3) sudo casaos-uninstall && afficher_info "CasaOS supprimé." ;;
                esac
            ;;
        4)
    utilisateur_action=$(dialog --clear \
                                --backtitle "Installation Interactive" \
                                --menu "Gestion des utilisateurs" 15 50 7 \
                                1 "Voir la liste des utilisateurs" \
                                2 "Créer un nouvel utilisateur" \
                                3 "Gérer les administrateurs" \
                                4 "Supprimer un utilisateur" \
                                5 "Modifier le mot de passe d'un utilisateur" \
                                7 "Retour" 2>&1 >/dev/tty)
    case "$utilisateur_action" in
        1)
            # Extraction de la liste des utilisateurs non systèmes
            liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

            if [[ -z "$liste_utilisateurs" ]]; then
                afficher_info "Aucun utilisateur disponible."
            else
                # Affichage sous forme de menu sans action
                dialog --menu "Liste des utilisateurs disponibles :" 15 50 10 $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty
            fi
            ;;

        2)
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


        3)
        # Récupération de la liste des utilisateurs non systèmes
        liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

        if [[ -z "$liste_utilisateurs" ]]; then
            afficher_info "Aucun utilisateur disponible."
        else
            # Sélection de l'utilisateur
            utilisateur_existant=$(dialog --menu "Sélectionnez un utilisateur pour la gestion sudo :" 15 50 10 $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty)

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




        4)
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


        5)
        # Récupération de la liste des utilisateurs non systèmes
        liste_utilisateurs=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd | sort)

        if [[ -z "$liste_utilisateurs" ]]; then
            afficher_info "Aucun utilisateur disponible."
        else
            # Sélection de l'utilisateur dans une liste
            utilisateur_selectionne=$(dialog --menu "Sélectionnez l'utilisateur pour changer le mot de passe :" 15 50 10 $(echo "$liste_utilisateurs" | awk '{print NR " " $1}') 2>&1 >/dev/tty)

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


        
    esac
    ;;


        
        5)
            if demander_confirmation "Voulez-vous restaurer les points de montage (fstab) ?"; then
                fstab_path=$(dialog --title "Choisissez le chemin du fichier fstab" --fselect / 10 60 2>&1 >/dev/tty)
                if [ -f "$fstab_path" ]; then
                    first_line=$(head -n 1 "$fstab_path")
                    if [ "$first_line" == "# /etc/fstab: static file system information." ]; then
                        sudo cp "$fstab_path" /etc/fstab
                        afficher_info "fstab mis à jour."
                        sudo systemctl daemon-reload
                        sudo mount -a &>/dev/null
                        afficher_info "Points de montage réinitialisés."
                    else
                        afficher_info "Erreur : La première ligne du fichier n'est pas conforme."
                    fi
                else
                    afficher_info "Chemin invalide. Aucun fichier copié."
                fi
            fi
            ;;

        6)  if [ ! -d "/mnt/CAKE/Misc" ] || [ ! "$(ls -A /mnt/CAKE/Misc)" ]; then
                dialog --title "Erreur" --msgbox "Le disque CAKE est vide ou inexistant. Il est essentiel pour la suite. Vérifiez le montage." 10 50
                continue
            fi
            restauration_action=$(dialog --clear \
                                         --backtitle "Installation Interactive" \
                                         --menu "Restauration des fichiers système" 15 50 4 \
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
                    afficher_info "alias restaurés."
                    ;;
                5)
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
        7)
            if [ ! -d "/mnt/CAKE/Misc" ] || [ ! "$(ls -A /mnt/CAKE/Misc)" ]; then
                dialog --title "Erreur" --msgbox "Le disque CAKE est vide ou inexistant. Il est essentiel pour la suite. Vérifiez le montage." 10 50
                continue
            fi

            choix_action=$(dialog --clear \
                                 --backtitle "Restaurer les données système" \
                                 --menu "Choisissez une option :" 15 50 3 \
                                 1 "Restaurer les scripts" \
                                 2 "Restaurer les données des apps" \
                                 3 "Restaurer les données de CasaOS" \
                                 2>&1 >/dev/tty)

            case "$choix_action" in
                1)
                    if demander_confirmation "Voulez-vous restaurer les scripts ?"; then
                        sudo mkdir -p /scripts/
                        sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/scripts/ /scripts/ &>/dev/null
                        sudo chmod 777 -R /scripts/
                        afficher_info "Scripts restaurés avec succès."
                    fi
                    ;;
                2)
                    if demander_confirmation "Voulez-vous restaurer le /DATA (ATTENTION : LONG !) ?"; then
                        sudo systemctl stop casaos
                        echo "CasaOS stoppé, démarrage de la copie"
                        sudo mkdir -p /DATA/
                        sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/DATA/ /DATA/
                        sudo systemctl start casaos
                        afficher_info "Copie terminée et CasaOS redémarré."
                    fi
                    ;;
                3)
                    if demander_confirmation "Voulez-vous restaurer les données de CasaOS ?"; then
                        sudo systemctl stop casaos
                        echo "CasaOS stoppé, démarrage de la copie"
                        sudo mkdir -p /var/lib/casaos/
                        sudo rsync -avP /mnt/CAKE/Misc/SYSTEM/var/lib/casaos/ /var/lib/casaos &>/dev/null
                        sudo systemctl start casaos
                        afficher_info "Configuration de CasaOS restaurée et CasaOS redémarré."
                    fi
                    ;;
                *)
                     
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
