# cage

[cage](https://github.com/cage-kiosk/cage) is the lightest way to host
quickgreet — it's a single-client kiosk compositor, so it needs no config file
at all. Put the whole thing in greetd's command:

```toml
[terminal]
vt = 1

[default_session]
command = "cage -s -- qs -p /usr/share/quickgreet/greeter.qml"
user = "greeter"
```

`-s` allows VT switching, which you want — it's how you reach a TTY if the
greeter misbehaves.

## The multi-monitor caveat

**cage cannot position multiple outputs independently.** Its `-m` flag offers
only:

- `-m last` — draw on the most recently connected output; the others stay dark
- `-m extend` — span one surface across all outputs as a single combined area

Neither reproduces a real desktop layout, so on a multi-monitor machine the
greeter will either appear on one screen or be stretched oddly across them.

If you have more than one display, use
[Hyprland](hyprland-greeter.conf) or [sway](sway-greeter.config) instead —
both take explicit per-output position and scale.

cage also does no fractional scaling, so on a HiDPI panel the greeter renders
at native pixel density. quickgreet compensates by scaling its own typography
to panel height, so this is usually fine, but it's worth knowing.
