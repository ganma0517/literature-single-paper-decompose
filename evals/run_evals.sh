#!/usr/bin/env bash
# run_evals.sh — P2-2 防幻覺 guard 的回歸測試 + 指標報告。
# 用法: bash evals/run_evals.sh
#
# 對「已知預期結果」的 fixtures 跑四支 guard,斷言退出碼是否符合預期,
# 量測 guard 的偵測能力(該擋的有沒有擋 / 該放的有沒有誤殺)。
# 退出碼: 0=全部符合預期; 1=有 guard 行為與預期不符(回歸)。
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SK="$(dirname "$HERE")/scripts"
FX="$HERE/fixtures"
pass=0; fail=0

# 一個 case: 描述 | 命令 | 預期退出碼
run_case(){
  local desc="$1" expect="$2"; shift 2
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" -eq "$expect" ]; then
    pass=$((pass+1)); printf '  ✅ %-46s (exit %s)\n' "$desc" "$got"
  else
    fail=$((fail+1)); printf '  ❌ %-46s (預期 %s, 實得 %s)\n' "$desc" "$expect" "$got"
  fi
}

echo "===== verify_claims (P0:全量引文 grep + strict) ====="
run_case "乾淨引文集 → PASS"           0 bash "$SK/verify_claims.sh" "$FX/clean_master.md" "$FX/claims_clean.tsv"
run_case "含捏造引文 → STRICT FAIL"    2 bash "$SK/verify_claims.sh" "$FX/clean_master.md" "$FX/claims_tampered.tsv"
run_case "空引文/缺tab → 不可假 PASS"  2 bash "$SK/verify_claims.sh" "$FX/clean_master.md" "$FX/claims_malformed.tsv"

echo "===== master_quality (P1-1:母本品質量化門檻) ====="
run_case "乾淨母本 → PASS"             0 bash "$SK/master_quality.sh" "$FX/clean_master.md"
run_case "髒母本 fixture → FAIL"       2 bash "$SK/master_quality.sh" "$HERE/dirty_master_fixture.md"

echo "===== stance_lint (P1-2:立場/語氣) ====="
run_case "立場一致 → PASS"             0 bash "$SK/stance_lint.sh" "$FX/stance_clean.tsv"
run_case "強依賴+否定 → 須覆核"        3 bash "$SK/stance_lint.sh" "$FX/stance_flagged.tsv"

echo "===== graph_lint (P1-3:架構圖防假清晰) ====="
run_case "定性/箭頭一致 → PASS"        0 bash "$SK/graph_lint.sh" "$FX/edges_clean.tsv"
run_case "confirmed 帶推測語氣 → FAIL" 2 bash "$SK/graph_lint.sh" "$FX/edges_bad.tsv"

total=$((pass+fail))
if [ "$total" -gt 0 ]; then rate=$(( pass * 100 / total )); else rate=0; fi
printf '\n===== 指標 =====\n'
printf '案例 %d | 通過 %d | 失敗(回歸) %d | 通過率 %d%%\n' "$total" "$pass" "$fail" "$rate"
if [ "$fail" -gt 0 ]; then
  echo "❌ 有 guard 行為與預期不符(回歸),請檢查上方 ❌ 項。"
  exit 1
fi
echo "✅ 全部 guard 行為符合預期:該擋的擋下、該放的放行。"
exit 0
