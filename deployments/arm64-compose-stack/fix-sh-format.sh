#!/bin/bash
# ============================================================================
# TigerAI Stack Utility - Fix Shell Script Formats (CRLF to LF)
# ============================================================================
# Purpose: Recursively convert all .sh files in this directory to Linux format
# ============================================================================

set -e
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "--------------------------------------------------------"
echo "🚀 Fixing CRLF -> LF for all .sh in: $TARGET_DIR"
echo "--------------------------------------------------------"

find "$TARGET_DIR" -type f -name "*.sh" | while read -r line; do
    if [[ "$line" == *$(basename "$0") ]]; then continue; fi
    echo "Processing: $line"
    sed -i 's/\r$//' "$line"
    chmod +x "$line"
done
echo "✅ Done!"
