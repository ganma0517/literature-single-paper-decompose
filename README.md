# literature-single-paper-decompose

一個 [Claude Code](https://claude.com/claude-code) **skill**：把單篇學術論文整理成**可追溯、低幻覺**的理論建構分析，並產出理論架構圖。

核心價值 ——**每個論斷都能 `grep` 回原文，且誠實區分「本文明示」與「分析者詮釋」**。

---

## 為什麼

近年論文（尤其 AI 輔助寫作）偶有捏造或張冠李戴的引用，而「整理論文」最隱蔽的幻覺不是捏造原典，而是**過度詮釋被分析文本**——把分析者歸納的標籤當成本文原話。本 skill 用一組可機械稽核的條件把這條線守住。

**鐵律**：只描述「本文如何使用文獻／如何建構理論」（citation context），**永不**宣稱「原典實際主張什麼」（那要讀原典，屬後續第二層工作）。

## 四步流程

1. **匯入** — `markitdown` 優先，品質檢查（黏字/浮水印）後必要時 fallback `pypdf`，轉成乾淨 Markdown 母本。
2. **資訊整理** — 文章 APA7 引用 + 結構化重點摘要 + 「理論相關」參考文獻轉 APA7 並連網查證（存在性/DOI/JCR/撤稿）。
3. **理論建構釐清** — 拆解理論來源(L1)、本文操作(L2)、理論關係(L3)，每條論斷套用防幻覺條件 **C1–C4**：
   - **C1** 附本文逐字引文　**C2** 標 `explicit`/`interpreted`　**C3** 可 grep 回母本的定位　**C4** 受控關係詞彙、貼近本文用語
4. **架構圖** — 理論來源 ↔ 本文架構 ↔ 研究方法 ↔ 研究發現整合成 Mermaid 圖，每條邊對應引文。

## 安裝

```bash
# 個人全域使用：clone 到 Claude Code 的 skills 目錄
git clone <this-repo-url> ~/.claude/skills/literature-single-paper-decompose

# 或專案內使用：放到專案的 .claude/skills/
git clone <this-repo-url> <your-project>/.claude/skills/literature-single-paper-decompose
```

**相依**：
- `markitdown`（`pipx install 'markitdown[pdf]'`，需 Python ≥ 3.10）
- `pypdf`（fallback 擷取）
- `firecrawl` MCP（參考文獻連網查證；或其他可連網搜尋工具）
- 可選：Obsidian（長期知識庫卡片化）

## 路徑配置（可攜）

SKILL.md 用兩個可配置路徑，預設值如下，依專案/機器調整：

| 變數 | 用途 | 預設 |
|---|---|---|
| `WORK_DIR` | 工作產物（母本 + 各步報告） | 當前專案下 `./ltm-work/` |
| `KB_DIR` | 可選的長期知識庫根（Obsidian KB 卡片化收尾） | 使用者 Obsidian vault 下 `literature-kb/` |

未指定時用預設，並在回報中說明落腳處。

## 內容

```
.
├── SKILL.md                      # skill 本體：4 步流程 + C1–C4 + Forbidden Actions
├── references/
│   └── schema-contract.md        # 三層知識網絡的共用資料契約（S1/S2/S3）
└── examples/                     # 實跑範例（不含原始 PDF）
    ├── Chen2026/                 # 政治學實證論文：step2/3/4 + 架構圖
    └── Karlson2012/              # 統計方法論文（KHB method）：整合報告
```

## 三層架構脈絡

這是「LTM 知識網絡」三層的**第一層**，刻意停在 citation context 層以維持低幻覺：
- **S1（本 skill）**：單篇解構 — 引用脈絡、存在性查證、理論建構釐清。
- **S2（未來）**：讀原典驗證理論主張，建立 pass 等級 theory claim。
- **S3（未來）**：把驗證過的理論接到研究設計（RQ/H），服務論文寫作。

資料契約（`references/schema-contract.md`）已預留 S2/S3 欄位，確保 S1 產出向後相容。

## License

MIT
