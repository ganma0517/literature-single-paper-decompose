# LTM 知識網絡 — 共用 Schema 契約 v1.1（v1.0 frozen + v1.1 向後相容修正；沿革見檔尾）

> 三個 skill（S1 單篇解構 / S2 理論驗證 / S3 研究設計接口）共用的資料契約。
> 目的：讓 S1 現在產出的卡片，日後能被 S2/S3 **無痛升級**，而非回頭重建。
> 標記慣例：每個欄位後標 `[S1]` / `[S2]` / `[S3]` 表示由哪個 skill 負責填寫。

---

## 已凍結的三個設計決策（v1.0）

1. **CI 粒度 = per (cited_source × ci_layer)**：同一文獻在**不同** ci_layer 被使用 → 各建一張卡（CI-001a/b）；同一 layer 多次出現 → 聚為一張、`section` 記錄所有位置。
   - 理由：理論建構時「Doshi 被當 foundation」與「Doshi 被當 counter（被挑戰）」是**兩種不同的理論關係**，必須分開，否則 S2 升級時會混淆。多數文獻只落單一 layer，卡片不會爆炸。

2. **TC 空殼產生 = 由 ci_layer 自動決定（非人工裁量）**：
   - **建 TC 空殼**：`ci_layer ∈ {foundation, definition, mechanism, counter}`（承載理論主張者）。
   - **可選建**：`method`（方法主張，理論建構通常用不到，預設不建、需要時補）。
   - **不建**：`empirical_anchor, context`（背景、新聞、案例證據，升級成理論主張無意義）。
   - 理由：把「要不要驗證原典」從人工判斷變成 **schema 驅動**，符合「用資料結構防幻覺」的哲學；也避免一篇 155 筆參考產生上百張無意義空殼。

3. **knowledge base 落腳 = `KB_DIR`（預設：使用者 Obsidian vault 下 `literature-kb/`）**：
   - 理由：放進既有 Obsidian vault，CI/TC 卡可用 `[[wiki-link]]` 互連、Mermaid 原生渲染；與 Downloads 暫存分離，適合長期知識網絡。

---

## 0. 不變式（Invariants — 整套系統永遠成立的規則）

1. **分層**：每個物件都有 `layer`，知道自己屬於哪個驗證層級。
2. **閘門**：只有 `status: pass` 的物件能進入 synthesis / ledger / confirmed graph。
3. **預設保守**：欄位不全 → `status: pending`，留在 uncertainty，不得偽裝成 pass。
4. **可溯源**：任何 `pass` 物件都能回溯到 `provenance`（原文頁碼 + 逐字引文）。
5. **存在性 ≠ 正確性**：`source_status: verified` 只證明文獻存在，不證明理論主張正確。
6. **標籤誠實**：產出物名稱必須反映其 `layer`（Draft Citation Context ≠ Confirmed Theory）。
7. **升級單向**：S1→S2→S3 只能升級狀態、補欄位，不可降級或刪除既有 provenance。
8. **引文可回溯（防詮釋幻覺）**：任何 citation context / 理論關係主張都必須附被分析文的逐字引文，且該引文能在匯入文本（markitdown 輸出）中字串搜尋到；分析者歸納的標籤須標 `evidence_type: interpreted`，不得冒充本文明示。

---

## 1. 共用基底欄位（所有物件型別都必須有）

```yaml
id: "..."                 # 全域唯一，型別前綴 + 序號（見各型別）
type: "..."               # article_metadata | source_registry | citation_context | theory_claim | concept | mechanism | debate | project_anchor
layer: "..."              # 見 §2 受控詞彙
status: "..."             # 見 §2 受控詞彙
provenance:               # 此物件的證據來源
  from_skill: "S1|S2|S3"  # 哪個 skill 建立
  source_doc: "..."       # 被分析文章 citekey，或原典 citekey
  location: "..."         # 頁碼/段落（citation context 用被分析文；theory claim 用原典）
created_date: "YYYY-MM-DD"
updated_date: "YYYY-MM-DD"
```

---

## 2. 受控詞彙（Enums — 不可自由發揮）

