#!/bin/bash
 
# install the smartctl package first! (apt-get install smartctl)

if sudo true
then
   true
else
   echo 'Root privileges required'

   exit 1
fi

for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   echo -n "$drive "

   smart=$(
      sudo smartctl -H $drive 2>/dev/null |

      grep '^SMART overall' |

      awk '{ print $6 }'
   )

   [[ "$smart" == "" ]] && smart='unavailable'

   echo "$smart"
smartconcat="$smartconcat 
$drive $smart"

TELEGRAM="💽 SMART CHECK $smartconcat"

done



#Telegram notif

	TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
	CHAT_ID="XXXXXXXXXX"
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
