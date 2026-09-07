# Changelog

## v0.1.3 — 2026-09-07

### Added

- **Power controls on the login card** — suspend, reboot and power off, so the
  machine can be shut down or restarted without logging in first. Gated by
  `behaviour.powerControls`, a list of the verbs to show (all three by
  default; `[]` hides the row entirely), with an unrecognised verb dropped
  with a warning rather than failing the config load. Reboot and power off arm
  on the first click and only run on a second one within three seconds:
  systemd's shipped policy lets the active session take down *other* logged-in
  sessions with no prompt, so a stray click on a login screen is worth a
  confirmation. Suspend is trivially reversible and runs immediately. No
  polkit rule ships with this — the greeter is the active session on the seat
  while it's displayed, and `allow_active` is `yes` for power-off, reboot and
  suspend alike; a rejected call surfaces as an on-screen message rather than
  a dead button, since a distro or admin can override those defaults. The
  glyphs are drawn on a `Canvas` like the existing submit arrow, so nothing
  depends on an icon font being present in a bare greeter's fontconfig.
- **More password-dot shapes, and the set is now configurable.**
  `appearance.passwordDotShapes` takes a list of shape names cycled by dot
  index, defaulting to `["circle", "squircle"]` — no change for an existing
  config. Four new shapes join those two: `gem` (the squircle rotated 45°),
  `wobbly` (a circle with a five-lobe ripple), `clover` (a four-lobe one), and
  `ring` (stroked rather than filled — the one that stays legible at the 8px
  a dot actually renders at on a 1080p panel, where silhouette differences
  mostly don't). All six are drawn by a single `components/DotShape.qml`
  canvas per dot however many shapes are configured, because the row is up to
  24 dots and a greeter often runs on unaccelerated rendering. Each shape is
  sized by matching its area to a same-box circle's rather than by fitting its
  bounding box, so the ones that pinch on the diagonals don't read lighter
  than the rest of the row. An unknown name, an empty list or a value that
  isn't a list at all warns once and falls back.

  The shape a dot draws is a function of its index and nothing else. The
  delegate's model carries the real typed characters, so choosing a shape from
  the character would paint the password's repeats and length onto the screen
  for anyone watching — that is deliberately not done, and it is the
  constraint any future change here has to keep.
- `.claude/` — the `github-triage` and `orchestrate` skills, their
  `task-executor`/`task-verifier` agents, `scripts/issue-status.sh` and a
  `.github/workflows/issue-status.yml` that owns the two ends of the
  `status:*` label lifecycle. Repo tooling, with no effect on the greeter
  itself: both features above were implemented and verified through it.

## v0.1.2 — 2026-09-03

### Security

- **A failed OTP/token prompt could leave the next password typed in
  cleartext on screen.** `Auth.echo` — which decides whether typed input
  renders as visible text or masked dots — was only ever set when a new
  `auth_message` arrived, never reset on failure. greetd's protocol allows
  any prompt in a PAM conversation to request visible echo, not just an
  OTP step specifically, so a PAM stack whose first prompt is `visible` left
  `echo` stuck `true` once that prompt was rejected — whatever the user
  retyped next, quite possibly their real password, rendered in clear
  instead of masked. `fail()` and `fatal()` now reset `echo` and `prompt`
  whenever an authentication attempt ends, so the field always defaults back
  to masked until a fresh prompt says otherwise.
- **A malformed `minUid`/`maxUid` in config.json silently exposed every
  account, root included, in the login picker.** `uid < min` and
  `uid >= max` both evaluate to `false` against a non-number, so a config
  typo (a quoted `"1000"`, a key resolving to `undefined`) disabled the UID
  filter entirely instead of falling back to the documented default —
  contradicting this project's own "malformed config never breaks silently"
  design. `Users.parse()` now coerces both bounds through a helper that
  accepts a numeric string but falls back to the built-in default on
  anything else.

### Fixed

- **Avatar never showed on a real install.** `avatarPath` expands against
  whatever account runs the greeter process — in demo mode that's your own
  desktop session, in production it's the unprivileged `greeter` account,
  whose home has no `.face`. The existence probe now also distinguishes
  "not found" (silent, the common case) from "exists but unreadable" or
  "exists but not a regular file" (now logged once), and the README documents
  the same copy-and-chown workaround already given for the palette/wallpaper.
- **Submit-button arrow was too small and drifted off-center.** It's drawn on
  a `Canvas` whose path was hardcoded in absolute pixel coordinates, so it
  didn't scale with `Tokens.scale` — on a real (often unscaled 4K) panel it
  stayed pinned near the canvas's origin instead of centering and growing
  with the rest of the UI. The path is now computed from the canvas's own
  size, and the icon is slightly larger to better fill the button.

### Added

- **Look-and-feel polish pass**, partly inspired by caelestia-shell's lock
  screen (a different, unrelated project — quickgreet has no code dependency
  on it, only a shared palette *file format*):
  - `appearance.clockTwoTone` — hour and minute rendered in different palette
    colours, with a small AM/PM pill for a 12-hour `clockFormat`.
  - `appearance.avatarShape` gains `"squircle"` — a soft superellipse blob,
    hand-drawn on a `Canvas` like the existing submit-arrow, no shapes
    library.
  - The submit arrow now has hover/press feedback (scale + opacity).
  - `appearance.passwordReveal` (on by default) — a hold-to-reveal eye button
    next to the submit arrow shows the typed password in clear while held.
  - `appearance.capsLockHint` (**opt-in**, off by default) — a muted "Caps
    Lock is on" line under the password field. Best-effort: seeded from
    `hyprctl -j devices` on a Hyprland greeter session, otherwise tracked
    from key presses seen after the greeter gets keyboard focus. Designed to
    only ever assert "on", never a false "off".
  - The login card now has a matching, brief collapse-out on successful
    login (mirroring its existing entrance), instead of appearing on screen
    then disappearing abruptly. Adds a bounded ~250ms delay between greetd
    signalling success and the actual session handoff so the motion has time
    to play.
  - `appearance.blurAmount`'s ceiling is now documented up to `128` (was
    undocumented above the default `24`), with a note that greeter sessions
    often run on unaccelerated rendering where blur cost is much higher than
    on a real desktop session.
  - The password field's typed-character dots are now a real `ListView` over
    the actual characters (a Quickshell `ScriptModel`), not just a count —
    each dot pops in as before, but a dot removed by backspace now fades and
    shrinks itself out instead of the row just vanishing, and dots alternate
    between a circle and the squircle shape above.
