#!/bin/bash
# ============================================================================
# TigerAI Stack Utility - Fix Shell Script Formats (CRLF to LF)
# ============================================================================
# Purpose: Recursively convert all .sh files in this directory to Linux format
# Usage: sudo ./fix-sh-format.sh
# ============================================================================

set -e

# Target directory is the current directory of the script
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "----------------------------------------------------------------------------"
echo "🚀 Fixing line endings (CRLF -> LF) for all .sh files in:"
echo "   $TARGET_DIR"
echo "----------------------------------------------------------------------------"

# 1. Find all .sh files recursively
# 2. Use sed to remove \r from the end of lines
# 3. Use chmod to make them executable
find "$TARGET_DIR" -type f -name "*.sh" | while read -r line; do
    # Skip the fixer script itself to avoid race conditions (though sed -i handles it)
    if [[ "$line" == *$(basename "$0") ]]; then
        continue
    fi
    
    echo "Processing: $line"
    # Remove \r safely
    sed -i 's/\r$//' "$line"
    # Make executable
    chmod +x "$line"
done

echo ""
echo "✅ Done! All shell scripts have been converted to Linux format (LF) and marked as executable."
echo "----------------------------------------------------------------------------"
