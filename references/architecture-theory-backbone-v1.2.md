# LTM 理論建構底層架構藍圖 v1.2（增補，未凍結）

> 目的：把現有的 `schema-contract v1.1`（資料契約）升級成一個可作為**文章理論建構底層邏輯**的系統設計，支援四種能力——**對話 / 建構 / 整合 / 避免虛幻**——且四者共用同一道防幻覺閘門。
>
> 與 `schema-contract.md` 的關係：本文件**不改既有欄位**（v1.1 frozen 仍成立），只**增補**新實體、新不變式與演進路線。標記 `[NEW v1.2]` 者為本次新增。
>
> 狀態：**設計階段**。本文件是藍圖，不含實作；落地時依「§7 演進路線」一層一層推。

---

## 1. 一句話原則

**底層 = 一個 provenance-gated 知識圖譜：任何物件進出都要（a）附被分析文逐字引文、（b）標好所屬 `layer`、（c）通過 `status: pass` 閘門。**

對話、建構、整合都只是這個圖譜的不同**讀寫視圖**，**任何視圖都不准繞過閘門**。防虛幻因此不是某個功能的附加檢查，而是整個儲存的**不變式**（invariant）——只要四種能力都被迫走同一道門，虛幻在定義上就難以發生。

---

## 2. 現況問題（為什麼需要這份藍圖）

| 問題 | 現況 | 後果 |
|---|---|---|
| **儲存分裂** | 三套互不相通：app `~/Documents/theory-maps/*.md`、`WORK_DIR/ltm-work/`、Obsidian `KB_DIR/` | 無單一真相，整合與對話無從接 |
| **app 是契約降級版** | app meta 為扁平字串 `title/citekey/authors/year/journal/doi/ranking/apa`；圖只存 `nodes/rels` | app 的圖**不帶 provenance**（無 `verbatim_quote`/`location_line`）→ 直接的虛幻漏洞 |
| **只實作 S1** | S2（讀原典填 TC）、S3（接 RQ/H）皆空 | 圖永遠停在 citation-context，不能宣稱理論關係；「你自己文章的理論」其實長在 S3，目前缺席 |
| **無對話層** | 知識庫只是檔案 | 無法問答；若直接讓 LLM 自由生成 → 繞過閘門 → 虛幻 |
| **無整合層** | 無 concepts/mechanisms/debates ledger、無實體解析 | 跨論文無法匯流到 canonical 概念節點 |
| **期刊資訊行政化** | journal metadata「查到即 pass」，且被 app 壓成一句 `ranking` 字串 | 規格遠弱於 C1–C4 對理論主張的嚴謹；缺 JCR 年度/分類、ISSN、registry 去重 |

---

## 3. 目標系統總覽

```
                ┌─────────────────────────────────────────────┐
                │   CANONICAL STORE（單一事實來源）            │
                │   = schema-contract KB（Obsidian, .md+FM）   │
                │   ART · SRC · JRN · CI · TC · ledger · anchor│
                └───────────────┬─────────────────────────────┘
                                │  所有讀寫都過閘門
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
   [視圖A 建構]            [視圖B 整合]            [視圖C 對話]
   Streamlit app          ledger / 實體解析       grounded Q&A
   渲染+編輯理論圖        跨論文匯流              cite-or-refuse
   (S1 圖 + S2/S3)        (只吃 pass TC)          (引文+行號或拒答)
        │                       │                       │
        └───────── 全部回寫 canonical store，不另立真相 ──┘
```

**關鍵決定（第 0 步）**：選定 **canonical store = `schema-contract` KB**。app 與對話都是它的視圖；app 現有的 `theory-maps/*.md` 改為 KB 的**匯出格式**（或讓 app 直接讀 KB），不再是獨立真相。

---

## 4. 四能力 × 分層對應

| 能力 | 對應層 | 現況 | v1.2 要補 |
|---|---|---|---|
| **建構** | S1→S2→S3 | 只有 S1（CI/TC 空殼） | S2 填 TC 7 欄、S3 `project_anchor` 接 RQ/H |
| **整合** | concepts/mechanisms/debates | 無 | `[NEW]` 實體解析 + ledger（只由 pass TC 建） |
| **對話** | 跨層查詢 | 無 | `[NEW]` grounded 查詢層（§5 cite-or-refuse） |
| **避免虛幻** | 不變式 | S1 內已強（C1–C4） | `[NEW]` 把不變式延伸到對話與整合 |

**「你自己文章的理論」長在哪裡**：S3 `project_anchor`。它把通過驗證的 `pass` TC 與 ledger 連到你的 `research_question` / `hypothesis`，`writing_status: usable` 需你親自確認 scope 涵蓋你的案例。建構的終點不是單篇圖，而是這份 anchor。

---

