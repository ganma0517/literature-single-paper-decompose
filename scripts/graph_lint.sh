#!/usr/bin/env bash
# graph_lint.sh — P1-3 架構圖「防假清晰」一致性檢查。
# 用法: bash graph_lint.sh <edges.tsv>
#   每行(邊—證據表逐行): <edge-id><TAB><arrow><TAB><定性><TAB><verbatim_quote>
#     arrow ∈ { -->(實線/已定性) , -.->(虛線/暫定) }
#     定性  ∈ { confirmed , tentative , conditional }
#
# 為什麼:把辯證/條件式論述硬壓成乾淨的節點與強關係邊,會製造「看似清晰、實則過度結構化」的
# 假架構(cross-ai-check/codex 點名)。本檢查確保:(1)定性與箭頭樣式一致;(2)標 confirmed 的邊,
# 其引文不得帶條件/推測語氣(否則應降為 tentative/conditional);(3)conditional 邊的條件要落在引文裡。
#
# 判定:
#   🔴 定性↔箭頭不一致(confirmed 卻畫虛線 / tentative|conditional 卻畫實線)
#   🔴 假清晰: 定性=confirmed 但引文含條件/推測訊號(if/when/unless/may/可能/在…下)
#   ⚠️ conditional 邊但引文未見條件訊號 → 條件可能沒落在引文,須補
#   ✅ 一致
# 退出碼: 0=全✅; 2=有🔴(結構不一致或假清晰,須修); 3=僅⚠️(須覆核)。
set -u

C="${1:?用法: bash graph_lint.sh <edges.tsv>  (每行 edge-id<TAB>arrow<TAB>定性<TAB>quote)}"
[ -r "$C" ] || { echo "讀不到 edges 檔: $C" >&2; exit 1; }

# 條件/推測訊號(英 + 中):標 confirmed 的邊不該出現這些
# 中文條件詞用有界距離([^，。]{0,15}),避免 .* 跨整段貪婪匹配誤殺 confirmed 邊。
COND='(\bif\b|\bwhen\b|\bunless\b|\bprovided that\b|conditional|depends on|\bmay\b|\bmight\b|\bcould\b|\bsuggest|\btends? to\b|在[^，。]{0,15}(條件|情況|前提)|可能|或許|端視|取決於|視[^，。]{0,12}而定)'

total=0; bad=0; warn=0
printf '%-26s %-7s %-12s %s\n' "EDGE-ID" "ARROW" "定性" "檢查"
printf '%s\n' "--------------------------------------------------------------------------------"

while IFS=$'\t' read -r id arrow qual quote || [ -n "${id:-}" ]; do
  id="${id%$'\r'}"
  [ -z "${id:-}" ] && continue
  case "$id" in \#*) continue;; esac
  total=$((total+1))
  q="${quote%$'\r'}"
  arrow="$(printf '%s' "$arrow" | tr -d ' ')"
  qual="$(printf '%s' "$qual" | tr -d ' ')"
  msg=""; sev=0   # 0 ok / 1 warn / 2 bad

  # malformed:缺箭頭/定性/引文 → 不可靜默放行(confirmed 邊缺引文會逃過假清晰偵測)
  if [ -z "$arrow" ] || [ -z "$qual" ] || [ -z "$q" ]; then
    bad=$((bad+1))
    printf '%-26s %-7s %-12s %s\n' "$id" "${arrow:-?}" "${qual:-?}" "🔴 malformed:缺箭頭/定性/引文,須補齊四欄"
    continue
  fi

  # 期望箭頭
  case "$qual" in
    confirmed)              exp="-->";;
    tentative|conditional)  exp="-.->";;
    *) msg="🔴 定性值非法(須 confirmed|tentative|conditional)"; sev=2;;
  esac

  if [ "$sev" -lt 2 ] && [ "$arrow" != "$exp" ]; then
    msg="🔴 定性↔箭頭不一致(定性=$qual 應用 $exp,實為 $arrow)"; sev=2
  fi

  if [ "$sev" -lt 2 ] && [ "$qual" = "confirmed" ] && printf '%s' "$q" | grep -iqE "$COND"; then
    msg="🔴 假清晰: confirmed 邊但引文帶條件/推測語氣 → 應降為 tentative/conditional"; sev=2
  fi

  if [ "$sev" -lt 1 ] && [ "$qual" = "conditional" ] && ! printf '%s' "$q" | grep -iqE "$COND"; then
    msg="⚠️ conditional 邊但引文未見條件訊號,確認條件有落在引文"; sev=1
  fi

  case "$sev" in
    2) bad=$((bad+1));  printf '%-26s %-7s %-12s %s\n' "$id" "$arrow" "$qual" "$msg";;
    1) warn=$((warn+1));printf '%-26s %-7s %-12s %s\n' "$id" "$arrow" "$qual" "$msg";;
    0) printf '%-26s %-7s %-12s %s\n' "$id" "$arrow" "$qual" "✅";;
  esac
done < "$C"

printf '%s\n' "--------------------------------------------------------------------------------"
printf '小結: 共 %d 邊 | 🔴須修 %d | ⚠️覆核 %d\n' "$total" "$bad" "$warn"
if [ "$bad" -gt 0 ]; then echo "❌ FAIL: 有結構不一致或假清晰的邊,須修正定性/箭頭或降級。"; exit 2; fi
if [ "$warn" -gt 0 ]; then echo "⚠️ WARN: 有 conditional 邊待覆核條件來源。"; exit 3; fi
echo "✅ PASS: 架構圖定性與引文語氣一致,未見假清晰。"; exit 0
