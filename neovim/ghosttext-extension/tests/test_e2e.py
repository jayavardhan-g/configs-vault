"""End-to-end: headless Firefox + GhostText build + Lua server in headless nvim.

usage: python3 test_e2e.py <xpi> <label>     (ONLY=ace,monaco to pick pages)
Needs firefox (any build: the add-on is loaded as a temporary one), nvim, and
network access for the editors' CDN builds. Uses ports 4021/8123/2829.
"""
import json, os, shutil, subprocess, sys, tempfile, time, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from marionette import Marionette
from wsclient import Nvim

HERE = os.path.dirname(os.path.abspath(__file__))
XPI, LABEL = sys.argv[1], sys.argv[2]
GT_PORT, WEB_PORT, MN_PORT = 4021, 8123, 2829
results = []


def check(name, cond, extra=""):
    results.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name, "" if cond else extra, flush=True)


def wait(fn, timeout=8, step=0.1):
    end = time.time() + timeout
    while time.time() < end:
        try:
            v = fn()
            if v:
                return v
        except Exception:
            pass
        time.sleep(step)
    return None


# test copy of the extension: point it at the test server port
ext_dir = tempfile.mkdtemp(prefix=f"gt-{LABEL}-")
with zipfile.ZipFile(XPI) as z:
    z.extractall(ext_dir)
shutil.rmtree(os.path.join(ext_dir, "META-INF"), ignore_errors=True)
n = 0
for f in os.listdir(ext_dir):
    if f.endswith(".js"):
        p = os.path.join(ext_dir, f)
        s = open(p).read()
        n += s.count("serverPort:4001")
        open(p, "w").write(s.replace("serverPort:4001", f"serverPort:{GT_PORT}"))
assert n >= 2, n
ext_id = json.load(open(os.path.join(ext_dir, "manifest.json")))["browser_specific_settings"]["gecko"]["id"]


