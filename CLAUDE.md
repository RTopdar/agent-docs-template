# CLAUDE.md — {{PROJECT_NAME}}

Claude Code-specific tool bindings. Extends [AGENTS.md](AGENTS.md) — read that first; this file only documents how Claude Code implements its rules.

## Rule #3 — Dedicated Agent for Incident Handling

When the user reports a bug/issue, use the `Agent` tool with:

```
subagent_type: "incident-handler"
```

Agent spec: `.claude/agents/incident-handler.md`.

Full cycle: check `doc/bug/index.md` → investigate if needed → fix → write incident doc → update index → relay summary back.

## Rule #4 — Doc-Sync Agent for Self-Healing Documentation

After significant code changes, use the `Agent` tool with:

```
subagent_type: "doc-sync"
```

Agent spec: `.claude/agents/doc-sync.md`.

Scans git diff for new modules/services/agents/decisions and updates `IMPLEMENTATION_PLAN.md`, `AGENTS.md`, and the `doc/feature/` OKF bundle to match code.

## Rule #5 — Knowledge Graph Before Code (only if you install one)

If you add a knowledge-graph tool/skill (e.g. `graphify`), wire it in here with the exact invocation your platform uses. Until then, skip this rule.

---

Add other Claude-Code-specific overrides below (permitted tools, MCP guardrails, project conventions) as they come up.
