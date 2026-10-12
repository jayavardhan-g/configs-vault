import socket, json


class Marionette:
    def __init__(s, port):
        s.sock = socket.create_connection(("127.0.0.1", port), timeout=90)
        s.id = 0
        s._read()

    def _read(s):
        n = b""
        while not n.endswith(b":"):
            n += s.sock.recv(1)
        n = int(n[:-1])
        data = b""
        while len(data) < n:
            data += s.sock.recv(n - len(data))
        return json.loads(data)

    def cmd(s, name, params=None):
        s.id += 1
        msg = json.dumps([0, s.id, name, params or {}])
        s.sock.sendall(f"{len(msg.encode())}:{msg}".encode())
        while True:
            r = s._read()
            if r[1] == s.id:
                break
        if r[2]:
            raise RuntimeError(f"{name}: {r[2]}")
        return r[3]

    def js(s, script, *args):
        return s.cmd("WebDriver:ExecuteScript", {"script": script, "args": list(args)}).get("value")
