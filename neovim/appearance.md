# Appearance

**Category:** neovim
**Files touched:** `colors/kitty.lua`, `lua/plugins/disabled.lua`, `lua/plugins/leetcode.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

<!-- graph:begin -->
**Graph:** [[kitty]] · [[Neovim]]
<!-- graph:end -->

Colours and transparency: the colorscheme that reads kitty's live theme, and see-through popups/sidebars. Part of the LazyVim setup - see [[lazyvim-migration]] for the migration itself and the index of all topic files.

Entries are in the order they happened. They were split out of `lazyvim-migration.md` on 2026-09-23 without rewording, so "above" and "previous follow-up" refer to entries in this file unless a link says otherwise.

## Follow-up: colorscheme now matches kitty's actual theme (2026-09-15)

**What**: `habamax` (the built-in fallback from the language-trim follow-up, now in [[languages-and-lsp]]) didn't look good.
Rather than pick another bundled colorscheme plugin, built one that reads kitty's *live*
theme file and matches it exactly - same spirit as the pre-LazyVim Vim/Neovim setups'
"no colorscheme, follow the terminal" preference, adapted for the fact that
`termguicolors` has to stay on for LazyVim's UI plugins (bufferline, blink.cmp, noice,
etc.) to render correctly - true ANSI-passthrough like the old Vim/Neovim configs used
isn't viable here, so this reads kitty's actual hex values instead of relying on the
terminal to reinterpret 16 ANSI slots.

Kitty's colors are dynamically managed by Noctalia, not a static file:
`~/.config/kitty/kitty.conf` has `include themes/noctalia.conf`, which
`~/.config/kitty/themes/noctalia.conf` provides (dark background `#0b0e14`, gold accent
`#e6b450`, full 16-color palette). Since Noctalia can regenerate this file later (e.g. on
a wallpaper change), the colorscheme reads it **live at load time** rather than
hardcoding a snapshot of today's values - it'll track future Noctalia theme changes
automatically.

**Change** - new `~/.config/nvim/colors/kitty.lua`: a standalone Neovim colorscheme file
(the standard `colors/<name>.lua` runtime convention, found automatically by
`:colorscheme kitty`). Parses kitty.conf's `include` line to locate the actual theme file
(so it keeps working if Noctalia ever renames it), reads `colorN #hex`/`background`/
`foreground`/`cursor`/`selection_*` lines, and maps them onto Neovim's highlight groups
using a base16-style convention (comments → color8, strings → color2, keywords → color5,
functions → color4, etc.) - full mapping in the file itself. Falls back to `habamax` if
the theme file can't be found/read, rather than erroring.

`~/.config/nvim/lua/plugins/disabled.lua` - `colorscheme` opts changed from `"habamax"`
to `"kitty"`.

**Verified live**: `vim.g.colors_name` reads `kitty`; `Normal`'s background highlight
resolves to `0x0B0E14` - byte-for-byte kitty's actual `background #0b0e14` - confirming
the file was read and applied correctly, not just falling back silently.

## Follow-up: see-through popups/sidebars, readable LeetCode descriptions (2026-09-23)

**What**: from a screenshot - the leetcode.nvim description panel was a solid grey box
that didn't match the see-through editor, and its plain text was nearly invisible.
Asked to make the explorer and LeetCode sidebars transparent like the editor instead of
writing a custom theme.

**Root cause, measured**:
- The editor looks see-through because `Normal` uses **exactly kitty's background
  colour**, which kitty renders at `background_opacity 0.6`. `NormalFloat` used
  `color0` (`#48454e`), a different colour, so kitty drew it solid. Both grey boxes
  trace back to it: the LeetCode description split sets
  `winhighlight = Normal:NormalFloat` (`leetcode-ui/split/description.lua:47`), and the
  Snacks explorer's outer layout box uses `SnacksNormal`, which Snacks links to
  `NormalFloat` (`snacks/win.lua:206`). Its list and input already used `Normal`.
- The unreadable text: leetcode.nvim draws plain description text in the theme's
  **`Conceal`** colour (`theme/default.lua`: `normal = { fg = hl("Conceal").fg }`) -
  here `#4f5258`, a colour meant to be faint. WCAG contrast against the panel: **1.2**
  (unreadable). Transparency alone only lifts that to **2.4** (4.5 is comfortable
  reading), so both fixes were needed.

**Decisions** (asked): transparency for **all** popups, not just the two sidebars;
and brighten the plain text too.

**Change**:
- `colors/kitty.lua` (now tracked in `files/`): `NormalFloat` and `FloatBorder` use
  `c.background` instead of `c.color0`. `Pmenu` (completion menu) deliberately left
  solid so the selected item stays easy to pick out.
- `lua/plugins/leetcode.lua`: wraps `leetcode.theme.default.get` so `normal` takes the
  live `Normal` foreground. Not a fixed colour, because kitty's colours change with
  Noctalia and leetcode.nvim re-reads `get()` at start and on every `ColorScheme`. Not a
  highlight link either: the plugin merges `normal` with bold/italic for emphasised
  words, and a link would silently drop those.

