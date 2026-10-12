-- GhostText server: edit browser text fields in Neovim.
--
-- Replaces nvim-ghost.nvim, whose Python server raced its own threads (a
-- browser update could swallow the next edit made in Neovim, or bounce a stale
-- text back to the page), sent every change twice, replaced the whole buffer
-- on each keystroke, reported cursor positions in the wrong units, and
-- accepted WebSocket connections from any web page.
--
-- Layout, all on localhost:
--   * every Neovim with a UI listens for WebSockets on its own random port;
--   * one of them (the "hub") also owns the GhostText port (4001), and answers
--     the extension's `GET /` with the port of whichever Neovim last had
--     focus. Others report focus with `GET /focus?port=N`; when the hub exits,
--     the next one to gain focus takes the port over.
--
-- Everything runs on Neovim's own event loop - no threads - so the echo
-- suppression is a plain "last text both sides agree on" comparison.

local uv = vim.uv
local protocol = require("ghosttext.protocol")

local M = {}

M.config = {
  port = tonumber(vim.env.GHOSTTEXT_SERVER_PORT) or 4001,
}

local state = {
  port = nil, ---@type integer? this instance's WebSocket port
  servers = {}, ---@type uv.uv_tcp_t[]
  hub = false, -- owns M.config.port
  focused = nil, ---@type integer? hub only: WebSocket port to hand out
  sessions = {}, ---@type table<ghosttext.Session, true>
  watchdog = nil, ---@type uv.uv_timer_t?
  warned = false,
}

local function notify(msg, level)
  vim.schedule(function()
    vim.notify("[ghosttext] " .. msg, level or vim.log.levels.INFO)
  end)
end

-- Browsers always send Origin on WebSocket handshakes, so this keeps ordinary
-- web pages from opening a session and injecting text into Neovim (or
-- reading it back). Our own Neovim instances send no Origin at all.
local function origin_allowed(origin)
  return origin == nil or origin:match("^[%w%-]+%-extension://") ~= nil
end

local function close_handle(h)
  if h and not h:is_closing() then
    h:close()
  end
end

local function respond(client, status, body, content_type)
  client:write(protocol.response(status, body, content_type), function()
    client:shutdown(function()
      close_handle(client)
    end)
  end)
end

---@param host string
---@param port integer
---@param on_connection fun(server: uv.uv_tcp_t)
---@return uv.uv_tcp_t? server
---@return string? err
local function listen(host, port, on_connection)
  local server = uv.new_tcp()
  local ok, err = server:bind(host, port)
  if ok then
    ok, err = server:listen(64, function(e)
      if not e then
        on_connection(server)
      end
    end)
  end
  if not ok then
    close_handle(server)
    return nil, err
  end
  return server
end

