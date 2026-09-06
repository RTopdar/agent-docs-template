# agent-docs-template

A portable, one-command scaffold for coding-agent project documentation: `CLAUDE.md` / `AGENTS.md` behavioral rules, `incident-handler` + `doc-sync` subagent specs, and a two-bundle [OKF](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) `doc/` structure (`doc/feature/` for architecture, `doc/bug/` for incidents). Platform-agnostic — works with any agent that reads `AGENTS.md`-style files (Claude Code, Cursor, Copilot, Codex, etc.), with an optional Claude-Code-specific binding layer.

## Quickstart

Scaffold into the current directory (never overwrites existing files by default). The script prompts interactively for your project name and fills `{{PROJECT_NAME}}` into the docs automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/RTopdar/agent-docs-template/master/install.sh | bash
```

```
   ┌─────────────────────────────────────┐
   │        agent-docs-template           │
   │  AGENTS.md · CLAUDE.md · OKF docs     │
   └─────────────────────────────────────┘

? Project name (used to fill {{PROJECT_NAME}} in the scaffolded docs): my-cool-app
→ Fetching template from RTopdar/agent-docs-template@master...
✓ Template fetched
→ Scaffolding files into /home/you/my-cool-app...
✓ Files scaffolded
Done. Scaffolded for my-cool-app:
  CLAUDE.md, AGENTS.md, .claude/agents/, doc/, IMPLEMENTATION_PLAN.md
