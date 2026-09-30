# Sourced by install.sh / uninstall.sh.
#
# restart_swayidle PID - restart a running swayidle of this user so it picks
# up whichever swayidle binary is now first on PATH.
#   - one supervised by resume-display-on-listener is only killed; that loop
#     respawns it within 2 s
#   - any other (Budgie's) is killed and started again with exactly the same
#     arguments, output to the journal as budgie-swayidle
restart_swayidle() {
    local pid=$1 parent i
    local -a argv
    mapfile -d '' argv < "/proc/$pid/cmdline" || return 1
    parent=$(tr '\0' ' ' < "/proc/$(ps -o ppid= -p "$pid" | tr -d ' ')/cmdline" 2>/dev/null)
    kill "$pid" 2>/dev/null || return 1
    case "$parent" in
        *resume-display-on-listener*) return 0 ;;
    esac
    for ((i = 0; i < 20; i++)); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
    PATH="$HOME/.local/bin:$PATH" setsid -f sh -c \
        'exec "$@" </dev/null 2>&1 | systemd-cat -t budgie-swayidle' _ "${argv[@]}"
}

# user_swayidles - PIDs of this user's swayidle processes, with their binary
user_swayidles() {
    local pid
    for pid in $(pgrep -u "$(id -u)" -x swayidle); do
        printf '%s %s\n' "$pid" "$(readlink "/proc/$pid/exe")"
    done
}
