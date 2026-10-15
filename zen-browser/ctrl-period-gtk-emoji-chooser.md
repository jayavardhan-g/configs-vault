# Ctrl+. opened GTK's emoji chooser (broke Google Docs superscript)

**Date:** 2026-10-16
**Category:** zen-browser
**Files touched:** `~/.var/app/app.zen_browser.zen/config/gtk-3.0/gtk.css` (new), `~/.config/gtk-3.0/gtk.css` (block appended). Copies: [`files/.var/app/app.zen_browser.zen/config/gtk-3.0/gtk.css`](files/.var/app/app.zen_browser.zen/config/gtk-3.0/gtk.css), [`files/.config/gtk-3.0/gtk.css`](files/.config/gtk-3.0/gtk.css)

<!-- graph:begin -->
**Graph:** [[Xpad]] · [[Zen Browser]]
<!-- graph:end -->

## What
Unbound Ctrl+. and Ctrl+; from GTK 3 text widgets, so they no longer open GTK's emoji
chooser in Zen or Xpad.

## Why
In Zen, Ctrl+. in Google Docs (superscript) popped up an emoji picker that took keyboard
focus; typing went nowhere until the page was clicked again. Xpad did the same.
- Not an input method: no IBus/Fcitx5 running, no `*_IM_MODULE` variables.
- It's GTK 3 itself: `GtkEntry`/`GtkTextView` bind **Ctrl+.** and **Ctrl+;** to the
  `insert-emoji` signal. Xpad is a GTK 3 app; Zen (like Firefox) borrows GTK's key
  bindings for editable fields, so web text fields inherit them too.
- Not related to the desktop shell (same under Noctalia and DMS). The system emoji picker
  is SUPER+. (shell launcher).

## Change
The same block in both files:
```css
@binding-set NoEmojiChooser {
    unbind "<Control>period";
    unbind "<Control>semicolon";
}
entry, textview { -gtk-key-bindings: NoEmojiChooser; }
```
- **Xpad** (and other native GTK 3 apps): appended to `~/.config/gtk-3.0/gtk.css`.
- **Zen** is a Flatpak without access to `~/.config`, so it reads
  `~/.var/app/app.zen_browser.zen/config/gtk-3.0/gtk.css` — created with just this block.

Restart the apps to pick it up. Both files validated with GTK 3's own parser
(`Gtk.CssProvider` via python-gobject, no parse errors).

## Notes
- `~/.config/gtk-3.0/gtk.css` is shared with the shell theming: Noctalia's GTK apply
  script only ensures its `@import url("noctalia.css")` line, and `shell-theme.sh`
  ([[dms-trial]]) only flips that line, so the appended block survives both.
- GTK 4 apps have no CSS key bindings, so this doesn't cover them (no GTK 4 app here was
  affected).
