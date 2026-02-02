#!/bin/bash
# ============================================================================
# TigerAI Stack - 修正所有 .sh 檔案的 Windows CRLF 格式問題
# ============================================================================
# 用途：將所有 .sh 檔案從 Windows CRLF (\r\n) 轉換為 Unix LF (\n)
# 執行：bash fix-sh-format.sh
# ============================================================================

set -e

echo "========================================="
echo "修正 Shell 腳本格式 (CRLF → LF)"
echo "========================================="
echo ""

# 計數器
TOTAL=0
FIXED=0

# 尋找所有 .sh 檔案
while IFS= read -r -d '' file; do
    ((TOTAL++))
    
    # 檢查是否有 CRLF
    if file "$file" | grep -q "CRLF"; then
        echo "修正: $file"
        
        # 轉換 CRLF 為 LF
        sed -i 's/\r$//' "$file"
        
        # 確保可執行
        chmod +x "$file"
        
        ((FIXED++))
    fi
done < <(find . -name "*.sh" -type f -print0)

echo ""
echo "========================================="
echo "完成"
echo "========================================="
echo "總計: $TOTAL 個 .sh 檔案"
echo "修正: $FIXED 個檔案"
echo ""

if [ $FIXED -eq 0 ]; then
    echo "✅ 所有檔案格式正確！"
else
    echo "✅ 已修正 $FIXED 個檔案的格式"
fi
