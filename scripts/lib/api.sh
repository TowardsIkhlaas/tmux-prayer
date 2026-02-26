#!/bin/bash
# Aladhan API client with caching

CACHE_DIR="${HOME}/.config/prayer-times/cache"
API_BASE="https://api.aladhan.com/v1"
API_TIMEOUT=5

# URL encode a string (handles spaces, apostrophes, etc.)
urlencode() {
    local string="$1"
    local encoded=""
    local i char

    for (( i=0; i<${#string}; i++ )); do
        char="${string:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-]) encoded+="$char" ;;
            ' ') encoded+="%20" ;;
            *) encoded+=$(printf '%%%02X' "'$char") ;;
        esac
    done
    echo "$encoded"
}

get_cache_file() {
    local date_str
    date_str=$(date +"%d-%m-%Y")
    echo "${CACHE_DIR}/${date_str}.json"
}

get_tomorrow_cache_file() {
    local date_str
    # macOS/BSD date
    date_str=$(date -v+1d +"%d-%m-%Y" 2>/dev/null)
    if [[ -z "$date_str" ]]; then
        # GNU date fallback
        date_str=$(date -d "tomorrow" +"%d-%m-%Y" 2>/dev/null)
    fi
    echo "${CACHE_DIR}/${date_str}.json"
}

is_cache_valid() {
    local cache_file="$1"
    [[ -f "$cache_file" && -s "$cache_file" ]]
}

fetch_prayer_times() {
    local date_str="$1"
    local url
    local response

    # Build API URL based on available location data
    if [[ -n "$PT_LATITUDE" && -n "$PT_LONGITUDE" ]]; then
        url="${API_BASE}/timings/${date_str}?latitude=${PT_LATITUDE}&longitude=${PT_LONGITUDE}"
    elif [[ -n "$PT_CITY" && -n "$PT_COUNTRY" ]]; then
        local encoded_city encoded_country
        encoded_city=$(urlencode "$PT_CITY")
        encoded_country=$(urlencode "$PT_COUNTRY")
        url="${API_BASE}/timingsByCity/${date_str}?city=${encoded_city}&country=${encoded_country}"
    else
        echo ""
        return 1
    fi

    # Add common parameters
    url="${url}&method=${PT_METHOD}&school=${PT_SCHOOL}"

    if [[ -n "$PT_HIJRI_ADJUSTMENT" && "$PT_HIJRI_ADJUSTMENT" != "0" ]]; then
        url="${url}&adjustment=${PT_HIJRI_ADJUSTMENT}"
    fi

    # Fetch with timeout
    response=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" "$url" 2>/dev/null)

    # Validate response
    if [[ -n "$response" ]] && echo "$response" | jq -e '.code == 200' >/dev/null 2>&1; then
        echo "$response"
        return 0
    fi

    echo ""
    return 1
}

get_prayer_data() {
    local cache_file
    local response

    cache_file=$(get_cache_file)

    # Try cache first
    if is_cache_valid "$cache_file"; then
        cat "$cache_file"
        return 0
    fi

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Fetch from API
    local today
    today=$(date +"%d-%m-%Y")
    response=$(fetch_prayer_times "$today")

    if [[ -n "$response" ]]; then
        echo "$response" > "$cache_file"
        echo "$response"
        return 0
    fi

    # Fallback to stale cache (any recent file)
    local stale_cache
    stale_cache=$(find "$CACHE_DIR" -name "*.json" -mtime -7 -type f 2>/dev/null | head -1)
    if [[ -n "$stale_cache" && -f "$stale_cache" ]]; then
        cat "$stale_cache"
        return 0
    fi

    echo ""
    return 1
}

get_tomorrow_prayer_data() {
    local cache_file
    local response

    cache_file=$(get_tomorrow_cache_file)

    # Try cache first
    if is_cache_valid "$cache_file"; then
        cat "$cache_file"
        return 0
    fi

    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Fetch from API
    local tomorrow
    # macOS/BSD date
    tomorrow=$(date -v+1d +"%d-%m-%Y" 2>/dev/null)
    if [[ -z "$tomorrow" ]]; then
        # GNU date fallback
        tomorrow=$(date -d "tomorrow" +"%d-%m-%Y" 2>/dev/null)
    fi

    response=$(fetch_prayer_times "$tomorrow")

    if [[ -n "$response" ]]; then
        echo "$response" > "$cache_file"
        echo "$response"
        return 0
    fi

    echo ""
    return 1
}

# Clean up old cache files (keep last 7 days)
cleanup_cache() {
    find "$CACHE_DIR" -name "*.json" -mtime +7 -type f -delete 2>/dev/null
}
