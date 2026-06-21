#!/usr/bin/env bash
# stance_lint.sh — P1-2 引用「立場」與「語氣」啟發式檢查。
# 用法: bash stance_lint.sh <claims_stance.tsv>
#   每行: <claim-id><TAB><relation><TAB><verbatim_quote>
#
# 為什麼:最常見的高階幻覺是「把作者轉述他人/反對的觀點,誤標成作者自己採納的立場」
# (codex 交叉檢核點名),以及「把帶 however/may 的讓步句抹平成肯定主張」。grep 無法判語意,
# 但能用「強依賴關係詞 vs 引文中的否定/讓步訊號」抓出**疑似錯配**,逼人工確認 citation_stance。
#
# 判定(啟發式,非定論——是「請覆核」的提示,不是 strict 拒絕):
#   🔴 疑似立場錯配: relation ∈ {draws-on,defines,applies,extends}(強依賴) 但引文含否定/反對訊號
#                    → 可能其實是 challenges/opposed,或本文在轉述他人,別當作者採納。
#   ⚠️ 語氣未保留風險: 引文含 hedge(may/suggest/可能…) → 論斷不得抹平成肯定,確認保留語氣。
#   ⚠️ 轉述訊號: 引文含 attribution(argues that/according to/認為…) → 確認是「他人觀點」非本文立場。
#   ✅ 未見明顯錯配訊號。
#
# 退出碼: 0=全 ✅; 3=有 ⚠️/🔴 須覆核(不硬性拒絕,因屬語意啟發式)。
set -u

C="${1:?用法: bash stance_lint.sh <claims_stance.tsv>  (每行 claim-id<TAB>relation<TAB>quote)}"
[ -r "$C" ] || { echo "讀不到 claims 檔: $C" >&2; exit 1; }

STRONG_DEP='draws-on|defines|applies|extends'
# 否定/反對訊號(英 + 中)。n['’]t 只收縮寫(don't/can't),不用 n.t 以免誤匹配 nat/n-t 等。
NEG="(\\bnot\\b|n['’]t\\b|\\bnever\\b|\\bno longer\\b|\\bhowever\\b|\\balthough\\b|\\bthough\\b|\\bwhereas\\b|rather than|instead of|contrary to|\\bcontra\\b|reject|critici[sz]|critique|\\boppos|\\bdeny\\b|\\bdenies\\b|fails to|\\bcannot\\b|does not|do not|did not|並非|不是|並不|反對|批判|質疑|駁斥|卻|然而|儘管)"
# 讓步/推測 hedge
HEDGE='(\bmay\b|\bmight\b|\bcould\b|\bsuggest|\bappears\b|\bseems\b|\btend|possibly|perhaps|arguably|可能|或許|傾向|似乎|未必)'
# 轉述/歸屬訊號
ATTR='(argues that|claims that|according to|in the view of|contends|posits|maintains that|認為|主張|指出|宣稱)'

total=0; warn=0; mis=0
printf '%-30s %-12s %s\n' "CLAIM-ID" "RELATION" "STANCE/語氣 偵測"
printf '%s\n' "--------------------------------------------------------------------------------"

while IFS=$'\t' read -r id rel quote || [ -n "${id:-}" ]; do
  id="${id%$'\r'}"
  [ -z "${id:-}" ] && continue
  case "$id" in \#*) continue;; esac
  total=$((total+1))
  rel="${rel%$'\r'}"
  q="${quote%$'\r'}"

  # malformed:缺 relation 或缺引文(含純空白) → 不可靜默 ✅,標 ⚠️ 須補
  if [ -z "$(printf '%s' "$rel" | tr -d '[:space:]')" ] || [ -z "$(printf '%s' "$q" | tr -d '[:space:]')" ]; then
    warn=$((warn+1))
    printf '%-30s %-12s %s\n' "$id" "${rel:-?}" "⚠️malformed:缺 relation 或引文(含純空白),無法檢查"
    continue
  fi
  flags=""

  has_neg=$(printf '%s' "$q"  | grep -iqE "$NEG"  && echo 1 || echo 0)
  has_hedge=$(printf '%s' "$q"| grep -iqE "$HEDGE"&& echo 1 || echo 0)
  has_attr=$(printf '%s' "$q" | grep -iqE "$ATTR" && echo 1 || echo 0)
  is_strong=$(printf '%s' "$rel" | grep -iqE "^($STRONG_DEP)$" && echo 1 || echo 0)

  if [ "$is_strong" = 1 ] && [ "$has_neg" = 1 ]; then
    flags="🔴立場錯配?(強依賴關係+否定/反對引文→確認非 challenges/轉述)"
    mis=$((mis+1))
  else
    [ "$has_hedge" = 1 ] && flags="$flags ⚠️hedge(保留語氣)"
    [ "$has_attr" = 1 ]  && flags="$flags ⚠️轉述(確認他人觀點非本文立場)"
    [ -n "$flags" ] && warn=$((warn+1))   # 此列為 warning 才累加(不再依賴全域 mis)
  fi

  if [ -n "$flags" ]; then
    printf '%-30s %-12s %s\n' "$id" "$rel" "$flags"
  else
    printf '%-30s %-12s %s\n' "$id" "$rel" "✅"
  fi
done < "$C"

printf '%s\n' "--------------------------------------------------------------------------------"
printf '小結: 共 %d 條 | 🔴疑似立場錯配 %d | ⚠️語氣/轉述/malformed 須覆核 %d\n' "$total" "$mis" "$warn"
if [ "$mis" -gt 0 ] || [ "$warn" -gt 0 ]; then
  echo "⚠️ 有需人工覆核的 citation_stance/語氣旗標(啟發式,非定論)。逐條確認後再定 relation 與 stance。"
  exit 3
fi
echo "✅ 未見明顯立場錯配或語氣抹平風險(啟發式掃描)。"
exit 0
