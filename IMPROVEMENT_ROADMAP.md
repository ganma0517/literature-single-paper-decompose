# literature-single-paper-decompose — 套件化改進 Roadmap

> 來源：cross-ai-check 交叉檢核（claude + codex；gemini 配額失敗未參與）2026-06-21。
> 目標：把「設計嚴謹的研究輔助 skill」推進到「他人可信賴的可發佈套件」。
> 核心共識：決定性缺口不是再加 prompt 規則，而是把「**可追溯**」升級為「**claim 被證據支撐**」、把可讀產物收斂到**已驗證 artifact**，並補測試集與失敗拒絕策略。

---

## P0 — 決定性（直接堵住最大幻覺殘留 + 可信度）　✅ 已實作 2026-06-21

> 落地：新增 `scripts/verify_claims.sh`（全量逐字 grep + strict 拒絕門檻 + 區分捏造/吞空格）；
> `SKILL.md` 加 C5 適配性、全量自我檢查取代抽樣、strict/refuse 門檻、digest 收斂到驗證 artifact、
> Forbidden Actions 增列第 11/12 條。Claude 驗證：對抗樣本(捏造→🔴/吞空格→⚠️,exit2)與
> 合法樣本(Vandamme 6條、Chin 7條全 ✅,exit0)雙向通過。

### P0-1 可讀產物收斂到已驗證 artifact
- **問題**：script 強制 grep 命中的是 KB 卡片，但使用者實際讀的 `digest` 只「自我宣稱已 grep」、無稽核軌跡——約束最低的產物正是讀者看的那份。
- **改法**：digest 每條 L1/L3 論斷後內聯帶 `claim-id + verbatim_quote + 母本行號 + 命中狀態(✅/❌)`；或明訂「KB 卡片為唯一可信產物，digest 僅導覽、不可單獨引用」。
- **落點**：`SKILL.md` 第 3 步 / 收尾回報；`references/schema-contract.md`。
- **驗收**：隨機抽 digest 任一論斷，可見其行號與 ✅；❌ 者不得出現在「最終結論」。

### P0-2 claim↔evidence 適配檢查 + strict/refuse 模式
- **問題**：現行只驗「quote 是否存在」，不驗「quote 是否**支撐** claim」——這是幻覺最大殘留區（可追溯 ≠ 可靠）。
- **改法**：(a) 第 3 步新增 **C5 適配性**：每條論斷須說明「此引文如何支撐此關係」，禁止引文與論斷錯位；(b) 新增 `strict mode`：凡 grep 不命中或引文不支撐 → 標 🔴 並**拒絕**寫入最終結論，而非照常輸出。
- **落點**：`SKILL.md` 第 3 步（加 C5）+ Forbidden Actions；可在 `_gen_kb.py`/script 加「不命中即 reject」分支。
- **驗收**：故意放一條「引文存在但不支撐」的論斷，strict 模式應擋下標 🔴。

### P0-3 全量 claim 自我 grep（取代隨機 2–3）
- **問題**：自我檢查「隨機抽 2–3 條」對系統性錯誤容易漏。
- **改法**：輸出前對**每一條** C1 引文逐條 grep，附「命中表」（claim-id ↔ 行號 ↔ ✅/❌）。
- **落點**：`SKILL.md` 第 3 步自我檢查；`scripts/`（可寫個 `verify_claims.sh` 全量掃）。
- **驗收**：產物附完整命中表，覆蓋率 = 100% 的論斷被檢查。

---

## P1 — 重要（穩健性地基）

### P1-1 母本品質量化門檻　✅ 已實作 2026-06-21
- **問題**：母本吞空格 → grep 失效卻可能假陰性過關；目前只「抽樣目檢」。
- **改法**：把目檢換成可測指標（長黏串率、逗號黏字率、URL 斷字、空白密度），低於門檻**自動 fallback 或停**。
- **落地**：新增 `scripts/master_quality.sh`（經驗校準門檻 + CJK 母本守門 + 嚴重度 PASS/WARN/FAIL→exit 0/3/2）；`SKILL.md` 第 1 步把「抽樣目檢」改為量化門檻，FAIL 強制 fallback、換抽後須重驗轉 PASS。
- **Claude 驗證**：whitehead/vandamme/fpos 三良好母本 PASS(exit0)、dirty fixture FAIL(exit2)；修掉一個 severity 排序 bug（WARN 退出碼 3 數值大於 FAIL 2，原會蓋掉 FAIL）。
- **校準基準**：良好母本長黏串率/逗號黏字率恆 0；髒 fixture 為 3.91 / 7.81。

