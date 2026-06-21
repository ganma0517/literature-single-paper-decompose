#!/usr/bin/env bash
# biblio_healthcheck.sh — 第1步匯入品質檢查 + 第2步全文書目體檢的可攜版本。
# 用法: bash biblio_healthcheck.sh <master.md>
# 設計原則:
#   - 不依賴 grep 的 \1 backreference(ugrep 不支援,會靜默失效)→ 重複字母偵測一律走 perl。
#   - URL/AI 連結偵測先 `tr -d ' '` 去空格,破解 markitdown 把 URL 拆成逐字的陷阱(否則假陰性)。
#   - 浮水印重複字母偵測加 guard:只看字母、且排除 URL/DOI 行,避免把 hex hash(deadbeef0000)誤報成浮水印。
#   - 命中只是「候選硬傷」,仍須人工覆核;查無只代表「全掃未見」,不等於每筆都對。
set -u
F="${1:?用法: bash biblio_healthcheck.sh <master.md>}"
[ -r "$F" ] || { echo "讀不到檔案: $F" >&2; exit 1; }
hit=0
sec(){ printf '\n===== %s =====\n' "$1"; }

sec "[A] AI 誤貼對話連結(去空格後比對,破 markitdown 拆字陷阱)"
if tr -d ' ' < "$F" | grep -onE "chatgpt\.com|claude\.ai|gemini\.google\.com|bard\.google\.com|poe\.com|copilot\.microsoft\.com" ; then hit=1; else echo "未見"; fi

sec "[B] DOI 拼錯: doi.ogr / 重複 scheme / 裸 DOI 缺 scheme"
grep -nE "doi\.ogr|https?://https?://|doi\.org\.|dio\.org" "$F" && hit=1 || echo "未見"
echo "-- 行首裸 DOI(缺 http scheme,屬候選非必錯)--"
grep -nE "^[[:space:]]*10\.[0-9]{4,}/" "$F" || true

sec "[C] placeholder / 佔位 URL"
grep -niE "PLACEHOLDER|INSERT[- ]?LINK|XXXX|TODO|example\.(com|org)/" "$F" && hit=1 || echo "未見"

sec "[D] 浮水印重複字母(perl backref;排除 URL/DOI 行 + 純數字串,免誤報 hex)"
perl -ne '
  next if m{https?:|www\.|\.com|\.org|10\.\d{4,}|doi}i;  # 跳過 URL/DOI 行,免把 hash/www 當浮水印
  while (/([A-Za-z])\1{2,}/g){                 # 同字母連續 >=3
    my $m=$&;
    next if lc($m) eq "www";                   # www 是 URL 殘留,非浮水印
    print "line $.: $m\n";
  }
' "$F" | sort | uniq -c | sort -rn | sed -n '1,15p' || true
echo "-- 同 token 緊鄰重複(SAMPLEsample / DRAFTdraft 類浮水印)--"
grep -noiE "(SAMPLE|DRAFT|WATERMARK|CONFIDENTIAL|PROQUEST){2,}" "$F" || echo "未見"

sec "[E] 系統性吞空格(逗號黏字 + 過長無空格純字母串)"
grep -noE "[a-z],[a-z]" "$F" | head || true
echo "-- 長度>=25 的純字母無空格串(疑似黏字,排除 URL)--"
perl -ne 'next if /https?:|\.com|\.org/; while(/([A-Za-z]{25,})/g){print "line $.: $1\n"}' "$F" || echo "未見"

sec "[F] 卷期/年份矛盾 — 機制無法保證,須人工語意判讀"
echo "grep 無法語意比對(如 1912 出版卻標 2019)。請人工掃 references 的年份/卷期是否互相矛盾。"

printf '\n===== 小結 =====\n'
if [ "$hit" -eq 1 ]; then
  echo "⚠️ 偵測到候選硬傷(見上)。逐筆覆核後在報告標 ⚠️ + ref 編號。"
else
  echo "全掃未見明顯硬傷(A/B/C 類)。注意:這只排除明顯 typo/誤貼,不等於每筆都正確。"
fi
echo "提醒:[F] 年份矛盾與深度查證(撤稿/DOI 對應)仍須另行人工/連網處理。"

# 遵守 guard 退出碼契約(0/3/2):候選硬傷 → WARN(3),全掃未見 → PASS(0)。
# 註:退出碼只看 [A][B][C](AI連結/DOItypo/placeholder)這類書目硬傷;
# [D][E](浮水印/系統性吞空格)僅列印提示——母本品質門檻由 master_quality.sh 負責判定退出碼。
[ "$hit" -eq 1 ] && exit 3 || exit 0
