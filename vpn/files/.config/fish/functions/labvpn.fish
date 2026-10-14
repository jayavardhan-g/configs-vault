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
