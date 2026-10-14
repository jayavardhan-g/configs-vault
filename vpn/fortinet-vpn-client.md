# Fortinet SSL-VPN client (openfortivpn)

**Date:** 2026-08-28
**Category:** system
**Files touched:** `~/.config/openfortivpn/config`, `~/.config/fish/functions/labvpn.fish`

<!-- graph:begin -->
**Graph:** [[fish]] · [[SSH]] · [[Fortinet VPN]]
<!-- graph:end -->

## What
Set up `openfortivpn` (lightweight CLI Fortinet SSL-VPN client) plus a `labvpn` fish
function: `labvpn start|stop|status|log` runs one command and returns, and plain `labvpn`
opens an interactive prompt. The VPN needed to reach a lab SSH/GPU server can be brought
up or down with minimal typing, from any terminal, which can then be closed.

## Why
User needs to connect through a Fortinet VPN before SSHing into a lab GPU server for
coursework. Wanted this minimal — small commands to start/stop, run from a terminal that
gets pushed to a background Hyprland workspace — rather than the full FortiClient GUI
client.

## Change

Install:
```
sudo pacman -S openfortivpn
```

`~/.config/openfortivpn/config` (create, then `chmod 600` — it holds the VPN password in
plaintext):
```
host = <vpn-host>
port = <vpn-port>
username = <username>
password = <password>
trusted-cert = <sha256 digest — see Notes>
```

`~/.config/fish/functions/labvpn.fish` (autoloaded automatically by fish — no `source`
needed):
```fish
function labvpn --description 'Control the lab VPN (openfortivpn): labvpn [start|stop|status|log]'
    set -l config_path ~/.config/openfortivpn/config
    set -l log_path ~/.cache/openfortivpn.log

    if not test -f $config_path
        echo "No config at $config_path — see setup notes."
        return 1
    end

    # One-shot: `labvpn start` etc. runs the command and returns.
    if set -q argv[1]
        switch $argv[1]
            case start
                _labvpn_start $config_path $log_path
            case stop
                _labvpn_stop
            case status
                _labvpn_status
            case log
                tail -n 20 -f $log_path
            case '*'
                echo "usage: labvpn [start|stop|status|log]   (no argument = interactive prompt)"
                return 1
        end
        return
    end

    # No argument: interactive prompt.
    echo "labvpn — commands: start, stop, status, log, exit"
    while true
        read -P "labvpn> " -l cmd
        switch $cmd
            case start
                _labvpn_start $config_path $log_path
            case stop
                _labvpn_stop
            case status
                _labvpn_status
            case log
                echo "tailing $log_path — ctrl-c to return"
                tail -n 20 -f $log_path
            case exit quit q
                break
            case ''
                continue
            case '*'
                echo "unknown command '$cmd' — try: start, stop, status, log, exit"
        end
    end
end

function _labvpn_start
    set -l config_path $argv[1]
    set -l log_path $argv[2]

    if pgrep -x openfortivpn >/dev/null
        echo "already running"
        return 0
    end

    touch $log_path
    # Fully detach from this terminal: stdin from /dev/null and a new session
    # (setsid). Before, the root openfortivpn kept the terminal as its stdin, so
    # the window couldn't close after `exit`. sudo still prompts for the password
    # (it reads /dev/tty, not stdin).
    sudo -b setsid openfortivpn -c $config_path </dev/null >>$log_path 2>&1
    echo -n "connecting"

    for i in (seq 1 20)
        if grep -q "Tunnel is up and running." $log_path
            echo ""
            echo "connected"
            return 0
        end
        echo -n "."
        sleep 1
    end
    echo ""
    echo "still connecting (or stuck) — check 'log' or 'status'"
end

function _labvpn_stop
    if not pgrep -x openfortivpn >/dev/null
        echo "not running"
        return 0
    end
    sudo pkill -x openfortivpn
    echo "stop signal sent"
end

function _labvpn_status
    if pgrep -x openfortivpn >/dev/null
        set -l pid (pgrep -x openfortivpn)
        echo "process:   running (pid $pid)"
    else
        echo "process:   not running"
    end

    set -l ppp_if (ip -o link show 2>/dev/null | string match -r 'ppp[0-9]+' | head -n 1)
    if test -n "$ppp_if"
        set -l ip_addr (ip -4 -o addr show $ppp_if 2>/dev/null | string match -r 'inet [0-9.]+' | string replace 'inet ' '')
        echo "interface: $ppp_if up ($ip_addr)"
    else
        echo "interface: none"
    end
end
```

## Notes
- **[`files/.config/openfortivpn/config`](files/.config/openfortivpn/config)** is a real
  copy of the live file's structure, but `host`/`username`/`password`/`trusted-cert` are
  placeholders — those are this specific VPN gateway's real credentials, not part of the
  setup being documented.
  [`files/.config/fish/functions/labvpn.fish`](files/.config/fish/functions/labvpn.fish)
  has no secrets and is copied as-is.
- **First connect must be done manually, in the foreground**, to accept the gateway's TLS
  certificate:
  ```
  sudo openfortivpn -c ~/.config/openfortivpn/config
  ```
  Answer `y` to the trust prompt, then copy the printed sha256 digest into the config's
  `trusted-cert` line. Automated `start` runs fully detached (`sudo -b`, no TTY) and would
  hang forever on that prompt without a pre-trusted cert — this is a one-time step per
  gateway.
- This version of openfortivpn (1.24.1) has no `--daemon` flag; backgrounding is done
  manually via `sudo -b` + log redirection to `~/.cache/openfortivpn.log`.
- The interface it brings up is named `ppp0` (via `pppd`), not `tun0` — `_labvpn_status`
  greps for `ppp[0-9]+` accordingly.
- **Terminal wouldn't close after `start` (fixed 2026-10-10).** The original start line was
  `sudo -b openfortivpn … >>log 2>&1`. That redirects output but not input, so the root
  `openfortivpn` kept the terminal as its stdin (`ps` showed `TT pts/1`). The window then
  waited forever after `exit`, and force-closing didn't stop the VPN, since the root
  process survives the hang-up. Fix: `sudo -b setsid openfortivpn … </dev/null`, which
  gives it a new session with no terminal. The VPN never needed the terminal open.
- **One-shot subcommands added the same day** (`labvpn start` etc.), as the user
  asked; the no-argument prompt is kept.
- `sudo -b` still needs a sudo password on `start`; it's cached (~15 min, default sudo
  timestamp) so `stop`/subsequent `start` calls in the same terminal session usually don't
  re-prompt.
