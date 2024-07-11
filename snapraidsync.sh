#!/bin/bash

echo "🗄️ SNAPRAID SYNC 🔄" &> /DATA/log/snapraidsync.txt
echo "Arrêt des Dockers" &>> /DATA/log/snapraidsync.txt
docker stop immich-server immich-postgres transmission &> /DATA/log/snapraidsynctemp.txt
echo "Début: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidsync.txt
snapraid -q sync &>> /DATA/log/snapraidsynctemp.txt
grep -e '^WARNING' /DATA/log/snapraidsynctemp.txt | tail -1 &>> /DATA/log/snapraidsync.txt
grep -e '^Unexpected' /DATA/log/snapraidsynctemp.txt | tail -1 &>> /DATA/log/snapraidsync.txt
grep -e '^Rerun' /DATA/log/snapraidsynctemp.txt | tail -1 &>> /DATA/log/snapraidsync.txt
grep -e '^SnapRaid' /DATA/log/snapraidsynctemp.txt | tail -1 &>> /DATA/log/snapraidsync.txt
grep -e '^Everything' /DATA/log/snapraidsynctemp.txt | tail -1 &>> /DATA/log/snapraidsync.txt
echo "Redémarrage des Dockers" &>> /DATA/log/snapraidsync.txt
docker start immich-server immich-postgres transmission &>> /DATA/log/snapraidsynctemp.txt
echo "Fin: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidsync.txt



#Telegram notif
	TELEGRAM=`cat /DATA/log/snapraidsync.txt`
	TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXX"
	CHAT_ID="XXXXXXXXX"


#Verification du nombre de caractères (limite de 1024 sur Telegram)
LENGTH=${#TELEGRAM}

#Choix du type du message à envoyer selon le nombre retourné
if (($LENGTH < 1000)); then
#Telegram notif complete
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    exit
else
#Telegram notif 2 si message trop gros
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="🗄️ SNAPRAID SYNC 🔄
        /DATA/log/snapraidsync.txt de $LENGTH caractères" > /dev/null
        exit
fi
