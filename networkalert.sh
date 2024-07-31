#!/bin/bash

# Interface réseau à surveiller
INTERFACE="eno1"
DURATION=10  # Durée en secondes
WHITELIST_IP=("192.168.1" "10.8.0" "130.117.185" "78.127.217.252")  # Ajoutez d'autres préfixes d'IP à ignorer si nécessaire LOCAL | VPN | WASABI | MYIP 
downloadlimit=6144 # en KB
uploadlimit=5048 # en KB
STATE_FILE="/DATA/log/networkalertstate.txt" # Fichier pour stocker l'état des alertes
# Telegram
TOKEN="HERE_YOUR_TELEGRAM_TOKEN"
CHAT_ID="HERE_YOUR_CHATID"

# Lecture de l'état actuel des alertes depuis le fichier
if [[ -f "$STATE_FILE" ]]; then
  source "$STATE_FILE"
else
  alertmodedown=false
  alertmodeup=false
fi

# Exécuter iftop et capturer la sortie
IFTOP_LOG=$(sudo iftop -t -n -i $INTERFACE -B -s $DURATION 2>&1)

# Lire le contenu de IFTOP_LOG et traiter les lignes
IFS=$'\n' read -d '' -r -a lines <<< "$IFTOP_LOG"

for ((i = 0; i < ${#lines[@]}; i++)); do
  if [[ "${lines[$i]}" =~ "=>" ]]; then
    if [[ $i -lt $((${#lines[@]} - 1)) ]]; then
      next_line="${lines[$i + 1]}"
      ip=$(echo "$next_line" | awk '{print $1}')
      modified_line=$(echo "${lines[$i]}" | sed -E "s/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/$ip/")
      lines[$i]="$modified_line"
    fi
  fi
done

# Concaténer les lignes modifiées
IFTOP_IP=$(printf "%s\n" "${lines[@]}")

# Filtrer les lignes dont l'IP commence par une des IP dans WHITELIST_IP
IFTOP_IP_FILTERED="$IFTOP_IP"
for whitelist_ip in "${WHITELIST_IP[@]}"; do
  IFTOP_IP_FILTERED=$(echo "$IFTOP_IP_FILTERED" | grep -v "$whitelist_ip")
done

# Séparer les lignes de téléchargement (=>) et d'upload (<=)
IFTOP_IP_DOWNLOAD=$(echo "$IFTOP_IP_FILTERED" | grep "<=")
IFTOP_IP_UPLOAD=$(echo "$IFTOP_IP_FILTERED" | grep "=>")

# Fonction pour convertir les tailles en KB
convert_to_kb() {
  local size=$1
  local unit=$2
  local size_kb=0

  if [[ "$unit" =~ ^MB ]]; then
    size_kb=$(echo "$size * 1024" | bc)
  elif [[ "$unit" =~ ^B ]]; then
    size_kb=$(echo "$size / 1024" | bc)
  elif [[ "$unit" =~ ^KB ]]; then
    size_kb=$size
  fi

  echo "$size_kb"
}

# Convertir les tailles de téléchargement en KB et calculer la somme
total_download_kb=0
while IFS= read -r line; do
  line=$(echo "$line" | sed 's/,/./g')
  size=$(echo "$line" | awk '{print $NF}' | grep -oE '[0-9]+(\.[0-9]+)?')
  unit=$(echo "$line" | awk '{print $NF}' | grep -oE '[a-zA-Z]+')
  size_kb=$(convert_to_kb "$size" "$unit")
  total_download_kb=$(echo "$total_download_kb + $size_kb" | bc)
done <<< "$IFTOP_IP_DOWNLOAD"

# Convertir les tailles d'upload en KB et calculer la somme
total_upload_kb=0
while IFS= read -r line; do
  line=$(echo "$line" | sed 's/,/./g')
  size=$(echo "$line" | awk '{print $NF}' | grep -oE '[0-9]+(\.[0-9]+)?')
  unit=$(echo "$line" | awk '{print $NF}' | grep -oE '[a-zA-Z]+')
  size_kb=$(convert_to_kb "$size" "$unit")
  total_upload_kb=$(echo "$total_upload_kb + $size_kb" | bc)
done <<< "$IFTOP_IP_UPLOAD"

# Calculer les débits en KB/s
download_speed_kbps=$(echo "$total_download_kb / $DURATION" | bc)
upload_speed_kbps=$(echo "$total_upload_kb / $DURATION" | bc)

# Afficher le résultat final
echo "Total download: ${download_speed_kbps} KB/s"
echo "Total upload: ${upload_speed_kbps} KB/s"

# Conditions de déclenchement des alertes
if (( $(echo "$download_speed_kbps > $downloadlimit" | bc -l) )); then
  #extraire les IP et la quantité de données consommée
  SUMMARY=$(echo "$IFTOP_IP_DOWNLOAD" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}.*([0-9]+[a-zA-Z]{1,2})$' | awk '{print $1, $(NF-1)}')
  TELEGRAMDOWN=$(echo "🚨 Alerte 🛜 
Download : $download_speed_kbps KB/s
$SUMMARY")
  alertmodedown=true 
  else
  alertmodedown=false
  TELEGRAMDOWN=$(echo "✅ Fin d'alerte 🛜 
  Download : $download_speed_kbps KB/s")
fi

if (( $(echo "$upload_speed_kbps > $uploadlimit" | bc -l) )); then
  #extraire les IP et la quantité de données consommée
  SUMMARY=$(echo "$IFTOP_IP_UPLOAD" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}.*([0-9]+[a-zA-Z]{1,2})$' | awk '{print $1, $(NF-1)}')
  #envoyer l'alerte
  TELEGRAMUP=$(echo "🚨 Alerte 🛜 
Upload : $upload_speed_kbps KB/s
$SUMMARY")
  alertmodeup=true
  else
  alertmodeup=false
  TELEGRAMUP=$(echo "✅ Fin d'alerte 🛜 
  Upload : $upload_speed_kbps KB/s")
fi

#########ENVOI DES NOTIFS

# Vérifier s'il y a eu un changement d'état
if [[ "$alertmodedown" != "$ALERT_MODE_DOWN" ]]; then
  echo "Changement d'état détecté pour alertmodedown."
  if [[ "$alertmodedown" == true ]]; then
    # Envoyer la notification Telegram pour alertmodedown
    echo "Envoi de la notification Telegram pour alertmodedown."
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMDOWN" > /dev/null
  else
  	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMDOWN" > /dev/null
  fi
fi

if [[ "$alertmodeup" != "$ALERT_MODE_UP" ]]; then
  echo "Changement d'état détecté pour alertmodeup."
  if [[ "$alertmodeup" == true ]]; then
    # Envoyer la notification Telegram pour alertmodeup
    echo "Envoi de la notification Telegram pour alertmodeup."
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMUP" > /dev/null
  else 
  	curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAMUP" > /dev/null
  fi
fi

# Mettre à jour l'état dans le fichier
echo "ALERT_MODE_DOWN=$alertmodedown" > "$STATE_FILE"
echo "ALERT_MODE_UP=$alertmodeup" >> "$STATE_FILE"



exit 0
