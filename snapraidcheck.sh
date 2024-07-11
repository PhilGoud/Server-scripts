#!/bin/bash
 
# install the smartctl package first! (apt-get install smartctl)

echo "🗄️ SNAPRAID CHECK 👀" &> /DATA/log/snapraidcheck.txt
echo "Début: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidcheck.txt
docker stop immich-server immich-postgres transmission &> /DATA/log/snapraidchecktemp.txt
snapraid check &>> /DATA/log/snapraidchecktemp.txt
docker start immich-server immich-postgres transmission &>> /DATA/log/snapraidchecktemp.txt
grep -e '^Checking' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
grep -e '^DANGER!' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
grep -e '^recoverable' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
grep -e '^Rerun' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
grep -e '^SnapRaid' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
grep -e '^Everything' /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
cat /DATA/log/snapraidchecktemp.txt | tail -1 &>> /DATA/log/snapraidcheck.txt
echo "Fin: $(date +"%d-%m-%y %H:%M:%S")" &>> /DATA/log/snapraidcheck.txt


#Telegram notif
TELEGRAM=`cat /DATA/log/snapraidcheck.txt`
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXXXXXX"

#Verification du nombre de caractères (limite de 1024 sur Telegram)
LENGTH=${#TELEGRAM}

#Choix du type du message à envoyer selon le nombre retourné
if (($LENGTH < 1000)); then
#Telegram notif complete
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    exit
else
#Telegram notif 2 si message trop gros
        curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="🗄️ SNAPRAID CHECK 👀
        /DATA/log/snapraidcheck.txt de $LENGTH caractères" > /dev/null
        exit
fi
