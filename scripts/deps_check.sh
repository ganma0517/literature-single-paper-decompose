#!/usr/bin/env bash
# deps_check.sh — P2-4 依賴缺失的 graceful 檢查:列出本 skill 各依賴是否到位 + 缺失影響。
# 用法: bash deps_check.sh
#
# 退出碼: 0=硬依賴齊全(軟依賴缺只警告); 2=有硬依賴缺(skill 無法可靠運作)。
set -u

hard_missing=0
chk(){ # 等級 名稱 指令 影響說明
  local level="$1" name="$2" cmd="$3" impact="$4"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '  ✅ %-12s %-7s %s\n' "$name" "[$level]" "已安裝"
  else
    if [ "$level" = "硬" ]; then hard_missing=$((hard_missing+1)); local mark="🔴"; else local mark="⚠️"; fi
    printf '  %s %-12s %-7s 缺:%s\n' "$mark" "$name" "[$level]" "$impact"
  fi
}

echo "===== 依賴檢查(literature-single-paper-decompose) ====="
echo "-- 硬依賴(缺則 guard/流程無法可靠運作) --"
chk 硬 bash bash "shell guard 全失效"
chk 硬 grep grep "引文回溯/書目體檢失效"
chk 硬 perl perl "浮水印/黏字偵測失效(走 perl backref)"
chk 硬 python3 python3 "pypdf fallback、部分查證失效"
chk 硬 awk awk "master_quality 指標計算失效"

echo "-- 軟依賴(缺則該功能降級,非全失效) --"
chk 軟 markitdown markitdown "主要 PDF→MD 擷取;缺則改用 pypdf fallback"
chk 軟 shasum shasum "provenance hash(macOS);Linux 改用 sha256sum"
chk 軟 git git "provenance 記不到 skill_commit"

echo ""
echo "-- 註:以下為 MCP 工具,非 CLI,無法用 command -v 檢查,須在 Claude 端確認連線 --"
echo "   firecrawl_search / Scholar Gateway semanticSearch(第2步書目查證)"
echo "   validate_and_render_mermaid_diagram(第4步架構圖語法驗證)"
echo "   cross-ai-check(第5步選用交叉檢核)"

echo ""
if [ "$hard_missing" -gt 0 ]; then
  echo "❌ 有 $hard_missing 個硬依賴缺失,skill 無法可靠運作,請先安裝。"
  exit 2
fi
echo "✅ 硬依賴齊全。軟依賴/MCP 缺失只影響對應步驟,會自動降級或須在報告揭露。"
exit 0