- `appearance.accentColor` — override the primary accent independently of
  the palette file.
- `appearance.radiusScale` — multiply the login card's corner radius.
- `packaging/quickgreet-git/PKGBUILD` — tracks the `main` branch HEAD, for
  installing and testing unreleased changes as a real package (unlike demo
  mode, this exercises the actual unprivileged `greeter`-account
  permissions). `packaging/PKGBUILD` is unchanged — still pinned to the
  latest tag, still what CI's release workflow builds.

## v0.1.1 — 2026-09-03

Everything here is about what the greeter *prints*. A login screen has nowhere
to hide startup output: anything the compositor or Qt logs is drawn over the UI
instead of scrolling past in a terminal nobody reads.

### Fixed

- **Hyprland startup warnings appeared over the login screen.** Hyprland 0.56
  prints two warnings that a greeter cannot hide:
  `You are using the .conf config format, support for which will be removed in
  Hyprland 0.57.` and `WARNING: Hyprland is being launched without
  start-hyprland.` The recommended wiring is now a Lua config launched through
  the wrapper — `start-hyprland -- -c /etc/greetd/hyprland-greeter.lua`.
  `start-hyprland` is a watchdog, and it was verified not to interfere with
  handoff: on the greeter's deliberate exit it reports a clean exit rather than
  restarting, so it cannot leave a greeter sitting over your session.
- **`Cannot open: file://…/.face` logged on every start, once per screen.** The
  avatar's `Image.source` was assigned whether or not the file existed — and
  most machines have no `~/.face`, which is the very case the initials fallback
  exists for. The path is now probed before it's used.

### Added

- `examples/compositors/hyprland-greeter.lua` — Hyprland 0.56+ wiring.
  `hyprland-greeter.conf` is kept for older Hyprland, marked as such.

## v0.1.0 — 2026-09-02

Initial release. Two-pane greeter (clock and date on one side, login on the
other) for `greetd`, built on Quickshell's `Quickshell.Services.Greetd`, themed
from a Material You `scheme.json` read as data.
