# Changelog

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
