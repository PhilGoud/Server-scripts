#!/bin/bash

echo "📦 BACKUP WASABI ⬆️" &> /DATA/log/rclonelog.txt
echo "Début à $(date +"%H:%M:%S")" &>> /DATA/log/rclonelog.txt

echo "Dossier /Famille" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/Famille/ wasabi:/backupchell/Famille &>> /DATA/log/rclonelogtemp.txt
echo "📽️ Famille" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /Photos" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/Photos/ wasabi:/backupchell/Photos &>> /DATA/log/rclonelogtemp.txt
echo "📷 Photos" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /Musique" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/Musique/ wasabi:/backupchell/Musique &>> /DATA/log/rclonelogtemp.txt
echo "🎧 Musique" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /Podcast" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/Podcasts/ wasabi:/backupchell/Podcasts &>> /DATA/log/rclonelogtemp.txt
echo "🎙️ Podcast" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /ASoundMR" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/ASoundMR/ wasabi:/backupchell/ASoundMR/ &>> /DATA/log/rclonelogtemp.txt
echo "🪶 ASoundMR" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /Documents" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /mnt/CAKE/Documents/ wasabi:/backupchell/Documents/ &>> /DATA/log/rclonelogtemp.txt
echo "🗃️ Documents" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Dossier /scripts" &> /DATA/log/rclonelogtemp.txt
sudo rclone sync -v /scripts/ wasabi:/backupchell/scripts &>> /DATA/log/rclonelogtemp.txt
echo "🛠️ scripts" &>> /DATA/log/rclonelog.txt
grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

#echo "Dossier /AppData" &> /DATA/log/rclonelogtemp.txt
#sudo rclone sync -v /DATA/AppData/ wasabi:/AppData/ &>> /DATA/log/rclonelogtemp.txt
#echo "📚 AppData" &>> /DATA/log/rclonelog.txt
#grep -e '^Errors' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
#grep -e '^Transferred' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt
#grep -e '^Elapsed' /DATA/log/rclonelogtemp.txt | tail -1 &>> /DATA/log/rclonelog.txt

echo "Fin à $(date +"%H:%M:%S")" &>> /DATA/log/rclonelog.txt

#La petite config telegram
#on récupère le contenu du rclonelog
TELEGRAM=`cat /DATA/log/rclonelog.txt`
#les identifiants nécéssaires à l'envoi du message
TOKEN="YOUR_TELEGRAM_TOKEN_HERE"
CHAT_ID="TELEGRAM_CHATID_HERE"

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
        
        
        
        /DATA/log/rclonelog.txt de $LENGTH caractères" > /dev/null
        exit
fi
done