## 5. 防虛幻不變式 — 延伸到對話與整合 `[NEW v1.2]`

S1 已對「理論主張」做到 C1–C4。對話與整合是**新表面**，必須套同一套鎖。

### 5.1 對話層：cite-or-refuse（六條硬規則）

| # | 規則 | 防的虛幻 |
|---|---|---|
| D1 | **檢索式接地**：答案只能引用 KB 卡片，且必附 `card_id` + `verbatim_quote` + `location_line` | 自由生成 |
| D2 | **拒答為預設**：無 `pass` 級卡片支撐 → 回「知識庫無此依據」，不腦補 | 無依據捏造 |
| D3 | **層級感知**：嚴格分「本文如何用 X」(CI，S1 可答) vs「X 原典主張」(TC，**僅 pass 可答**)。問原典而 TC=pending → 只能說「尚未讀原典，目前僅有 citation context」 | 把引用脈絡冒充原典主張 |
| D4 | **執行期 grep 自檢**：回答中每句引文，實際 `grep` 回母本；grep 不到**不准輸出** | 引文漂移（把 S1 的抽查變成每次回答的硬斷言） |
| D5 | **evidence_type 透明**：答案標明該依據是 `explicit`（本文明示）或 `interpreted`（分析者歸納） | 把詮釋當原話 |
| D6 | **揭露分母**：跨多篇彙總時講清「N 篇命中、M 篇 pass、其餘 pending」 | 部分查證看似全部 |

### 5.2 整合層：保守合併（兩條硬規則）

| # | 規則 | 防的虛幻 |
|---|---|---|
| I1 | **實體解析從嚴**：兩概念除非同源或本文明示同一，否則**不自動合併**；模糊者進 `uncertainty/`，不偽裝同節點 | 假等同（把不同概念併成一個） |
| I2 | **synthesis 只吃 pass**：ledger / confirmed graph 只由 7 欄齊備的 `pass` TC 構成；pending/inferred 一律擋外 | 用未驗證主張組理論結構 |

> 這 8 條與 v1.1 §0 不變式、§5 禁令**一致延伸**，不衝突。

---

## 6. Schema 增補（v1.2）

### 6.1 `[NEW]` `journal_registry` (JRN) — 期刊正規化實體
把 `journal_ranking` 從每篇文章抽出，一刊一筆，多文以 ISSN 外鍵參照 → 解決重複查證 + JCR 年度/分類缺口。

```yaml
id: "JRN-<issn>"                # 以 ISSN 為主鍵
type: journal_registry          # [NEW v1.2]
layer: existence
status: pass | pending
name: "Sociological Methods & Research"
name_abbrev: "Sociol. Methods Res."   # APA7/Zotero 需要
issn: "0049-1241"
eissn: "1552-8294"
publisher: "SAGE"
rankings:                       # 一刊可多體系、多年度、多分類（陣列）
  - system: "JCR"               # 受控列舉見下
    year: 2023                  # ← v1.1 缺的「年度」（IF/分位逐年變）
    category: "Sociology"       # ← v1.1 缺的「分類別」（一刊可多類不同等級）
    grade_type: "quartile"      # quartile | rating | inclusion | metric-only
    grade: "Q1"                 # 依 grade_type 填值（見下表）
    metric: {name: "IF", value: 5.5}   # 可選量化指標
    source: "<查證 URL>"        # ranking_source 升級為可溯源
    source_status: verified | searched
```

**`rankings[].system` 受控列舉（含 Scopus / CSSCI / ABDC）`[v1.2 擴充]`**：

| system | grade_type | grade 值 | metric | category 來源 | year |
|---|---|---|---|---|---|
| `JCR` | quartile | Q1–Q4 | IF | WoS category | JCR 版本年 |
| `Scopus` | quartile | Q1–Q4（CiteScore 百分位） | CiteScore / SJR / SNIP | Scopus subject area | CiteScore 年 |
| `ABDC` | rating | A* / A / B / C | —（無量化） | ABDC FoR field | 名單版本年 |
| `CSSCI` | inclusion | included / extended（來源／擴展版） | —（收錄制） | CSSCI 學科 | 名單期別 |
| `TSSCI` | inclusion | included（或第一級/第二級） | — | TSSCI 學門 | 名單年 |
| `SSCI` / `AHCI` | inclusion | included | — | WoS category | 收錄年 |

> 設計重點：`grade` 是**多型**欄位，由 `grade_type` 決定語意——quartile（Q1–Q4）、rating（A*–C，ABDC 用）、inclusion（收錄制，CSSCI/TSSCI/SSCI 用）。**不可**把 ABDC 的 A* 硬塞成 quartile，或把 CSSCI 收錄當成有分位——這正是 v1.1 單一 `quartile` 欄無法表達、會逼出虛幻的地方。查不到一律 `pending`，不捏造等級。

