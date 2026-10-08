#!/usr/bin/env python3
"""Laptop side of Focus sync with the phone app (Sync).

Pomo.qml runs this; it never touches the timer itself, it only carries
messages. Two one-way lanes, so nobody hears their own messages back:

  phone  -> laptop   the phone posts to this laptop's private ntfy channel,
                     which `listen` reads and prints, one JSON per line.
  laptop -> phone    `send` posts to the phone's UnifiedPush address (the
                     ntfy app on the phone), learnt from the phone's hello.

Every message is encrypted with the pairing key, so ntfy.sh only sees
ciphertext. Byte for byte the same scheme as the phone's SyncCrypto.kt:
AES-256-CBC then HMAC-SHA256 (encrypt-then-MAC), keys derived from the one
32-byte pairing key, wire = base64url(0x01 | iv | ciphertext | hmac).
Only the standard library and the `openssl` command are needed.

  pomo-sync.py pair [--new]   print the pairing link, write its QR code
  pomo-sync.py send MSG...    encrypt and send JSON messages to the phone
  pomo-sync.py listen         print the phone's messages, forever
  pomo-sync.py status         print pairing status as one JSON line
  pomo-sync.py unpair         tell the phone, forget it, retire the key
"""
import base64
import hashlib
import hmac
import json
import os
import secrets
import socket
import subprocess
import sys
import time
import urllib.parse
import urllib.request

DATA = os.path.expanduser("~/.local/share/pomodoro")
STATE = os.path.join(DATA, "sync.json")
QR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "pomo-pair.png")
SERVER = "https://ntfy.sh"
VERSION = 1
DEVICE = "laptop"


# ── crypto ──

def b64e(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def b64d(s: str) -> bytes:
    s = s.strip()
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def derive(key: bytes, label: str) -> bytes:
    return hmac.new(key, label.encode(), hashlib.sha256).digest()


def aes(data: bytes, key: bytes, iv: bytes, decrypt: bool) -> bytes:
    cmd = ["openssl", "enc", "-aes-256-cbc", "-K", key.hex(), "-iv", iv.hex()]
    if decrypt:
        cmd.insert(2, "-d")
    return subprocess.run(cmd, input=data, capture_output=True, check=True).stdout


def encrypt(plain: str, key: bytes, iv: bytes = None) -> str:
    iv = iv or secrets.token_bytes(16)
    body = bytes([VERSION]) + iv + aes(plain.encode(), derive(key, "sync-focus-enc"), iv, False)
    return b64e(body + hmac.new(derive(key, "sync-focus-mac"), body, hashlib.sha256).digest())


def decrypt(wire: str, key: bytes):
    try:
        raw = b64d(wire)
        if len(raw) < 1 + 16 + 16 + 32 or raw[0] != VERSION:
            return None
        body, tag = raw[:-32], raw[-32:]
        if not hmac.compare_digest(tag, hmac.new(derive(key, "sync-focus-mac"), body, hashlib.sha256).digest()):
            return None
        return aes(body[17:], derive(key, "sync-focus-enc"), body[1:17], True).decode()
    except Exception:
        return None


# ── state ──

def load() -> dict:
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(state: dict) -> None:
    os.makedirs(DATA, exist_ok=True)
    tmp = STATE + ".tmp"
    with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(state, f, indent=1)
    os.replace(tmp, STATE)


def emit(obj: dict) -> None:
    print(json.dumps(obj), flush=True)


def status_line(state: dict) -> dict:
    phone = state.get("phone") or {}
    return {"type": "status", "paired": bool(phone.get("endpoint")), "phone": phone.get("name"),
            "lastHeard": state.get("lastHeard", 0), "pairing": bool(state.get("topic"))}


def envelope(msg: dict, state: dict) -> dict:
    return {"v": VERSION, "from": DEVICE, "name": state.get("name") or socket.gethostname(), **msg}


def post(url: str, body: str) -> bool:
    try:
        req = urllib.request.Request(url, data=body.encode(), method="POST", headers={"Content-Type": "text/plain"})
        with urllib.request.urlopen(req, timeout=10) as r:
            return 200 <= r.status < 300
    except Exception:
        return False


# ── commands ──

def cmd_pair(new: bool) -> None:
    state = load()
    if new or not state.get("topic") or not state.get("key"):
        state = {"topic": "pomo-" + secrets.token_urlsafe(18), "key": b64e(secrets.token_bytes(32)),
                 "server": SERVER, "name": socket.gethostname()}
        save(state)
    url = "sync://pair?" + urllib.parse.urlencode({
        "v": VERSION, "name": state["name"], "topic": state["topic"], "key": state["key"], "server": state["server"]})
    subprocess.run(["qrencode", "-s", "8", "-m", "2", "-o", QR, url], check=True)
    os.chmod(QR, 0o600)
    emit({"type": "pairing", "url": url, "qr": QR})


def cmd_send(raw: list) -> None:
    state = load()
    endpoint = (state.get("phone") or {}).get("endpoint")
    if not endpoint or not state.get("key"):
        return
    key = b64d(state["key"])
    for one in raw:
        post(endpoint, encrypt(json.dumps(envelope(json.loads(one), state)), key))


def cmd_listen() -> None:
    while True:
        state = load()
        emit(status_line(state))
        if not state.get("topic") or not state.get("key"):
            time.sleep(5)
            continue
        key = b64d(state["key"])
        since = state.get("since") or "12h"
        url = f'{state["server"]}/{state["topic"]}/json?since={since}'
        try:
            with urllib.request.urlopen(url, timeout=90) as stream:
                for line in stream:
                    event = json.loads(line)
                    if event.get("event") != "message":
                        # Keepalives; also notice an unpair done from the panel.
                        if load().get("topic") != state.get("topic"):
                            break
                        continue
                    state = load()
                    state["since"] = event["id"]
                    text = decrypt(event.get("message", ""), key)
                    msg = json.loads(text) if text else None
                    if not msg or msg.get("v") != VERSION or msg.get("from") == DEVICE:
                        save(state)
                        continue
                    state["lastHeard"] = int(time.time() * 1000)
                    kind = msg.get("type")
                    if kind == "hello" and msg.get("endpoint"):
                        state["phone"] = {"endpoint": msg["endpoint"], "name": msg.get("name") or "Phone"}
                        save(state)
                        post(msg["endpoint"], encrypt(json.dumps(envelope({"type": "welcome"}, state)), key))
                    elif kind == "unpair":
                        state.pop("phone", None)
                        state["key"] = b64e(secrets.token_bytes(32))
                        state["topic"] = "pomo-" + secrets.token_urlsafe(18)
                        state.pop("since", None)
                    save(state)
                    emit(msg)
                    emit(status_line(state))
                    if kind == "unpair":
                        break
        except Exception:
            time.sleep(5)


def cmd_unpair() -> None:
    state = load()
    cmd_send([json.dumps({"type": "unpair"})])
    # Retire the key and channel too: an old QR code must not pair again.
    save({})
    emit(status_line({}))


def main() -> None:
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args[0] == "pair":
        cmd_pair("--new" in args)
    elif args[0] == "send":
        cmd_send(args[1:])
    elif args[0] == "listen":
        cmd_listen()
    elif args[0] == "status":
        emit(status_line(load()))
    elif args[0] == "unpair":
        cmd_unpair()
    elif args[0] == "vector":
        # A fixed-key, fixed-IV sample for the phone's unit tests.
        print(encrypt(args[1], bytes(range(32)), bytes(range(16))))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
