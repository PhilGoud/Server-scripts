#!/bin/bash
 
# install the smartctl package first! (apt-get install smartctl)
HAToken="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjMWNiZDMwMzQzNzc0NTIxYWJhZGQ5ZGJmN2JkZjA5MCIsImlhdCI6MTcxODM3NzM0NiwiZXhwIjoyMDMzNzM3MzQ2fQ.D6qRsJ4KLAQa61XFujo911CGcyokBDHNWfyX6w9wi4Q"

for drive in /dev/sd[a-a] /dev/sd[a-a][b-a]
do
   if [[ ! -e $drive ]]; then continue ; fi


   smart=$(
      sudo smartctl -a $drive 2>/dev/null  | grep "Temperature_Celsius" | awk -F' ' '{print $10}' 
   )

  
   [[ "$smart" == "" ]] && smart='unavailable'

   
   
if (("$smart" >= "48"))
then
echo -n "SSD "
echo "$smart°C"

smartconcat="$smartconcat 
SSD $smart°C"

TELEGRAM="🔥 TEMP ALERT ❗ $smartconcat"


fi



done




#Telegram notif

	TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
	CHAT_ID="HERE_YOUR_CHATID"
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
