# zsh-keywords-highlight

A powerful zsh plugin that automatically highlights important keywords in command output with colors. Perfect for making build logs, error messages, and system output more readable at a glance.

![Demo](https://img.shields.io/badge/demo-available-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Shell](https://img.shields.io/badge/shell-zsh-green)

## Features

- 🎨 **Automatic keyword highlighting** with customizable colors
- 🔍 **Smart detection** of errors, warnings, and info messages
- 📝 **Case-insensitive matching** (handles all capitalization variants)
- ⚡ **Real-time highlighting** for command output and log files
- 🛠️ **Highly customizable** colors and keywords
- 🔧 **Easy integration** with existing workflows
- 📦 **Lightweight** and fast

## Installation

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/chalone0808/zsh-keywords-highlight.git ~/.zsh/zsh-keywords-highlight
```

2. Source the plugin in your `~/.zshrc`:
```bash
# Add this line to your ~/.zshrc
source ~/.zsh/zsh-keywords-highlight/zsh-keywords-highlight.zsh
```

3. Reload your shell:
```bash
source ~/.zshrc
```

### Oh My Zsh Installation

```bash
git clone https://github.com/chalone0808/zsh-keywords-highlight.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-keywords-highlight

# Add to your ~/.zshrc plugins list
plugins=(... zsh-keywords-highlight)
```

## Quick Start

Test the highlighting functionality:
```bash
zkh_test
```

Run commands with highlighting:
```bash
zkh_run make
zkh_run ./configure
zkh_run npm install
```

Monitor log files with highlighting:
```bash
zkh_tail /var/log/syslog -f
zkh_tail application.log
```

## Usage

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `zkh_run <command>` | Run any command with keyword highlighting | `zkh_run make build` |
| `zkh_tail <logfile>` | Monitor log files with highlighting | `zkh_tail app.log -f` |
| `zkh_test` | Test the highlighting functionality | `zkh_test` |
| `zkh_help` | Show help and usage information | `zkh_help` |

### Pipe Usage

You can pipe any command output through the highlighter:

```bash
# Pipe stdout and stderr
your_command 2>&1 | zkh_highlight_stream

# Examples
cat error.log | zkh_highlight_stream
docker build . 2>&1 | zkh_highlight_stream
npm test | zkh_highlight_stream
```

### Advanced Usage

#### Enable Global Highlighting (Experimental)
```bash
zkh_enable_global   # Enables highlighting for common commands (ls, cat, grep, etc.)
zkh_disable_global  # Disables global highlighting
```

#### Custom Color Management
```bash
zkh_list_colors     # Show all available colors
zkh_set_color error '\033[1;31m'  # Set custom color for error keywords
zkh_reset_colors    # Reset colors to defaults
```

## Keyword Categories

The plugin recognizes three main categories of keywords:

### 🔴 Error Keywords (Red)
- `error`, `failed`, `fail`, `fatal`, `crash`, `abort`
- `not found`, `access denied`, `permission denied`
- `segmentation fault`, `null pointer`, `stack overflow`
- And many more... (88 variations including all capitalization cases)

### 🟡 Warning Keywords (Yellow)
- `warning`, `deprecated`, `caution`, `attention`
- `memory usage high`, `disk space low`, `timeout warning`
- `security risk`, `potential issue`, `unstable`
- And many more... (156 variations including all capitalization cases)

### 🟢 Info Keywords (Green)
- `success`, `completed`, `ok`, `ready`, `done`
- `connected`, `established`, `installed`, `loaded`
- `found`, `available`, `active`, `running`
- And many more... (96 variations including all capitalization cases)

## Customization

### Adding Custom Keywords

Edit the keyword files in the `keywords/` directory:

```bash
# Add error keywords
echo "my_custom_error" >> keywords/keywords_error.zsh

# Add warning keywords  
echo "my_custom_warning" >> keywords/keywords_warning.zsh

# Add info keywords
echo "my_custom_info" >> keywords/keywords_info.zsh

# Reload keywords
zkh_load_keywords
```

### Customizing Colors

Edit `colors.zsh` or use the built-in functions:

```bash
# Change error color to bold red
zkh_set_color error $'\033[1;31m'

# Change warning color to bold yellow
zkh_set_color warning $'\033[1;33m'

# List all available colors
zkh_list_colors
```

Available color options:
- `info` - Green (default)
- `error` - Red (default)  
- `warning` - Yellow (default)
- `success` - Bright green
- `debug` - Cyan
- `important` - Magenta
- `notice` - Bright blue

## Examples

### Build Systems
```bash
# Highlight make output
zkh_run make

# Highlight npm/yarn output
zkh_run npm install
zkh_run yarn build

# Highlight cmake output
zkh_run cmake --build .
```

### System Administration
```bash
# Monitor system logs
zkh_tail /var/log/syslog -f

# Check service status
systemctl status nginx | zkh_highlight_stream

# Monitor application logs
zkh_tail /var/log/apache2/error.log
```

### Development Workflow
```bash
# Highlight test output
zkh_run pytest
zkh_run npm test

# Highlight linting output
zkh_run eslint src/
zkh_run flake8 .

# Highlight git output
git status | zkh_highlight_stream
```

## Configuration

### Case Sensitivity

The plugin handles all capitalization variants automatically:
- `error` → `error`, `Error`, `ERROR`
- `not found` → `not found`, `Not Found`, `Not found`, `NOT FOUND`

### Performance

The plugin is optimized for performance:
- Keywords are sorted by length (longest first) to handle phrases correctly
- Already highlighted text is not re-processed
- Minimal overhead for real-time processing

## Troubleshooting

### Colors not showing?
```bash
# Test color support
zkh_list_colors

# Check if terminal supports colors
echo $TERM
```

### Keywords not being highlighted?
```bash
# Test with debug output
zkh_debug "test error message"

# Reload keywords
zkh_load_keywords

# Check keyword files
ls -la keywords/
```

### Performance issues?
```bash
# Disable global highlighting if enabled
zkh_disable_global

# Use specific commands instead
zkh_run your_command
```

## Contributing

Contributions are welcome! Please feel free to:

1. **Add new keywords** to the keyword files
2. **Improve color schemes** in `colors.zsh`
3. **Fix bugs** or **add features**
4. **Improve documentation**

### Adding Keywords

When adding keywords, please add all capitalization variants:
```bash
# For single words, add:
keyword
Keyword  
KEYWORD

# For phrases, add:
phrase word
Phrase Word
Phrase word
PHRASE WORD
```

## License

MIT License - see LICENSE file for details.

## Support

- 🐛 **Bug reports**: [GitHub Issues](https://github.com/chalone0808/zsh-keywords-highlight/issues)
- 💡 **Feature requests**: [GitHub Issues](https://github.com/chalone0808/zsh-keywords-highlight/issues)
- 📖 **Documentation**: This README and `zkh_help`

## Related Projects

- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting for zsh commands
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Command suggestions for zsh

---

**Made with ❤️ for developers who like colorful terminals**
