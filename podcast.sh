#!/bin/sh

#THIS SCRIPT WILL GIVE YOU A NOTIFICATION IF RSS FEED OF A PODCAST HAS A NEW ITEM

# TELEGRAM CREDENTIALS
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CHAT_ID="XXXXXXXXXXXX"

# RSS feed infos
RSS_URL="https://feed-url-here.com/rss"
NAME="The name of the feed"

# Specify the base path
BASE_PATH="/DATA/log/$NAME"

# Check if directory exists, if not create it
if test -d $BASE_PATH/; 
then 
    continue
else
    mkdir -p $BASE_PATH/
fi

# Fetch the RSS feed
curl --silent "$RSS_URL" -o $BASE_PATH/$NAME-feed.txt

# Verify that the feed is not broken, otherwise exit
test=$(cat $BASE_PATH/$NAME-feed.txt | head -1 | sed -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g" -e 's/\s//' -e 's/\t//' -e 's/\n//' | head -c 3)

if [ "$test" = "xml" ]; 
then
    continue
else
    echo "feed error"
    echo "$test"
    exit
fi

# Check GUID
# Isolate the last GUID and clean it up a bit
last=$(grep -E '(guid>)' $BASE_PATH/$NAME-feed.txt | head -1 | sed -e 's/^[ \t]*//' -e 's/<guid isPermaLink="false">//' -e 's/<\/guid>//')
previous=$(grep -e '' $BASE_PATH/$NAME-previous.txt)

# Check if the last GUID has changed, if yes, notify
if [ "$last" != "$previous" ]; 
then
    podcast=$(grep -E '(title>)' $BASE_PATH/$NAME-feed.txt | head -1 | sed -e 's/^[ \t]*//' -e 's/<title>//' -e 's/<\/title>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//' -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g")
    episode=$(grep -E '(title>)' $BASE_PATH/$NAME-feed.txt | head -4 | tail -1 | sed -e 's/^[ \t]*//' -e 's/<title>//' -e 's/<\/title>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//' -e "s/[\"\'\`\?\&\<\>\/\=\:\[\]//g")
    link=$(grep -E '(link>)' $BASE_PATH/$NAME-feed.txt | head -3 | tail -1 | sed -e 's/^[ \t]*//' -e 's/<link>//' -e 's/<\/link>//' -e 's/<title><\!\[CDATA\[//' -e 's/\]\]><\/title>//' -e 's/<\!\[CDATA\[//' -e 's/\]\]>//')

    # Telegram notification
    TELEGRAM="🎙️ New episode of $podcast: 
$episode
$link"

    # Send the message via Telegram
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$TELEGRAM" > /dev/null

    # Write the new episode
    echo "$last" > $BASE_PATH/$NAME-previous.txt
fi
