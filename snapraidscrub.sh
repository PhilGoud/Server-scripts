#!/bin/bash
 
# install the smartctl package first! (apt-get install smartctl)
echo "🗄️ SNAPRAID SCRUB 🧽" &> /DATA/log/snapraidscrub.txt
echo "Début: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidscrub.txt
docker stop immich-server immich-postgres transmission &> /DATA/log/snapraidscrubtemp.txt
snapraid -q sync &>> /DATA/log/snapraidscrubtemp.txt
docker start immich-server immich-postgres transmission &>> /DATA/log/snapraidscrubtemp.txt
grep -e '^WARNING' /DATA/log/snapraidscrubtemp.txt | tail -1 &>> /DATA/log/snapraidscrub.txt
grep -e '^Unexpected' /DATA/log/snapraidscrubtemp.txt | tail -1 &>> /DATA/log/snapraidscrub.txt
grep -e '^Rerun' /DATA/log/snapraidscrubtemp.txt | tail -1 &>> /DATA/log/snapraidscrub.txt
grep -e '^SnapRaid' /DATA/log/snapraidscrubtemp.txt | tail -1 &>> /DATA/log/snapraidscrub.txt
grep -e '^Everything' /DATA/log/snapraidscrubtemp.txt | tail -1 &>> /DATA/log/snapraidscrub.txt
echo "Fin: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidscrub.txt

#Telegram notif
TELEGRAM=`cat /DATA/log/snapraidscrub.txt`
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
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
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="🗄️ SNAPRAID SCRUB 🧽
        /DATA/log/snapraidscrub.txt de $LENGTH caractères" > /dev/null
        exit
fi
