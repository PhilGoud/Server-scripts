#!/bin/bash

echo "📦 Dump Google DRIVE ⬇️" &> /DATA/log/rclone-drivelog.txt
echo "Début à $(date +"%H:%M:%S")" &>> /DATA/log/rclone-drivelog.txt

sudo rclone sync googledrive:/ /mnt/CAKE/GDrive/ &> /DATA/log/rclone-drivelogtemp.txt
grep -e '^Errors' /DATA/log/rclone-drivelogtemp.txt | tail -1 &>> /DATA/log/rclone-drivelog.txt
grep -e '^Transferred' /DATA/log/rclone-drivelogtemp.txt | tail -2 &>> /DATA/log/rclone-drivelog.txt
grep -e '^Elapsed' /DATA/log/rclone-drivelogtemp.txt | tail -1 &>> /DATA/log/rclone-drivelog.txt
echo "Fin à $(date +"%H:%M:%S")" &>> /DATA/log/rclone-drivelog.txt

#La petite config telegram
#on récupère le contenu du rclonelog
TELEGRAM=`cat /DATA/log/rclone-drivelog.txt`
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
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="📦 Dump Google DRIVE ⬇️
        /DATA/log/rclone-drivelog.txt de $LENGTH caractères" > /dev/null
        exit
fi
done