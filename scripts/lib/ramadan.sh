#!/bin/bash
# Ramadan and contextual prayer label awareness

# Check if current month is Ramadan (Hijri month 9)
is_ramadan() {
    local json="$1"
    local hijri_month

    hijri_month=$(echo "$json" | jq -r '.data.date.hijri.month.number' 2>/dev/null)

    [[ "$hijri_month" == "9" ]]
}

# Check if today is Friday (for Jumuah)
is_friday() {
    local json="$1"
    local weekday

    weekday=$(echo "$json" | jq -r '.data.date.gregorian.weekday.en' 2>/dev/null)

    [[ "$weekday" == "Friday" ]]
}

# Get contextual label for a prayer
# Input: prayer_name, is_ramadan (true/false), is_friday (true/false)
# Output: contextual label
get_prayer_label() {
    local prayer_name="$1"
    local in_ramadan="$2"
    local on_friday="$3"

    # Friday: Dhuhr becomes Jumuah
    if [[ "$prayer_name" == "Dhuhr" && "$on_friday" == "true" ]]; then
        echo "Jumuah"
        return
    fi

    # Ramadan contextual labels
    if [[ "$in_ramadan" == "true" ]]; then
        case "$prayer_name" in
            Fajr)
                echo "Suhoor End"
                return
                ;;
            Maghrib)
                echo "Iftar"
                return
                ;;
            Isha)
                echo "Taraweeh"
                return
                ;;
        esac
    fi

    echo "$prayer_name"
}

# Legacy function for backwards compatibility
get_ramadan_label() {
    local prayer_name="$1"
    local in_ramadan="$2"
    get_prayer_label "$prayer_name" "$in_ramadan" "false"
}

# Get Hijri date string
get_hijri_date() {
    local json="$1"
    local day month

    day=$(echo "$json" | jq -r '.data.date.hijri.day' 2>/dev/null)
    month=$(echo "$json" | jq -r '.data.date.hijri.month.en' 2>/dev/null)

    if [[ -n "$day" && -n "$month" && "$day" != "null" && "$month" != "null" ]]; then
        echo "${day} ${month}"
    fi
}