→ Next: fill in IMPLEMENTATION_PLAN.md and start documenting modules under doc/feature/.
```

Pass `--name "My Project"` to skip the prompt (useful for non-interactive/CI runs — the script falls back to the current directory's name if no name is given and no terminal is reachable):

```bash
curl -fsSL https://raw.githubusercontent.com/RTopdar/agent-docs-template/master/install.sh | bash -s -- --name "My Project"
```

Add `--caveman` to also install the [caveman](https://github.com/JuliusBrussee/caveman) Claude Code plugin (terse, token-saving agent output) and drop `.caveman.json`:

```bash
curl -fsSL https://raw.githubusercontent.com/RTopdar/agent-docs-template/master/install.sh | bash -s -- --caveman
```

Pass `--force` to overwrite files that already exist in the target directory:

```bash
curl -fsSL https://raw.githubusercontent.com/RTopdar/agent-docs-template/master/install.sh | bash -s -- --force
```

Flags combine, e.g. `bash -s -- --name "My Project" --caveman --force`.

As with any `curl | bash` install, review the script first if you want to verify what it does before running it:

```bash
curl -fsSL https://raw.githubusercontent.com/RTopdar/agent-docs-template/master/install.sh -o install.sh
less install.sh
bash install.sh
```

Or scaffold directly with [giget](https://github.com/unjs/giget) (skips the `--caveman` step):

```bash
npx giget@2 gh:RTopdar/agent-docs-template .
```

### What gets added

```
CLAUDE.md                          # Claude Code tool bindings (extends AGENTS.md)
AGENTS.md                          # platform-agnostic agent rules
IMPLEMENTATION_PLAN.md             # narrative architecture + open decisions
.claude/agents/incident-handler.md # bug-handling subagent spec
.claude/agents/doc-sync.md         # doc-sync subagent spec
doc/index.md                       # index of indexes
doc/feature/index.md               # architecture OKF bundle index
doc/bug/index.md                   # incident OKF bundle index
doc/bug/incidents/                 # per-incident OKF docs go here
.caveman.json                      # only with --caveman
```

### After scaffolding

1. Replace every `{{PROJECT_NAME}}` placeholder.
2. Fill in `IMPLEMENTATION_PLAN.md` Components/Architecture.
3. Add project-specific rules to the bottom of `AGENTS.md` (data-model conventions, migration policy, etc. — this template ships without them since they're stack-specific).
4. Write your first `doc/feature/architecture_overview.md`.

## Security scan (SkillSpector)

Scanned with [NVIDIA SkillSpector](https://github.com/NVIDIA/skillspector) (`~/.local/bin/skillspector`), a static+LLM security scanner built for AI-agent skill packages. Two passes were run: static-only (`--no-llm`) and LLM-augmented (`claude_cli` provider).

**Headline score: 100/100, CRITICAL, "DO NOT INSTALL."** Read past the headline before reacting to it — see [Reading the score](#reading-the-score) below. SkillSpector's threat model is a *runtime* agent skill (something an LLM agent loads and executes autonomously); this repo is a *human-run installer script* that scaffolds text/markdown files. Several of its detectors (external script fetching, tool chaining, self-modification) fire on any installer that does `curl | bash` + `rsync` by design — that's how installers work, not a vulnerability in this one. Two of the findings *were* real and have been fixed (see below).

### Findings fixed as a result of this scan

| Finding | Where | Fix applied |
|---|---|---|
| `SDI-2` (MEDIUM, 60%) — `--caveman` installs a third-party plugin marketplace with no disclosure | `install.sh` | Script now prints exactly what `--caveman` does (marketplace added, plugin installed, what the plugin does) before running it; documented in this README and in the script's header comment |
| `SQP-2` (MEDIUM, 55%) — `rsync` overwrites files with no confirmation/warning | `install.sh` | Default behavior changed to `rsync --ignore-existing` (never overwrites); added explicit `--force` flag to opt into overwriting, with a printed warning |
| `SQP-2` (MEDIUM, 70%) — install instructions pipe a remote script into `bash` with no integrity-check note | `README.md` | Added a "review before piping" step to the quickstart above |
| `P2` (HIGH, 70%) — "Hidden Instructions" flagged on an HTML comment in `IMPLEMENTATION_PLAN.md` | `IMPLEMENTATION_PLAN.md`, `doc/feature/index.md`, `doc/bug/index.md` | Replaced all HTML `<!-- -->` placeholder comments (invisible in rendered markdown — a real injection vector in general, even though these were just template hints) with plain visible italic text |
| `RP1` (MEDIUM, 70%) — unpinned `npx giget` invocation | `install.sh`, `README.md` | Pinned to `giget@2` |

### Reading the score

The remaining HIGH/MEDIUM findings after fixes are inherent to what `install.sh` *is* — an installer that fetches a remote template and writes files:

- **SC2 "External Script Fetching"** on the `npx giget`/`git clone` lines — that's the template fetch; there's no way to scaffold a repo without fetching it from somewhere.
- **TM2 "Chaining Abuse"** on the `curl | bash` line in the README and the `git clone` line in the script — SkillSpector reads "fetch → pipe → execute" as agent tool-chaining; here it's a human running one install command, the standard pattern for this whole class of tool (Homebrew, rustup, nvm, etc. all do the same).
- **TM1 "Tool Parameter Abuse"** on `--force`/`git clone --branch` — flagged because `--force`-shaped flags are on a dangerous-parameter denylist; here `--force` only controls whether local scaffold files get overwritten, not a destructive filesystem op.
- **RA1 "Self-Modification"** on the `rsync` line — flagged because the script writes into its own working directory; it explicitly excludes `install.sh` itself from the copy, so it isn't rewriting its own logic.
- **RA2 "Session Persistence" / EA2 "Autonomous Decision Making"** on lines inside the README's example terminal transcript (the fenced block showing what a run looks like) — the scanner pattern-matches words like "Fetching"/"Scaffolding"/"Done" in that illustrative output as if they were live agent behavior, not markdown prose showing a sample run.
- **RP1 "unpinned reference"** duplicated across several README lines — same `giget@2` mention appearing once per code block (quickstart, giget-direct, and the example transcript), each counted separately.

None of these represent an agent being tricked into unauthorized action at runtime, which is what SkillSpector is built to catch — they're static pattern matches on an installer shape and its own documentation. Documented here rather than "resolved away" by disabling the checks, so anyone auditing this repo can see the tool's actual output and judge for themselves.

### Full reports

<details>
<summary>Static analysis (<code>skillspector scan . --no-llm --format markdown</code>) — latest, post interactive-prompt update</summary>

```
Score: 100/100 — CRITICAL — DO NOT INSTALL
Components inspected: 12/12 (100% coverage), 26 findings (up from 10 pre-prompt-update,
almost entirely duplicate/example-transcript noise from the expanded README — see above)

