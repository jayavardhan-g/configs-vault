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

# Checks the link the way a friend's device would: public DNS (not this laptop's
# Tailscale MagicDNS, which always answers), then an HTTPS request to that public address.
function _moviesshare_public_ok
    set -l name (string replace -r '^.*@' '' $moviesshare_host)
    set -l answer (curl -s -m8 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$name&type=A")
    set -l ip (string match -r -g '"data":"([0-9.]+)"' -- $answer)[1]
    test -n "$ip"; or return 1
    set -l code (curl -s -m10 -o /dev/null -w '%{http_code}' --resolve "$name:443:$ip" https://$name/)
    string match -q -r '^[23]' -- $code
end

function _moviesshare_start
    if test (_moviesshare_ssh systemctl is-active jellyfin 2>/dev/null) != active
        echo "Jellyfin isn't running on the server — start it first: sudo systemctl start jellyfin"
        return 1
    end
    # Off then on: after a server reboot Funnel can stay "on" locally without being
    # announced to Tailscale, so the public name disappears. Re-enabling announces it again.
    _moviesshare_ssh tailscale funnel --https=443 off >/dev/null 2>&1
    if not _moviesshare_ssh tailscale funnel --bg 8096 >/dev/null
        echo "couldn't turn sharing on — try 'status'"
        return 1
    end
    echo -n "sharing on, checking the public link"
    for i in (seq 1 12)
        if _moviesshare_public_ok
            echo ""
            echo "link works — send your friend:"
            echo "  "(_moviesshare_url)
            echo "  plus their own Jellyfin username/password"
            return 0
        end
        echo -n "."
        sleep 5
    end
    echo ""
    echo "turned on, but the link isn't reachable from the internet yet — Tailscale can take"
    echo "up to 10 minutes to publish it. Check again with 'status'."
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
        if _moviesshare_public_ok
            echo "sharing:   ON, link works  ("(_moviesshare_url)")"
        else
            echo "sharing:   ON on the server, but NOT reachable from the internet"
            echo "           run 'start' to re-announce it"
        end
    else
        echo "sharing:   off"
    end
    echo "jellyfin:  "(_moviesshare_ssh systemctl is-active jellyfin 2>/dev/null)
end
