#!/usr/bin/env bash
# provenance.sh — P2-1 產物可重現性:輸出一段 provenance YAML,嵌入 digest/artifact frontmatter。
# 用法: bash provenance.sh <master.md> [來源.pdf]
#
# 為什麼:同一篇論文每次跑可能因 parser/模型版本不同而產出不同理論圖,難以信賴與重現。
# 固定並記錄「輸入 hash + 工具版本 + skill commit + schema 版本」,讓產物可被重跑比對。
set -u

M="${1:?用法: bash provenance.sh <master.md> [來源.pdf]}"
PDF="${2:-}"
[ -r "$M" ] || { echo "讀不到母本: $M" >&2; exit 1; }

# sha256:macOS 用 shasum -a 256,Linux fallback sha256sum
sha(){ if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}';
       elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
       else echo "unavailable"; fi; }

ver(){ command -v "$1" >/dev/null 2>&1 && "$@" 2>&1 | head -1 || echo "absent"; }

HERE="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$HERE")"
commit="$(git -C "$SKILL_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
schema="$(grep -m1 -oE 'v[0-9]+\.[0-9]+' "$SKILL_DIR/references/schema-contract.md" 2>/dev/null | head -1)"; schema="${schema:-unknown}"
today="$(date +%Y-%m-%d)"

master_sha="$(sha "$M")"
pdf_sha="$( [ -n "$PDF" ] && [ -r "$PDF" ] && sha "$PDF" || echo "n/a" )"

cat <<YAML
# ↓↓↓ provenance (P2-1 可重現性;貼進產物 frontmatter) ↓↓↓
provenance:
  generated_date: "$today"
  skill_commit: "$commit"
  schema_version: "$schema"
  input_pdf: "${PDF:-n/a}"
  input_pdf_sha256: "$pdf_sha"
  master_md: "$M"
  master_sha256: "$master_sha"
  tools:
    python: "$(ver python3 --version)"
    markitdown: "$(ver markitdown --version)"
    bash: "$BASH_VERSION"
    perl: "$(ver perl -e 'print "$^V"')"
  note: "同一輸入 + 同 commit/schema 應可重跑得同結果;hash 不符即輸入或工具已變動,須重驗。"
# ↑↑↑ provenance ↑↑↑
YAML
