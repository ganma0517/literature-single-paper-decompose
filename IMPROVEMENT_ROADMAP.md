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

### P1-2 citation 立場分類 + 否定/讓步語氣處理　✅ 已實作 2026-06-21
- **問題**：把「有引用」過度解讀成「依賴該理論」；把背景鋪陳當理論基礎；漏掉 however/although/not/may 等 hedge → 理論誤讀高發區。
- **改法**：與 relation 正交新增 `citation_stance`（author-endorsed / attributed-other / opposed / background）；保留否定/讓步語氣（已併入 C5）。
- **落地**：新增 `scripts/stance_lint.sh`（強依賴關係詞+否定引文→🔴疑似錯配、hedge→⚠️、轉述訊號→⚠️；exit 0/3）；`SKILL.md` 第 3 步加 citation_stance 標記規則 + 鐵則 + lint 指令；Forbidden Actions 增列第 13 條；`schema-contract.md` citation_context 加 `citation_stance` 欄位。
- **Claude 驗證**：對抗案例(錯配🔴/hedge⚠️/轉述⚠️/oppose一致✅/clean✅,exit3)正確；真實 Vandamme+Chin 6 條全 ✅ **零誤報**(exit0)，含 Pitkin「act completely independently」未誤觸否定偵測。

### P1-3 架構圖防「假清晰」　✅ 已實作 2026-06-21
- **問題**：把辯證/條件式論述硬壓成節點與邊，看似清楚實則過度結構化。
- **改法**：邊—證據表加「定性」欄（confirmed/tentative/conditional）；tentative/conditional 用 Mermaid 虛線 `-.->`，conditional 須把條件寫進 label 與引文。
- **落地**：新增 `scripts/graph_lint.sh`（定性↔箭頭一致性 + confirmed 卻帶條件/推測語氣的假清晰偵測 + conditional 條件未落引文；exit 0/3/2）；`SKILL.md` 第 4 步加定性欄與虛線慣例 + lint 指令；Forbidden Actions 增列第 14 條。
- **Claude 驗證**：對抗案例(箭頭不一致🔴/假清晰🔴/條件式✅/條件缺引文⚠️,exit2)正確；全乾淨案例 PASS(exit0)。

---

## P2 — 套件成熟度　✅ 已實作 2026-06-21

> 落地：`scripts/provenance.sh` + `scripts/deps_check.sh` + `evals/run_evals.sh` + `evals/fixtures/`；
> `SKILL.md` 新增「工具與錯誤碼契約」節（0/3/2 一致語意 + strict 總則 + 回歸指令）；
> `README.md` 改 C1–C5、repo layout 補 scripts/evals、加 Quality gates(exit-code contract) 與版權/scope 誠實段。

### P2-1 可重現性　✅
- **落地**：`scripts/provenance.sh` 輸出 provenance YAML（輸入 PDF/母本 sha256 + skill_commit + schema 版本 + 工具版本），嵌入產物 frontmatter。
- **Claude 驗證**：hash 重跑穩定；修掉 schema 版本多行 bug（`-o` 全印→`head -1`）。

### P2-2 測試集 + 評估指標　✅
- **落地**：`evals/run_evals.sh` 對四支 guard × 8 個 fixtures 斷言預期退出碼並報通過率；`evals/fixtures/` 含 clean/tampered claims、stance、edges。
- **Claude 驗證**：8/8 全綠（exit 0）；修掉 awk-in-printf 造成的小結重印 bug。
- **缺口（誠實）**：尚未納雙欄/OCR/公式/人文長註等真實 PDF 對抗樣本（需實檔），目前 fixtures 為合成；觸發正確性量測仍受阻於 desc-opt 工具失效。

### P2-3 失敗拒絕策略　✅
- **落地**：strict 總則彙整進 SKILL.md「工具與錯誤碼契約」+ 收尾回報；任一 guard 回 2 即須排除/降級/停。

### P2-4 套件邊界與契約　✅
- **落地**：`scripts/deps_check.sh`（硬/軟依賴 + MCP 盤點，硬缺 exit 2）；README 明示「是 Claude skill + 輔助 script，非獨立 CLI/pip 套件」、exit-code 契約、隱私（已於中文摘要）、版權（逐字引文庫再散布提醒）。

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
