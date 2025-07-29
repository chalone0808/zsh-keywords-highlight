#!/usr/bin/env zsh

# zsh-keywords-highlight - Highlight keywords in stdout/stderr output
# Usage: source this file in your .zshrc or run it directly

# Initialize color array if not already declared
typeset -gA ZKH_COLORS

# Get the directory where this script is located
ZKH_SCRIPT_DIR="${0:A:h}"

# Source color configuration
source "${ZKH_SCRIPT_DIR}/colors.zsh"

# Arrays to store keywords by type
typeset -ga ZKH_ERROR_KEYWORDS
typeset -ga ZKH_WARNING_KEYWORDS
typeset -ga ZKH_INFO_KEYWORDS

# Load keywords from files
zkh_load_keywords() {
    local keywords_dir="${ZKH_SCRIPT_DIR}/keywords"
    
    # Clear arrays first
    ZKH_ERROR_KEYWORDS=()
    ZKH_WARNING_KEYWORDS=()
    ZKH_INFO_KEYWORDS=()
    
    # Load error keywords
    if [[ -f "${keywords_dir}/keywords_error.zsh" ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue
            # Trim whitespace
            line="${line## }"
            line="${line%% }"
            [[ -n "$line" ]] && ZKH_ERROR_KEYWORDS+=("$line")
        done < "${keywords_dir}/keywords_error.zsh"
    fi
    
    # Load warning keywords
    if [[ -f "${keywords_dir}/keywords_warning.zsh" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue
            line="${line## }"
            line="${line%% }"
            [[ -n "$line" ]] && ZKH_WARNING_KEYWORDS+=("$line")
        done < "${keywords_dir}/keywords_warning.zsh"
    fi
    
    # Load info keywords
    if [[ -f "${keywords_dir}/keywords_info.zsh" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]] && continue
            line="${line## }"
            line="${line%% }"
            [[ -n "$line" ]] && ZKH_INFO_KEYWORDS+=("$line")
        done < "${keywords_dir}/keywords_info.zsh"
    fi
}

# Function to highlight a single line
zkh_highlight_line() {
    local line="$1"
    local highlighted_line="$line"
    
    # Debug: show what we're working with
    # echo "DEBUG: Processing line: '$line'" >&2
    
    # Create arrays sorted by word count (longest phrases first)
    local -a error_keywords_sorted warning_keywords_sorted info_keywords_sorted
    
    # Sort error keywords by length (longest first to handle phrases before individual words)
    for keyword in "${ZKH_ERROR_KEYWORDS[@]}"; do
        [[ -n "$keyword" ]] && error_keywords_sorted+=("$keyword")
    done
    error_keywords_sorted=(${(On)error_keywords_sorted})
    
    # Sort warning keywords by length
    for keyword in "${ZKH_WARNING_KEYWORDS[@]}"; do
        [[ -n "$keyword" ]] && warning_keywords_sorted+=("$keyword")
    done
    warning_keywords_sorted=(${(On)warning_keywords_sorted})
    
    # Sort info keywords by length  
    for keyword in "${ZKH_INFO_KEYWORDS[@]}"; do
        [[ -n "$keyword" ]] && info_keywords_sorted+=("$keyword")
    done
    info_keywords_sorted=(${(On)info_keywords_sorted})
    
    # Highlight error keywords (highest priority, longest phrases first)
    for keyword in "${error_keywords_sorted[@]}"; do
        if [[ -n "$keyword" && "$highlighted_line" == *"$keyword"* ]]; then
            # Check if this keyword is not already part of a highlighted phrase
            if [[ "$highlighted_line" != *"${ZKH_COLORS[error]}"*"$keyword"*"${ZKH_COLORS[reset]}"* ]]; then
                highlighted_line="${highlighted_line//$keyword/${ZKH_COLORS[error]}$keyword${ZKH_COLORS[reset]}}"
            fi
        fi
    done
    
    # Highlight warning keywords (medium priority)
    for keyword in "${warning_keywords_sorted[@]}"; do
        if [[ -n "$keyword" && "$highlighted_line" == *"$keyword"* ]]; then
            # Only highlight if not already colored
            if [[ "$highlighted_line" != *"${ZKH_COLORS[error]}"*"$keyword"*"${ZKH_COLORS[reset]}"* && 
                  "$highlighted_line" != *"${ZKH_COLORS[warning]}"*"$keyword"*"${ZKH_COLORS[reset]}"* ]]; then
                highlighted_line="${highlighted_line//$keyword/${ZKH_COLORS[warning]}$keyword${ZKH_COLORS[reset]}}"
            fi
        fi
    done
    
    # Highlight info keywords (lowest priority)  
    for keyword in "${info_keywords_sorted[@]}"; do
        if [[ -n "$keyword" && "$highlighted_line" == *"$keyword"* ]]; then
            # Only highlight if not already colored
            if [[ "$highlighted_line" != *"${ZKH_COLORS[error]}"*"$keyword"*"${ZKH_COLORS[reset]}"* && 
                  "$highlighted_line" != *"${ZKH_COLORS[warning]}"*"$keyword"*"${ZKH_COLORS[reset]}"* &&
                  "$highlighted_line" != *"${ZKH_COLORS[info]}"*"$keyword"*"${ZKH_COLORS[reset]}"* ]]; then
                highlighted_line="${highlighted_line//$keyword/${ZKH_COLORS[info]}$keyword${ZKH_COLORS[reset]}}"
            fi
        fi
    done
    
    printf '%s\n' "$highlighted_line"
}

# Debug function to test highlighting
zkh_debug() {
    local test_line="$1"
    echo "Testing line: '$test_line'"
    echo "Error keywords count: ${#ZKH_ERROR_KEYWORDS[@]}"
    echo "First error keyword: '${ZKH_ERROR_KEYWORDS[1]}'"
    echo "Color test: ${ZKH_COLORS[error]}RED${ZKH_COLORS[reset]}"
    echo "Highlighted result:"
    zkh_highlight_line "$test_line"
}

# Function to process input stream and highlight keywords
zkh_highlight_stream() {
    while IFS= read -r line; do
        zkh_highlight_line "$line"
    done
}

# Function to run a command with keyword highlighting
zkh_run() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zkh_run <command> [args...]"
        echo "Example: zkh_run ls -la"
        return 1
    fi
    
    # Run command and pipe both stdout and stderr through our highlighter
    "$@" 2>&1 | zkh_highlight_stream
}

# Function to monitor a log file with highlighting
zkh_tail() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zkh_tail <logfile> [tail_args...]"
        echo "Example: zkh_tail /var/log/syslog -f"
        return 1
    fi
    
    local logfile="$1"
    shift
    
    if [[ ! -f "$logfile" ]]; then
        echo "Error: File '$logfile' not found"
        return 1
    fi
    
    # Use tail with the provided arguments and highlight output
    tail "$@" "$logfile" | zkh_highlight_stream
}

# Function to enable keyword highlighting for all command output (experimental)
zkh_enable_global() {
    echo "Enabling global keyword highlighting..."
    echo "Note: This is experimental and may affect performance"
    
    # Create a wrapper function for common commands
    for cmd in ls cat grep tail head less more; do
        if command -v "$cmd" &> /dev/null; then
            eval "
            ${cmd}_orig() { command $cmd \"\$@\"; }
            $cmd() { command $cmd \"\$@\" | zkh_highlight_stream; }
            "
        fi
    done
}

# Function to disable global highlighting
zkh_disable_global() {
    echo "Disabling global keyword highlighting..."
    
    # Restore original commands
    for cmd in ls cat grep tail head less more; do
        if type "${cmd}_orig" &> /dev/null; then
            eval "$cmd() { ${cmd}_orig \"\$@\"; }"
            unfunction "${cmd}_orig"
        fi
    done
}

# Function to test the highlighting
zkh_test() {
    echo "Testing zsh-keywords-highlight..."
    echo ""
    
    echo "Info keywords (should be ${ZKH_COLORS[info]}green${ZKH_COLORS[reset]}):"
    zkh_highlight_line "  ✓ Installation successful"
    zkh_highlight_line "  ✓ Connection established"
    zkh_highlight_line "  ✓ Test passed"
    echo ""
    
    echo "Error keywords (should be ${ZKH_COLORS[error]}red${ZKH_COLORS[reset]}):"
    zkh_highlight_line "  ✗ File not found"
    zkh_highlight_line "  ✗ Access denied"
    zkh_highlight_line "  ✗ Connection failed"
    echo ""
    
    echo "Warning keywords (should be ${ZKH_COLORS[warning]}yellow${ZKH_COLORS[reset]}):"
    zkh_highlight_line "  ⚠ This feature is deprecated"
    zkh_highlight_line "  ⚠ Memory usage warning"
    zkh_highlight_line "  ⚠ Potential security risk"
    echo ""
    
    echo "Mixed line:"
    zkh_highlight_line "Build completed with 0 errors and 3 warnings."
    echo ""
}

# Function to show usage information
zkh_help() {
    cat << 'EOF'
zsh-keywords-highlight - Highlight keywords in command output

USAGE:
    zkh_run <command>           Run command with keyword highlighting
    zkh_tail <logfile> [args]   Monitor log file with highlighting
    zkh_test                    Test the highlighting functionality
    zkh_enable_global           Enable highlighting for common commands (experimental)
    zkh_disable_global          Disable global highlighting
    zkh_help                    Show this help message

EXAMPLES:
    zkh_run make                # Run make with highlighted output
    zkh_run ./configure         # Run configure script with highlighting
    zkh_tail /var/log/syslog -f # Follow syslog with highlighting
    cat file.log | zkh_highlight_stream  # Pipe through highlighter

CUSTOMIZATION:
    - Edit keyword files in keywords/ directory
    - Modify colors in colors.zsh
    - Use zkh_set_color to change colors dynamically

PIPE USAGE:
    You can pipe any command output through zkh_highlight_stream:
    
    your_command | zkh_highlight_stream
    your_command 2>&1 | zkh_highlight_stream

EOF
}

# Initialize by loading keywords
zkh_load_keywords

# If script is run directly (not sourced), show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$ZSH_EVAL_CONTEXT" =~ :file$ ]]; then
    echo "zsh-keywords-highlight loaded successfully!"
    echo "Run 'zkh_help' for usage information or 'zkh_test' to test highlighting."
    echo ""
    echo "Quick start:"
    echo "  zkh_run <command>    # Run any command with highlighting"
    echo "  zkh_test             # Test the highlighting"
fi
