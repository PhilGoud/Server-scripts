#!/bin/bash

# Reads crontab and orders it in a easily understandable way
# Helped me to check for inconsistencies I missed

# Function to get day of the week
get_weekday() {
    case $1 in
        0) echo "Sunday" ;;
        1) echo "Monday" ;;
        2) echo "Tuesday" ;;
        3) echo "Wednesday" ;;
        4) echo "Thursday" ;;
        5) echo "Friday" ;;
        6) echo "Saturday" ;;
        *) echo "Unknown day" ;;
    esac
}

# Function to get month
get_month() {
    case $1 in
        1) echo "January" ;;
        2) echo "February" ;;
        3) echo "March" ;;
        4) echo "April" ;;
        5) echo "May" ;;
        6) echo "June" ;;
        7) echo "July" ;;
        8) echo "August" ;;
        9) echo "September" ;;
        10) echo "October" ;;
        11) echo "November" ;;
        12) echo "December" ;;
        *) echo "Unknown month" ;;
    esac
}

# Function to get day suffix
get_day_suffix() {
    case $1 in
        1 | 21 | 31) echo "${1}st" ;;
        2 | 22) echo "${1}nd" ;;
        3 | 23) echo "${1}rd" ;;
        *) echo "${1}th" ;;
    esac
}

# Read the user's crontab
crontab_content=$(crontab -l)

# Check if the crontab is empty
if [ -z "$crontab_content" ]; then
    echo "Your crontab is empty."
    exit 0
fi

# Initialize arrays to hold different types of scripts
minute_based_scripts=()
hour_based_scripts=()
day_based_scripts=()
month_based_scripts=()

# Parse each line of the crontab
while read -r line; do
    # Skip comment lines and empty lines
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi

    # Extract time fields and the command
    minute=$(echo "$line" | awk '{print $1}')
    hour=$(echo "$line" | awk '{print $2}')
    day_of_month=$(echo "$line" | awk '{print $3}')
    month=$(echo "$line" | awk '{print $4}')
    day_of_week=$(echo "$line" | awk '{print $5}')
    command=$(echo "$line" | cut -d ' ' -f 6-)

    # Build the readable description
    description=""

    if [[ "$minute" == "*" && "$hour" == "*" && "$day_of_month" == "*" && "$month" == "*" && "$day_of_week" == "*" ]]; then
        description+="Every 01 minutes"
   	 elif [[ "$minute" == "0" && "$hour" == "*" && "$day_of_month" == "*" && "$month" == "*" && "$day_of_week" == "*" ]]; then
        description+="Every 01 hours"
   	 elif [[ "$minute" == "*/"* ]]; then
        NB_carac=$(echo -n "${minute#*/}" | wc -m  )
        if [[ "$NB_carac" == 1 ]]; then
        description+="Every 0${minute#*/} minutes"        
        else
        description+="Every ${minute#*/} minutes"
		fi
    fi

    if [[ "$hour" == "*/"* ]]; then
        description+=", every ${hour#*/} hours"
   	 elif [[ "$hour" != "*" ]]; then
        description+="$(printf '%02d' "$hour"):$(printf '%02d' "$minute")"
    fi

    if [[ "$day_of_month" == "*/"* ]]; then
        description+=", every ${day_of_month#*/} days"
  	  elif [[ "$day_of_month" != "*" ]]; then
        description+=", on the $(get_day_suffix "$day_of_month")"
    fi

    if [[ "$month" == "*/"* ]]; then
        description+=", every ${month#*/} months"
  	  elif [[ "$month" != "*" ]]; then
        description+=", in $(get_month "$month")"
    fi

    if [ "$day_of_week" != "*" ]; then
        description+=", on $(get_weekday "$day_of_week")"
    fi

    # Add the command
    description+=": $command"

    # Add to the appropriate array based on the frequency criteria
    if [[ "$minute" == "*" && "$hour" == "*" && "$day_of_month" == "*" && "$month" == "*" && "$day_of_week" == "*" ]]; then
        minute_based_scripts+=("$description")
  	  elif [[ "$minute" == "*/"* ]]; then
        minute_based_scripts+=("$description")
  	  elif [[ "$minute" != "*" && "$hour" == "*" ]]; then
        minute_based_scripts+=("$description")
  	  elif [[ "$hour" == "*/"* || ( "$hour" != "*" && "$day_of_month" == "*" && "$day_of_week" == "*" ) ]]; then
        hour_based_scripts+=("$description")
  	  elif [[ "$day_of_week" != "*" ]]; then
        day_based_scripts+=("$description")
  	  elif [[ "$day_of_month" == "*/"* || ( "$day_of_month" != "*" && "$month" == "*" ) ]]; then
        day_based_scripts+=("$description")
  	  elif [[ "$month" == "*/"* || "$month" != "*" ]]; then
        month_based_scripts+=("$description")
    fi
done <<< "$crontab_content"

# Function to sort and print scripts
print_sorted_scripts() {
    local scripts=("$@")
    for script in "${scripts[@]}"; do
        echo "$script"
    done | sort
}

# Print the results
echo "Your crontab summary:"
echo
print_sorted_scripts "${minute_based_scripts[@]}"
echo
print_sorted_scripts "${hour_based_scripts[@]}"
echo
print_sorted_scripts "${day_based_scripts[@]}"
echo
print_sorted_scripts "${month_based_scripts[@]}"
