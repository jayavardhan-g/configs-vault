-- Searchable cheatsheet, driven by ~/.config/nvim/cheatsheet.md.
--
-- The markdown is parsed into one entry per "### Title" block, grouped by the
-- "## Category" above it. The picker fuzzy-matches entry titles (plus their
-- category), previews the selected entry on the right, and <CR> opens just
-- that entry on its own - deliberately never dumping you into the raw file
-- scrolled to a line, which is what made earlier versions unpleasant.
--
-- Two files: cheatsheet.md is the original and is never touched by normal
-- editing. The first <C-e> edit copies it to cheatsheet.user.md, and from
-- then on the picker shows that copy. <C-x> deletes the copy (after asking),
-- restoring the original no matter how old the edits are. <C-o> edits the
-- original itself, which also changes what a restore brings back. Edits are
-- always one entry at a time, in a float - the same "never the raw file"
-- rule as viewing.

local M = {}

local function config_file(name)
  return vim.fn.stdpath("config") .. "/" .. name
end

local function original_path()
  return config_file("cheatsheet.md")
end

local function copy_path()
  return config_file("cheatsheet.user.md")
end

local function has_copy()
  return vim.uv.fs_stat(copy_path()) ~= nil
end

local function active_path()
  return has_copy() and copy_path() or original_path()
end

---@param file string
---@return string[]
local function read_lines(file)
  if vim.fn.filereadable(file) == 0 then
    return {}
  end
  return vim.fn.readfile(file)
end

---@class cheatsheet.Entry
---@field category string
---@field title string
---@field body string
---@field first integer line of the "### Title" heading
---@field last integer last non-blank line of the entry
---@field n integer which occurrence of this category+title it is (duplicates)

