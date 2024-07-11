#!/bin/bash

#backups et ajouts au fichier de log rclone.txt
echo "📦 BACKUP RCLONE 🆗" &> /DATA/log/rclonelog.txt


echo "Dossier /Famille" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v -c --check-first /mnt/CAKE/Famille/ swissbackup:/Famille/ &>> /DATA/log/rclonelogtemp.txt
echo "📽️ Famille ✔️" &>> /DATA/log/rclonelog.txt
echo $(date +"%d-%m-%y %H:%M:%S") &>> /DATA/log/rclonelog.txt
#Ici on récupère la dernière itération des infos Checks, Transferred et Elapsed
grep -e '^Checks' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt 
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /ASoundMR" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v -c --check-first /mnt/CAKE/ASoundMR/ swissbackup:/ASoundMR/ &>> /DATA/log/rclonelogtemp.txt
echo "🪶 ASoundMR ✔️" &>> /DATA/log/rclonelog.txt
echo $(date +"%d-%m-%y %H:%M:%S") &>> /DATA/log/rclonelog.txt
grep -e '^Checks' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt 
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /scripts" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v -c --check-first /scripts/ swissbackup:/scripts/ &>> /DATA/log/rclonelogtemp.txt
echo "🛠️ scripts ✔️" &>> /DATA/log/rclonelog.txt
echo $(date +"%d-%m-%y %H:%M:%S") &>> /DATA/log/rclonelog.txt
grep -e '^Checks' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt 
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt 
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

#La petite config telegram
#on récupère le contenu du rclonelog
TELEGRAM=`cat /DATA/log/rclonelog.txt`
#les identifiants nécéssaires à l'envoi du message
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXXX"

#Verification du nombre de caractères (limite de 1024 sur Telegram)
LENGTH=${#TELEGRAM}

#Choix du type du message à envoyer selon le nombre retourné
if (($LENGTH < 1000)); then
#Telegram notif complete
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    exit
else
#Telegram notif 2 si message trop gros
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="📦 BACKUP RCLONE🆗
        📽️ Famille ✔️
        🪶 ASoundMR ✔️
        🛠️ scripts ✔️
        /DATA/log/rclonelog.txt de $LENGTH caractères" > /dev/null
        exit
fi
done
