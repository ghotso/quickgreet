## Execution report — {{UNIT_ID}}

**Workspace:** `{{WORKSPACE_PATH}}`
**Issues in this dispatch:** {{#<n>, #<n>, … in the order you worked them}}

{{FOR EACH ISSUE — one block per issue in this dispatch, including any you had
to report blocked:}}

### #{{ISSUE_NUMBER}} — {{ISSUE_TITLE}}

**Status:** {{done|blocked}}
**Commit:** `{{SHA}}` {{or "none — blocked"}}

**Files touched:**
- {{path}}
- {{path}}

**Summary:** {{2-5 sentences: what was implemented and how}}

**Self-check run:** {{the lint/test command(s) actually run inside WORKSPACE
for this issue, and their result — or "none available for this change" and
why}}

**Live pass:** {{what you actually drove in demo mode and what you observed —
or "not applicable" and why. If the change has visible behaviour and you didn't
run it, say that plainly rather than leaving this blank.}}

**Both window modes:** {{how the change behaves in the per-monitor layer-shell
production path as well as the demo FloatingWindow — or "demo-only surface,
production path unaffected" and why that's true}}

**Deviations from the issue text:** {{any place the implementation differs from
the issue body, and why — or "none"}}

**Left undone / blocked:** {{anything not completed, and why — or "none"}}

{{END FOR}}

### Findings outside these issues
{{anything real you noticed that none of the issues above cover and you
therefore did not fix: a pre-existing defect, a stale README line, a missing
optdepends, host tooling that's broken. One line each — what it is, where
(`file:line` or the command that shows it), and why it isn't yours. The
orchestrator files these; you never open an issue yourself. "none" is a fine
answer, but don't drop a finding here just because it was inconvenient to
mention.}}