---@param lines string[]
---@return cheatsheet.Entry[]
local function parse(lines)
  local items, category, cur, seen = {}, nil, nil, {}

  local function flush()
    if cur then
      -- body stops at the last non-blank line so previews don't have dead space
      cur.body = table.concat(vim.list_slice(lines, cur.first + 1, cur.last), "\n")
      items[#items + 1] = cur
    end
    cur = nil
  end

  -- Headings inside fenced code blocks are content, not structure - the
  -- bodies contain shell/vim snippets and ASCII mockups where a leading
  -- "#" is common.
  local in_fence = false

  for i, line in ipairs(lines) do
    if line:match("^%s*```") then
      in_fence = not in_fence
    end

    -- "###" must be tested before "##": the "##" pattern needs whitespace
    -- after it, so it won't match a "###" line, but order makes that explicit
    local entry = not in_fence and line:match("^###%s+(.+)$") or nil
    local cat = not in_fence and line:match("^##%s+(.+)$") or nil
    if entry then
      flush()
      local key = (category or "") .. "\0" .. entry
      seen[key] = (seen[key] or 0) + 1
      cur = { category = category or "", title = entry, first = i, last = i, n = seen[key] }
    elseif cat then
      flush()
      category = cat
    elseif cur and not line:match("^%s*$") then
      cur.last = i
    end
  end
  flush()

  return items
end

---@return cheatsheet.Entry[]
function M.entries()
  return parse(read_lines(active_path()))
end

--- Find an entry by identity (category + title + occurrence), not by line
--- number - the file may have changed since the entry was picked.
---@param entries cheatsheet.Entry[]
---@param want { category: string, title: string, n?: integer }
---@return cheatsheet.Entry?
local function find(entries, want)
  for _, e in ipairs(entries) do
    if e.category == want.category and e.title == want.title and e.n == (want.n or 1) then
      return e
    end
  end
end

---@param lines string[]
---@param title string
local function float(lines, title)
  local width = math.min(92, math.floor(vim.o.columns * 0.8))
  -- +2 for the title/padding, capped so long entries still fit on screen
  local height = math.max(5, math.min(#lines + 2, math.floor(vim.o.lines * 0.8)))
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  }
end

--- Open a single entry in its own centered floating window.
---@param item table
function M.show(item)
  local lines = vim.split("# " .. item.title .. "\n\n" .. item.body, "\n")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, float(lines, item.title))
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2

  local opts = { buffer = buf, silent = true, nowait = true }
  vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", opts)
  -- backspace goes back to the search list, so you can keep browsing
  vim.keymap.set("n", "<BS>", function()
    vim.api.nvim_win_close(win, true)
    M.open()
  end, opts)
  -- e switches from reading this entry to editing it
  vim.keymap.set("n", "e", function()
    vim.api.nvim_win_close(win, true)
    M.edit(item, "copy")
  end, opts)
end

--- Edit one entry in a float. `:w` writes just that entry back into its
--- file; the rest of the file is untouched.
---@param item { category: string, title: string, n?: integer }
---@param which "copy"|"original"
function M.edit(item, which)
  local file = which == "original" and original_path() or copy_path()
  local label = which == "original" and "original" or "your copy"

  if which == "copy" and not has_copy() then
    vim.fn.writefile(read_lines(original_path()), copy_path())
    vim.notify("Created your copy: cheatsheet.user.md - the original stays untouched", vim.log.levels.INFO)
  end

  local entry = find(parse(read_lines(file)), item)
  if not entry then
    vim.notify(("\"%s\" isn't in the %s"):format(item.title, label), vim.log.levels.WARN)
    return
  end
  if which == "original" and has_copy() then
    vim.notify(
      "Editing the original. The picker shows your copy, so this appears after a restore (<C-x>)",
      vim.log.levels.INFO
    )
  end

  -- Identity of the entry being edited; updated after each save in case the
  -- title line itself was changed.
  local key = { category = entry.category, title = entry.title, n = entry.n }
  local function buf_name()
    return ("cheatsheet://%s/%s/%s/%d"):format(which, key.category, key.title, key.n)
  end

  -- One buffer per entry, found by name. A plain :q with unsaved changes
  -- only hides it (bufhidden=hide), so reopening the entry brings those
  -- edits back; :q! unloads it, and a stale one is replaced here.
  local lines = vim.list_slice(read_lines(file), entry.first, entry.last)
  local buf = vim.fn.bufnr(buf_name())
  local created = false
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
    vim.notify("Brought back your unsaved edits to this entry", vim.log.levels.INFO)
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  else
    if buf ~= -1 then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    buf = vim.api.nvim_create_buf(false, false)
    created = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- acwrite: :w runs the BufWriteCmd below instead of writing a real file.
    -- Not bufhidden=wipe: with 'hidden' on, :q would silently throw away
    -- unsaved edits.
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modified = false
    vim.api.nvim_buf_set_name(buf, buf_name())
  end

  local win = vim.api.nvim_open_win(buf, true, float(lines, ("Edit: %s (%s)"):format(entry.title, label)))
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 0 -- show the markdown as written while editing

  -- Handlers belong to the buffer, so a reopened buffer already has them -
  -- registering again would make every :w save twice.
  if not created then
    return
  end

  local function close()
    local w = vim.fn.bufwinid(buf)
    if w ~= -1 then
      vim.api.nvim_win_close(w, true)
    end
  end

  -- Nothing unsaved once the window is gone: drop the buffer. A modified
  -- one is kept (hidden) so reopening the entry brings the edits back.
  vim.api.nvim_create_autocmd("BufHidden", {
    buffer = buf,
    callback = function()
      if not vim.bo[buf].modified then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) and vim.fn.bufwinid(buf) == -1 then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      while #new > 0 and new[#new]:match("^%s*$") do
        table.remove(new)
      end
      if #new > 0 and not new[1]:match("^###%s+.+$") then
        vim.notify("The first line must stay a \"### Title\" heading - not saved", vim.log.levels.ERROR)
        return
      end

      local current = read_lines(file)
      local target = find(parse(current), key)
      if not target then
        vim.notify("This entry is no longer in the file - not saved", vim.log.levels.ERROR)
        return
      end

      local rest = target.last + 1
      if #new == 0 then
        if vim.fn.confirm(("Delete the entry \"%s\"?"):format(key.title), "&Delete\n&Cancel", 2) ~= 1 then
          return
        end
        -- take the blank lines that separated it along with it
        while current[rest] and current[rest]:match("^%s*$") do
          rest = rest + 1
        end
      end

      local out = vim.list_slice(current, 1, target.first - 1)
      vim.list_extend(out, new)
      vim.list_extend(out, vim.list_slice(current, rest))
      vim.fn.writefile(out, file)
      vim.bo[buf].modified = false

      if #new == 0 then
        vim.notify(("Deleted \"%s\" from %s"):format(key.title, label), vim.log.levels.INFO)
        close()
        return
      end
      -- re-identify by position: the saved entry now starts at target.first
      for _, e in ipairs(parse(out)) do
        if e.first == target.first then
          key = { category = e.category, title = e.title, n = e.n }
          pcall(vim.api.nvim_buf_set_name, buf, buf_name())
          break
        end
      end
      vim.notify(("Saved \"%s\" to %s"):format(key.title, label), vim.log.levels.INFO)
    end,
  })

  vim.keymap.set("n", "q", function()
    if vim.bo[buf].modified then
      vim.notify("Unsaved changes - :w to save, :q! to discard", vim.log.levels.WARN)
    else
      close()
    end
  end, { buffer = buf, silent = true, nowait = true })
end

--- Discard your copy entirely, going back to the original.
function M.restore()
  if not has_copy() then
    vim.notify("Already showing the original - no edits to discard", vim.log.levels.INFO)
    return
  end
  local choice =
    vim.fn.confirm("Discard ALL your cheatsheet edits and go back to the original?", "&Discard\n&Cancel", 2)
  if choice ~= 1 then
    return
  end
  os.remove(copy_path())
  vim.notify("Cheatsheet restored to the original", vim.log.levels.INFO)
