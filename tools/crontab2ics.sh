#!/bin/bash

# Function to get day of the week
get_weekday() {
    case $1 in
        0) echo "SU" ;;
        1) echo "MO" ;;
        2) echo "TU" ;;
        3) echo "WE" ;;
        4) echo "TH" ;;
        5) echo "FR" ;;
        6) echo "SA" ;;
        *) echo "Unknown day" ;;
    esac
}

# Function to create an iCalendar event
create_ical_event() {
    local start_date="$1"
    local start_time="$2"
    local end_date="$3"
    local end_time="$4"
    local summary="$5"
    local rrule="$6"
    local all_day="$7"

    echo "BEGIN:VEVENT"
    if [ "$all_day" == "true" ]; then
        echo "DTSTART;VALUE=DATE:$start_date"
        echo "DTEND;VALUE=DATE:$end_date"
    else
        echo "DTSTART:${start_date}T${start_time}Z"
        echo "DTEND:${end_date}T${end_time}Z"
    fi
    echo "SUMMARY:$summary"
    if [ -n "$rrule" ]; then
        echo "RRULE:$rrule"
    fi
    echo "END:VEVENT"
}

# Function to print usage
print_usage() {
    echo "Usage: $0 -f <calendar_name> -d <destination_directory>"
    echo "  -f: Name of the calendar file to be created (e.g., mycalendar.ics)"
    echo "  -d: Destination directory where the calendar file will be saved"
    exit 1
}

# Parse command-line options
while getopts "f:d:" opt; do
    case $opt in
        f) calendar_file="$OPTARG" ;;
        d) destination_dir="$OPTARG" ;;
        *) print_usage ;;
    esac
done

# Check if required options are provided
if [ -z "$calendar_file" ] || [ -z "$destination_dir" ]; then
    print_usage
fi

# Ensure destination directory exists
if [ ! -d "$destination_dir" ]; then
    echo "Error: Destination directory does not exist."
    exit 1
fi

# Read the user's crontab
crontab_content=$(crontab -l)

# Check if the crontab is empty
if [ -z "$crontab_content" ]; then
    echo "Your crontab is empty."
    exit 0
fi

# Initialize the iCalendar file
ical_file="$destination_dir/$calendar_file"
echo "BEGIN:VCALENDAR" > $ical_file
echo "VERSION:2.0" >> $ical_file
echo "PRODID:-//Your Organization//Your Product//EN" >> $ical_file

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
    description="$command"

    # Default start and end times
    start_date=""
    start_time=""
    end_date=""
    end_time=""
    rrule=""
    all_day="false"

    if [[ "$minute" == "*" && "$hour" == "*" && "$day_of_month" == "*" && "$month" == "*" && "$day_of_week" == "*" ]]; then
        description="Every minute: $command"
        start_date="20240101"
        end_date="20240102"
        all_day="true"
        rrule="FREQ=DAILY;INTERVAL=1"
    elif [[ "$minute" == "*/"* ]]; then
        interval=${minute#*/}
        description="Every $interval minutes: $command"
        start_date="20240101"
        end_date="20240102"
        all_day="true"
        rrule="FREQ=MINUTELY;INTERVAL=$interval"
    elif [[ "$hour" == "*/"* ]]; then
        interval=${hour#*/}
        description="Every $interval hours: $command"
        start_date="20240101"
        start_time="$(printf '%02d' $minute)0000"
        end_date="20240101"
        end_time="$(printf '%02d' $minute)3000"
        rrule="FREQ=HOURLY;INTERVAL=$interval"
    elif [[ "$day_of_month" == "*/"* ]]; then
        interval=${day_of_month#*/}
        description="Every $interval days: $command"
        start_date="20240101"
        start_time="$(printf '%02d' $hour)$(printf '%02d' $minute)00"
        end_date="20240101"
        end_time="$(printf '%02d' $hour)$(printf '%02d' $(($minute + 30)))00"
        rrule="FREQ=DAILY;INTERVAL=$interval"
    elif [[ "$month" == "*/"* ]]; then
        interval=${month#*/}
        description="Every $interval months: $command"
        start_date="20240101"
        start_time="$(printf '%02d' $hour)$(printf '%02d' $minute)00"
        end_date="20240101"
        end_time="$(printf '%02d' $hour)$(printf '%02d' $(($minute + 30)))00"
        rrule="FREQ=MONTHLY;INTERVAL=$interval"
    elif [[ "$day_of_week" != "*" ]]; then
        day=$(get_weekday "$day_of_week")
        description="Every $day: $command"
        start_date="20240101"
        start_time="$(printf '%02d' $hour)$(printf '%02d' $minute)00"
        end_date="20240101"
        end_time="$(printf '%02d' $hour)$(printf '%02d' $(($minute + 30)))00"
        rrule="FREQ=WEEKLY;BYDAY=$day"
    elif [[ "$day_of_month" != "*" ]]; then
        day=$(printf '%02d' $day_of_month)
        description="On the $day: $command"
        start_date="202401$day"
        start_time="$(printf '%02d' $hour)$(printf '%02d' $minute)00"
        end_date="202401$day"
        end_time="$(printf '%02d' $hour)$(printf '%02d' $(($minute + 30)))00"
        rrule="FREQ=MONTHLY;BYMONTHDAY=$day_of_month"
    fi

    # Add the event to the iCalendar file
    create_ical_event "$start_date" "$start_time" "$end_date" "$end_time" "$description" "$rrule" "$all_day" >> $ical_file
done <<< "$crontab_content"

# End the iCalendar file
echo "END:VCALENDAR" >> $ical_file

echo "iCalendar file created: $ical_file"
