import socket, os, base64, json, struct, time, subprocess, urllib.request
def http(port, path, origin=None):
    req = urllib.request.Request(f"http://127.0.0.1:{port}{path}")
    if origin: req.add_header("Origin", origin)
    try:
        with urllib.request.urlopen(req, timeout=2) as r: return r.status, r.read().decode()
    except urllib.error.HTTPError as e: return e.code, ""
class WS:
    def __init__(s, port, origin="moz-extension://test"):
        s.sock = socket.create_connection(("127.0.0.1", port), timeout=2)
        key = base64.b64encode(os.urandom(16)).decode()
        s.sock.sendall((f"GET / HTTP/1.1\r\nHost: localhost:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\nOrigin: {origin}\r\n\r\n").encode())
        s.buf = b""
        while b"\r\n\r\n" not in s.buf:
            c = s.sock.recv(4096)
            if not c: break
            s.buf += c
        head, _, s.buf = s.buf.partition(b"\r\n\r\n")
        s.status = head.split(b"\r\n")[0].decode()
    def send(s, obj, op=1, raw=None):
        data = raw if raw is not None else json.dumps(obj).encode()
        mask = os.urandom(4); n = len(data)
        hdr = bytes([0x80|op]) + (bytes([0x80|n]) if n<126 else bytes([0x80|126])+struct.pack(">H",n) if n<65536 else bytes([0x80|127])+struct.pack(">Q",n))
        s.sock.sendall(hdr + mask + bytes(b ^ mask[i%4] for i,b in enumerate(data)))
    def recv(s, timeout=0.6):
        s.sock.settimeout(timeout)
        try:
            while True:
                if len(s.buf) >= 2:
                    n = s.buf[1] & 0x7f; p = 2
                    if n == 126: n = struct.unpack(">H", s.buf[2:4])[0]; p = 4
                    elif n == 127: n = struct.unpack(">Q", s.buf[2:10])[0]; p = 10
                    if len(s.buf) >= p+n:
                        op, data = s.buf[0] & 0xf, s.buf[p:p+n]; s.buf = s.buf[p+n:]
                        return op, data
                c = s.sock.recv(65536)
                if not c: return None
                s.buf += c
        except socket.timeout: return "timeout"
    def drain(s):
        out = []
        while True:
            r = s.recv(0.4)
            if r in (None, "timeout"): return out
            out.append(r)
class Nvim:
    def __init__(s, sock): s.sock = sock
    def lua(s, code):
        return subprocess.run(["nvim","--server",s.sock,"--remote-expr",f"luaeval('{code}')"],capture_output=True,text=True).stdout.strip()
    def keys(s, k): subprocess.run(["nvim","--server",s.sock,"--remote-send",k])
