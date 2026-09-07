## 🔍 Verification — {{PASS|FAIL}}

**Attempt:** {{N}} of {{MAX}}
**Reviewed commit:** `{{SHA}}` (scratch workspace, not yet landed on `main`)

| Layer | Result |
|---|---|
| Correctness / compilation | {{✅ ⚠️ or ❌}} — {{one line}} |
| Scope | {{✅ ⚠️ or ❌}} — {{one line}} |
| Security (login-screen surface) | {{✅ ⚠️ or ❌}} — {{one line}} |
| Best practice | {{✅ ⚠️ or ❌}} — {{one line}} |
| Obvious bugs (incl. both window modes) | {{✅ ⚠️ or ❌}} — {{one line}} |

### Checks run
{{the exact lint/test commands executed and their outcome, plus what was driven
in demo mode — or "no machine-verifiable check applies to this change" and
why}}

{{ — only if FAIL, otherwise omit this whole section: }}
### Findings — must be addressed before the next attempt
1. **{{short title}}** — `{{file:line}}` — {{concrete description of the
   problem and what closing it requires}}
2. {{…}}

{{ — only if there are any, otherwise omit this whole section: }}
### Findings outside this issue
Not blockers for this issue — recorded so they can be filed separately.
1. **{{short title}}** — `{{file:line}}` or {{the command that shows it}} —
   {{what's wrong, and why it isn't in this issue's scope}}
2. {{…}}

---
*Verified by `task-verifier` (sonnet) via the `orchestrate` skill. This comment
does not close or relabel the issue — only a landed commit's `Fixes #`/`Closes #`
trailer does that, once it's pushed.*