### P1-2 citation role 分類 + 否定/讓步語氣處理
- **問題**：把「有引用」過度解讀成「依賴該理論」；把背景鋪陳當理論基礎；漏掉 however/although/not/may 等 hedge → 理論誤讀高發區。
- **改法**：受控關係詞之外加 `role`（作者自身主張/他人觀點/背景/批判對象/方法來源/資料來源/例子）；新增規則：論斷涉及否定或讓步語氣時須保留該語氣，不得抹平。
- **落點**：`SKILL.md` C2/C4 擴充 + Forbidden Actions 增列。
- **驗收**：對一段「作者轉述他人觀點」的引文，產物正確標 role=他人觀點，不誤判為作者立場。

### P1-3 架構圖防「假清晰」
- **問題**：把辯證/條件式論述硬壓成節點與邊，看似清楚實則過度結構化。
- **改法**：允許「條件邊 / 存疑邊」標記；對無法明確定性的關係，標 `tentative` 而非強行給受控動詞。
- **落點**：`SKILL.md` 第 4 步。
- **驗收**：辯證型論文的圖中出現至少一條 tentative/條件邊，而非全部硬定性。

---

## P2 — 套件成熟度（對外發佈才需）

### P2-1 可重現性
- 固定 parser/模型/prompt/schema 版本 + 輸入 PDF hash + 輸出 artifact hash，寫進產物 metadata。同篇重跑可比對。
- **落點**：產物 frontmatter；`schema-contract.md`。

### P2-2 測試集 + 評估指標
- 擴充 `evals/`：雙欄 PDF、掃描 OCR、公式密集、人文長腳註、**植入假 claim 的對抗樣本**。
- 量測：引文命中率、錯誤 claim 率、關係動詞誤判率、explicit/interpreted 混淆率、母本抽取錯誤率、書目查核召回率。
- **落點**：`evals/`（目前只有 1 個髒母本樣本，不足）。

### P2-3 失敗拒絕策略
- 擷取品質差／核心文獻查無／引文定位不到時 → 降級標紅或停止，不產「看似完整」的報告。
- **落點**：`SKILL.md` 各步 + 收尾回報；對應 strict mode（見 P0-2）。

### P2-4 套件邊界與契約
- 明訂它是 Claude skill / CLI / Python package？定義安裝、輸入、輸出、錯誤碼、依賴缺失（markitdown/pypdf/firecrawl/mermaid）的 graceful 處理、隱私（連網/外部模型上傳了什麼、是否保存、如何關閉）、版權（逐字引文庫對外發佈的授權問題）。
- **落點**：`README.md` + `SKILL.md` 風險段。

---

## 暫不做 / 受阻

- **觸發正確性量測**：受阻於本機 desc-opt 評分工具失效（恆 0% recall，需 py3.12 環境）。在修好量測工具前無法可靠驗證「何時用本 skill vs 一般摘要 skill」。屬 P2-2 一環，但需先修工具鏈。
- **版權處理**：僅在「對外發佈逐字引文庫」情境才成立；個人研究用途可暫緩（已列 P2-4）。
- **不建議的方向**：再堆更多 prompt 規則來「補洞」——兩方一致認為效益遞減，應改投資於可驗證 artifact 與測試/指標。

---

## 建議施作順序
1. **P0-2 + P0-3**（claim↔evidence 適配 + 全量 grep + strict/refuse）：一次到位堵住最大幻覺殘留，且可立即在現有 script 上加。
2. **P0-1**（digest 收斂到可驗證 artifact）：解決「讀者讀到弱產物」。
3. **P1-1**（母本量化門檻）：鞏固地基。
4. **P1-2 / P1-3**（role 分類 + 語氣 + 圖防假清晰）：降語義誤讀。
5. **P2**：要對外發佈時才補。