**Verified live**: `NormalFloat`, `FloatBorder` and the explorer's layout box all now
resolve to the editor background (`#141318`); `Pmenu` still `#48454e`. In a
`nvim leetcode.nvim` session, plain text (`<p>`) uses `#e6e1e9` (the Normal
foreground, contrast 14.4), `<strong>` is still bold and `<em>` still italic in that
colour, and `<code>` keeps its own colour. Visual look in the real terminal not
verifiable headlessly.

**Side effect**: inline code "chips" in descriptions used to stand out because their
background (the editor colour, see-through) differed from the grey panel. With the
panel now the same colour, inline code is distinguished only by its colour. Flagged to
the user rather than changed.

## Follow-up: colorscheme reloads live when Noctalia changes kitty's theme (2026-10-01)

> **Superseded the same day** by the next follow-up (transparent `NONE` backgrounds, no
> live reload). Kept for the root cause and the libuv findings.

**What**: with Neovim open, a wallpaper change turned the see-through editor into a solid
dark box until Neovim was reopened.

**Root cause**: `colors/kitty.lua` read kitty's theme only when the colorscheme loaded.
On a wallpaper change Noctalia rewrites `~/.config/kitty/themes/noctalia.conf` and its
kitty `post_hook` (`/usr/share/noctalia/assets/templates/kitty/apply.sh`) sends
`pkill -USR1 kitty`, so kitty switches background at once. Neovim kept painting the
*old* background, and kitty only applies `background_opacity` to cells in exactly its
own current background colour - so everything drew solid.

**Change** - `colors/kitty.lua` now starts a `vim.uv` fs_event watcher (once per
Neovim, guarded by `vim.g.kitty_theme_watched`) on the theme file's **directory** (a
file replaced via rename would drop a file watch), filtered to the theme's file name,
debounced 150 ms, which re-runs `:colorscheme kitty` if it's still the active scheme.
That fires `ColorScheme`, so plugins re-derive their colours too (leetcode.nvim's
`Theme.load` already listens for it). Full file:
[`files/.config/nvim/colors/kitty.lua`](files/.config/nvim/colors/kitty.lua).

**Verified (headless, real config)**: rewriting the theme with `background #123456`
reloaded the scheme by itself (`Normal`/`NormalFloat` bg → `#123456`); restoring the
original reloaded it back (`#0f150a`). Theme file restored byte-identical, kitty not
signalled. The visual result in a live kitty window wasn't checked from here.

**Hardening (same day, asked: no runaway processes/leaks/hogging)** - exactly one
fs_event + one timer per Neovim, reused for every event; the reload callback is built
once. Reloads only from a complete file (an empty/half-written one would otherwise drop
to the `habamax` fallback and stop following kitty). If the watched dir disappears -
which libuv reports as an ordinary event, not an error, verified - both handles are
closed and the guard cleared, so the next `:colorscheme kitty` re-watches. Tested in a
throwaway `$HOME` with `nvim -u NONE`: 500 rewrites in a burst → 1 reload, handles 2 →
2, Lua memory +1.1 KB, ~12 ms CPU; empty file → no reload, scheme stays `kitty`;
themes dir deleted → handles 2 → 0, recreated + `:colorscheme kitty` → watch works
again; 50× `:colorscheme kitty` → still 2 handles.

## Follow-up: open Neovim keeps its colours, transparency via NONE (2026-10-01)

**What**: asked to drop the live reload - an open Neovim should keep the theme it
started with (no colour change mid-session) but stay see-through when kitty's theme
changes; the new theme applies on the next launch.

**Change** - `colors/kitty.lua`: every editor-background highlight (`Normal`,
`NormalFloat`, `FloatBorder`, `SignColumn`, `DiffAdd/Delete/Change/Text`) now uses
`bg = "NONE"` instead of kitty's background hex. `NONE` means "terminal default
background", which kitty always draws at `background_opacity`, whatever colour its
theme has - so a theme change can no longer make it solid. The fs_event watcher from
the previous follow-up is removed; the theme is read once, at load. Foregrounds,
`Pmenu`, `CursorLine`, statusline etc. still come from kitty's palette as before.
Full file: [`files/.config/nvim/colors/kitty.lua`](files/.config/nvim/colors/kitty.lua).

**Plugins that read `Normal`'s background** (checked before switching): mason.nvim and
noice.nvim detect a missing bg and switch to their transparent mode; lazy.nvim just
skips its dimmed backdrop; leetcode.nvim's test-case chips become see-through. No
other installed plugin reads it.

**Verified**: real config loads with no messages; `Normal`/`NormalFloat`/`SnacksNormal`
bg = NONE; no fs_event handle left. Sandbox (`nvim -u NONE`, throwaway `$HOME`): theme
file changed while open → 0 reloads, colours unchanged, bg still NONE; reloading the
scheme (= next launch) picks up the new theme. Not checked visually in a live kitty
window from here.

**Trade-off**: until Neovim is reopened, its old text colours sit on kitty's new
background colour, so contrast can be a little off after a big palette change.
