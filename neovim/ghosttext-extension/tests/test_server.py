"""Lua server, one Neovim: sessions, echo suppression, cursor, framing, Origin check.

Run: python3 test_server.py  (needs nvim; uses spare ports, not 4001)
"""
import os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
TMP = tempfile.mkdtemp(prefix="gt-test-")
BOOT = os.path.join(HERE, "boot.lua")
import json, time, subprocess, os
from wsclient import *
PORT=4011; SOCK=os.path.join(TMP, "a.sock")
if os.path.exists(SOCK): os.remove(SOCK)
p = subprocess.Popen(["nvim","--headless","--clean","--listen",SOCK,"-u",BOOT], env={**os.environ,"TEST_PORT":str(PORT)})
time.sleep(0.8); nv = Nvim(SOCK)
def check(name, cond, extra=""): print(("PASS " if cond else "FAIL ")+name, extra if not cond else "")
st, body = http(PORT, "/", "moz-extension://x"); wsport = json.loads(body)["WebSocketPort"]
check("hub answers extension", st==200 and wsport>0)
check("hub rejects web page", http(PORT, "/", "https://evil.example")[0]==403)
evil = WS(wsport, "https://evil.example"); check("ws rejects web page origin", "403" in evil.status, evil.status)
w = WS(wsport); check("ws handshake", "101" in w.status, w.status)
w.send({"text":"int a;\nint b;\nint c;","url":"leetcode.com","title":"t","syntax":"c_cpp","selections":[{"start":9,"end":9}]})
time.sleep(0.3)
check("open: ft from ace hint", nv.lua('vim.bo.filetype')=="cpp", nv.lua('vim.bo.filetype'))
check("open: User event in ghost buf", nv.lua('_G.opened.buf == _G.opened.cur and _G.opened.host') == "leetcode.com")
check("open: cursor placed", nv.lua('vim.api.nvim_win_get_cursor(0)[1]..\",\"..vim.api.nvim_win_get_cursor(0)[2]')=="2,2", nv.lua('vim.inspect(vim.api.nvim_win_get_cursor(0))'))
check("open: nothing echoed", w.drain()==[])
# multi-line change in nvim -> exactly one message with all lines
nv.lua('vim.cmd([[%s#^#// #]])')
msgs = w.drain(); texts=[json.loads(d)["text"] for op,d in msgs if op==1]
check("nvim multi-line edit -> 1 full message", texts==["// int a;\n// int b;\n// int c;"], texts)
# browser burst of 20 updates: no echo, final state applied, minimal diff keeps line-1 mark
nv.lua('vim.api.nvim_buf_set_mark(0, "m", 1, 3, {})')
for i in range(20): w.send({"text":f"// int a;\n// int b{i};\n// int c;","url":"leetcode.com","syntax":"c_cpp"})
time.sleep(0.4)
check("burst applied", nv.lua('table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),\"|\")')=="// int a;|// int b19;|// int c;")
check("burst: no echo", w.drain()==[])
check("minimal diff keeps mark on untouched line", nv.lua('vim.api.nvim_buf_get_mark(0,\"m\")[2]')=="3")
# nvim edit right after burst is NOT swallowed
nv.lua('vim.api.nvim_buf_set_lines(0,2,3,false,{\"int z;\"})')
texts=[json.loads(d)["text"] for op,d in w.drain() if op==1]
check("first nvim edit after browser burst sent", texts==["// int a;\n// int b19;\nint z;"], texts)
# unicode cursor as utf-16 offset
w.send({"text":"తెలుగు😀x","url":"leetcode.com","syntax":"c_cpp"}); time.sleep(0.2)
nv.lua('vim.api.nvim_win_set_cursor(0,{1,#\"తెలుగు😀\"})'); nv.lua('vim.api.nvim_buf_set_text(0,0,#\"తెలుగు😀\",0,#\"తెలుగు😀\",{\"Y\"})')
m=[json.loads(d) for op,d in w.drain() if op==1]
exp=len("తెలుగు😀".encode("utf-16-le"))//2
check("utf-16 cursor offset", m and m[-1]["selections"][0]["start"] in (exp, exp+1), (m, exp))
# language switch follows page; manual override sticks
w.send({"text":"x","url":"leetcode.com","syntax":"python"}); time.sleep(0.2)
check("syntax switch -> python", nv.lua('vim.bo.filetype')=="python")
nv.lua('vim.cmd(\"set ft=lua\")'); w.send({"text":"y","url":"leetcode.com","syntax":"java"}); time.sleep(0.2)
check("manual ft kept", nv.lua('vim.bo.filetype')=="lua")
w.drain()
# fast typing in nvim while the page echoes stale text back: no rewind
w.send({"text":"the quick brown","url":"leetcode.com"}); time.sleep(0.2); w.drain()
nv.lua('vim.api.nvim_win_set_cursor(0,{1,15})')
nv.lua('vim.api.nvim_buf_set_text(0,0,15,0,15,{\" \"})'); time.sleep(0.1)
nv.lua('vim.api.nvim_buf_set_text(0,0,16,0,16,{\"f\"})'); time.sleep(0.1)
w.send({"text":"the quick brown ","url":"leetcode.com"}); time.sleep(0.2)  # stale echo of an earlier send
check("stale echo ignored", nv.lua('vim.api.nvim_get_current_line()')=="the quick brown f", nv.lua('vim.api.nvim_get_current_line()'))
w.drain()
# genuine browser edit before the cursor carries the cursor along
nv.lua('vim.api.nvim_buf_set_lines(0,0,-1,false,{\"the quick brown\"})'); time.sleep(0.2); w.drain()
nv.lua('vim.api.nvim_win_set_cursor(0,{1,15})')
w.send({"text":"XX the quick brown","url":"leetcode.com"}); time.sleep(0.2)
# (normal mode: the cursor sat on the final "n", and must still be on it)
check("cursor follows text after browser insert", nv.lua('vim.api.nvim_win_get_cursor(0)[2]')=="17", nv.lua('vim.api.nvim_win_get_cursor(0)[2]'))
nv.lua('vim.api.nvim_buf_set_text(0,0,18,0,18,{\" fox\"})'); time.sleep(0.2)
check("typing after browser insert lands at the end", nv.lua('vim.api.nvim_get_current_line()')=="XX the quick brown fox")
w.drain()
# an old text is only "stale" for a few seconds: a later real revert still applies
time.sleep(3.2)
w.send({"text":"the quick brown","url":"leetcode.com"}); time.sleep(0.2)
check("old text applies after the echo window", nv.lua('vim.api.nvim_get_current_line()')=="the quick brown", nv.lua('vim.api.nvim_get_current_line()'))
w.drain()
# ping
w.send(None, op=9, raw=b"hi"); r=w.recv(); check("ping->pong", r==(10,b"hi"), r)
# big message (>64k, 16/64-bit length)
big="a"*100000+"\n"+"b"*70000
w.send({"text":big,"url":"leetcode.com"}); time.sleep(0.5)
check("100k message", nv.lua('#vim.api.nvim_buf_get_lines(0,0,-1,false)[1]')=="100000")
# wipe buffer in nvim -> close frame
nv.lua('vim.cmd(\"bwipeout!\")'); r=w.recv(1); check("buffer wipe closes socket", r and r!="timeout" and r[0]==8, r)
# browser close -> buffer wiped
w2=WS(wsport); w2.send({"text":"hello","url":"github.com"}); time.sleep(0.3)
b=nv.lua('vim.api.nvim_get_current_buf()'); check("2nd field no ft", nv.lua('vim.bo.filetype')=="")
w2.send(None, op=8, raw=b"\x03\xe8"); time.sleep(0.3)
check("browser close wipes buffer", nv.lua(f'vim.api.nvim_buf_is_valid({b})')=="false")
check("no sessions left", nv.lua('#require(\"ghosttext\").status().fields')=="0")
p.terminate()
