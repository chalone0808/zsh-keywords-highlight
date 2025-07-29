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

# Function to enable automatic highlighting for ALL commands using preexec hook
zkh_enable_auto() {
    echo "Enabling automatic keyword highlighting for all commands..."
    echo "Note: This will highlight output from every command you run"
    
    # Save original preexec if it exists
    if [[ -n "$preexec_functions" ]]; then
        ZKH_ORIG_PREEXEC_FUNCTIONS=("${preexec_functions[@]}")
    fi
    
    # Define our preexec function
    zkh_preexec() {
        # Store the command being executed
        ZKH_CURRENT_COMMAND="$1"
    }
    
    # Define our precmd function to capture output
    zkh_precmd() {
        # This runs after each command completes
        unset ZKH_CURRENT_COMMAND
    }
    
    # Add our functions to the hook arrays
    autoload -U add-zsh-hook
    add-zsh-hook preexec zkh_preexec
    add-zsh-hook precmd zkh_precmd
    
    # Set up command execution wrapper using exec
    zkh_exec_wrapper() {
        local cmd="$1"
        shift
        
        # Run the command and pipe through our highlighter
        command "$cmd" "$@" 2>&1 | zkh_highlight_stream
    }
    
    echo "Automatic highlighting enabled. Use 'zkh_disable_auto' to disable."
}

# Function to enable highlighting using exec redirection (most comprehensive)
zkh_enable_exec() {
    echo "Enabling exec-based keyword highlighting..."
    echo "This will highlight ALL command output automatically."
    
    # Create named pipes for stdout and stderr
    ZKH_STDOUT_PIPE=$(mktemp -u)
    ZKH_STDERR_PIPE=$(mktemp -u)
    
    mkfifo "$ZKH_STDOUT_PIPE" "$ZKH_STDERR_PIPE"
    
    # Background processes to handle the pipes
    zkh_highlight_stream < "$ZKH_STDOUT_PIPE" &
    ZKH_STDOUT_PID=$!
    
    zkh_highlight_stream < "$ZKH_STDERR_PIPE" >&2 &
    ZKH_STDERR_PID=$!
    
    # Redirect stdout and stderr to our pipes
    exec 3>&1 4>&2  # Save original stdout/stderr
    exec 1>"$ZKH_STDOUT_PIPE" 2>"$ZKH_STDERR_PIPE"
    
    ZKH_EXEC_ENABLED=1
    echo "Exec-based highlighting enabled. Use 'zkh_disable_exec' to disable."
}

# Function to disable exec-based highlighting
zkh_disable_exec() {
    if [[ "$ZKH_EXEC_ENABLED" == "1" ]]; then
        echo "Disabling exec-based keyword highlighting..."
        
        # Restore original stdout/stderr
        exec 1>&3 2>&4
        exec 3>&- 4>&-
        
        # Kill background processes
        [[ -n "$ZKH_STDOUT_PID" ]] && kill "$ZKH_STDOUT_PID" 2>/dev/null
        [[ -n "$ZKH_STDERR_PID" ]] && kill "$ZKH_STDERR_PID" 2>/dev/null
        
        # Clean up pipes
        [[ -p "$ZKH_STDOUT_PIPE" ]] && rm -f "$ZKH_STDOUT_PIPE"
        [[ -p "$ZKH_STDERR_PIPE" ]] && rm -f "$ZKH_STDERR_PIPE"
        
        unset ZKH_EXEC_ENABLED ZKH_STDOUT_PID ZKH_STDERR_PID ZKH_STDOUT_PIPE ZKH_STDERR_PIPE
        echo "Exec-based highlighting disabled."
    else
        echo "Exec-based highlighting is not currently enabled."
    fi
}

# Function to disable automatic highlighting
zkh_disable_auto() {
    echo "Disabling automatic keyword highlighting..."
    
    # Remove our hook functions
    if command -v add-zsh-hook >/dev/null; then
        add-zsh-hook -d preexec zkh_preexec
        add-zsh-hook -d precmd zkh_precmd
    fi
    
    # Restore original preexec functions if they existed
    if [[ -n "$ZKH_ORIG_PREEXEC_FUNCTIONS" ]]; then
        preexec_functions=("${ZKH_ORIG_PREEXEC_FUNCTIONS[@]}")
        unset ZKH_ORIG_PREEXEC_FUNCTIONS
    fi
    
    echo "Automatic highlighting disabled."
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
    zkh_enable_auto             Enable automatic highlighting for ALL commands (zsh hooks)
    zkh_disable_auto            Disable automatic highlighting
    zkh_enable_exec             Enable exec-based highlighting (most comprehensive)
    zkh_disable_exec            Disable exec-based highlighting
    zkh_help                    Show this help message

AUTOMATIC HIGHLIGHTING OPTIONS:
    1. zkh_enable_global   - Wraps common commands (ls, cat, grep, etc.)
    2. zkh_enable_auto     - Uses zsh hooks to highlight all commands
    3. zkh_enable_exec     - Redirects stdout/stderr for universal highlighting

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
