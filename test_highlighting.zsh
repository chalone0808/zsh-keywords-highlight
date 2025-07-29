#!/usr/bin/env zsh

# Example script to test zsh-keywords-highlight functionality
# This script outputs various messages that should be highlighted

echo "=== Testing zsh-keywords-highlight ==="
echo ""

echo "Info messages (should be green):"
echo "  ✓ Installation successful"
echo "  ✓ Connection established"
echo "  ✓ Test passed"
echo "  ✓ Build completed"
echo ""

echo "Error messages (should be red):"
echo "  ✗ File not found"
echo "  ✗ Access denied" 
echo "  ✗ Connection failed"
echo "  ✗ Compilation error"
echo ""

echo "Warning messages (should be yellow):"
echo "  ⚠ This feature is deprecated"
echo "  ⚠ Memory usage high"
echo "  ⚠ Configuration warning"
echo "  ⚠ Potential security risk"
echo ""

echo "Mixed messages:"
echo "  The installation was successful, but there are some warnings about deprecated features."
echo "  Build completed with 0 errors and 3 warnings."
echo "  Connection established successfully, but timeout may occur."
echo ""

echo "=== Test completed ==="
