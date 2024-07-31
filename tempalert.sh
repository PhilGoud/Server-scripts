#!/bin/bash
 
# install the smartctl package first! (apt-get install smartctl)

#Gestion des alertes
for drive in /dev/sd[b-z] /dev/sd[b-z][b-z]
do
   if [[ ! -e $drive ]]; then continue ; fi
   smart=$(
      sudo smartctl -a $drive 2>/dev/null  | grep "Temperature_Celsius" | awk -F' ' '{print $10}' 
   ) 
   [[ "$smart" == "" ]] && smart='inconnu'  
if (("$smart" >= "48"))
then
 mount_point=$(lsblk -no MOUNTPOINT $drive | grep -v '^$')
      if [[ $mount_point =~ /mnt/disk-([a-zA-Z0-9]+) ]]; then
         disk_number="${BASH_REMATCH[1]}"
      else
          disk_number=$mount_point
      fi
      echo -n "$disk_number "
      echo "$smart°C"
      smartconcat="$smartconcat 
$disk_number $smart°C"
TELEGRAM="🔥 TEMP ALERT ❗ $smartconcat"
fi
done

#Telegram notif
	TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
	CHAT_ID="HERE_YOUR_CHATID"
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null

#Gestion des ventilateurs
if [ -n "$smartconcat" ];
then
curl -s -X POST http://192.168.1.10:8123/api/webhook/-uPoJsuS8m8NYWnXPKqqWNsaL 
else
curl -s -X POST http://192.168.1.10:8123/api/webhook/-Oj9YBLTC-JO-HSjVYAmJdMqW 
fi


