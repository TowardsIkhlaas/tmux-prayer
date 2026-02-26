#!/bin/bash
# Main prayer-times script for tmux status bar
# Called via tmux #() command

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source library modules
source "${LIB_DIR}/config.sh"
source "${LIB_DIR}/api.sh"
source "${LIB_DIR}/time_utils.sh"
source "${LIB_DIR}/ramadan.sh"
source "${LIB_DIR}/display.sh"

main() {
    # Load configuration
    load_config

    # Get prayer data (from cache or API)
    local prayer_data
    prayer_data=$(get_prayer_data)

    if [[ -z "$prayer_data" ]]; then
        format_error
        return
    fi

    # Check if it's Ramadan
    local in_ramadan="false"
    if [[ "$PT_RAMADAN_AWARE" == "true" ]] && is_ramadan "$prayer_data"; then
        in_ramadan="true"
    fi

    # Check if it's Friday (for Jumuah)
    local on_friday="false"
    if is_friday "$prayer_data"; then
        on_friday="true"
    fi

    # Get Hijri date if needed
    local hijri_date=""
    if [[ "$PT_SHOW_HIJRI" == "true" ]]; then
        hijri_date=$(get_hijri_date "$prayer_data")
    fi

    # Parse and find next prayer
    local prayers
    prayers=$(parse_prayer_times "$prayer_data")

    local next_prayer_info
    next_prayer_info=$(find_next_prayer "$prayers")

    if [[ -n "$next_prayer_info" ]]; then
        # We have an upcoming prayer today
        IFS='|' read -r prayer_name prayer_time prayer_epoch <<< "$next_prayer_info"

        # Get contextual label (Ramadan-aware, Friday-aware)
        local label
        label=$(get_prayer_label "$prayer_name" "$in_ramadan" "$on_friday")

        # Format countdown
        local countdown
        countdown=$(format_countdown "$prayer_epoch")

        # Output
        format_output "$label" "$countdown" "$hijri_date"
    else
        # All prayers done for today
        case "$PT_AFTER_ISHA" in
            done_icon)
                format_done
                ;;
            tomorrow_fajr|*)
                # Get tomorrow's Fajr time
                local tomorrow_data
                tomorrow_data=$(get_tomorrow_prayer_data)

                if [[ -n "$tomorrow_data" ]]; then
                    local fajr_time
                    fajr_time=$(echo "$tomorrow_data" | jq -r '.data.timings.Fajr' | cut -d' ' -f1)

                    if [[ -n "$fajr_time" && "$fajr_time" != "null" ]]; then
                        local fajr_epoch
                        fajr_epoch=$(time_to_epoch_tomorrow "$fajr_time")

                        local countdown
                        countdown=$(format_countdown "$fajr_epoch")

                        format_tomorrow_fajr "$countdown" "$hijri_date"
                    else
                        format_done
                    fi
                else
                    format_done
                fi
                ;;
        esac
    fi

    # Cleanup old cache files (run occasionally)
    if [[ $((RANDOM % 100)) -eq 0 ]]; then
        cleanup_cache
    fi
}

main