procs = []
procs.append(subprocess.Popen([sys.executable, "-m", "http.server", str(WEB_PORT), "--directory", os.path.join(HERE, "site")],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
sock = os.path.join(ext_dir, "nvim.sock")
if os.path.exists(sock):
    os.remove(sock)
procs.append(subprocess.Popen(["nvim", "--headless", "--clean", "--listen", sock, "-u", os.path.join(HERE, "boot.lua")],
                              env={**os.environ, "TEST_PORT": str(GT_PORT)}, stderr=subprocess.DEVNULL))
profile = tempfile.mkdtemp(prefix="ffprof-")
open(os.path.join(profile, "user.js"), "w").write(f"""
user_pref("marionette.port", {MN_PORT});
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("extensions.originControls.grantByDefault", true);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
""")
procs.append(subprocess.Popen(["firefox", "--headless", "--marionette", "--remote-allow-system-access", "--no-remote", "--profile", profile],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
time.sleep(1)
nv = Nvim(sock)
m = wait(lambda: Marionette(MN_PORT), 30, 0.5)
m.cmd("WebDriver:NewSession", {"capabilities": {}})
m.cmd("Addon:Install", {"path": ext_dir, "temporary": True})


def buf_text():
    return nv.lua('table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),\"\\n\")')


def nvim_set(text):
    nv.lua(f'vim.api.nvim_buf_set_lines(0,0,-1,false,vim.split({json.dumps(text)!r}:sub(2,-2):gsub(\"\\\\n\",\"\\n\"),\"\\n\"))')


def nvim_set_lines(lines):
    # lines -> lua table literal
    lua = "{" + ",".join(json.dumps(l) for l in lines) + "}"
    nv.lua(f"vim.api.nvim_buf_set_lines(0,0,-1,false,{lua})".replace("'", "\\'"))


def type_into(selector, text):
    el = m.cmd("WebDriver:FindElement", {"using": "css selector", "value": selector})["value"]
    m.cmd("WebDriver:ElementSendKeys", {"id": list(el.values())[0], "text": text})


def open_page(name):
    opened_before = nv.lua("_G.opened and _G.opened.buf or 0")
    m.cmd("WebDriver:Navigate", {"url": f"http://localhost:{WEB_PORT}/{name}.html"})
    assert wait(lambda: m.js("return window.ready === true"), 30), f"{name} never got ready"
    time.sleep(0.3)
    m.cmd("Marionette:SetContext", {"value": "chrome"})
    m.js(f"""
      const {{ ExtensionParent }} = ChromeUtils.importESModule("resource://gre/modules/ExtensionParent.sys.mjs");
      const ext = ExtensionParent.GlobalManager.getExtension({json.dumps(ext_id)});
      ExtensionParent.apiManager.global.browserActionFor(ext).triggerAction(window);
    """)
    m.cmd("Marionette:SetContext", {"value": "content"})
    ok = wait(lambda: nv.lua("_G.opened and _G.opened.buf or 0") != opened_before, 10)
    check(f"{name}: field connects", ok, m.js("return [...document.querySelectorAll('[data-gt-field]')].map(e => e.className + '=' + e.dataset.gtField).join(' ')"))
    time.sleep(0.5)


ONLY = os.environ.get("ONLY")
try:
    # ---- Ace: the reported "only one line commented" bug
    if not ONLY or "ace" in ONLY.split(","):
        open_page("ace")
        check("ace: initial text in nvim", buf_text() == "int a;\nint b;\nint c;", buf_text())
        check("ace: language -> ft cpp", nv.lua("vim.bo.filetype") == "cpp", nv.lua("vim.bo.filetype"))
        m.js("editor.selectAll(); editor.execCommand('togglecomment');")
        time.sleep(0.6)
        check("ace: multi-line comment reaches nvim", buf_text() == "// int a;\n// int b;\n// int c;", repr(buf_text()))
        m.js("editor.session.insert({row: 0, column: 0}, 'X');")  # page-made change, not a command
        time.sleep(0.6)
        check("ace: page-made change reaches nvim", buf_text().startswith("X// int a;"), repr(buf_text()))
        m.js("editor.session.getUndoManager().reset(); editor.clearSelection(); editor.moveCursorTo(2, 3);")
        nvim_set_lines(["X// int a;", "// int b;", "// int c; // from nvim"])
        time.sleep(0.6)
        check("ace: nvim edit applied", m.js("return editor.getValue()") == "X// int a;\n// int b;\n// int c; // from nvim", m.js("return editor.getValue()"))
        check("ace: browser undo still works after nvim edit", m.js("return editor.session.getUndoManager().hasUndo()"))
        check("ace: cursor not reset to top", m.js("return editor.getCursorPosition().row") != 0, m.js("return editor.getCursorPosition()"))

    # ---- Monaco
    if not ONLY or "monaco" in ONLY.split(","):
        open_page("monaco")
        check("monaco: language -> ft cpp", nv.lua("vim.bo.filetype") == "cpp", nv.lua("vim.bo.filetype"))
        m.js("editor.setSelection(editor.getModel().getFullModelRange()); editor.trigger('t', 'editor.action.commentLine');")
        time.sleep(0.6)
        check("monaco: multi-line comment reaches nvim", buf_text() == "// int a;\n// int b;\n// int c;", repr(buf_text()))
        nvim_set_lines(["// int a;", "// int b;", "int c; // from nvim"])
        time.sleep(0.6)
        check("monaco: nvim edit applied", m.js("return editor.getValue()") == "// int a;\n// int b;\nint c; // from nvim", m.js("return editor.getValue()"))
        check("monaco: browser undo kept", m.js("return editor.getModel().canUndo()"))

    # ---- CodeMirror 6
    if not ONLY or "cm6" in ONLY.split(","):
        open_page("cm6")
        check("cm6: initial", buf_text() == "a = 1\nb = 2", m.js("const c=document.querySelector('.cm-content'); return JSON.stringify([typeof c.cmView, c.cmView && Object.getOwnPropertyNames(c.cmView).join(','), typeof (c.cmView && c.cmView.view), Object.getOwnPropertyNames(c).join(',')])"))
        check("cm6: language -> ft python", nv.lua("vim.bo.filetype") == "python", nv.lua("vim.bo.filetype"))
        m.js("view.dispatch({changes: {from: 0, insert: '# hi\\n'}})")
        t0 = time.time()
        ok = wait(lambda: buf_text() == "# hi\na = 1\nb = 2", 3, 0.02)
        check("cm6: browser edit reaches nvim", ok, repr(buf_text()))
        check("cm6: latency < 400ms", ok and time.time() - t0 < 0.4, time.time() - t0)
        nvim_set_lines(["# hi", "a = 10", "b = 2"])
        check("cm6: nvim edit applied", wait(lambda: m.js("return view.state.doc.toString()") == "# hi\na = 10\nb = 2", 3), m.js("return view.state.doc.toString()"))

    # ---- React textarea + Escape re-render
    if not ONLY or "react" in ONLY.split(","):
        open_page("react")
        nvim_set_lines(["hello from", "nvim"])
        time.sleep(0.6)
        check("react: DOM updated", m.js("return document.getElementById('ta').value") == "hello from\nnvim")
        check("react: React state updated", m.js("return window.reactState") == "hello from\nnvim", m.js("return window.reactState"))
        el = m.cmd("WebDriver:FindElement", {"using": "css selector", "value": "#ta"})["value"]
        m.cmd("WebDriver:ElementSendKeys", {"id": list(el.values())[0], "text": "\ue00c"})  # Escape
        time.sleep(0.4)
        check("react: text survives Escape re-render", m.js("return document.getElementById('ta').value") == "hello from\nnvim", m.js("return document.getElementById('ta').value"))

    # ---- ProseMirror
    if not ONLY or "prosemirror" in ONLY.split(","):
        open_page("prosemirror")
        nvim_set_lines(["first line", "second <b>line</b> & co"])
        time.sleep(0.8)
        check("prosemirror: editor model updated", m.js("return pmText()") == "first line\nsecond <b>line</b> & co", repr(m.js("return pmText()")))
        type_into(".ProseMirror", "!")
        time.sleep(0.6)
        check("prosemirror: browser edit reaches nvim as plain text", buf_text() == "first line\nsecond <b>line</b> & co!", repr(buf_text()))

    # ---- Lexical
    if not ONLY or "lexical" in ONLY.split(","):
        open_page("lexical")
        nvim_set_lines(["lexical one", "lexical two"])
        time.sleep(0.8)
        check("lexical: editor model updated", (m.js("return lexText()") or "").replace("\n\n", "\n") == "lexical one\nlexical two", repr(m.js("return lexText()")))
        check("lexical: nvim keeps its text", buf_text() == "lexical one\nlexical two", repr(buf_text()))
        type_into("#ed", "!")
        time.sleep(0.6)
        check("lexical: typing reaches nvim", buf_text() == "lexical one\nlexical two!", repr(buf_text()))
        nvim_set_lines(["replaced"])
        time.sleep(0.8)
        check("lexical: second write replaces", m.js("return lexText()") == "replaced", repr(m.js("return lexText()")))

    # ---- plain contenteditable
    if not ONLY or "plain-ce" in ONLY.split(","):
        open_page("plain-ce")
        check("plain-ce: read as text", buf_text() == "start", repr(buf_text()))
        nvim_set_lines(["a < b", "c"])
        time.sleep(0.6)
        check("plain-ce: '<' stays text, newline kept", m.js("return document.getElementById('ed').innerText.trim()") == "a < b\nc", repr(m.js("return document.getElementById('ed').innerText")))

finally:
    passed = sum(ok for _, ok in results)
    print(f"== {LABEL}: {passed}/{len(results)} passed")
    try:
        m.cmd("Marionette:Quit")
    except Exception:
        pass
    for p in procs:
        p.kill()
    shutil.rmtree(profile, ignore_errors=True)
    shutil.rmtree(ext_dir, ignore_errors=True)
    sys.exit(0 if results and all(ok for _, ok in results) else 1)