### 6.2 `article_metadata` / `source_registry` — 對齊與補欄
- `journal_ranking: {...}` 內嵌物件**改為** `journal_ref: "JRN-<issn>"`（外鍵）。舊欄位保留相容，新資料優先用外鍵。
- 補 `issn` / `coverage` / `zotero_key`（v1.1 已有，確保 app 也存）。

### 6.3 app ↔ contract 對齊
- app 扁平 meta 升級為結構化 `article_metadata`（或在現有 TMDATA JSON 內存完整物件，UI 顯示摘要）。
- **app 的圖每條邊必須帶 provenance**：`rels` 增 `verbatim_quote` + `location_line`（即把 CI 的 C1/C3 帶進 app）。**這是目前最直接的虛幻漏洞**——無引文的邊不得渲染為理論關係。

### 6.4 `[NEW]` 對話層所需索引欄
- 每張 CI/TC 已有 `verbatim_quote` + `location_line` + `source_doc` → 對話層直接用其組 citation；無新增欄位，只需**檢索索引**（檔名/frontmatter 即可，不必向量庫起步）。

---

## 7. 演進路線（一次推一層，每步附驗收）

| 步 | 內容 | 完成定義（DoD） |
|---|---|---|
| **0 統一真相** | 選定 canonical store = KB；現有三套對齊成「KB + 視圖」 | 一份來源；app 讀/匯出 KB，不再各自為政 |
| **1 app 帶 provenance** | meta 結構化；`rels` 加 `verbatim_quote`+`location_line`；無引文的邊不渲染為理論邊 | 隨機抽 app 圖 2–3 條邊，引文能 grep 回母本 |
| **2 期刊 registry** | 落 JRN 實體；ART/SRC 改外鍵；補 JCR 年度+分類、ISSN | 同一期刊多篇只一筆 JRN；分位帶年度與分類 |
| **3 實作 S2** | 讀原典 → 填 TC 7 欄 → pass → 建 ledger | 有 ≥1 張 `theory_claim_pass`；fail 觸發 CI `invalidated` |
| **4 S3 + 對話層** | `project_anchor` 接 RQ/H；對話層套 §5 cite-or-refuse | 問答能引卡+行號或拒答；問原典時正確區分 CI/TC |

> 順序理由：對話與整合的**可信度上限**取決於底下有沒有 pass TC（§5 D3、I2）。所以先打地基（0→2）、再長 S2（3）、最後才開對話（4），否則對話只能停在 citation-context 層、且易繞過閘門。

---

## 8. 已定案（2026-06-21）與其影響

| # | 決定 | 對架構的影響 |
|---|---|---|
| 1 | **canonical store = Obsidian KB** | KB（`.md`+frontmatter+wiki-link）為**唯一事實來源**；app 的 `theory-maps/*.md` 降為 KB 的**匯出/編輯視圖**——需一條 KB↔app 的讀寫橋（app 載入時讀 KB 卡片、儲存時回寫 KB，不另立真相）。Graph view + wiki-link 成為整合層的天然底盤。 |
| 2 | **對話層 = 獨立 RAG**（非 app tab） | 一個**獨立程序**（CLI 或小服務）讀 KB，套 §5 cite-or-refuse。**起步用 grep + frontmatter 索引即可**（MVP，零向量庫）；卡片量大或需語意檢索再上向量庫，且**檢索回來仍須附 `verbatim_quote`+`location_line`**，向量庫只負責「找候選」，不負責「生成答案」。 |
| 3 | **分級體系 = JCR/TSSCI + Scopus/CSSCI/ABDC** | `journal_registry.rankings[].system` 採 §6.1 受控列舉；`grade` 多型（quartile/rating/inclusion）。查證時 firecrawl/Scholar Gateway 需分別比對各體系來源，未查到的體系不列、不捏造。 |

**仍待定（不阻擋起步）**：向量庫選型（步 4 才需要）、KB↔app 橋是「app 直讀 KB」或「雙向同步腳本」（步 1 決定）。

---

## 9. 落地順序確認（依 §8 決定收斂）

藍圖完成。依 §7 路線，**下一步 = 步 0：以 Obsidian KB 為真相做收斂**——把現有三套儲存對齊成「KB + 視圖」，並定 KB↔app 橋。其餘維持設計階段，一次推一層。

---

*v1.2 增補 — 新增 journal_registry（含 Scopus/CSSCI/ABDC 多型 grade）、對話層 cite-or-refuse（D1–D6）、整合層保守合併（I1–I2）、app provenance 對齊、四步演進路線；§8 三項決定已定案（Obsidian KB／獨立 RAG／三體系擴充）。既有 v1.1 欄位不改，向後相容。*