--- Fire a plain HTTP GET at another instance's hub. `cb(body)` gets nil on
--- any failure. Callable from fast contexts; `cb` runs in one.
---@param path string
---@param cb fun(body: string?)
local function http_get(path, cb)
  local client = uv.new_tcp()
  local timer = uv.new_timer()
  local done = false
  local function finish(body)
    if done then
      return
    end
    done = true
    close_handle(timer)
    close_handle(client)
    cb(body)
  end
  timer:start(1000, 0, function()
    finish(nil)
  end)
  client:connect("127.0.0.1", M.config.port, function(err)
    if err then
      return finish(nil)
    end
    local chunks = {}
    client:read_start(function(rerr, chunk)
      if rerr then
        return finish(nil)
      end
      if chunk then
        chunks[#chunks + 1] = chunk
        return
      end
      local raw = table.concat(chunks)
      finish(raw:match("^HTTP/%d%.%d 200") and raw:match("\r\n\r\n(.*)$") or nil)
    end)
    client:write(("GET %s HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"):format(path))
  end)
end

--- Is something accepting connections on a local port? `cb` runs in a fast context.
local function probe(port, cb)
  local client = uv.new_tcp()
  client:connect("127.0.0.1", port, function(err)
    close_handle(client)
    cb(err == nil)
  end)
end

--------------------------------------------------------------------------------
-- Sessions: one browser field <-> one buffer
--------------------------------------------------------------------------------

---@class ghosttext.Session
---@field client uv.uv_tcp_t
---@field buf? integer
---@field host string
---@field synced? string text both sides last agreed on
---@field auto_ft string filetype last set from the browser's hint
---@field applying boolean
---@field pending boolean
---@field inbox string
---@field fragments string[]
---@field closed boolean
---@field socket_closed boolean
local Session = {}
Session.__index = Session

function Session.new(client)
  local self = setmetatable({
    client = client,
    host = "",
    auto_ft = "",
    applying = false,
    pending = false,
    inbox = "",
    fragments = {},
    closed = false,
    socket_closed = false,
  }, Session)
  state.sessions[self] = true
  return self
end

-- Browser syntax hints (Monaco language ids, Ace modes, CodeMirror MIME
-- types) that aren't already Neovim filetype names.
local ft_aliases = {
  c_cpp = "cpp",
  ["c++"] = "cpp",
  ["text/x-c++src"] = "cpp",
  ["text/x-csrc"] = "c",
  ["text/x-java"] = "java",
  ["text/x-python"] = "python",
  ["text/x-rustsrc"] = "rust",
  ["text/x-go"] = "go",
  ["text/javascript"] = "javascript",
  ["text/typescript"] = "typescript",
  ["text/x-markdown"] = "markdown",
  csharp = "cs",
  golang = "go",
  python3 = "python",
  bash = "sh",
  shell = "sh",
  plaintext = "",
  plain_text = "",
  text = "",
}

local known_filetypes
--- Map a browser syntax hint to a Neovim filetype, or nil if there's none.
---@param hint any
---@return string?
local function filetype_for(hint)
  if type(hint) ~= "string" or hint == "" then
    return nil
  end
  local ft = hint:lower():gsub("^ace/mode/", "")
  if ft_aliases[ft] ~= nil then
    ft = ft_aliases[ft]
  end
  if ft == "" then
    return nil
  end
  if not known_filetypes then
    known_filetypes = {}
    for _, name in ipairs(vim.fn.getcompletion("", "filetype")) do
      known_filetypes[name] = true
    end
  end
  return known_filetypes[ft] and ft or nil
end

local function utf16_len(s)
  return vim.str_utfindex(s, "utf-16")
end

--- Cursor of the window showing `buf`, as a UTF-16 offset into the joined
--- text (the unit browser selection APIs use).
---@param buf integer
---@param lines string[]
local function cursor_offset(buf, lines)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= buf then
    win = vim.fn.win_findbuf(buf)[1]
  end
  if not win then
    return nil
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  local offset = 0
  for i = 1, row - 1 do
    offset = offset + utf16_len(lines[i]) + 1
  end
  local line = lines[row] or ""
  return offset + vim.str_utfindex(line, "utf-16", math.min(col, #line), false)
end

--- Inverse of cursor_offset: put the cursor at a UTF-16 offset.
local function set_cursor(win, lines, offset)
  for row, line in ipairs(lines) do
    local len = utf16_len(line)
    if offset <= len or row == #lines then
      local col = vim.str_byteindex(line, "utf-16", math.min(offset, len), false)
      pcall(vim.api.nvim_win_set_cursor, win, { row, col })
      return
    end
    offset = offset - len - 1
  end
end

-- Fast context: raw bytes from the socket.
function Session:feed(chunk)
  self.inbox = self.inbox .. chunk
  while true do
    local frame, rest = protocol.parse_frame(self.inbox)
    if not frame then
      return
    end
    self.inbox = rest
    local op = frame.opcode
    if op == protocol.op.ping then
      self.client:write(protocol.frame(protocol.op.pong, frame.payload))
    elseif op == protocol.op.close then
      self:close_socket()
      vim.schedule(function()
        self:close()
      end)
      return
    elseif op == protocol.op.text or op == protocol.op.continuation then
      self.fragments[#self.fragments + 1] = frame.payload
      if frame.fin then
        local message = table.concat(self.fragments)
        self.fragments = {}
        vim.schedule(function()
          self:on_message(message)
        end)
      end
    end
  end
end

function Session:on_message(message)
  if self.closed then
    return
  end
  local ok, data = pcall(vim.json.decode, message)
  if not ok or type(data) ~= "table" or type(data.text) ~= "string" then
    return
  end
  data.text = data.text:gsub("\r\n", "\n")
  if self.buf then
    self:apply(data)
  else
    self:open(data)
  end
end

function Session:open(data)
  local buf = vim.api.nvim_create_buf(false, true) -- nofile, noswapfile
  vim.bo[buf].bufhidden = "wipe"
  self.buf = buf
  self.host = type(data.url) == "string" and data.url or ""
  self.synced = data.text
  local lines = vim.split(data.text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  if not pcall(vim.cmd, "tab sbuffer " .. buf) then
    notify(("field from %s opened in hidden buffer %d"):format(self.host, buf))
  end
  local sel = type(data.selections) == "table" and data.selections[1]
  if type(sel) == "table" and type(sel["end"]) == "number" then
    set_cursor(vim.api.nvim_get_current_win(), lines, sel["end"])
  end

  local ft = filetype_for(data.syntax)
  if ft then
    vim.bo[buf].filetype = ft
    self.auto_ft = ft
  end

  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      if self.closed then
        return true -- detach
      end
      if self.applying or self.pending then
        return
      end
      -- coalesce every change made in this tick (a multi-line comment
      -- toggle, :s, a formatter) into one message
      self.pending = true
      vim.schedule(function()
        self.pending = false
        self:flush()
      end)
    end,
    on_detach = function()
      vim.schedule(function()
        self:close()
      end)
    end,
  })

  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_exec_autocmds("User", {
      pattern = "GhostTextOpen",
      data = { buf = buf, host = self.host, title = data.title },
    })
  end)
end

--- Browser -> Neovim. Only the changed run of lines is replaced, so the
--- cursor, folds, marks and diagnostics elsewhere stay put.
function Session:apply(data)
  local buf = self.buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if data.text ~= self.synced then
    self.synced = data.text
    local new = vim.split(data.text, "\n", { plain = true })
    local old = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local head = 0
    while head < #old and head < #new and old[head + 1] == new[head + 1] do
      head = head + 1
    end
    local tail = 0
    while tail < #old - head and tail < #new - head and old[#old - tail] == new[#new - tail] do
      tail = tail + 1
    end
    if head + tail < math.max(#old, #new) then
      self.applying = true
      pcall(vim.api.nvim_buf_set_lines, buf, head, #old - tail, false, vim.list_slice(new, head + 1, #new - tail))
      self.applying = false
    end
  end

  -- follow a language switch in the page (e.g. LeetCode's picker), unless the
  -- filetype was changed by hand since we last set it
  local ft = filetype_for(data.syntax)
  if ft and ft ~= self.auto_ft and vim.bo[buf].filetype == self.auto_ft then
    vim.bo[buf].filetype = ft
    self.auto_ft = ft
  end
end

--- Neovim -> browser.
function Session:flush()
  local buf = self.buf
  if self.closed or not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if text == self.synced then
    return
  end
  self.synced = text
  local message = { text = text }
  local offset = cursor_offset(buf, lines)
  if offset then
    message.selections = { { start = offset, ["end"] = offset } }
  end
  self:send(vim.json.encode(message))
end

function Session:send(text)
  if not self.socket_closed then
    self.client:write(protocol.frame(protocol.op.text, text))
  end
end

-- Safe from fast contexts.
function Session:close_socket()
  if self.socket_closed then
    return
  end
  self.socket_closed = true
  local client = self.client
  if client:is_closing() then
    return
  end
  client:write(protocol.frame(protocol.op.close, "\3\232"), function() -- 1000: normal closure
    client:shutdown(function()
      close_handle(client)
    end)
  end)
end

--- End the session from either side: browser field closed, or buffer wiped.
function Session:close()
  if self.closed then
    return
  end
  self.closed = true
  state.sessions[self] = nil
  self:close_socket()
  local buf = self.buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

--------------------------------------------------------------------------------
-- Servers
--------------------------------------------------------------------------------

local become_hub

-- GhostText's `GET /`: which WebSocket port to use.
local function answer_hub(client)
  local function reply(port)
    respond(client, "200 OK", ('{"ProtocolVersion":1,"WebSocketPort":%d}'):format(port), "application/json")
  end
  local target = state.focused or state.port
  if target == state.port then
    return reply(target)
  end
  probe(target, function(alive)
    if not alive then
      state.focused = state.port
      target = state.port
    end
    reply(target)
  end)
end

local function route(client, req)
  local path, query = req.path, req.query
  if path == "/" then
    if state.hub then
      return answer_hub(client)
    end
    return respond(client, "200 OK", ('{"ProtocolVersion":1,"WebSocketPort":%d}'):format(state.port), "application/json")
  elseif path == "/focus" and tonumber(query.port) then
    state.focused = tonumber(query.port)
    return respond(client, "200 OK", "ok")
  elseif path == "/bye" and tonumber(query.port) then
    if state.focused == tonumber(query.port) then
      state.focused = state.port
    end
    return respond(client, "200 OK", "ok")
  elseif path == "/ghosttext-lua" then
    return respond(client, "200 OK", "ok")
  end
  respond(client, "404 Not Found", "not found")
end

---@param server uv.uv_tcp_t
local function on_connection(server)
  local client = uv.new_tcp()
  server:accept(client)
  local head, session = "", nil
  client:read_start(function(err, chunk)
    if session then
      if err or not chunk then
        session:close_socket()
        vim.schedule(function()
          session:close()
        end)
      else
        session:feed(chunk)
      end
      return
    end
    if err or not chunk then
      return close_handle(client)
    end
    head = head .. chunk
    local stop = head:find("\r\n\r\n", 1, true)
    if not stop then
      if #head > 16384 then
        close_handle(client)
      end
      return
    end
    local req = protocol.parse_request(head:sub(1, stop - 1))
    local rest = head:sub(stop + 4)
    if not req or req.method ~= "GET" then
      return respond(client, "400 Bad Request", "bad request")
    end
    if not origin_allowed(req.headers.origin) then
      return respond(client, "403 Forbidden", "forbidden")
    end
    local key = req.headers["sec-websocket-key"]
    if (req.headers.upgrade or ""):lower() == "websocket" and key then
      client:write(protocol.handshake(key))
      session = Session.new(client)
      if #rest > 0 then
        session:feed(rest)
      end
      return
    end
    route(client, req)
  end)
end

--- Bind on both loopback families: "localhost" may resolve to either.
---@return uv.uv_tcp_t[]? servers
---@return string? err
local function listen_loopback(port)
  local v4, err = listen("127.0.0.1", port, on_connection)
  if not v4 then
    return nil, err
  end
  local servers = { v4 }
  local v6 = listen("::1", port == 0 and v4:getsockname().port or port, on_connection)
  if v6 then
    servers[#servers + 1] = v6
  end
  return servers
end

--- Tell the hub (or become it) that this instance should get new fields.
local function report_focus()
  if not state.port then
    return
  end
  if state.hub then
    state.focused = state.port
    return
  end
  http_get("/focus?port=" .. state.port, function(body)
    if body ~= "ok" then
      become_hub()
    end
  end)
end

local tries = 0
-- Fast-context safe.
function become_hub()
  local servers = listen_loopback(M.config.port)
  if servers then
    vim.list_extend(state.servers, servers)
    state.hub = true
    state.focused = state.port
    tries = 0
    return
  end
  -- port taken: another instance of us, nvim-ghost's old server, or a stranger
  http_get("/ghosttext-lua", function(body)
    if body == "ok" then
      return report_focus()
    end
    http_get("/is_ghost_binary", function(legacy)
      if legacy == "True" and tries < 5 then
        tries = tries + 1
        -- nvim-ghost's server exits on request; retry once the port frees up
        http_get("/exit", function()
          local timer = uv.new_timer()
          timer:start(300, 0, function()
            close_handle(timer)
            become_hub()
          end)
        end)
      elseif not state.warned then
        state.warned = true
        notify(("port %d is used by another program; GhostText can't reach Neovim"):format(M.config.port), vim.log.levels.WARN)
      end
    end)
  end)
end

function M.start()
  if state.port then
    return
  end
  local servers, err = listen_loopback(0)
  if not servers then
    return notify("could not open a WebSocket port: " .. tostring(err), vim.log.levels.ERROR)
  end
  state.servers = servers
  state.port = servers[1]:getsockname().port

  local group = vim.api.nvim_create_augroup("ghosttext", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = report_focus })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
  report_focus()

  -- if the hub quits while focus is in the browser, nobody would claim the
  -- port until some Neovim regained focus
  state.watchdog = uv.new_timer()
  state.watchdog:start(3000, 3000, function()
    if not state.hub then
      probe(M.config.port, function(alive)
        if not alive and not state.hub then
          become_hub()
        end
      end)
    end
  end)
end

function M.stop()
  for session in pairs(state.sessions) do
    session:close()
  end
  if state.port and not state.hub then
    http_get("/bye?port=" .. state.port, function() end)
  end
  for _, server in ipairs(state.servers) do
    close_handle(server)
  end
  close_handle(state.watchdog)
  state.servers, state.port, state.hub, state.focused = {}, nil, false, nil
  pcall(vim.api.nvim_del_augroup_by_name, "ghosttext")
end

function M.status()
  local fields = {}
  for session in pairs(state.sessions) do
    fields[#fields + 1] = ("%s (buf %s)"):format(session.host, session.buf or "-")
  end
  return {
    port = state.port,
    hub = state.hub,
    focused = state.focused,
    fields = fields,
  }
end

---@param opts? { port?: integer }
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
  vim.api.nvim_create_user_command("GhostTextStatus", function()
    vim.print(M.status())
  end, { desc = "GhostText server state" })
  -- only Neovims with a UI serve fields (not headless/embedded ones)
  if #vim.api.nvim_list_uis() > 0 then
    M.start()
  else
    vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = M.start })
  end
end

return M
