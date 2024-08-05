#!/bin/bash

# Vérifie l'utilisation de la mémoire en pourcentage
memory_usage=$(free | awk '/Mem:/ { printf("%.0f"), $3/$2*100 }')

# Si l'utilisation de la mémoire est supérieure à 90%
if [ "$memory_usage" -gt 90 ]; then
    echo "Mémoire utilisée: $memory_usage%. Arrêt et redémarrage des dockers non essentiels"
    
    # Lancer le script stopdockers.sh
    /scripts/stopdockers.sh
    
    # Lancer le script startdockers.sh
    /scripts/startdockers.sh
    
    #Telegram notif

	TOKEN="YOUR_TELEGRAM_TOKEN_HERE"

	CHAT_ID="TELEGRAM_CHATID_HERE"

	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="❗ RAM à $memory_usage%
    Les dockers non essentiels ont été relancés" > /dev/null
    
else
    echo "Mémoire utilisée: $memory_usage%. Aucune action."
fi