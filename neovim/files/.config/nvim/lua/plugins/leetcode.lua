-- LeetCode inside Neovim: browse problems, run, test and submit without the
-- browser. Launch a dedicated session with `nvim leetcode.nvim`.
--
-- Solutions are real .cpp files, so clangd, clang-format and format-on-save
-- all work normally (unlike the GhostText route, which needs workarounds).

--- Sign-in with two boxes (csrftoken, then LEETCODE_SESSION) instead of the
--- plugin's single "paste the whole Cookie header" box. The plugin's parser
--- needs both, as `name=value` pairs; pasting just one value fails with
--- "Bad csrf token format". The assembled string goes through the plugin's
--- own cookie.set, so saving and the login check are unchanged. A full
--- Cookie header pasted into the first box still works as before.
---@param cb? fun(success: boolean)
local function two_box_cookie_prompt(cb)
  local cmd = require("leetcode.command")
  local cookie = require("leetcode.cache.cookie")
  local log = require("leetcode.logger")
  local NuiInput = require("nui.input")
  local event = require("nui.utils.autocmd").event
  local toggle = require("leetcode.config").user.keys.toggle

  -- same look as the plugin's own prompt, just wider (tokens are long)
  local function ask(title, on_value)
    local input = NuiInput({
      relative = "editor",
      position = { row = "50%", col = "50%" },
      size = 60,
      border = { style = "rounded", text = { top = (" %s "):format(title), top_align = "left" } },
      win_options = { winhighlight = "Normal:Normal" },
    }, {
      prompt = " 󰆘 ",
      on_submit = function(value)
        on_value(vim.trim(value or ""))
      end,
    })
    input:mount()
    input:map("n", toggle, function()
      input:unmount()
    end)
    input:on(event.BufLeave, function()
      input:unmount()
    end)
  end

  local function finish(str)
    local err = cookie.set(str)
    if not err then
      log.info("Sign-in successful")
      cmd.start_user_session()
    else
      log.error("Sign-in failed: " .. err)
    end
    pcall(cb, not err)
  end

  ask("1/2  csrftoken", function(csrf)
    if csrf == "" then
      return
    end
    if csrf:find("LEETCODE_SESSION=", 1, true) then
      return finish(csrf)
    end
    csrf = csrf:gsub("^csrftoken=", "")
    -- let the first popup close before mounting the second
    vim.schedule(function()
      ask("2/2  LEETCODE_SESSION", function(session)
        if session == "" then
          return
        end
        session = session:gsub("^LEETCODE_SESSION=", "")
        finish(("csrftoken=%s; LEETCODE_SESSION=%s"):format(csrf, session))
      end)
    end)
  end)
end

--- The console (testcases + result) is a floating popup pair by default:
--- centred over the code, closed the moment focus leaves it, and immune to
--- window commands. This turns its two windows into real splits along the
--- bottom, full width under the description and code:
---
---   ┌─ description ─┬───── code ─────┐
---   │               │                │
---   ├── testcases ──┴──── result ────┤
---   └────────────────────────────────┘
---
--- Neovim (0.10+) can turn a float into a split with nvim_win_set_config,
--- so the plugin keeps creating and owning the windows; they're just moved.
--- The floats nui adds around them (an invisible layout container and a
--- border window per popup) are closed - nui tolerates that. The border
--- titles move to winbars drawn in FloatBorder, which the plugin re-links
--- per window to colour the verdict (green accepted, red wrong), so the
--- result's winbar still changes colour.
--- Last docked size per console ({ height, width } of the testcases window),
--- so a re-dock puts back the size you resized to.
local dock_sizes = setmetatable({}, { __mode = "k" })

