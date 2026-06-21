#!/usr/bin/env bash
# master_quality.sh — P1-1 母本品質「量化門檻」(把第1步抽樣目檢升級為可測指標 + 自動判定)。
# 用法: bash master_quality.sh <master.md>
#
# 為什麼:母本吞空格 → 逐字引文 grep 回溯失效卻可能假陰性過關(整條防幻覺防線地基崩塌)。
# 抽樣目檢會漏;本 script 給可測指標 + 門檻,FAIL 即應 fallback(markitdown↔pypdf 互換)或停。
#
# 門檻為「經驗校準」(2026-06-21):
#   - 已知良好母本(grep回溯全通過:whitehead/vandamme/fpos)→ 長黏串率0、逗號黏字率0、URL斷字0、空白密度~0.155
#   - 已知髒母本(dirty_master_fixture)→ 長黏串率3.91、逗號黏字率7.81、URL斷字1
#   故良好母本在「黏字」類指標恆為 0,任何非 0 即異常;門檻設在良好值與髒值之間。
#
# 退出碼(對齊 verify_claims.sh): 0=PASS, 3=WARN(可用但須注意/局部瑕疵), 2=FAIL(品質不足,回溯不可靠)。
set -u

F="${1:?用法: bash master_quality.sh <master.md>}"
[ -r "$F" ] || { echo "讀不到母本: $F" >&2; exit 1; }

words=$(wc -w < "$F" | tr -d ' ')
[ "${words:-0}" -gt 0 ] || { echo "母本無內容(0 詞)" >&2; exit 2; }
chars=$(wc -m < "$F" | tr -d ' ')
nonsp=$(tr -d '[:space:]' < "$F" | wc -m | tr -d ' ')
latin=$(grep -oE '[A-Za-z]' "$F" | wc -l | tr -d ' ')

# --- 指標 ---
# 1) 長黏串:>=25 字母無空格(排除 URL/DOI 行),典型 markitdown 系統性吞空格
glued=$(perl -ne 'next if /https?:|\.com|\.org|10\.\d{4,}|www\./i; while(/([A-Za-z]{25,})/g){print "1\n"}' "$F" | wc -l | tr -d ' ')
# 2) 逗號黏字 a,b(逗號後缺空格)
cglue=$(grep -oE '[a-z],[a-z]' "$F" 2>/dev/null | wc -l | tr -d ' ')
# 3) URL 斷字(h t t p):整檔被逐字拆開的訊號
urlsplit=$(grep -cE 'h[[:space:]]t[[:space:]]t[[:space:]]p' "$F" 2>/dev/null || true)
# 4) 空白密度(整檔災難性吞空格訊號;CJK 母本天然偏低,須守門)
spratio=$(awk "BEGIN{printf \"%.3f\",($chars-$nonsp)/$chars}")
latin_frac=$(awk "BEGIN{if($nonsp>0)printf \"%.2f\",$latin/$nonsp; else print 0}")
# 5) 頁碼覆蓋(pypdf 母本才有 ===== PDF page N =====)
pages=$(grep -cE '===== PDF page' "$F" 2>/dev/null || true)

# 每千詞率
gluedk=$(awk "BEGIN{printf \"%.2f\",$glued/$words*1000}")
cgluek=$(awk "BEGIN{printf \"%.2f\",$cglue/$words*1000}")

# 嚴重度 sev: 0=PASS < 1=WARN < 2=FAIL(注意退出碼 WARN=3>FAIL=2,不能直接拿退出碼取 max,
# 否則 WARN 會蓋掉更嚴重的 FAIL)。最後再把 sev 映射成退出碼。
sev=0
note(){ printf '  %s\n' "$1"; }
bump(){ [ "$1" -gt "$sev" ] && sev="$1"; return 0; }

printf '===== 母本品質量化體檢: %s =====\n' "$F"
printf '詞數=%s 字元=%s 空白密度=%s 拉丁字佔比=%s\n\n' "$words" "$chars" "$spratio" "$latin_frac"

printf -- '-- [1] 長黏串率(>=25字母無空格/千詞) = %s --\n' "$gluedk"
if   awk "BEGIN{exit !($gluedk>2.0)}"; then note "🔴 FAIL: 系統性吞空格(校準髒值 3.91);grep 回溯多半失效,須換工具重抽。"; bump 2
elif awk "BEGIN{exit !($gluedk>0)}";   then note "⚠️ WARN: 偶見長黏串;可能是合法長 token(化學名/編號)或局部吞空格,逐處覆核。"; bump 1
else note "✅ 無長黏串(同良好母本)。"; fi

printf -- '\n-- [2] 逗號黏字率(a,b 缺空格/千詞) = %s --\n' "$cgluek"
if   awk "BEGIN{exit !($cgluek>3.0)}"; then note "🔴 FAIL: 系統性逗號黏字(校準髒值 7.81);標點層吞空格。"; bump 2
elif awk "BEGIN{exit !($cgluek>0)}";   then note "⚠️ WARN: 偶見逗號黏字,逐處覆核。"; bump 1
else note "✅ 無逗號黏字(同良好母本)。"; fi

printf -- '\n-- [3] URL 斷字(h t t p 逐字拆開) = %s --\n' "$urlsplit"
if [ "${urlsplit:-0}" -gt 0 ]; then note "⚠️ WARN: 偵測到被拆開的 URL → 母本有逐字拆字現象,書目體檢請務必走 tr -d 去空白(見 biblio_healthcheck.sh)。"; bump 1
else note "✅ 未見 URL 斷字。"; fi

printf -- '\n-- [4] 空白密度 = %s (拉丁字佔比 %s) --\n' "$spratio" "$latin_frac"
if awk "BEGIN{exit !($latin_frac<0.30)}"; then
  note "ℹ️ CJK 為主母本:空白密度天然偏低,本項略過(不據此 FAIL),改以 [1][2] 黏字指標為準。"
else
  if   awk "BEGIN{exit !($spratio<0.09)}"; then note "🔴 FAIL: 空白密度過低 → 整檔災難性吞空格,母本不可用。"; bump 2
  elif awk "BEGIN{exit !($spratio<0.12)}"; then note "⚠️ WARN: 空白密度偏低,抽幾段已知片語確認 grep 命中。"; bump 1
  else note "✅ 空白密度正常(良好母本 ~0.155)。"; fi
fi

if [ "${pages:-0}" -gt 0 ]; then
  printf -- '\n-- [5] 頁碼覆蓋(pypdf 母本) = %s 個 page marker --\n' "$pages"
  miss=$(awk -v n="$pages" 'BEGIN{} /===== PDF page/{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){p[$i]=1; if($i>mx)mx=$i}} END{c=0; for(i=1;i<=mx;i++) if(!(i in p)){c++} ; print c+0}' "$F")
  if [ "${miss:-0}" -gt 0 ]; then note "⚠️ WARN: 頁碼可能不連續(疑漏 $miss 頁),核對 PDF 頁數。"; bump 1
  else note "✅ 頁碼連續。"; fi
fi

printf '\n===== 判定 =====\n'
case "$sev" in
  0) echo "✅ PASS: 母本品質達標,逐字引文 grep 回溯可信。"; exit 0;;
  1) echo "⚠️ WARN: 有局部瑕疵,可用但須對 WARN 處逐一覆核(尤其抽該段片語實測 grep)。"; exit 3;;
  2) echo "❌ FAIL: 母本品質不足,grep 回溯不可靠 → 換工具重抽(markitdown↔pypdf)或人工修復後再驗,不可逕用。"; exit 2;;
esac
