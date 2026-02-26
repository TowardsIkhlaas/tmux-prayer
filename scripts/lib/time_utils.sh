#!/bin/bash
# Time calculation utilities for prayer-times module

# Convert HH:MM to epoch seconds for today
time_to_epoch() {
    local time_str="$1"
    local epoch

    # macOS/BSD date
    epoch=$(date -j -f "%H:%M" "$time_str" +%s 2>/dev/null)

    if [[ -z "$epoch" ]]; then
        # GNU date fallback
        epoch=$(date -d "today $time_str" +%s 2>/dev/null)
    fi

    echo "$epoch"
}

# Convert HH:MM to epoch seconds for tomorrow
time_to_epoch_tomorrow() {
    local time_str="$1"
    local epoch

    # macOS/BSD date: get today's epoch then add 24 hours
    epoch=$(date -j -f "%H:%M" "$time_str" +%s 2>/dev/null)
    if [[ -n "$epoch" ]]; then
        epoch=$((epoch + 86400))
        echo "$epoch"
        return
    fi

    # GNU date fallback
    epoch=$(date -d "tomorrow $time_str" +%s 2>/dev/null)
    echo "$epoch"
}

# Get current epoch
now_epoch() {
    date +%s
}

# Calculate time difference and format
format_countdown() {
    local target_epoch="$1"
    local now
    local diff
    local hours
    local minutes

    now=$(now_epoch)
    diff=$((target_epoch - now))

    # If negative, time has passed
    if [[ $diff -lt 0 ]]; then
        echo "passed"
        return
    fi

    hours=$((diff / 3600))
    minutes=$(((diff % 3600) / 60))

    case "$PT_DISPLAY_FORMAT" in
        long)
            if [[ $hours -gt 0 ]]; then
                if [[ $hours -eq 1 ]]; then
                    echo "${hours} hour ${minutes} minutes"
                else
                    echo "${hours} hours ${minutes} minutes"
                fi
            else
                if [[ $minutes -eq 1 ]]; then
                    echo "${minutes} minute"
                else
                    echo "${minutes} minutes"
                fi
            fi
            ;;
        minutes)
            local total_minutes=$((diff / 60))
            echo "${total_minutes}m"
            ;;
        short|*)
            if [[ $hours -gt 0 ]]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${minutes}m"
            fi
            ;;
    esac
}

# Parse prayer times from API response
# Returns: prayer_name|time pairs, newline separated
parse_prayer_times() {
    local json="$1"
    local timings

    timings=$(echo "$json" | jq -r '.data.timings')

    # Standard five prayers
    echo "Fajr|$(echo "$timings" | jq -r '.Fajr' | cut -d' ' -f1)"
    echo "Dhuhr|$(echo "$timings" | jq -r '.Dhuhr' | cut -d' ' -f1)"
    echo "Asr|$(echo "$timings" | jq -r '.Asr' | cut -d' ' -f1)"
    echo "Maghrib|$(echo "$timings" | jq -r '.Maghrib' | cut -d' ' -f1)"
    echo "Isha|$(echo "$timings" | jq -r '.Isha' | cut -d' ' -f1)"

    # Additional prayers if configured
    if [[ -n "$PT_ADDITIONAL_PRAYERS" ]]; then
        IFS=',' read -ra extras <<< "$PT_ADDITIONAL_PRAYERS"
        for extra in "${extras[@]}"; do
            extra=$(echo "$extra" | xargs)  # trim whitespace
            case "$extra" in
                sunrise)
                    echo "Sunrise|$(echo "$timings" | jq -r '.Sunrise' | cut -d' ' -f1)"
                    ;;
                imsak)
                    echo "Imsak|$(echo "$timings" | jq -r '.Imsak' | cut -d' ' -f1)"
                    ;;
                midnight)
                    echo "Midnight|$(echo "$timings" | jq -r '.Midnight' | cut -d' ' -f1)"
                    ;;
                lastthird)
                    echo "Last Third|$(echo "$timings" | jq -r '.Lastthird' | cut -d' ' -f1)"
                    ;;
            esac
        done
    fi
}

# Find next upcoming prayer
# Input: newline-separated prayer_name|time pairs
# Output: prayer_name|time|epoch of next prayer (or empty if all passed)
find_next_prayer() {
    local prayers="$1"
    local now
    local next_prayer=""
    local next_time=""
    local next_epoch=0

    now=$(now_epoch)

    while IFS='|' read -r name time; do
        [[ -z "$name" || -z "$time" ]] && continue

        local epoch
        epoch=$(time_to_epoch "$time")

        # Skip if time has passed
        [[ $epoch -le $now ]] && continue

        # First upcoming prayer, or earlier than current next
        if [[ -z "$next_prayer" || $epoch -lt $next_epoch ]]; then
            next_prayer="$name"
            next_time="$time"
            next_epoch="$epoch"
        fi
    done <<< "$prayers"

    if [[ -n "$next_prayer" ]]; then
        echo "${next_prayer}|${next_time}|${next_epoch}"
    fi
}