end

--- Pull the `backtick spans` out of a body - the keys and commands an entry
--- is about, without the surrounding prose.
---@param body string
---@return string[]
local function key_terms(body)
  -- Strip fenced blocks first. A ``` fence is three backticks, so leaving
  -- them in shifts the pairing of every inline `span` that follows and the
  -- extracted terms come out as garbage.
  local kept = {}
  local in_fence = false
  for line in (body .. "\n"):gmatch("(.-)\n") do
    if line:match("^%s*```") then
      in_fence = not in_fence
    elseif not in_fence then
      kept[#kept + 1] = line
    end
  end
  body = table.concat(kept, "\n")

  local seen, out = {}, {}
  for term in body:gmatch("`([^`]+)`") do
    if not seen[term] and #term <= 24 then
      seen[term] = true
      out[#out + 1] = term
    end
  end
  return out
end

--- The exact strings a search can equal to put this entry first: each key
--- span, plus leader keys without the leader (`<lead>sm` -> "sm") and spelled
--- the way people type it ("<leader>sm"). Case-sensitive on purpose, so `s`
--- and `S` stay different keys.
---@param terms string[]
---@return table<string, boolean>
local function exact_keys(terms)
  local set = {}
  for _, t in ipairs(terms) do
    set[t] = true
    local rest = t:match("^<lead>(.+)$")
    if rest then
      set[rest] = true
      set["<leader>" .. rest] = true
    end
  end
  return set
end

function M.open()
  local items = {}
  for i, entry in ipairs(M.entries()) do
    local terms = key_terms(entry.body)
    items[#items + 1] = {
      idx = i,
      score = 0,
      -- Matching runs against the title, its category, and the keys the
      -- entry mentions - so "ghP" or "ciw" find the right entry. The prose
      -- body is deliberately excluded: including it made a search for
      -- "find" return 69 noisy hits with the wrong one ranked first.
      text = entry.title .. " " .. entry.category .. " " .. table.concat(terms, " "),
      keys = exact_keys(terms),
      title = entry.title,
      category = entry.category,
      n = entry.n,
      body = entry.body,
      preview = {
        text = "# " .. entry.title .. "\n\n" .. entry.body,
        ft = "markdown",
        loc = false,
      },
    }
  end

  -- Same keys from the search box and the results list.
  local keys = {
    ["<c-e>"] = { "cheatsheet_edit", mode = { "n", "i" } },
    ["<c-x>"] = { "cheatsheet_restore", mode = { "n", "i" } },
    ["<c-o>"] = { "cheatsheet_edit_original", mode = { "n", "i" } },
  }

  -- Typing a key exactly (`s`, `x`, `gd`, `sm`) puts the entries that list
  -- that key first. Plain fuzzy matching can't do this for short keys: a
  -- one-letter search matches nearly every entry, which left the `s` (Flash)
  -- entry at rank 74. Everything else keeps the normal fuzzy order.
  local picker ---@type snacks.Picker?
  local function exact(item)
    local q = picker and vim.trim(picker.input.filter.pattern or "") or ""
    return q ~= "" and item.keys[q] == true
  end

  picker = Snacks.picker({
    source = "cheatsheet",
    sort = function(a, b)
      local ea, eb = exact(a), exact(b)
      if ea ~= eb then
        return ea
      end
      if a.score ~= b.score then
        return a.score > b.score
      end
      return a.idx < b.idx
    end,
    title = has_copy() and "Cheatsheet (your copy)" or "Cheatsheet",
    items = items,
    preview = "preview",
    layout = {
      preset = "default",
      -- Snacks' default backdrop is a 60%-opacity black overlay across the
      -- whole editor, which reads as "the theme changed" every time this
      -- opens. Off: everything behind keeps its normal colours.
      layout = { backdrop = false },
    },
    actions = {
      cheatsheet_edit = function(picker, item)
        picker:close()
        if item then
          M.edit(item, "copy")
        end
      end,
      cheatsheet_edit_original = function(picker, item)
        picker:close()
        if item then
          M.edit(item, "original")
        end
      end,
      cheatsheet_restore = function(picker)
        picker:close()
        M.restore()
      end,
    },
    win = {
      input = { keys = keys },
      list = { keys = keys },
      -- The bodies are prose, so let the preview wrap instead of cutting
      -- lines off at the pane edge (Snacks defaults preview windows to
      -- wrap=false, which suits code previews, not paragraphs).
      preview = { wo = { wrap = true, linebreak = true } },
    },
    format = function(item)
      return {
        { ("%-46s"):format(item.title) },
        { item.category, "Comment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.show(item)
      end
    end,
  })
end

return M
