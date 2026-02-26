#!/bin/bash
# Config parser for prayer-times module

CONFIG_FILE="${HOME}/.config/prayer-times/config"

# Uppercase conversion (compatible with bash 3.2)
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Get system timezone (IANA format) from macOS/Linux settings
detect_timezone() {
    local tz=""

    # macOS: read from /etc/localtime symlink
    if [[ -L /etc/localtime ]]; then
        tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
    fi

    # Fallback: try timedatectl (Linux)
    if [[ -z "$tz" ]] && command -v timedatectl &>/dev/null; then
        tz=$(timedatectl show --property=Timezone --value 2>/dev/null)
    fi

    # Fallback: use TZ env var
    if [[ -z "$tz" && -n "$TZ" ]]; then
        tz="$TZ"
    fi

    echo "$tz"
}

load_config() {
    # Set defaults
    export PT_CITY=""
    export PT_COUNTRY=""
    export PT_LATITUDE=""
    export PT_LONGITUDE=""
    export PT_TIMEZONE="America/Chicago"
    export PT_METHOD="2"
    export PT_SCHOOL="0"
    export PT_ADDITIONAL_PRAYERS=""
    export PT_RAMADAN_AWARE="true"
    export PT_HIJRI_ADJUSTMENT="0"
    export PT_SHOW_HIJRI="false"
    export PT_DISPLAY_FORMAT="short"
    export PT_AFTER_ISHA="tomorrow_fajr"
    export PT_DONE_ICON="󱠧"

    # Read config file if it exists
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue

            # Trim whitespace (sed handles apostrophes better than xargs)
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Skip if no value
            [[ -z "$value" ]] && continue

            # Export as PT_* variable (uppercase)
            local upper_key
            upper_key=$(to_upper "$key")
            export "PT_${upper_key}"="$value"
        done < "$CONFIG_FILE"
    fi

    # Auto-detect timezone if set to "auto"
    if [[ "$PT_TIMEZONE" == "auto" ]]; then
        PT_TIMEZONE=$(detect_timezone)
        export PT_TIMEZONE
    fi
}

get_config() {
    local key="$1"
    local upper_key
    upper_key=$(to_upper "$key")
    eval "echo \"\$PT_${upper_key}\""
}
