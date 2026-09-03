# quickgreet

A [greetd](https://sr.ht/~kennylevinsen/greetd) login greeter built with
[Quickshell](https://quickshell.org) — a two-pane login screen that picks up
your Material You colour scheme and your wallpaper, so the machine looks like
itself before you've logged in.

![quickgreet](docs/screenshot.png)

## What it is

Most graphical greetd greeters are a form on a flat background. quickgreet
reads your **palette** and **wallpaper** from disk and lays out a clock on one
side and the login card on the other, scaled to the panel it's running on.

It reads the palette as *data* — a small JSON file — so it isn't tied to any
particular shell's internals. It works well with
[caelestia](https://github.com/caelestia-dots/shell) because that's the format
it reads, but any tool that writes the same shape works, and with no palette
file at all it falls back to a built-in scheme.

**Not affiliated with or endorsed by caelestia.** It just speaks the same
colour-scheme file format.

## Requirements

- `quickshell` (0.3+ — needs `Quickshell.Services.Greetd`)
- `greetd`
- A Wayland compositor to host it: **Hyprland**, **sway**, or **cage**
  (quickgreet is a Wayland client, not a compositor)

## Install

### Arch

```sh
cd packaging && makepkg -si
```

### Manual

```sh
sudo install -d /usr/share/quickgreet
sudo cp -r components config services ui greeter.qml /usr/share/quickgreet/
```

## Wiring it up

quickgreet needs a compositor to run inside. greetd launches the compositor,
the compositor launches quickgreet.

### greetd

`/etc/greetd/config.toml` — pick the compositor line that matches your setup:

```toml
[terminal]
vt = 1

[default_session]
# Hyprland (best if you already run it — one set of monitor semantics)
command = "start-hyprland -- -c /etc/greetd/hyprland-greeter.lua"
# sway
# command = "sway --config /etc/greetd/sway-greeter.config"
# cage — simplest, but single-output only
# command = "cage -s -- qs -p /usr/share/quickgreet/greeter.qml"
user = "greeter"
```

Example compositor configs are in [`examples/compositors/`](examples/compositors).
Each one sets up your outputs and then runs:

```
qs -p /usr/share/quickgreet/greeter.qml
```

**On Hyprland, two details are worth getting right**, because anything Hyprland
prints at startup is drawn *over the login screen* rather than scrolling past in
a terminal you never look at:

- **Use the `.lua` config, not `.conf`.** Hyprland 0.56 warns that `.conf`
  "support ... will be removed in Hyprland 0.57". Use
  [`hyprland-greeter.conf`](examples/compositors/hyprland-greeter.conf) only if
  you're on an older Hyprland that has no Lua support.
- **Launch through `start-hyprland --`.** Called directly, Hyprland warns it
  "is being launched without start-hyprland". The wrapper is a watchdog that
  exits when Hyprland exits cleanly — which is exactly what the greeter does at
  handoff — so it won't keep the greeter alive over your session.

Validate whichever you use before restarting greetd:

```sh
Hyprland --verify-config -c /etc/greetd/hyprland-greeter.lua
```

**Multi-monitor:** monitor layout is deliberately *not* quickgreet's
concern — it's the host compositor's config. That's the seam that keeps this
portable, so configure your outputs there. `cage` can't position multiple
outputs independently; use Hyprland or sway if you have more than one screen.

### Letting the greeter read your palette

The greeter runs as the unprivileged `greeter` user, which usually **cannot
read your home directory at all** (`/home/you` is commonly `drwx------`). So
the palette and wallpaper have to be copied somewhere it can reach, e.g.:

```sh
sudo install -d -o greeter -g greeter /var/lib/greetd/.local/state/caelestia/wallpaper
sudo cp ~/.local/state/caelestia/scheme.json /var/lib/greetd/.local/state/caelestia/
# copy the image itself, not just the pointer file
sudo cp "$(cat ~/.local/state/caelestia/wallpaper/path.txt)" \
        /var/lib/greetd/.local/state/caelestia/wallpaper/current.png
echo /var/lib/greetd/.local/state/caelestia/wallpaper/current.png \
  | sudo tee /var/lib/greetd/.local/state/caelestia/wallpaper/path.txt
sudo chown -R greeter:greeter /var/lib/greetd/.local/state/caelestia
```

Re-run after a deliberate theme change. This is a static copy on purpose —
there is no live sync, because there's no session to sync from at login time.

### Letting the greeter read your avatar

Same problem as the palette: `greeter` usually can't read into your home
directory at all. The default `avatarPath` is `~/.face`, which expands to
`greeter`'s *own* home — so copying the file there needs no config change:

```sh
# confirm greeter's actual home first — commonly /var/lib/greetd
getent passwd greeter

sudo cp ~/.face /var/lib/greetd/.face
sudo chown greeter:greeter /var/lib/greetd/.face
sudo chmod 644 /var/lib/greetd/.face
```

Re-run after you change your avatar — same static-copy caveat as the
palette above; there's no live sync at login time.

If the greeter still falls back to your initials, check the journal: an
avatar that exists but can't be read now logs one line; a path with nothing
there at all stays silent, since that's the default case on most machines
and isn't itself an error.

## Configuration

`/etc/quickgreet/config.json`, or `$QUICKGREET_CONFIG`. Every key is optional
and a missing or malformed file just means defaults — a greeter that refuses
to start because of a typo is a greeter that locks you out.

```jsonc
{
  "session": {
    "command": null,          // null = use the selected session's Exec=
    "environment": []         // extra VAR=value entries
  },
  "appearance": {
    "paletteSource":   "~/.local/state/caelestia/scheme.json",
    "wallpaperSource": "~/.local/state/caelestia/wallpaper/path.txt",
    "wallpaperFallback": "",  // used when the above is unreadable
    "blurWallpaper": true,
    "blurAmount": 24,         // 0 disables
    "dim": 0.22,              // scrim over the wallpaper, 0–1
    "accentColor": null,      // hex, overrides primary/onPrimary regardless of palette
    "radiusScale": 1,         // multiplies the login card's corner radius — 0 = sharp
    "avatarPath": "~/.face",  // falls back to the user's initial
    "avatarShape": "circle",  // "circle" | "rounded" | "square"
    "greeting": "",
    "clockFormat": "HH:mm",
    "dateFormat": "dddd • d MMM"
  },
  "behaviour": {
    "showUserPicker":    "auto",  // "auto" | "always" | "never"
    "showSessionPicker": "auto",  // auto = shown only when >1 exists
    "rememberLastUser": true,
    "rememberLastSession": true,
    "minUid": 1000,
    "maxUid": 60000
  }
}
```

Paths are expanded relative to the **greeter** user's home, not yours.

### The palette file

`paletteSource` points at JSON of this shape — hex values **without** a leading
`#`:

```json
{
  "name": "my-scheme",
  "mode": "dark",
  "colours": {
    "surface": "12131a",
    "onSurface": "e4e1e9",
    "surfaceContainerHigh": "262731",
    "primary": "bfc2ff",
    "onPrimary": "242a60",
    "error": "ffb4ab"
  }
}
```

Any [Material 3 role names](https://m3.material.io/styles/color/roles) work;
they're read generically, and anything absent falls back to the built-in
palette. The roles actually used are `surface`, `surfaceDim`,
`surfaceContainer`, `surfaceContainerHigh`, `onSurface`, `onSurfaceVariant`,
`primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`,
`secondaryContainer`, `onSecondaryContainer`, `outline`, `outlineVariant`,
`error`, `errorContainer`, `onErrorContainer`, `shadow` and `scrim`.

### Customizing beyond the palette

A few things are config-driven rather than being baked into the palette
file:

- **`accentColor`** overrides `primary`, `onPrimary`, `primaryContainer` and
  `onPrimaryContainer` on top of whatever the palette (or built-in
  fallback) provided — a readable `onPrimary*` is computed from a simple
  luminance check, not full Material tonal generation. It deliberately does
  **not** touch `secondaryContainer`/`onSecondaryContainer`; edit
  `colours.secondaryContainer` in the palette file itself for that.
- **`radiusScale`** multiplies the login card's corner radius (`0` = sharp
  corners, `1` = the current default, `>1` = rounder). It only affects that
  one `Tokens.rounding`-driven shape — the pill-shaped password field and
  the avatar have their own fixed/`avatarShape`-driven rounding and aren't
  affected.
- **`avatarShape`** controls the avatar's mask: `"circle"` (default),
  `"rounded"` (a large rounded-square) or `"square"`.

## Developing

Iterating on a greeter is risky — a broken one locks you out. So develop it in
**demo mode**, which runs the whole UI in an ordinary window inside your
existing session, against a mock auth backend:

```sh
QUICKGREET_DEMO=1 qs -p greeter.qml
```

Any password matching `dev.mockPassword` (default `test`) "succeeds"; anything
else exercises the failure path. Demo mode is triggered **only** by that
environment variable, never inferred from greetd being absent — if a real
rollout breaks, you want a visible error, not a fake successful login.

Run the auth state-machine tests with:

```sh
QUICKGREET_DEMO=1 qs -p test-auth-flow.qml
```

For reproducible demos and screenshots that don't depend on (or expose) the
accounts on your machine, point `$QUICKGREET_CONFIG` at a file setting
`dev.mockUsers`:

```jsonc
{ "dev": { "mockUsers": [{ "name": "alex", "gecos": "Alex Morgan", "uid": 1000 }] } }
```

That substitution applies in demo mode only; the real greeter always reads
`/etc/passwd`.

Demo mode covers UI iteration, but it runs as your own user — it can't
exercise the permissions issues that only show up as the unprivileged
`greeter` account (see "Letting the greeter read your palette/avatar"
above). To actually install and test unreleased changes for real:

```sh
cd packaging/quickgreet-git && makepkg -sif
```

`packaging/quickgreet-git/PKGBUILD` always builds from the current `main`
branch HEAD (standard `-git` package convention: its `pkgver` is derived
from `git describe`). It installs to the same paths as the regular
`quickgreet` package and `conflicts`/`provides` against it, so only one is
ever installed at a time. `packaging/PKGBUILD` — what `cd packaging &&
makepkg -si` above uses, and what CI's release workflow builds — stays
pinned to the latest tagged release.

## Rolling back

Keep your previous greeter installed until you're happy. Snapshot the config
before switching, and reverting is one command:

```sh
sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.bak   # before
sudo cp /etc/greetd/config.toml.bak /etc/greetd/config.toml   # to revert
sudo systemctl restart greetd
```

Test from a second TTY with a root shell already open, so a broken greeter
can't strand you.

## Scope

quickgreet is *a good-looking Quickshell greeter that reads a Material You
palette* — not a general display manager. Deliberately out of scope: monitor
layout (the compositor's job), multi-seat, XDMCP, autologin orchestration, PAM
policy, and biometrics.

## Status

Maintained primarily for one person's setup and shared as-is. Issues and PRs
are welcome but may go unanswered; fork freely.

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
