#!/usr/bin/env bash
# Reboot a Prolink PRN3002-C (Realtek/Boa firmware) via its web interface.
# Install to: /usr/local/bin/reboot_router.sh  (chmod 750)
# Settings: put them in /etc/router-reboot.env (chmod 600), NOT in this file:
#   ROUTER_IP="192.168.0.2"     # your router's LAN address, required
#   ROUTER_USER="admin"
#   ROUTER_PASS='yourpassword'

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: reboot_router.sh [--no-wait]

Send a reboot request to a Prolink PRN3002-C router.

Options:
  --no-wait   Send the request and exit without waiting for the router.
  -h, --help  Show this help and exit.

Configuration:
  ROUTER_IP, ROUTER_USER, and ROUTER_PASS are required.
  The script reads them from $ENV_FILE, router-reboot.env next to the
  script, or /etc/router-reboot.env.
EOF
}

NO_WAIT=0
while [ $# -gt 0 ]; do
    case "$1" in
        --no-wait)
            NO_WAIT=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 3
            ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "${ENV_FILE:-}" ] && [ ! -r "$ENV_FILE" ]; then
    echo "ENV_FILE is set to $ENV_FILE but the file is not readable." >&2
    exit 3
fi

if [ -n "${ENV_FILE:-}" ]; then
    CONFIG_FILE="$ENV_FILE"
elif [ -r "$SCRIPT_DIR/router-reboot.env" ]; then
    CONFIG_FILE="$SCRIPT_DIR/router-reboot.env"
else
    CONFIG_FILE="/etc/router-reboot.env"
fi

if [ -r "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

ROUTER_IP="${ROUTER_IP:-}"
ROUTER_USER="${ROUTER_USER:-}"
ROUTER_PASS="${ROUTER_PASS:-}"

missing=""
if [ -z "$ROUTER_IP" ]; then
    missing="ROUTER_IP"
fi
if [ -z "$ROUTER_USER" ]; then
    missing="${missing:+$missing, }ROUTER_USER"
fi
if [ -z "$ROUTER_PASS" ]; then
    missing="${missing:+$missing, }ROUTER_PASS"
fi

if [ -n "$missing" ]; then
    echo "Missing required configuration: $missing" >&2
    echo "Set these values in $CONFIG_FILE or in the environment." >&2
    echo "Files checked: \$ENV_FILE (if set), $SCRIPT_DIR/router-reboot.env, /etc/router-reboot.env" >&2
    exit 3
fi

case "$ROUTER_IP" in
    *://*|*/*)
        echo "ROUTER_IP must be an address or hostname only, without http:// or a path." >&2
        exit 3 ;;
esac

# --- Endpoints/fields: VERIFY these with browser DevTools (see instructions) ---
LOGIN_URL="http://${ROUTER_IP}/login.cgi"
LOGIN_FIELDS=(--data-urlencode "username=${ROUTER_USER}"
              --data-urlencode "password=${ROUTER_PASS}"
              --data-urlencode "submit.htm?login.htm=Send")

REBOOT_URL="http://${ROUTER_IP}/form2Reboot.cgi"
REBOOT_FIELDS=(--data-urlencode "reboot=Reboot"
               --data-urlencode "submit.htm?reboot.htm=Send")
# -----------------------------------------------------------------------------

JAR="$(mktemp)"
trap 'rm -f "$JAR"' EXIT
log() {
    local message
    message="$(date '+%F %T') $*"
    echo "$message"
    if command -v logger >/dev/null 2>&1; then
        logger -t router-reboot "$*" 2>/dev/null || true
    fi
}

# Skip if router is unreachable
if ! ping -c 2 -W 2 "$ROUTER_IP" >/dev/null 2>&1; then
    log "Router $ROUTER_IP not reachable, aborting."
    exit 1
fi

log "Logging in..."
curl -sS --max-time 15 -c "$JAR" -b "$JAR" \
     -e "http://${ROUTER_IP}/login.htm" \
     "${LOGIN_FIELDS[@]}" "$LOGIN_URL" -o /dev/null

log "Sending reboot request..."
curl -sS --max-time 15 -c "$JAR" -b "$JAR" \
     -e "http://${ROUTER_IP}/reboot.htm" \
     "${REBOOT_FIELDS[@]}" "$REBOOT_URL" -o /dev/null || true

if [ "$NO_WAIT" -eq 1 ]; then
    log "Reboot request sent. Not waiting for the router."
    exit 0
fi

# Wait for it to go down, then come back (up to ~90s)
sleep 10
for _ in $(seq 1 40); do
    if ping -c 1 -W 2 "$ROUTER_IP" >/dev/null 2>&1; then
        log "Router is back online."
        exit 0
    fi
    sleep 2
done
log "Router did not come back within the expected time."
exit 2
