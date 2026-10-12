"""Lua server, several Neovims: focus routing, failover, replacing nvim-ghost's old binary.

Run: python3 test_hub.py  (needs nvim; uses spare ports, not 4001)
"""
import os, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
TMP = tempfile.mkdtemp(prefix="gt-test-")
BOOT = os.path.join(HERE, "boot.lua")
import json, time, subprocess, os
from wsclient import *
def check(name, cond, extra=""): print(("PASS " if cond else "FAIL ")+name, extra if not cond else "")
def boot(name, port):
    s=os.path.join(TMP, name+".sock")
    if os.path.exists(s): os.remove(s)
    p=subprocess.Popen(["nvim","--headless","--clean","--listen",s,"-u",BOOT],env={**os.environ,"TEST_PORT":str(port)},stderr=subprocess.DEVNULL)
    time.sleep(0.8); return p, Nvim(s)
PORT=4013
pa, a = boot("a", PORT); pb, b = boot("b", PORT)
sa, sb = [json.loads(n.lua('vim.json.encode(require(\"ghosttext\").status())')) for n in (a,b)]
check("A is hub, B is not", sa["hub"] and not sb["hub"], (sa,sb))
port = lambda: json.loads(http(PORT,"/","moz-extension://x")[1])["WebSocketPort"]
check("last started (B) gets fields", port()==sb["port"])
a.lua('vim.api.nvim_exec_autocmds(\"FocusGained\",{})'); time.sleep(0.3)
check("focus A -> A gets fields", port()==sa["port"])
b.lua('vim.api.nvim_exec_autocmds(\"FocusGained\",{})'); time.sleep(0.3)
pb.kill(); time.sleep(0.3)
check("focused B died -> falls back to hub A", port()==sa["port"])
pb, b = boot("b", PORT); pa.kill(); time.sleep(4)
sb=json.loads(b.lua('vim.json.encode(require(\"ghosttext\").status())'))
check("hub died -> B takes over port", sb["hub"] and port()==sb["port"], sb)
pb.kill()
# legacy nvim-ghost binary on a test port gets replaced
bin_=os.path.expanduser("~/.local/share/nvim/lazy/nvim-ghost.nvim/nvim-ghost-binary")
if not os.path.exists(bin_):
    print("SKIP legacy takeover (nvim-ghost binary not installed)")
    sys.exit(0)
LP=4014; leg_sock=os.path.join(TMP, "leg.sock")
if os.path.exists(leg_sock): os.remove(leg_sock)
pl=subprocess.Popen(["nvim","--headless","--clean","--listen",leg_sock],stderr=subprocess.DEVNULL); time.sleep(0.5)
pg=subprocess.Popen([bin_],env={**os.environ,"GHOSTTEXT_SERVER_PORT":str(LP),"NVIM_LISTEN_ADDRESS":leg_sock},stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); time.sleep(1.5)
check("legacy binary running", http(LP,"/is_ghost_binary")[1]=="True")
pc, c = boot("c", LP); time.sleep(1.5)
sc=json.loads(c.lua('vim.json.encode(require(\"ghosttext\").status())'))
check("legacy binary replaced", sc["hub"] and pg.poll() is not None, (sc, pg.poll()))
for p in (pc,pl):
    p.kill()
if pg.poll() is None: pg.kill()
