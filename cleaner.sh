#!/bin/bash

echo "🧹CLEANER" &> /DATA/log/cleanerlog.txt
sudo find "/DATA/AppData/plex/config/Library/Application Support/Plex Media Server/Cache/PhotoTranscoder" -name "*.jpg" -type f -mtime +3 -delete &>> /DATA/log/cleanerlog.txt
echo "Vidange des pochettes Plex ✅" &>> /DATA/log/cleanerlog.txt
sudo journalctl --vacuum-size=0M &>> /DATA/log/cleanerlog.txt
echo "Vidange des journaux ✅" &>> /DATA/log/cleanerlog.txt
sudo service casaos stop
sudo /scripts/stopdockers.sh
sudo mount -a
sudo service casaos start
sudo /scripts/startdockers.sh
echo "Redémarrer CasaOS, dockers et remount ✅" &>> /DATA/log/cleanerlog.txt
sudo trash-empty 7
echo "Vider la corbeille ✅" &>> /DATA/log/cleanerlog.txt
sudo crontab -l > /mnt/CAKE/Misc/crontab.txt
sudo rsync -avP /etc/fstab /mnt/CAKE/Misc/fstab.txt
sudo rsync -avP /etc/motd /mnt/CAKE/Misc/motd.txt
sudo rsync -avP /etc/sudoers.lecture /mnt/CAKE/Misc/sudoers.lecture.txt
echo "Sauvegarder personnalisation Chell ✅" &>> /DATA/log/cleanerlog.txt
sudo apt-get update &> /DATA/log/cleanerlog-upgrade.txt
sudo apt-get upgrade &>> /DATA/log/cleanerlog-upgrade.txt
echo "Mise à jour des paquets ✅" &>> /DATA/log/cleanerlog.txt



#La petite config telegram
#on récupère le contenu du rclonelog
TELEGRAM=`cat /DATA/log/cleanerlog.txt`
#les identifiants nécéssaires à l'envoi du message
TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
CHAT_ID="HERE_YOUR_CHATID"

#Verification du nombre de caractères (limite de 1024 sur Telegram)
LENGTH=${#TELEGRAM}

#Choix du type du message à envoyer selon le nombre retourné
if (($LENGTH < 1000)); then
#Telegram notif complete
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    exit
else
#Telegram notif 2 si message trop gros
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="🧹CLEANER
        
        
        
        /DATA/log/cleanerlog.txt de $LENGTH caractères" > /dev/null
        exit
fi
done
