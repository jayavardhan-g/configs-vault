# Appearance

**Category:** neovim
**Files touched:** `colors/kitty.lua`, `lua/plugins/disabled.lua`, `lua/plugins/leetcode.lua` (all under `~/.config/nvim/`; copies in [`files/`](files/))

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

## Catch-up: backgrounds are now `NONE`, not kitty's hex (found 2026-10-04)

**Superseded** the "exactly kitty's background colour" approach above. Found when re-syncing [`files/.config/nvim/colors/kitty.lua`](files/.config/nvim/colors/kitty.lua); the date of the change is unknown and the reasons come from the file's comments. `Normal`, `NormalFloat` and `FloatBorder` (and every other "editor background") now use `bg = "NONE"`, i.e. kitty's own default background, which kitty always draws at `background_opacity`.

**Why**: painting kitty's background hex explicitly looked see-through only until the theme changed. After Noctalia regenerated kitty's theme, kitty treated the old hex as an ordinary colour and drew it solid, leaving a black box in an already-open Neovim. Related: an open Neovim now deliberately keeps its colours when the kitty theme changes; the new theme applies the next time Neovim starts.