```yaml
layer:                    # 驗證層級，可信度遞增
  - metadata              # 行政資訊
  - existence             # 文獻存在性（DOI/ISBN 查證）
  - citation_context      # 被分析文「如何使用」某文獻   ← S1 上限
  - theory_claim_pending  # 原典主張，尚未讀原典
  - theory_claim_pass     # 原典主張，已讀+頁碼+引文     ← S2 才可達
  - synthesis             # 由 pass 主張構成的理論結構

status:
  - pass                  # 通過閘門，可進 synthesis
  - pending               # 欄位不全或待驗證（預設值）
  - fail                  # 原典不支持該用法 → 觸發回饋環
  - invalidated           # 上游 TC fail 後被反向標記
  - suspect               # 書目/撤稿異常

confidence:               # citation context 專用
  - direct                # 明確引用/近似引文
  - inferred              # 使用隱含、非明確 → 預設進 uncertainty，需 opt-in
  - unclear               # 脈絡不足 → 永遠只進 uncertainty

ci_layer:                 # citation context 的引用角色
  - foundation | definition | mechanism | empirical_anchor | method | counter | context

relation_type:            # 本文與理論的關係（C4，優先採本文自己的動詞）
  - draws-on | defines | applies | extends | challenges | repositions | controls-for

evidence_type:            # C2：此論斷的證據性質
  - explicit              # 本文有句子直接表達，附逐字引文
  - interpreted           # 分析者歸納的分類/角色標籤，不得冒充本文原話

edge_type:                # confirmed graph 邊型別（S2 用）
  - supports | defines | contradicts | scopes | enables
```

---

## 3. 物件 Schema（標明欄位歸屬）

### 3.1 article_metadata（被分析文章本身）— 全 [S1]
```yaml
id: "ART-Chen2026"
type: article_metadata
layer: metadata
status: pass                       # metadata 查到即 pass
title / authors / year / journal / doi / issn          # [S1]
journal_ranking: {ssci, tssci, ahci, impact_factor, quartile, ranking_source}  # [S1]
coverage: full | partial | abstract-only               # [S1]
zotero_key: "..."                  # [S1] 查不到留空，不可捏造
```

### 3.2 source_registry（被分析文引用的每一筆參考文獻）— 全 [S1]
```yaml
id: "SRC-Doshi2021"
type: source_registry
layer: existence
status: pass | pending                 # [S1] 通用閘門狀態：查證完成→pass，待查→pending（用 §2 受控詞彙，勿填 verified）
source_status: verified | searched | suspect | unverifiable   # [S1] 存在性細分；未經查證者一律 searched/unverifiable
authors / year / title / publication_type / journal / volume / issue / pages / doi / isbn  # [S1]
journal_ranking: {...}             # [S1] 期刊文獻才填
cited_in_analyzed_paper:           # [S1] 此文獻在被分析文中的引用位置
  - location: "p.9–10"
    ci_layer: foundation
    ci_card: "CI-..."              # 對應的 citation_context id
retraction_status: clean | retracted | expression_of_concern | unchecked  # [S1]
zotero_key: "..."                  # [S1] 查不到留空
```

### 3.3 citation_context (CI)（被分析文如何使用某文獻）— 全 [S1]，**S1 的主產物**
```yaml
id: "CI-001"                       # 同一文獻×不同 ci_layer → CI-001a/b
type: citation_context
layer: citation_context
status: pass | pending             # 有 direct 引文即 pass（指「引用脈絡」確認，非理論主張確認）
confidence: direct | inferred | unclear   # [S1]
analyzed_paper: "Chen2026"         # [S1]
cited_source: "Doshi2021"          # [S1]
ci_layer: foundation               # [S1]
relation: draws-on                 # [S1][C4] 受控 relation_type；優先採本文動詞
allowed_statement: "Chen2026 uses Doshi2021 as foundation for the great-changes framework."  # [S1] 只可寫「如何使用」
# ↓↓↓ C1–C3：定位與引文（防詮釋幻覺，皆 [S1] 必填） ↓↓↓
verbatim_quote: "According to Doshi, this sense of ... has driven Chinese leadership to reshape global governance structures"  # [C1] 被分析文逐字原文
location_line: "L366"              # [C3] markitdown 文本行號（可字串搜尋回溯）；取代不可靠的 PDF 頁碼
evidence_type: explicit            # [C2] explicit（附引文）| interpreted（分析者歸納，如群組/角色標籤）
# ↓↓↓ 以下為 S2 預留欄位，S1 一律留空/預設 ↓↓↓
tc_candidates: []                  # [S2] 由此 CI 衍生的 theory_claim id
role_status: pending               # [S2] TC fail 時改 invalidated
```

### 3.4 theory_claim (TC)（原典實際主張）— **S1 只建空殼，S2 填實**

> **空殼產生規則（決策 2）**：S1 僅為 `ci_layer ∈ {foundation, definition, mechanism, counter}` 的 CI 自動建立 TC 空殼；`method` 可選；`empirical_anchor`/`context` 不建。一張 CI 對應一張 TC 空殼（透過 `ci_origin` 連結）。

