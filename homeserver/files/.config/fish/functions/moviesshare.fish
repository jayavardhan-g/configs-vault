function moviesshare --description 'Interactive control for sharing Jellyfin publicly (Tailscale Funnel on the home server)'
    if not set -q moviesshare_host
        echo "Server not set. Run once:  set -U moviesshare_host <user>@<nas>.<tailnet>.ts.net"
        return 1
    end

    echo "moviesshare — commands: start, stop, status, link, exit"
    while true
        read -P "moviesshare> " -l cmd
        switch $cmd
            case start
                _moviesshare_start
            case stop
                _moviesshare_stop
            case status
                _moviesshare_status
            case link
                echo (_moviesshare_url)
            case exit quit q
                break
            case ''
                continue
            case '*'
                echo "unknown command '$cmd' — try: start, stop, status, link, exit"
        end
    end
end

function _moviesshare_ssh
    ssh -o BatchMode=yes -o ConnectTimeout=8 $moviesshare_host $argv
end

function _moviesshare_url
    echo https://(string replace -r '^.*@' '' $moviesshare_host)
end

function _moviesshare_start
    if test (_moviesshare_ssh systemctl is-active jellyfin 2>/dev/null) != active
        echo "Jellyfin isn't running on the server — start it first: sudo systemctl start jellyfin"
        return 1
    end
    if _moviesshare_ssh tailscale funnel --bg 8096 >/dev/null
        echo "sharing on — send your friend:"
        echo "  "(_moviesshare_url)
        echo "  plus their own Jellyfin username/password"
    else
        echo "couldn't turn sharing on — try 'status'"
    end
end

function _moviesshare_stop
    if _moviesshare_ssh tailscale funnel --https=443 off >/dev/null 2>&1
        echo "sharing off — the public link no longer works"
    else
        echo "couldn't reach the server (or sharing was already off) — try 'status'"
    end
end

function _moviesshare_status
    set -l out (_moviesshare_ssh tailscale funnel status 2>&1)
    if test $status -ne 0
        echo "server:    unreachable"
        return 1
    end
    if string match -q '*Funnel on*' -- $out
        echo "sharing:   ON  ("(_moviesshare_url)")"
    else
        echo "sharing:   off"
    end
    echo "jellyfin:  "(_moviesshare_ssh systemctl is-active jellyfin 2>/dev/null)
end
