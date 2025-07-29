#!/usr/bin/env zsh

# Color configuration for zsh-keywords-highlight
# Users can modify these colors to customize the highlighting

# Initialize color array if not already declared
typeset -gA ZKH_COLORS

# ANSI color codes
# Reset color
ZKH_COLORS[reset]=$'\033[0m'

# Basic colors for different keyword types
ZKH_COLORS[info]=$'\033[32m'        # Green for info keywords
ZKH_COLORS[error]=$'\033[31m'       # Red for error keywords
ZKH_COLORS[warning]=$'\033[33m'     # Yellow for warning keywords
ZKH_COLORS[success]=$'\033[92m'     # Bright green for success
ZKH_COLORS[debug]=$'\033[36m'       # Cyan for debug
ZKH_COLORS[important]=$'\033[35m'   # Magenta for important
ZKH_COLORS[notice]=$'\033[94m'      # Bright blue for notices

# Additional style options (can be combined with colors)
ZKH_COLORS[bold]=$'\033[1m'
ZKH_COLORS[underline]=$'\033[4m'
ZKH_COLORS[italic]=$'\033[3m'
ZKH_COLORS[dim]=$'\033[2m'

# Background colors (optional)
ZKH_COLORS[bg_red]=$'\033[41m'
ZKH_COLORS[bg_green]=$'\033[42m'
ZKH_COLORS[bg_yellow]=$'\033[43m'
ZKH_COLORS[bg_blue]=$'\033[44m'
ZKH_COLORS[bg_magenta]=$'\033[45m'
ZKH_COLORS[bg_cyan]=$'\033[46m'

# Custom color combinations (you can add more)
ZKH_COLORS[critical]=$'\033[1;31m'  # Bold red
ZKH_COLORS[highlight]=$'\033[1;33m' # Bold yellow

# Function to set custom color for a keyword type
zkh_set_color() {
    local color_key="$1"
    local color_code="$2"
    
    if [[ -z "$color_key" || -z "$color_code" ]]; then
        echo "Usage: zkh_set_color <color_key> <color_code>"
        echo "Example: zkh_set_color error $'\\033[1;31m'"
        return 1
    fi
    
    ZKH_COLORS[$color_key]="$color_code"
    echo "Set color for '$color_key' to '$color_code'"
}

# Function to list available colors
zkh_list_colors() {
    local color_key color_code
    echo "Available colors:"
    for color_key color_code in "${(@kv)ZKH_COLORS}"; do
        if [[ "$color_key" != "reset" ]]; then
            # Display the color name with the actual color applied
            printf "%s%s%s\n" "$color_code" "$color_key" "${ZKH_COLORS[reset]}"
        fi
    done
}

# Function to reset colors to defaults
zkh_reset_colors() {
    # Clear existing colors
    ZKH_COLORS=()
    
    # Reload this file
    source "${${(%):-%x}:A}"
    echo "Colors reset to defaults"
}
