# What this repo is

quickgreet is a [greetd](https://sr.ht/~kennylevinsen/greetd/) login greeter
built with [Quickshell](https://quickshell.org), themed at runtime from a
Material You `scheme.json`. It is **not** a display manager — monitor layout,
multi-seat, XDMCP, autologin orchestration, PAM policy and biometrics are all
deliberately out of scope (README, "Scope").

Read in this order:

- [`README.md`](README.md) — **the specification.** Install, greetd wiring,
  compositor examples, the full config reference, the demo-mode dev loop, the
  rollback procedure. Where any other doc disagrees with it, it wins.
- [`quickgreet.json.example`](quickgreet.json.example) — every config key with
  its default, mirroring `config/Config.qml`'s `defaults` object.
- [`CHANGELOG.md`](CHANGELOG.md) — what actually shipped per tag.
- [`examples/`](examples/) — the greetd and compositor configs the README's
  install steps refer to.

**Consumer:** [`archetype`](https://github.com/ghotso/archetype) (`../archetype`
locally) uses quickgreet as its greeter and is the reason the palette contract
exists. Its predecessor `../archetype-archive` carries the original writeup at
`docs/mechanisms/quickgreet-greeter.md`. Both are context, never a place to
push changes from here.

# A broken greeter locks the machine

This is the constraint everything else here bends around.
`quickgreet-git` is **installed on this host and is the live greeter** — the
login screen the maintainer actually gets on boot comes from this repo's
`main`. A change that crashes on startup is not a failed test, it is a machine
nobody can log into.

Three rules follow, and none of them are negotiable:

- **An agent never runs `sudo`, `pacman`, `makepkg -sif`, `systemctl restart
  greetd`, or writes under `/etc`** — `/etc/greetd/config.toml` and
  `/etc/quickgreet/config.json` especially. Work labelled `needs-sudo` is
  *prepared* by an agent (files staged, exact commands printed) and **run by
  the maintainer**, who does it from a second TTY with a root shell already
  open (README, "Rolling back").
- **`makepkg -f` with neither `-i` nor `-s` is fine** and is how a packaging
  change gets verified: it builds `quickgreet-*.pkg.tar.zst` and stops — no
  root, no pacman transaction. `makepkg --printsrcinfo` is the cheaper
  read-only check when only metadata changed. The ban is on the *install*
  step, not on building.
- **Never make the greeter refuse to start.** `config/Config.qml` says it
  outright: a missing or malformed config logs once and falls back to defaults,
  because "a greeter that refuses to start because its config has a typo is a
  greeter that locks you out of your machine." Any new config surface inherits
  that — parse defensively, fall back, log, keep running.

# Issues are the plan

GitHub issues are this project's plan and memory between sessions. This is a
public repo, so they are also where other people's reports arrive.

- **New work starts as an issue.** Use `github-triage` to turn a rough report
  — yours or a stranger's — into a structured one.
- **Flat issues, no epics.** There is no roadmap file and no sub-issue tree
  here; an issue is the unit of work, full stop.
- **Always label.** A type (`bug` / `enhancement` / `documentation` /
  `chore`) plus an `area:*` (`ui`, `services`, `config`, `packaging`, `docs`,
  `ci`), and `needs-sudo` when the work can only be finished as root. Keep the
  set small — don't invent labels without saying so.
- **`status:*` is machine-managed — exactly one per issue, never set by
  hand.** The two ends belong to `.github/workflows/issue-status.yml`
  (opened/reopened → `status:new`, closed → `status:closed` /
  `status:cancelled`); everything in between goes through
  `scripts/issue-status.sh <issue> <status>`, which replaces the whole label
  set in one call and is the only reason "exactly one" actually holds.
  `github-triage` sets `status:ready`; `orchestrate`'s executor and verifier
  own `in-progress` → `in-review` → `implemented`. Never
  `gh issue edit --add-label status:…`, and never `status:closed` by hand.
- **Close via commit trailers.** A commit that finishes issue-tracked work
  carries `Fixes #<n>` / `Closes #<n>`, so the issue closes when the commit
  reaches `main` on GitHub. **Never invent or guess a number** — a wrong one
  silently closes the wrong thing. If no tracked issue is genuinely in context,
  leave the trailer out.
- **Never close an issue by hand.** No agent runs `gh issue close`. The one
  exception is the maintainer explicitly asking for a manual close of
  something stale or superseded — never an agent's own judgement.
- Don't open an issue for something you finish in the same session; that's
  bookkeeping theatre. Issues are for work that spans sessions.
- **Executing a filed issue end to end** — implement, verify, land — is the
  `orchestrate` skill's job, not something to do by hand in the main session.
  It spawns `task-executor`/`task-verifier` subagents in isolated scratch
  clones and only lands a commit on `main` after an independent verification
  pass.

# Working on this repo

- Single maintainer, public repo. Work directly on `main` — do **not** create a
  feature branch before committing.
- Only commit when asked; this rule removes the "branch first" default, it
  doesn't change *when* to commit.
- **Nothing is pushed automatically, ever.** `orchestrate` lands verified
  commits on the local `main` and stops there; the maintainer reads them and
  pushes. On a public repo the push is the moment strangers see the work, so it
  stays a human action — which is also when the `Fixes #` trailers actually
  close their issues.
- A release is a tag: `.github/workflows/release.yml` fires on `v*` and builds
  from `packaging/PKGBUILD`, which is pinned to the tagged release.
  `packaging/quickgreet-git/PKGBUILD` tracks `main` HEAD and carries a local
  `pkgver` bump from every `makepkg` run — `git add` it alongside other changes
  when it's dirty rather than leaving it as a separate ask.
- The user's shell is **fish**, not bash — never hand them a `<<EOF` heredoc
  (fish has no heredoc syntax; it fails with `Erwartete a string, aber fand a
  redirection`). For a multi-line file write via `sudo tee`, use
  `printf '%s\n' 'line one' 'line two' | sudo tee <path>`. Fish also doesn't
  take bare `--include=*.qml` globs in `grep` — quote them, or use
  `find … | xargs grep`.

# Developing the greeter

- **Demo mode is the dev loop.** `QUICKGREET_DEMO=1 qs -p greeter.qml` runs the
  whole UI as an ordinary `FloatingWindow` inside the running session, against
  a mock auth backend — no greetd, no layer shell, no keyboard grab, no risk to
  the login path. Any password matching `dev.mockPassword` (default `test`)
  succeeds; anything else exercises the failure path. Demo mode is triggered
  **only** by that environment variable and is never inferred from greetd being
  absent, so a real rollout that breaks gives a visible error rather than a
  fake successful login.
- **`QUICKGREET_DEMO=1 qs -p test-auth-flow.qml`** runs the auth state-machine
  tests. Run it for anything touching `services/Auth.qml` or the login path.
- **Demo windows don't collide.** Unlike a layer-shell bar, two demo instances
  are just two ordinary windows — parallel `orchestrate` lanes can each run one
  without fighting over exclusive zones or pointer routing. Point a demo run at
  its own workspace (`qs -p <workspace>/greeter.qml`); distinct absolute config
  paths already get distinct Quickshell shell IDs, so neither evicts the other.
- **For reproducible screenshots, mock the users.** Point `$QUICKGREET_CONFIG`
  at a file setting `dev.mockUsers` rather than showing the machine's real
  accounts. That substitution is demo-mode only; the real greeter always reads
  `/etc/passwd`.
- **`qmllint` must be the Qt6 binary, by full path:**
  `/usr/lib/qt6/bin/qmllint -I . <files>`. Arch also ships qt5-declarative's
  `/usr/bin/qmllint`, which exits 255 with **no output at all** on this repo's
  Qt6 QML — a silent 255 reads like a clean run, which is worse than no check.
  `.qmllint.ini` in the repo root is picked up automatically. CI does exactly
  this (`.github/workflows/qml-lint.yml`).
- **Quickshell's own API docs are the first place to look, via the
  `quickshell` MCP server.** A pre-1.0 QML API moves faster than any model's
  training data, so a recalled property or enum is a guess dressed as
  knowledge. Use `quickshell_search` / `quickshell_get_type`, validate
  generated QML with `quickshell_validate_qml`, and put runtime errors through
  `quickshell_explain_error`. This host runs `quickshell-git 0.3.1.r10` — pass
  that `version` explicitly rather than taking the tools' `latest` default;
  fallback docs: <https://quickshell.org/docs/v0.3.1/types/>.

## Architectural invariants

Four things to know before writing any surface here:

1. **Two window modes, one surface.** `greeter.qml` instantiates
   `ui/GreeterSurface.qml` twice over: production is a `Variants` over
   `Quickshell.screens` giving one fullscreen `WlrLayer.Overlay` `PanelWindow`
   per monitor with `WlrKeyboardFocus.Exclusive`; demo is a single
   `FloatingWindow`. Anything you add must work in both — a feature that only
   exists in one of them is broken by construction.
2. **The card lives on the first screen only.** `primary: panel.modelData ===
   Quickshell.screens[0]` — other monitors get wallpaper and nothing else.
   Don't duplicate the login card across screens.
3. **A theme is never hardcoded.** No palette colour may appear as a literal
   anywhere outside `services/Colours.qml`'s documented `fallback` object —
   not as a default, not "just until the wiring lands". Colours are read as
   *data* from `scheme.json` at runtime. A literal that matches today's
   palette is still a bug: it stops tracking the moment the user's theme
   changes. Structure comes from the components; colour comes from the
   palette.
4. **Config is read-only, and every key is optional.** Nothing in the greeter
   writes its config back, and there is no settings UI. `config/Config.qml`
   holds the defaults; a new key means a default there, an entry in
   `quickgreet.json.example`, and a README line — all three, or it doesn't
   exist as far as users are concerned.

## Security surface — this is a login screen

Treat anything on the password path as security-relevant, because it is:

- Never log, echo, persist or expose a typed password — including into a debug
  `console.log`. `appearance.passwordReveal` is the one deliberate exception
  and it is a documented shoulder-surfing tradeoff, off-switchable by config.
- `behaviour.minUid`/`maxUid` bound which `/etc/passwd` entries are offered.
  Validate them; don't widen them for convenience.
- `services/Remember.qml` persists the last user and session. Persist the
  minimum, never anything secret.
- Reset transient auth state on failure — a stale echo or a stale error left
  on screen after a failed attempt is a real bug (fixed once already in
  `a7dec0a`).