HIGH    TM2  README.md:10, install.sh:16     Chaining Abuse (curl | bash quickstart / fetch → rsync)
HIGH    SC2  README.md:49,106,121            External Script Fetching (example transcript + giget mentions)
HIGH    SC2  install.sh:13,17,18,19,69       External Script Fetching (npx giget / git clone fallback)
HIGH    RA1  install.sh:18                   Self-Modification (rsync writes into cwd)
HIGH    TM1  install.sh:92                   Tool Parameter Abuse (--force flag pattern)
MED     RA2  README.md:83                    Session Persistence (example transcript text)
MED     EA2  README.md:96,150                Autonomous Decision Making (example transcript text)
MED     RP1  README.md:105,123,128,149       Unpinned npx giget reference (duplicate mentions)
LOW     SC2  README.md:10,32,38,44,52        External Script Fetching (low-confidence dups)
```

</details>

<details>
<summary>LLM-augmented analysis (<code>SKILLSPECTOR_PROVIDER=claude_cli skillspector scan .</code>) — pre-fix, informed the fixes above</summary>

```
Score: 100/100 — CRITICAL — DO NOT INSTALL
Degraded scan: meta-analyzer batches failed (no ANTHROPIC_API_KEY /
NVIDIA_INFERENCE_KEY configured in this environment; fell back to
static-only for the affected batches).

HIGH    P2      IMPLEMENTATION_PLAN.md:11   Hidden Instructions (HTML comment)      → fixed
HIGH    SC2     install.sh:4,5              External Script Fetching               → inherent
HIGH    TM2     README.md:8, install.sh:4   Chaining Abuse                          → inherent
HIGH    TM1     install.sh:26               Tool Parameter Abuse                    → inherent
MED     SQP-2   README.md:8                 curl|bash with no integrity-check note  → fixed
MED     RP1     README.md:20, install.sh:23 Unpinned npx giget                      → fixed
MED     SQP-2   install.sh:30               rsync overwrites with no confirmation   → fixed
MED     SDI-2   install.sh:32-43            Undisclosed --caveman plugin install    → fixed
MED     SQP-2   install.sh:34-41            Third-party plugin, permissions undocumented → fixed
LOW     SC2     README.md:8,14              External Script Fetching (low-conf dup) → inherent
LOW     SQP-2   README.md:14                --caveman disclosure (low-conf dup)     → fixed
LOW     SQP-2   README.md:20                Silent overwrite (low-conf dup)         → fixed
LOW     SQP-2   README.md:50                gh repo create --public, no visibility warning → see note below
LOW     SDI-4   install.sh:2                Header comment scope mismatch           → fixed
```

Note on the `gh repo create --public` finding: this is a one-time *publisher* instruction (for whoever maintains this template), not something `install.sh` runs — end users scaffolding a project never trigger it. Flagged here for completeness rather than fixed, since a public repo is the intended outcome of publishing a template.

</details>

Re-run either scan yourself after cloning:

```bash
skillspector scan . --no-llm --format markdown
SKILLSPECTOR_PROVIDER=claude_cli skillspector scan .   # or another provider, see `skillspector scan --help`
```

## Publishing this repo (one-time, for maintainers)

```bash
cd agent-docs-template
git init && git add -A && git commit -m "Initial agent-docs-template scaffold"
gh repo create RTopdar/agent-docs-template --public --source=. --push
```

Then update `REPO=` in `install.sh` and the URLs above to match. Review the repo for secrets before pushing, as with any `--public` repo creation.

## License

MIT — see [LICENSE](LICENSE).
