#!/bin/bash
# Output formatting for prayer-times module

# Format final output string
# Input: prayer_label, countdown, hijri_date (optional)
format_output() {
    local label="$1"
    local countdown="$2"
    local hijri_date="$3"
    local output=""

    # Add Hijri date if enabled and available
    if [[ "$PT_SHOW_HIJRI" == "true" && -n "$hijri_date" ]]; then
        output="${hijri_date} | "
    fi

    output="${output}${label} (${countdown})"

    echo "$output"
}

# Format output for "done" state (after Isha, done_icon mode)
format_done() {
    echo "$PT_DONE_ICON"
}

# Format output for tomorrow's Fajr
format_tomorrow_fajr() {
    local countdown="$1"
    local hijri_date="$2"
    local output=""

    # Add Hijri date if enabled and available
    if [[ "$PT_SHOW_HIJRI" == "true" && -n "$hijri_date" ]]; then
        output="${hijri_date} | "
    fi

    output="${output}Fajr tmrw (${countdown})"

    echo "$output"
}

# Format error/loading state
format_error() {
    echo "..."
}
