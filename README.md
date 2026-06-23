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
      G --> H{"C1–C5 grounding:<br/>verbatim quote · evidence_type<br/>grep-able locator · controlled verbs<br/>· quote–claim adequacy"}
    end

    H --> I
    subgraph S4["Step 4 · Architecture diagram"]
      I["Mermaid graph:<br/>sources ↔ framework ↔ method ↔ findings<br/>every edge maps to a quote"]
    end

    I --> J([Report in WORK_DIR])
    J -.optional.-> K[("Obsidian KB cards<br/>KB_DIR · S2/S3-ready")]
```

## Anti-hallucination conditions (C1–C5)

Every theory-relation claim in Step 3 (and every edge in Step 4) must satisfy:

| # | Condition | Guards against |
|---|---|---|
| **C1** | Attach the paper's **verbatim quote** (no paraphrase, no page-only) | interpretation drift |
| **C2** | Tag `evidence_type`: `explicit` (paper states it, quoted) vs `interpreted` (analyst's grouping/label) | passing inference off as the paper's words |
| **C3** | Locate via a **grep-able** line/quote in the clean master | citation drift, unverifiable page numbers |
| **C4** | Use a **controlled relation vocabulary** (`draws-on / defines / applies / extends / challenges / repositions / controls-for`) and prefer the paper's own verb | upgrading a weak verb into a stronger claim |
| **C5** | **Quote–claim adequacy**: the quote must actually *support* the relation, not merely exist in the master; preserve hedges (may / however / not) | "traceable ≠ reliable": a quote that greps back but supports something else |

Plus an orthogonal **`citation_stance`** label (`author-endorsed` / `attributed-other` / `opposed` / `background`) so "the paper cites X" is never silently read as "the paper depends on X's theory."

> Self-check is **exhaustive, not sampled**: every C1 quote is grep-verified by `scripts/verify_claims.sh`, and any miss is a hard strict-mode stop (see *Quality gates* below).

## When to use / not use

**Use:** deep forensic analysis of a single paper — you need to know exactly what the paper *explicitly says* (with verbatim quotes) vs. what the analyst inferred; building Obsidian KB cards for a longer writing project; verifying whether a paper's citations are real and whether the paper actually supports the claim it's being cited for.

**Don't use:** batch processing many papers quickly → `academic-paper-digest` (lighter); writing a literature review → `literature-review-hardened`; designing a course reading list → `course-syllabus`; visualizing a full literature network across many papers (this is single-paper only).

---

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

**Dependencies** (run `bash scripts/deps_check.sh` to verify):
- Hard: `bash` / `grep` / `perl` / `python3` / `awk` — the guard scripts
- `markitdown` — `pipx install 'markitdown[pdf]'` (needs Python ≥ 3.10); `pypdf` fallback extractor
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
├── SKILL.md                      # The skill: 5-step pipeline + C1–C5 + 14 Forbidden Actions
├── references/
│   └── schema-contract.md        # Shared three-layer data contract (S1/S2/S3)
├── scripts/                      # Portable bash guards (exit-code contract: 0 PASS / 3 WARN / 2 FAIL)
│   ├── biblio_healthcheck.sh     #   watermark / AI-pasted links / DOI typos
│   ├── master_quality.sh         #   quantitative master-quality threshold (P1-1)
│   ├── verify_claims.sh          #   full-set verbatim-quote grep + strict refuse (P0)
│   ├── stance_lint.sh            #   citation-stance / hedge heuristics (P1-2)
│   ├── graph_lint.sh             #   architecture-diagram false-clarity check (P1-3)
│   ├── provenance.sh             #   reproducibility frontmatter: input hashes + versions (P2-1)
│   └── deps_check.sh             #   hard/soft dependency preflight (P2-4)
├── evals/                        # Self-test regression suite + fixtures
│   ├── run_evals.sh              #   asserts each guard's verdict on known fixtures
│   ├── dirty_master_fixture.md   #   planted-defect master
│   └── fixtures/                 #   clean/tampered claims, stance, edges
└── examples/                     # Real run examples (no source PDFs)
    ├── Chen2026/                 # Political-science empirical paper: step2/3/4 + diagram
    └── Karlson2012/              # Statistical-method paper (KHB method): combined report
```

## Quality gates (exit-code contract)

All guards in `scripts/` share one convention: **`0` = PASS, `3` = WARN (usable, review), `2` = FAIL (that item is untrusted; strict mode must drop it)**. Under strict mode, any `2` means the affected claim/edge/master **must not** enter the final conclusion — fix and re-verify, or honestly down-rank it; never paper over it. The toolchain itself is regression-tested:

```bash
bash scripts/deps_check.sh        # preflight: hard/soft deps + MCP tools
bash evals/run_evals.sh           # all guards green on known fixtures (该挡有挡 / 该放有放)
```

For reproducibility, embed `scripts/provenance.sh <master> [pdf]` output (input sha256 + skill commit + schema version) into each artifact's frontmatter so the same input re-runs to a comparable result.

> **Scope honesty (not yet a turnkey package):** this is a Claude skill plus helper scripts, **not** a standalone CLI/pip package. It is hallucination-*reducing*, not hallucination-*free*: verification is grep-exhaustive but stance/adequacy (C5/stance) remain model-judgment with heuristic lints, so outputs still need human review. Note also that retaining verbatim quotes builds a quote database — mind source copyright/licensing if you redistribute artifacts.

## Three-layer context

This is **layer one (S1)** of an "LTM knowledge network," deliberately stopping at the citation-context layer to stay low-hallucination:

- **S1 (this skill)** — single-paper decomposition: citation context, existence verification, theory-construction mapping.
- **S2 (future)** — read the *originals* to verify theory claims; build pass-grade theory-claim cards.
- **S3 (future)** — connect verified theory to research design (RQ/H) for writing.

The data contract (`references/schema-contract.md`) already reserves S2/S3 fields so S1 output stays forward-compatible.

## 中文摘要（補充）

本工具用於**單篇學術論文的精讀**，將其整理成一份「**每項論斷皆可回溯至原文**」的分析，並繪製論文的**理論架構圖**。

其核心原則是**嚴格區分「論文明示之內容」與「分析者詮釋之內容」**。AI 在整理論文時最常見的問題，並非憑空虛構，而是**將自身的理解陳述為作者原話**（過度詮釋）。因此本工具要求每項論斷皆須附上原文逐字引文、且須可經文字搜尋驗證，否則不予採用。此外，它**僅描述「本文如何援用某份文獻」**，不宣稱「該文獻原本之主張為何」——後者須回溯原典查證，屬後續工作範疇。

**使用方式**：將論文 PDF 或 DOI 提供給 Claude，並說明「精讀本篇、須可回溯原文、避免自行臆測」即可。產出包含書目（APA7）、結構化摘要、參考文獻查證（含撤稿狀態），以及理論架構圖。

**使用前須留意**：① 本工具**無法保證完全無誤**，重要結果仍須自行覆核；② 查證過程會將論文片段送至外部搜尋服務，第 5 步交叉檢核並會送交其他 AI 模型，**未發表稿件請自行斟酌**；③ API 金鑰屬個人機密，**切勿貼入對話視窗**，僅應存放於本機。

> 完整技術細節以上方英文文件為準。

## License

MIT