--- Is the bottom row of the current tab exactly testcases | result?
local function is_docked(tc_win, res_win)
  local layout = vim.fn.winlayout()
  if layout[1] ~= "col" then
    return false
  end
  local bottom = layout[2][#layout[2]]
  return bottom[1] == "row"
    and #bottom[2] == 2
    and bottom[2][1][1] == "leaf"
    and bottom[2][1][2] == tc_win
    and bottom[2][2][1] == "leaf"
    and bottom[2][2][2] == res_win
end

---@param console lc.ui.Console?
local function dock_console(console)
  local function valid(win)
    return win and vim.api.nvim_win_is_valid(win)
  end
  local function floating(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
  end
  if not console or not console.visible then
    return
  end
  local tc, res = console.testcase, console.result
  if not (valid(tc.winid) and valid(res.winid)) then
    return
  end

  -- Every run/submit shows the console again. If it's already docked, leave
  -- the windows alone: moving a window that's already a split re-creates it,
  -- which grew the bottom row each time and reset testcases | result to 50/50.
  local already = not floating(tc.winid) and not floating(res.winid) and is_docked(tc.winid, res.winid)
  if already then
    dock_sizes[console] = {
      height = vim.api.nvim_win_get_height(tc.winid),
      width = vim.api.nvim_win_get_width(tc.winid),
    }
  else
    -- Re-docking: the console came back as floats (hidden and re-shown), or
    -- :Leet desc reshuffled the layout. Put back the last docked size; 30%
    -- high and an even split the very first time.
    local size = dock_sizes[console] or {}
    local height = size.height
      or (not floating(tc.winid) and vim.api.nvim_win_get_height(tc.winid))
      or math.floor(vim.o.lines * 0.3)
    vim.api.nvim_win_set_config(tc.winid, { split = "below", win = -1, height = height })
    vim.api.nvim_win_set_config(res.winid, { split = "right", win = tc.winid })
    -- moving hands the moved windows' rows to their neighbours first, so set
    -- the size again afterwards
    vim.api.nvim_win_set_height(tc.winid, height)
    if size.width then
      vim.api.nvim_win_set_width(tc.winid, size.width)
    end
    dock_sizes[console] = {
      height = vim.api.nvim_win_get_height(tc.winid),
      width = vim.api.nvim_win_get_width(tc.winid),
    }
  end

  for _, popup in ipairs({ tc, res }) do
    if valid(popup.border.winid) then
      vim.api.nvim_win_close(popup.border.winid, true)
    end
    popup.border.winid = nil
  end
  if valid(console.winid) then
    vim.api.nvim_win_close(console.winid, true)
  end
  console.winid = nil

  local keys = require("leetcode.config").user.keys
  vim.wo[tc.winid].winbar = ("%%#FloatBorder#%%= Testcases (%s)  ·  Reset (%s) %%="):format(
    keys.focus_testcases,
    keys.reset_testcases
  )
  vim.wo[res.winid].winbar = ("%%#FloatBorder#%%= Result (%s)  ·  Use testcase (%s) %%="):format(
    keys.focus_result,
    keys.use_testcase
  )
end

--- Class patches that put the console in dock_console's layout. Applied from
--- the `enter` hook, not config(): these modules pull in the plugin's cookie
--- cache, which only exists after the plugin's own setup at VimEnter -
--- requiring them any earlier errors and the session never starts.
local console_patched = false
local function patch_console()
  if console_patched then
    return
  end
  console_patched = true

  -- The plugin re-creates the console windows as floats on every show, so
  -- dock after each one. Patched on the classes, which every question's
  -- console looks its methods up on.
  local Console = require("leetcode-ui.layout.console")
  local show = Console.show
  Console.show = function(self, ...)
    show(self, ...)
    dock_console(self)
  end
  -- It also hides itself as soon as focus leaves it (BufLeave/WinLeave),
  -- which is what made comparing output with code impossible. Docked, it
  -- just stays; `q` inside it or :Leet console still hides it.
  require("leetcode-ui.popup.console").handle_leave = function() end
  -- Run/submit moved focus into the result; stay where you were (usually
  -- the code) - the result is visible right below now. L focuses it.
  local run = Console.run
  Console.run = function(self, ...)
    local win = vim.api.nvim_get_current_win()
    run(self, ...)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end
  -- :Leet desc re-opens the description as a full-height left split,
  -- which would squeeze the console to the right of it; re-dock after.
  local Description = require("leetcode-ui.split.description")
  local desc_show = Description.show
  Description.show = function(self, ...)
    local ret = desc_show(self, ...)
    dock_console(self.question and self.question.console)
    return ret
  end
end

return {
  {
    "kawre/leetcode.nvim",
    -- No `build = ":TSUpdate html"` (upstream's suggestion): it fails here
    -- because treesitter isn't loaded at plugin-build time. The html parser
    -- is installed via treesitter's ensure_installed instead (languages.lua).
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lang = "cpp", -- the plugin's default too; explicit for the record
      -- No injector needed for C++: LeetCode compiles with bits/stdc++.h and
      -- `using namespace std` implicitly, and the plugin already injects
      -- exactly those two lines by default (lua/leetcode/config/imports.lua),
      -- folded out of the way. That's what keeps clangd from flagging every
      -- vector/string as undeclared. Only the marked code section is sent on
      -- run/test/submit, so the injected lines never get submitted.

      -- The plugin ships no keys for run/submit, only :Leet commands. These
      -- are buffer-local to solution buffers, so they can't clash with
      -- anything elsewhere. No separate "test" key: :Leet test and :Leet run
      -- hit the same endpoint (interpret_solution). question_enter fires
      -- after the solution buffer exists, and again for the new buffer when
      -- :Leet lang switches language.
      hooks = {
        -- No swap files in LeetCode sessions. The plugin loads solutions with
        -- bufload(), and when any other Neovim already has that file open (a
        -- second LeetCode session, or a stale .swp), Neovim raises E325
        -- there instead of prompting - the plugin treats that as fatal and
        -- the question never opens, whichever of Recover/Delete you pick.
        -- A per-file fix doesn't work (the swap check runs before
        -- BufReadPre/SwapExists could intervene); session-wide does. `enter`
        -- fires at session start, before any question buffer exists.
        -- Tradeoff: a crash loses edits since the last :w.
        enter = {
          function()
            vim.o.swapfile = false
          end,
          patch_console,
        },
        question_enter = {
          function(question)
            local function map(lhs, sub, desc)
              vim.keymap.set("n", lhs, "<cmd>Leet " .. sub .. "<cr>", { buffer = question.bufnr, desc = desc })
            end
            map("<localleader>r", "run", "LeetCode: Run")
            map("<localleader>s", "submit", "LeetCode: Submit")
            map("<localleader>c", "console", "LeetCode: Console show/hide")
            map("<localleader>h", "hints", "LeetCode: Hints")
            map("<localleader>i", "info", "LeetCode: Info (stats, topics)")
            map("<localleader>t", "tabs", "LeetCode: Jump to another open question")
            map("<localleader>o", "open", "LeetCode: Open in browser")
            map("<localleader>y", "yank", "LeetCode: Yank solution code")
            -- capitals: these replace the code (u undoes)
            map("<localleader>R", "reset", "LeetCode: Reset to starting template")
            map("<localleader>L", "last_submit", "LeetCode: Restore last submission")
            -- the description is a side panel, so `e` like the explorer's
            -- <leader>e - on the local leader, leaving the explorer alone
            map("<localleader>e", "desc", "LeetCode: Description show/hide")

            -- open with the console already docked (see dock_console), focus
            -- staying in the code; `q` in the console still hides it and
            -- :Leet console brings it back
            question.console:show()
            if vim.api.nvim_win_is_valid(question.winid) then
              vim.api.nvim_set_current_win(question.winid)
            end
          end,
        },
      },
    },
    config = function(_, opts)
      require("leetcode").setup(opts)
      -- Two places hold the prompt: `:Leet cookie update` keeps a reference
      -- in cmd.commands (captured when the module loads, so it's patched
      -- directly), and the sign-in page's button captures cmd.cookie_prompt
      -- when that page first renders - which happens after this runs.
      local cmd = require("leetcode.command")
      cmd.cookie_prompt = two_box_cookie_prompt
      cmd.commands.cookie.update[1] = two_box_cookie_prompt


      -- Plain description text is drawn in the theme's Conceal colour, which
      -- is meant to be faint: 1.2:1 contrast on the old grey panel, 2.4:1
      -- even transparent. Use the normal text colour instead (14.4:1).
      -- Wrapping default.get rather than setting a fixed colour keeps it in
      -- step with the colorscheme - Theme.load re-reads get() at start and on
      -- every ColorScheme event, and kitty's colours change with Noctalia.
      -- A real fg, not a link: the plugin merges `normal` with bold/italic
      -- for emphasised words, and a link would silently drop those.
      local default = require("leetcode.theme.default")
      local get = default.get
      default.get = function()
        local theme = get()
        theme.normal = { fg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).fg }
        return theme
      end
    end,
  },
}
