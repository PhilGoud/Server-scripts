#!/bin/bash

echo "🐤 Mise à jour bases Kiwix" &> /DATA/log/zimupdate.txt
echo "Début à $(date +"%H:%M:%S")" &>> /DATA/log/zimupdate.txt
timelimit -T10000 -t100100 sudo /mnt/CAKE/Kiwix/kiwix-zim-updater/kiwix-zim-updater.sh -d -c -f /mnt/CAKE/Kiwix/ &> /DATA/log/zimupdatetemp.txt
echo "Fin à $(date +"%H:%M:%S")" &>> /DATA/log/zimupdate.txt

#La petite config telegram
#on récupère le contenu du rclonelog
TELEGRAM=`cat /DATA/log/zimupdate.txt`
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
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="🐤 Mise à jour bases Kiwix
        /DATA/log/zimupdate.txt de $LENGTH caractères" > /dev/null
        exit
fi
done
