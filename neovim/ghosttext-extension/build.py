#!/usr/bin/env python3
"""Build the patched GhostText extension from an upstream .xpi.

    python3 build.py <upstream ghosttext.xpi> [out.xpi]

The upstream build is minified, so the patches are exact string replacements;
each must match exactly once or the build stops - after an upstream update,
re-check the failing pattern against the new ghost-text.js / background.js.
See README.md for what each patch fixes.
"""

import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
UPSTREAM_VERSION = "26.5.12"
PATCH_LEVEL = "2"
ADDON_ID = "ghosttext-patched@configs.local"
NAME = "GhostText (patched)"

# Helpers injected at the top of the content script's main module. They live in
# the same scope as the field wrappers (class `d` = contenteditable wrapper).
HELPERS = r"""
function gtDiff(a,b){const m=Math.min(a.length,b.length);let s=0;for(;s<m&&a.charCodeAt(s)===b.charCodeAt(s);)s++;s>0&&a.charCodeAt(s-1)>=55296&&a.charCodeAt(s-1)<=56319&&s--;let e=0;for(;e<m-s&&a.charCodeAt(a.length-1-e)===b.charCodeAt(b.length-1-e);)e++;e>0&&a.charCodeAt(a.length-e)>=56320&&a.charCodeAt(a.length-e)<=57343&&e--;return{from:s,to:a.length-e,insert:b.slice(s,b.length-e)}}
function gtCeText(root){const blocks=/^(P|DIV|LI|H[1-6]|BLOCKQUOTE|PRE|UL|OL|TR|TABLE|SECTION|ARTICLE|HEADER|FOOTER)$/;let out="";const walk=n=>{for(const c of n.childNodes)if(c.nodeType===3)out+=c.data;else if(c.nodeName==="BR")out+="\n";else if(c.nodeType===1){const b=blocks.test(c.nodeName);b&&out&&!out.endsWith("\n")&&(out+="\n");walk(c);b&&!out.endsWith("\n")&&(out+="\n")}};walk(root);return out.replace(/[​﻿]/g,"").replace(/ /g," ").replace(/\n$/,"")}
function gtWrite(field,text){
if(field instanceof d){const el=field.el;if(gtCeText(el)===text)return;el.focus({preventScroll:!0});getSelection().selectAllChildren(el);
document.execCommand(text?"insertText":"delete",!1,text)||(el.innerText=text);return}
const el=field,old=el.value;if(old===text)return;const{from,to,insert}=gtDiff(old,text);
try{document.activeElement!==el&&el.focus({preventScroll:!0});el.setSelectionRange(from,to);if(document.execCommand(insert?"insertText":"delete",!1,insert)&&el.value===text)return}catch{}
el.value=text;el.dispatchEvent(new Event("input",{bubbles:!0}))}
""".strip()

GHOST_TEXT_PATCHES = [
    (
        "inject helpers",
        's("8LEgM",function(t,i){let n;',
        's("8LEgM",function(t,i){let n;\n' + HELPERS + "\n",
    ),
    (
        # rich editors keep their own model; read plain text and write through
        # real input (see gtWrite) instead of innerHTML both ways
        "contenteditable as plain text",
        "class d{get value(){return this.el.innerHTML}set value(e){this.el.innerHTML=e}",
        "class d{get value(){return gtCeText(this.el)}set value(e){gtWrite(this,e)}",
    ),
    (
        "keep the editor's language from the page bridge",
        'this.el.addEventListener("gt:input",e=>{this._value=e.detail.value})',
        'this.el.addEventListener("gt:input",e=>{this._value=e.detail.value,this.syntax=e.detail.syntax||""})',
    ),
    (
        "send the language, and don't echo our own writes",
        'if(!(e&&e.detail?.ghostTextSyntheticEvent)){',
        'if(!this.applying&&!(e&&e.detail?.ghostTextSyntheticEvent)){',
    ),
    (
        "send the language",
        'syntax:"",text:this.field.value',
        'syntax:this.field.syntax||"",text:this.field.value',
    ),
    (
        # was: field.value = text + fake keydown/keypress/textInput/input/keyup
        "write fields through real input events",
        'this.field.value=t.text,this.field.dispatchEvent&&(this.field.dispatchEvent(new KeyboardEvent("keydown"),c),'
        'this.field.dispatchEvent(new KeyboardEvent("keypress"),c),this.field.dispatchEvent(new CompositionEvent("textInput"),c),'
        'this.field.dispatchEvent(new CustomEvent("input",{...c,detail:{ghostTextSyntheticEvent:!0}})),'
        'this.field.dispatchEvent(new KeyboardEvent("keyup"),c))',
        "this.field instanceof f?this.field.value=t.text:(this.applying=!0,gtWrite(this.field,t.text),this.applying=!1)",
    ),
    (
        "keep-alive only while connected",
        'globalThis.gtInterval??=setInterval(()=>{chrome.runtime.sendMessage({code:"Keep alive"})},5e3)',
        'globalThis.gtInterval??=setInterval(()=>{l.size&&chrome.runtime.sendMessage({code:"Keep alive"})},5e3)',
    ),
]

BACKGROUND_PATCHES = [
    (
        # the minifier renamed stopGT() to l() inside the injected function, so
        # "Disconnect GhostText on this page" and the close shortcut threw
        "disconnect actually disconnects",
        "func:()=>l()",
        "func:()=>stopGT()",
    ),
    (
        # a refused WebSocket still reported "ready", then silently disconnected
        "report a WebSocket that never opened",
        'await Promise.race([(0,i.default)(a,"open"),(0,i.default)(a,"error")]);',
        'await Promise.race([(0,i.default)(a,"open"),(0,i.default)(a,"error")]);'
        'if(a.readyState!==WebSocket.OPEN)throw Error("Could not connect to the server.");',
    ),
]


def patch(path: Path, patches):
    text = path.read_text()
    for name, old, new in patches:
        count = text.count(old)
        if count != 1:
            sys.exit(f"{path.name}: patch '{name}' matched {count} times (expected 1)")
        text = text.replace(old, new)
    path.write_text(text)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    upstream = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE / f"ghosttext-patched-{UPSTREAM_VERSION}.{PATCH_LEVEL}.xpi"

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        with zipfile.ZipFile(upstream) as z:
            z.extractall(root)
        shutil.rmtree(root / "META-INF", ignore_errors=True)  # upstream signature

        manifest = json.loads((root / "manifest.json").read_text())
        if manifest["version"] != UPSTREAM_VERSION:
            sys.exit(f"upstream is {manifest['version']}, patches target {UPSTREAM_VERSION}")
        manifest["name"] = NAME
        manifest["version"] = f"{UPSTREAM_VERSION}.{PATCH_LEVEL}"
        manifest["browser_specific_settings"]["gecko"]["id"] = ADDON_ID
        (root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

        patch(root / "ghost-text.js", GHOST_TEXT_PATCHES)
        for background in root.glob("background*.js"):  # Firefox script + Chrome worker copy
            patch(background, BACKGROUND_PATCHES)
        shutil.copy(HERE / "advanced-editors-messenger.js", root / "advanced-editors-messenger.js")

        out.unlink(missing_ok=True)
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            for file in sorted(root.rglob("*")):
                if file.is_file():
                    z.write(file, file.relative_to(root).as_posix())
    print(out)


if __name__ == "__main__":
    main()
