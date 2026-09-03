# Changelog

## Unreleased

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

- `appearance.accentColor` — override the primary accent independently of
  the palette file.
- `appearance.radiusScale` — multiply the login card's corner radius.
- `appearance.avatarShape` — `"circle"` (default), `"rounded"` or `"square"`.
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
