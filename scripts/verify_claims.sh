#!/usr/bin/env bash
# verify_claims.sh — P0-3 全量 claim 逐字引文 grep 回溯 + P0-2 strict 拒絕門檻。
# 用法: bash verify_claims.sh <master.md> <claims.tsv>
#   claims.tsv 每行: <claim-id><TAB><verbatim_quote>  (以第一個 tab 切;引文可含空白)
#
# 對「每一條」C1 引文做逐字回溯(取代隨機抽 2-3),分三種結果:
#   ✅ Lnn      逐字命中母本第 nn 行 → 可追溯
#   ⚠️ 吞空格    逐字不中,但去空白後命中 → 母本品質問題(非捏造);grep 回溯失效,須修母本(見 P1-1)
#   🔴 MISS     逐字、去空白皆不中 → 疑似捏造或定位幻覺,strict 模式必須拒絕此論斷
#
# 設計原則(對齊 biblio_healthcheck.sh):
#   - 引文一律用 grep -F 固定字串比對,免把引文中的標點當 regex(ugrep/GNU/BSD 皆一致)。
#   - 「去空白」用 tr -d '[:space:]',破解 markitdown 把字/URL 拆成逐字加空格的陷阱,
#     以區分「真的查無(捏造)」與「母本吞空格(品質問題)」這兩種完全不同的失敗。
#   - 退出碼: 0=全部 ✅; 2=有 🔴 MISS(strict 模式據此拒絕輸出); 3=有 ⚠️ 但無 🔴; 1=用法/讀檔錯。
set -u

M="${1:?用法: bash verify_claims.sh <master.md> <claims.tsv>}"
C="${2:?用法: bash verify_claims.sh <master.md> <claims.tsv>}"
[ -r "$M" ] || { echo "讀不到母本: $M" >&2; exit 1; }
[ -r "$C" ] || { echo "讀不到 claims 檔: $C" >&2; exit 1; }

# 預先做一份「去空白母本」供 fallback 比對(只建一次)。
MASTER_NOSP="$(tr -d '[:space:]' < "$M")"

ok=0; sp=0; miss=0; total=0
printf '%-28s %-8s %s\n' "CLAIM-ID" "STATUS" "LOCATION / 引文片段"
printf '%s\n' "------------------------------------------------------------------------"

while IFS=$'\t' read -r id quote || [ -n "${id:-}" ]; do
  # 跳過空行與註解行(# 開頭)
  [ -z "${id:-}" ] && continue
  case "$id" in \#*) continue;; esac
  total=$((total+1))
  q="${quote%$'\r'}"   # 去尾端 CR(跨平台)

  # 1) 逐字精確命中(取第一個命中行號)
  ln="$(grep -F -n -- "$q" "$M" 2>/dev/null | head -1 | cut -d: -f1)"
  if [ -n "$ln" ]; then
    ok=$((ok+1))
    printf '%-28s %-8s L%s\n' "$id" "✅" "$ln"
    continue
  fi

  # 2) 去空白 fallback:命中=母本吞空格(品質問題,非捏造)
  qnosp="$(printf '%s' "$q" | tr -d '[:space:]')"
  if [ -n "$qnosp" ] && printf '%s' "$MASTER_NOSP" | grep -Fq -- "$qnosp"; then
    sp=$((sp+1))
    printf '%-28s %-8s %s\n' "$id" "⚠️吞空格" "去空白後命中;母本品質問題,須修母本(grep 回溯失效)"
    continue
  fi

  # 3) 皆不中:疑似捏造 / 定位幻覺
  miss=$((miss+1))
  short="$(printf '%s' "$q" | cut -c1-40)"
  printf '%-28s %-8s %s\n' "$id" "🔴MISS" "查無:「${short}...」→ strict 模式拒絕此論斷"
done < "$C"

printf '%s\n' "------------------------------------------------------------------------"
printf '小結: 共 %d 條 | ✅命中 %d | ⚠️吞空格 %d | 🔴MISS %d\n' "$total" "$ok" "$sp" "$miss"

if [ "$miss" -gt 0 ]; then
  echo "❌ STRICT FAIL: 有 $miss 條引文查無 → 這些論斷不得寫入最終結論(P0-2)。"
  exit 2
elif [ "$sp" -gt 0 ]; then
  echo "⚠️ 母本品質警告: 有 $sp 條須去空白才命中 → 逐字 grep 回溯對這些條失效,建議重抽母本(P1-1)。"
  exit 3
else
  echo "✅ PASS: 全部 $total 條引文逐字命中母本,可追溯。"
  exit 0
fi
