#!/bin/sh

#Url of the RSS feed
RSS_URL="https://aperoriginale.lepodcast.fr/rss"
NAME="Aperoriginale"

if test -d /DATA/log/$NAME/; 
then continue
else
	mkdir /DATA/log/$NAME/
fi


#Récupérer le flux
curl  --silent "$RSS_URL" -o /DATA/log/$NAME/$NAME-feed.txt

#verifier que le flux soit pas planté, sinon exit
test=$(cat /DATA/log/$NAME/$NAME-feed.txt | head -1 | sed -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g" -e 's/\s//' -e 's/\t//' -e 's/\n//'| head -c 3)

if  [ "$test" = "xml" ] 
then
	continue
else
	echo "erreur de flux"
    echo "$test"
    exit
fi

#Check GUID
#isoler le dernier guid et nettoyer un peu
last=$(grep -E '(guid>)' /DATA/log/$NAME/$NAME-feed.txt  | head -1 | sed -e 's/^[ \t]*//' -e 's/<guid isPermaLink="false">//' -e 's/<\/guid>//' )
previous=$(grep -e '' /DATA/log/$NAME/$NAME-previous.txt)

#Vérifier si le dernier guid a changé, si oui, prévenir
if [ "$last" != "$previous" ]
	then
    podcast=$(grep -E '(title>)' /DATA/log/$NAME/$NAME-feed.txt | head -1 | sed -e 's/^[ \t]*//' -e 's/<title>//' -e 's/<\/title>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//' -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g" )
    episode=$(grep -E '(title>)' /DATA/log/$NAME/$NAME-feed.txt | head -4 | tail -1 | sed -e 's/^[ \t]*//' -e 's/<title>//' -e 's/<\/title>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//' -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g" )
    link=$(grep -E '(link>)' /DATA/log/$NAME/$NAME-feed.txt | head -3 | tail -1 | sed -e 's/^[ \t]*//' -e 's/<link>//' -e 's/<\/link>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//'  )
    
	#Telegram notif
	TELEGRAM="🎙️ Nouvel épisode de $podcast : 
$episode
$link"
	TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
	CHAT_ID="HERE_YOUR_CHATID"
	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null
    #ecrire le nouvel épisode
	echo "$last" > /DATA/log/$NAME/$NAME-previous.txt
fi
