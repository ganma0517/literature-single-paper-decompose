# literature-single-paper-decompose

> **Author**: Wen-Cheng Lin　｜　**Experimental skill**
>
> ⚠️ Designed to reduce AI fabrication, but it **cannot guarantee zero errors**. Treat the output as a research aid and **verify important citations and theory attributions yourself**. Whether to use it is your call. （中文摘要見文末。）

A [Claude Code](https://claude.com/claude-code) **skill** that turns a single academic paper into a **traceable, low-hallucination theory-construction analysis** plus an architecture diagram.

Core value — **every claim can be `grep`-ed back to the source text, and "what the paper explicitly says" is kept strictly separate from "what the analyst inferred."**

---

## Why

Fabricated or misattributed citations are an increasing risk (especially in AI-assisted writing). But the most insidious hallucination when *summarizing* a paper is not inventing the original source — it is **over-interpreting the analyzed text itself**: passing off the analyst's own labels as the paper's words. This skill enforces a set of mechanically auditable conditions to hold that line.

**Cardinal rule:** describe only *how the paper uses a reference / constructs its theory* (citation context). **Never** assert *what the original source actually claims* — that requires reading the original and belongs to a later layer.

## Pipeline

```mermaid
flowchart TD
    A([Paper PDF / DOI]) --> B

    subgraph S1["Step 1 · Import"]
      B["markitdown"] --> C{"Quality check:<br/>glued words? watermark noise?"}
      C -->|clean| E["Clean Markdown master<br/>(WORK_DIR/citekey.md)"]
      C -->|fails| D["pypdf fallback<br/>(page-marked)"] --> E
    end

    E --> F
    subgraph S2["Step 2 · Information"]
      F["Article APA7 citation<br/>+ structured summary<br/>+ theory-relevant refs → APA7<br/>+ online verification (DOI/JCR/retraction)"]
    end

    F --> G
    subgraph S3["Step 3 · Theory construction"]
      G["L1 sources · L2 operations · L3 relations"]
      G --> H{"C1–C4 grounding:<br/>verbatim quote · evidence_type<br/>grep-able locator · controlled verbs"}
    end

    H --> I
    subgraph S4["Step 4 · Architecture diagram"]
      I["Mermaid graph:<br/>sources ↔ framework ↔ method ↔ findings<br/>every edge maps to a quote"]
    end

    I --> J([Report in WORK_DIR])
    J -.optional.-> K[("Obsidian KB cards<br/>KB_DIR · S2/S3-ready")]
```

## Anti-hallucination conditions (C1–C4)

Every theory-relation claim in Step 3 (and every edge in Step 4) must satisfy:

| # | Condition | Guards against |
|---|---|---|
| **C1** | Attach the paper's **verbatim quote** (no paraphrase, no page-only) | interpretation drift |
| **C2** | Tag `evidence_type`: `explicit` (paper states it, quoted) vs `interpreted` (analyst's grouping/label) | passing inference off as the paper's words |
| **C3** | Locate via a **grep-able** line/quote in the clean master | citation drift, unverifiable page numbers |
| **C4** | Use a **controlled relation vocabulary** (`draws-on / defines / applies / extends / challenges / repositions / controls-for`) and prefer the paper's own verb | upgrading a weak verb into a stronger claim |

> Self-check: after Step 3, randomly pick 2–3 claims and actually `grep` their quotes against the master. A miss means a locator/quality problem to fix.

## Installation

```bash
# Global (all projects)
git clone https://github.com/ganma0517/literature-single-paper-decompose.git \
  ~/.claude/skills/literature-single-paper-decompose

# Per-project
git clone https://github.com/ganma0517/literature-single-paper-decompose.git \
  <your-project>/.claude/skills/literature-single-paper-decompose
```

Restart Claude Code to load the skill.

**Dependencies:**
- `markitdown` — `pipx install 'markitdown[pdf]'` (needs Python ≥ 3.10)
- `pypdf` — fallback extractor
- `firecrawl` MCP (or any web-search tool) — reference verification
- Optional: Obsidian — long-term knowledge-base cards

## Path configuration (portable)

SKILL.md uses two configurable paths; adjust per project/machine:

| Variable | Purpose | Default |
|---|---|---|
| `WORK_DIR` | Work products (master + step reports) | `./ltm-work/` in the current project |
| `KB_DIR` | Optional long-term knowledge base (Obsidian KB cards) | `literature-kb/` under the user's Obsidian vault |

If unset, defaults are used and the landing location is stated in the report.

## Repository layout

```
.
├── SKILL.md                      # The skill: 4-step pipeline + C1–C4 + Forbidden Actions
├── references/
│   └── schema-contract.md        # Shared three-layer data contract (S1/S2/S3)
└── examples/                     # Real run examples (no source PDFs)
    ├── Chen2026/                 # Political-science empirical paper: step2/3/4 + diagram
    └── Karlson2012/              # Statistical-method paper (KHB method): combined report
```

## Three-layer context

This is **layer one (S1)** of an "LTM knowledge network," deliberately stopping at the citation-context layer to stay low-hallucination:

- **S1 (this skill)** — single-paper decomposition: citation context, existence verification, theory-construction mapping.
- **S2 (future)** — read the *originals* to verify theory claims; build pass-grade theory-claim cards.
- **S3 (future)** — connect verified theory to research design (RQ/H) for writing.

The data contract (`references/schema-contract.md`) already reserves S2/S3 fields so S1 output stays forward-compatible.

## 中文摘要（補充）

這是一個 Claude Code 外掛，幫你**精讀一篇學術論文**，整理成「每句話都能查回原文」的分析，並畫出**理論架構圖**。核心是**分清「論文白紙黑字寫的」與「分析者自己推論的」**——AI 整理論文最常見的毛病不是憑空捏造，而是把自己的理解講得像作者原話；本工具用硬規矩（每個說法要附原文逐字引文、且能用搜尋找到）擋住這點。它**只描述「這篇論文怎麼使用某份文獻」**，不宣稱「那份文獻原本主張什麼」。

**怎麼用**：把論文 PDF／DOI 給 Claude，說「幫我精讀、要能查回原文、別腦補」即可。產出含書目（APA7）、重點摘要、參考文獻查證（含撤稿）、理論架構圖。

**使用前注意**：① 不保證零錯誤，重要結果請自行覆核；② 隱私——查證會把論文片段送到外部搜尋，第 5 步交叉檢核還會送給其他 AI，未發表稿件請斟酌；③ API 金鑰是個人機密，**絕不要貼進聊天視窗**，只存本機。

> 完整技術細節以上方英文為準。

## License

MIT
