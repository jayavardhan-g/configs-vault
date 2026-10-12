-- Wire-format helpers for the GhostText server (lua/ghosttext/init.lua):
-- a minimal HTTP request parser and RFC 6455 WebSocket framing. Pure Lua with
-- no Neovim API calls, so everything here is safe inside libuv callbacks.

local bit = require("bit")
local band, bor, bxor, bnot, lshift, rshift, rol, tobit =
  bit.band, bit.bor, bit.bxor, bit.bnot, bit.lshift, bit.rshift, bit.rol, bit.tobit

local M = {}

--- SHA-1 digest (raw 20 bytes). Only used for the WebSocket handshake, which
--- requires it; Neovim itself only ships sha256.
---@param msg string
---@return string
function M.sha1(msg)
  local h0, h1, h2, h3, h4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0
  local bits = #msg * 8
  local len = {}
  for i = 8, 1, -1 do
    len[i] = bits % 256
    bits = math.floor(bits / 256)
  end
  msg = msg .. "\128" .. string.rep("\0", (55 - #msg) % 64) .. string.char(unpack(len))

  local w = {}
  for chunk = 1, #msg, 64 do
    for i = 0, 15 do
      local a, b, c, d = msg:byte(chunk + i * 4, chunk + i * 4 + 3)
      w[i] = bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)
    end
    for i = 16, 79 do
      w[i] = rol(bxor(w[i - 3], w[i - 8], w[i - 14], w[i - 16]), 1)
    end
    local a, b, c, d, e = h0, h1, h2, h3, h4
    for i = 0, 79 do
      local f, k
      if i < 20 then
        f, k = bor(band(b, c), band(bnot(b), d)), 0x5A827999
      elseif i < 40 then
        f, k = bxor(b, c, d), 0x6ED9EBA1
      elseif i < 60 then
        f, k = bor(band(b, c), band(b, d), band(c, d)), 0x8F1BBCDC
      else
        f, k = bxor(b, c, d), 0xCA62C1D6
      end
      a, b, c, d, e = tobit(rol(a, 5) + f + e + k + w[i]), a, rol(b, 30), c, d
    end
    h0, h1, h2, h3, h4 = tobit(h0 + a), tobit(h1 + b), tobit(h2 + c), tobit(h3 + d), tobit(h4 + e)
  end

  local out = {}
  for _, h in ipairs({ h0, h1, h2, h3, h4 }) do
    out[#out + 1] = string.char(band(rshift(h, 24), 255), band(rshift(h, 16), 255), band(rshift(h, 8), 255), band(h, 255))
  end
  return table.concat(out)
end

--- Value for the Sec-WebSocket-Accept response header.
---@param key string the client's Sec-WebSocket-Key
function M.accept_key(key)
  return vim.base64.encode(M.sha1(key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
end

---@class ghosttext.Request
---@field method string
---@field path string
---@field query table<string, string>
---@field headers table<string, string> lower-cased names

--- Parse a request head (everything before the blank line).
---@param head string
---@return ghosttext.Request?
function M.parse_request(head)
  local lines = vim.split(head, "\r\n", { plain = true })
  local method, target = lines[1]:match("^(%u+) (%S+) HTTP/%d%.%d$")
  if not method then
    return nil
  end
  local path, qs = target:match("^([^?]*)%??(.*)$")
  local query = {}
  for k, v in qs:gmatch("([^&=]+)=([^&]*)") do
    query[k] = v
  end
  local headers = {}
  for i = 2, #lines do
    local name, value = lines[i]:match("^([^:]+):%s*(.-)%s*$")
    if name then
      headers[name:lower()] = value
    end
  end
  return { method = method, path = path, query = query, headers = headers }
end

---@param status string e.g. "200 OK"
---@param body string
---@param content_type? string
function M.response(status, body, content_type)
  return ("HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s"):format(
    status,
    content_type or "text/plain",
    #body,
    body
  )
end

---@param key string
function M.handshake(key)
  return "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
    .. ("Sec-WebSocket-Accept: %s\r\n\r\n"):format(M.accept_key(key))
end

M.op = { continuation = 0, text = 1, binary = 2, close = 8, ping = 9, pong = 10 }

--- Encode one unmasked, unfragmented server frame.
---@param opcode integer
---@param payload string
function M.frame(opcode, payload)
  local n = #payload
  local head
  if n < 126 then
    head = string.char(0x80 + opcode, n)
  elseif n < 65536 then
    head = string.char(0x80 + opcode, 126, math.floor(n / 256), n % 256)
  else
    local len = {}
    for i = 8, 1, -1 do
      len[i] = n % 256
      n = math.floor(n / 256)
    end
    head = string.char(0x80 + opcode, 127, unpack(len))
  end
  return head .. payload
end

local function unmask(s, key)
  local out = {}
  for start = 1, #s, 4096 do
    local bytes = { s:byte(start, math.min(start + 4095, #s)) }
    for i = 1, #bytes do
      bytes[i] = bxor(bytes[i], key[(start + i - 2) % 4 + 1])
    end
    out[#out + 1] = string.char(unpack(bytes))
  end
  return table.concat(out)
end

---@class ghosttext.Frame
---@field fin boolean
---@field opcode integer
---@field payload string

--- Decode the first complete frame in `buf`.
---@param buf string
---@return ghosttext.Frame? frame nil when `buf` doesn't hold a whole frame yet
---@return string rest unconsumed bytes
function M.parse_frame(buf)
  if #buf < 2 then
    return nil, buf
  end
  local b1, b2 = buf:byte(1, 2)
  local len, pos = band(b2, 0x7f), 3
  if len == 126 then
    if #buf < 4 then
      return nil, buf
    end
    local hi, lo = buf:byte(3, 4)
    len, pos = hi * 256 + lo, 5
  elseif len == 127 then
    if #buf < 10 then
      return nil, buf
    end
    len = 0
    for i = 3, 10 do
      len = len * 256 + buf:byte(i)
    end
    pos = 11
  end
  local key
  if band(b2, 0x80) ~= 0 then
    if #buf < pos + 3 then
      return nil, buf
    end
    key = { buf:byte(pos, pos + 3) }
    pos = pos + 4
  end
  if #buf < pos + len - 1 then
    return nil, buf
  end
  local payload = buf:sub(pos, pos + len - 1)
  if key then
    payload = unmask(payload, key)
  end
  return { fin = band(b1, 0x80) ~= 0, opcode = band(b1, 0x0f), payload = payload }, buf:sub(pos + len)
end

return M
