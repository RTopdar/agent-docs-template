# Agent Instructions — {{PROJECT_NAME}}

These rules apply to any AI coding agent working in this repo (Claude Code, Cursor, Copilot, Codex, etc.). Rename or delete this placeholder line once filled in.

## 1. Implementation Plan

- `IMPLEMENTATION_PLAN.md` holds the architecture and design of this project.
- Update it every time something new is added (module, service, dependency, major decision). Treat drift between this file and the actual code as a bug.
- Before starting non-trivial work, read this file first.

## 2. `doc/` Structure — Two OKF Bundles + Index of Indexes

`doc/` holds two independent **OKF (Open Knowledge Format v0.2) bundles**. Never mix their content:

- **`doc/bug/`** — incidents. [doc/bug/index.md](doc/bug/index.md) is the bundle index; each incident gets its own OKF concept file under `doc/bug/incidents/`.
- **`doc/feature/`** — architecture. [doc/feature/index.md](doc/feature/index.md) is the bundle index; each concept (module, service, script) gets its own small OKF file under `doc/feature/`.
- **`doc/index.md`** — index of indexes. Points to both bundle indexes above and holds no content of its own. Read this first when you don't already know which bundle is relevant.

### OKF format (applies to both bundles)

- Every `.md` file (except reserved `index.md`/`log.md`) has YAML frontmatter with at minimum a `type` field (`Module`, `Bundle Index`, `Incident`, etc.); recommended fields: `title`, `description`, `resource` (path to the source file it documents/affects), `tags`, `status`.
- **One concept per file, kept small.** A module, script, or incident gets its own doc — never bundle multiple concepts into one large file.
- Cross-link concepts with bundle-relative markdown links (`[Chunker](/doc/feature/chunker.md)`), not prose.
- Each bundle's `index.md` lists and links every concept doc in it — update it whenever a concept doc is added or removed.
- Reference: [Google Cloud OKF spec](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md).

### Mandatory: read before you write

**Before suggesting or making any change to a module, check its `doc/feature/` concept doc (and `doc/bug/index.md` for prior incidents in that area) first.** If no concept doc exists yet for the module, that's a signal docs have drifted (flag it / delegate to `doc-sync`), not a reason to skip the check.

### Bug/Issue Handling (`doc/bug/`)

- **When a new problem is reported:**
  1. Check `doc/bug/index.md` first for a matching or related incident. If a resolution already exists, apply/reference it — do not re-derive from scratch.
  2. Also check the relevant `doc/feature/` concept doc for the affected module.
  3. If nothing matches, only then investigate the codebase, fix it, and create a new incident file.
- **Each incident file** (`doc/bug/incidents/INC-XXX-short-slug.md`) must contain: root cause, resolution method, final status (resolved / not resolved).
- **When a new bug/issue is introduced** (by us or discovered as a side effect), it also gets logged in the index, not just fixes.
- Keep `doc/bug/index.md` continuously up to date — it's the source of truth for "has this happened before."

## 3. Dedicated Agent for Bug Handling

- Delegate the bug-handling flow above to a dedicated subagent rather than doing it inline in the main thread.
- Main thread's job: receive the problem report, hand it to the `incident-handler` subagent (`.claude/agents/incident-handler.md`), relay the result.

## 4. Doc-Sync Agent for Architecture Documentation

- Keep `IMPLEMENTATION_PLAN.md`, `AGENTS.md`, and the `doc/feature/` OKF bundle in sync with the actual codebase.
- When code changes introduce new modules, services, major decisions, or agents, delegate to the `doc-sync` subagent (`.claude/agents/doc-sync.md`) to scan diffs and update docs.
- **Self-healing scope**: doc-sync updates `IMPLEMENTATION_PLAN.md` and `doc/feature/*.md`. It does not touch `doc/bug/` — that subtree is owned exclusively by `incident-handler`.

## 5. File Size Cap — 500 Lines

- No file should grow past 500 lines. Enforces DRY — a file that big usually means logic that should be split out, not one giant module.
- Before writing/extending a file past 500 lines: check if part of it can become a reusable component/module in a new file. If yes, extract it there.
- If it genuinely can't be split (no reusable seam), it's fine to exceed the cap — but ask before doing so rather than silently blowing past it.

## 6. Knowledge Graph Before Code (optional — requires a knowledge-graph tool)

If a knowledge-graph tool (e.g. `graphify`) is available in your platform:

- **Order of lookup** for any "where is X" / "how does X work" question, or before editing a module you haven't touched this session:
  1. `doc/index.md` → relevant bundle index → the specific concept doc. Fastest, hand-curated, cheapest.
  2. Knowledge graph query if the doc bundle doesn't have the answer or seems stale.
  3. Raw code grep/read only if neither of the above resolves it.
- If no such tool exists on your platform, skip straight to step 3 — this rule is optional infrastructure, not a hard requirement.

---

Add project-specific rules (data-model conventions, migration policy, file-size caps, exception-handling policy, etc.) below this line as they emerge — this template intentionally ships without them since they're stack-specific.
