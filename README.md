# tmux-prayer-times

A tmux status bar module that displays the next Islamic prayer time with countdown. Integrates with the [catppuccin-tmux](https://github.com/catppuccin/tmux) theme.

## Features

- Displays next prayer with countdown: `Dhuhr (2h 15m)`
- Friday-aware: shows `Jumuah` instead of `Dhuhr` on Fridays
- Ramadan-aware labels: Suhoor End, Iftar, Taraweeh
- Optional Hijri date display: `2 Ramadan | Iftar (12m)`
- After Isha: shows tomorrow's Fajr or a "done" icon
- Daily caching (minimizes API calls)
- Offline fallback (uses stale cache if network unavailable)
- Auto-detects system timezone

## Prerequisites

- **tmux** with [catppuccin-tmux](https://github.com/catppuccin/tmux) theme
- **curl** - for API requests
- **jq** - for JSON parsing
- **bash** 3.2+ (macOS default works)

Install dependencies (macOS):
```bash
brew install jq
```

Install dependencies (Ubuntu/Debian):
```bash
sudo apt install curl jq
```

## Installation

### 1. Clone/copy the module

```bash
# Create directory structure
mkdir -p ~/.config/tmux-prayer-times/{cache,scripts/lib}

# Copy all files from this repo to ~/.config/tmux-prayer-times/
```

Or if you have the files:
```
~/.config/tmux-prayer-times/
├── config
├── README.md
├── cache/
└── scripts/
    ├── prayer.sh
    └── lib/
        ├── api.sh
        ├── config.sh
        ├── display.sh
        ├── ramadan.sh
        └── time_utils.sh
```

### 2. Make scripts executable

```bash
chmod +x ~/.config/tmux-prayer-times/scripts/prayer.sh
chmod +x ~/.config/tmux-prayer-times/scripts/lib/*.sh
```

### 3. Configure your location

Edit `~/.config/tmux-prayer-times/config` with your city and preferences (see [Configuration](#configuration) below).

### 4. Test the script

```bash
bash ~/.config/tmux-prayer-times/scripts/prayer.sh
```

You should see output like: `Dhuhr (2h 15m)`

### 5. Add catppuccin module

Create `~/.config/tmux/plugins/catppuccin-tmux/custom/prayer_times.sh`:

```bash
show_prayer_times() {
  local index=$1
  local icon="$(get_tmux_option "@catppuccin_prayer_times_icon" "󱠧")"
  local color="$(get_tmux_option "@catppuccin_prayer_times_color" "$thm_green")"
  local text="$(get_tmux_option "@catppuccin_prayer_times_text" "#($HOME/.config/prayer-times/scripts/prayer.sh)")"
  local module=$(build_status_module "$index" "$icon" "$color" "$text")
  echo "$module"
}
```

### 6. Update tmux.conf

Add `prayer_times` to your status modules:

```bash
set -g @catppuccin_status_modules_right "prayer_times"
set -g @catppuccin_prayer_times_text "#($HOME/.config/prayer-times/scripts/prayer.sh)"
```

### 7. Reload tmux

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

## Configuration

Edit `~/.config/tmux-prayer-times/config`. All options use `key=value` format.

### Location (required)

You must set **either** city/country **or** latitude/longitude.

| Option | Description | Example |
|--------|-------------|---------|
| `city` | City name | `Chicago`, `St. John's`, `London` |
| `country` | Country name or code | `USA`, `Canada`, `UK` |
| `latitude` | Decimal latitude (more precise) | `41.8781` |
| `longitude` | Decimal longitude (more precise) | `-87.6298` |

**Tip**: For most accurate times, use exact coordinates from Google Maps.

### Timezone

| Option | Description | Example |
|--------|-------------|---------|
| `timezone` | IANA timezone or `auto` | `America/Chicago`, `auto` |

Using `auto` detects from system settings (recommended).

### Calculation Method

| Option | Description | Default |
|--------|-------------|---------|
| `method` | Calculation method (0-23) | `2` (ISNA) |

Different organizations use different angles for Fajr and Isha. Common methods:

| Value | Method | Region |
|-------|--------|--------|
| `0` | Jafari / Shia Ithna-Ashari | Iran, Iraq |
| `1` | University of Islamic Sciences, Karachi | Pakistan, Bangladesh |
| `2` | Islamic Society of North America (ISNA) | North America |
| `3` | Muslim World League | Europe, Far East |
| `4` | Umm Al-Qura University, Makkah | Saudi Arabia |
| `5` | Egyptian General Authority of Survey | Africa, Middle East |
| `7` | Institute of Geophysics, University of Tehran | Iran |
| `8` | Gulf Region | UAE, Kuwait, Qatar |
| `9` | Kuwait | Kuwait |
| `10` | Qatar | Qatar |
| `11` | Majlis Ugama Islam Singapura | Singapore |
| `12` | Union Organization Islamic de France | France |
| `13` | Diyanet İşleri Başkanlığı | Turkey |
| `14` | Spiritual Administration of Muslims of Russia | Russia |
| `15` | Moonsighting Committee Worldwide | North America (alternative) |

Full list: https://aladhan.com/calculation-methods

### Juristic School

| Option | Description | Default |
|--------|-------------|---------|
| `school` | Asr calculation school | `0` |

| Value | School | Asr Timing |
|-------|--------|------------|
| `0` | Shafi'i, Maliki, Hanbali | Earlier (shadow = object length) |
| `1` | Hanafi | Later (shadow = 2× object length) |

### Additional Prayers

| Option | Description | Default |
|--------|-------------|---------|
| `additional_prayers` | Comma-separated list | (empty) |

Options: `sunrise`, `imsak`, `midnight`, `lastthird`

Example: `additional_prayers=sunrise,midnight`

### Ramadan Settings

| Option | Description | Default |
|--------|-------------|---------|
| `ramadan_aware` | Use contextual labels during Ramadan | `true` |
| `hijri_adjustment` | Adjust Hijri date (-2 to +2) | `0` |
| `show_hijri` | Show Hijri date in output | `false` |

When `ramadan_aware=true` and it's Ramadan:
- Fajr → "Suhoor End"
- Maghrib → "Iftar"
- Isha → "Taraweeh"

### Display Settings

| Option | Description | Default |
|--------|-------------|---------|
| `display_format` | Countdown format | `short` |
| `after_isha` | Behavior after Isha | `tomorrow_fajr` |
| `done_icon` | Icon when prayers complete | `󱠧` |

**display_format** options:
- `short` → `2h 15m`
- `long` → `2 hours 15 minutes`
- `minutes` → `135m`

**after_isha** options:
- `tomorrow_fajr` → Shows `Fajr tmrw (7h 30m)`
- `done_icon` → Shows just the icon

## Example Configurations

### North America (ISNA, Hanafi)
```
city=Chicago
country=USA
timezone=auto
method=2
school=1
ramadan_aware=true
```

### UK (Muslim World League, Shafi'i)
```
city=London
country=UK
timezone=auto
method=3
school=0
ramadan_aware=true
```

### Saudi Arabia (Umm Al-Qura)
```
city=Riyadh
country=Saudi Arabia
timezone=auto
method=4
school=1
ramadan_aware=true
```

### Using coordinates (most precise)
```
latitude=47.5615
longitude=-52.7126
timezone=auto
method=2
school=1
```

## Display Examples

| State | Output |
|-------|--------|
| Normal | `Dhuhr (2h 15m)` |
| Friday (Dhuhr time) | `Jumuah (2h 15m)` |
| After Isha (tomorrow mode) | `Fajr tmrw (7h 30m)` |
| After Isha (done mode) | `󱠧` |
| Ramadan, before Fajr | `Suhoor End (45m)` |
| Ramadan, near Maghrib | `Iftar (12m)` |
| Ramadan, after Maghrib | `Taraweeh (1h 5m)` |
| With Hijri enabled | `2 Ramadan | Iftar (12m)` |
| API error, no cache | `...` |

## Troubleshooting

### Script returns `...`
- Check internet connection
- Verify city/country spelling (or use lat/long)
- Check `~/.config/tmux-prayer-times/cache/` for cached files

### Wrong prayer times
- Verify your calculation method matches your local mosque
- Check latitude/longitude are correct
- Adjust `hijri_adjustment` if Hijri date is off

### Timezone issues
- Set `timezone=auto` to use system settings
- Or specify explicitly: `timezone=America/New_York`

### Debug mode
```bash
bash -x ~/.config/tmux-prayer-times/scripts/prayer.sh
```

## Cache

Prayer times are cached daily in `~/.config/tmux-prayer-times/cache/DD-MM-YYYY.json`. The cache:
- Prevents excessive API calls (tmux refreshes frequently)
- Enables offline operation
- Auto-cleans files older than 7 days

To force refresh, delete the cache:
```bash
rm ~/.config/tmux-prayer-times/cache/*.json
```

## API

Uses the free [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api). No API key required.

## License

MIT