```yaml
id: "TC-001"
type: theory_claim
layer: theory_claim_pending        # [S1] 建立時固定 pending；[S2] 驗證後改 theory_claim_pass
status: pending                    # [S1] 預設 pending
source: "Doshi2021"                # [S1] 可先帶
ci_origin: "CI-001"                # [S1] 衍生自哪張 CI
# ↓↓↓ 以下 7 欄為 pass 硬條件，全部 [S2]，S1 留空 ↓↓↓
evidence_location: ""              # [S2] 原典頁碼/段落
source_quote: ""                   # [S2] 原典逐字引文
source_quote_verified: false       # [S2] 人工/檢索確認
context_meaning: ""                # [S2] supports/limits/contradicts/background
scope_condition: ""                # [S2] 適用範圍
allowed_inference: ""              # [S2] 可推導什麼
not_supported: ""                  # [S2] 不可過度推導什麼（防延伸關鍵欄）
# 升級條件：上列 7 欄齊備 → status: pass, layer: theory_claim_pass
project_relevance:                 # [S3] 關聯到 RQ/H
  research_question: ""
  hypothesis: ""
  writing_status: pending
```

### 3.5 concept / mechanism / debate ledger — 全 [S2]
> 僅由 `status: pass` 的 TC 建立。S1 不碰。定義須逐字引自 pass TC 的 `source_quote`，不可自由心證。

### 3.6 project_anchor（一個專案一份）— 全 [S3]
> 把 pass TC 與 ledger 連到你的研究問題/假設。`writing_status: usable` 需研究者親自確認 scope 涵蓋你的案例。

---

## 4. 接力契約（三個 skill 如何交棒）

```
S1 產出：ART + SRC + CI(填實) + TC(空殼, pending)
            │  全部進 knowledge base，但 layer ≤ citation_context
            ▼
S2 接手：讀原典 → 把選定的 TC 空殼填滿 7 欄 → pass → 建 ledger
            │  fail 的 TC 觸發回饋環：CI.role_status = invalidated
            ▼
S3 接手：pass TC + ledger → project_anchor → 連到 RQ/H → 服務寫作
```

**關鍵**：S1 不需要知道 S2/S3 的細節，只需**忠實留下空殼與 provenance**。S2 永遠不從零開始——它讀的是 S1 已標好 `ci_origin` 的 TC 空殼。

---

## 5. 防幻覺不變式對應的禁令（負面表列，跨 skill 通用）

1. S1 不准把 CI 寫成「Doshi 主張 X」（只能寫「Chen2026 用 Doshi 作為 foundation」）。
2. 任何 skill 不准在 7 欄不全時把 TC 標 `pass`。
3. 不准把存在性查證（source_status）當成理論主張正確的證據。
4. 不准把 `inferred`/`unclear` 的 CI 未經 opt-in 放進任何圖。
5. 不准把 S1 的引用脈絡網絡命名為「理論關係圖」——只能叫 "Citation Context Network (Draft)"。
6. TC fail 時不准只擱置，必須反向把來源 CI 標 `invalidated`。

---

## 6. 檔案佈局（knowledge base）

> 根目錄：`KB_DIR`（預設：使用者 Obsidian vault 下 `literature-kb/`）（決策 3）

```
KB_DIR/   (預設 literature-kb/)
├── README.md                       # 目前 pipeline 狀態 + 風險分數
├── project_anchor.md               # [S3] 一專案一份（資料放 YAML frontmatter）
├── articles/
│   └── <citekey>.md                # [S1] 中心文章節點＝graph 樞紐；metadata 放 frontmatter、論證骨架放 body
├── source_registry/  SRC-*.md      # [S1]
├── citation_contexts/ CI-*.md      # [S1] ← S1 主產物
├── theory_claims/    TC-*.md       # [S1 空殼] → [S2 填實]
├── concepts/ mechanisms/ debates/  # [S2]
├── synthesis/                      # [S2] 僅 pass TC
└── uncertainty/
    ├── unresolved_claims.md        # pending TC + inferred CI
    └── suspect_citations.md        # fail/invalidated/retracted
```

> **Obsidian 相容性（v1.1 修正）**：所有卡片一律用 **`.md`**——Obsidian 只索引 `.md`，`.yaml` 不進 graph、wiki-link 連不到。中心文章節點命名 **`<citekey>.md`**（非 `<citekey>__metadata.yaml`），使各卡的 `[[<citekey>]]` 樞紐連結有目標、在 Graph view 成為中心節點。結構化欄位（metadata / skeleton / CI / TC）放 YAML frontmatter，人讀說明與 `[[wiki-link]]` 放 body。

---

*v1.1 — 修正兩處：(1) source_registry 拆出通用 `status: pass|pending`（受控詞彙）與細分 `source_status: verified|...`，不再讓 `verified` 佔用通用 status；(2) 所有 KB 卡片改 `.md`、中心節點命名 `<citekey>.md` 以修復 Obsidian graph 斷鏈。欄位只增不改，向後相容。*
*v1.0 frozen — 三個設計決策已定（見文件開頭）。*
