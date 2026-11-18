#!/usr/bin/env bash
# Reboot a Prolink PRN3002-C (Realtek/Boa firmware) via its web interface.
# Install to: /usr/local/bin/reboot_router.sh  (chmod 750)
# Settings: put them in /etc/router-reboot.env (chmod 600), NOT in this file:
#   ROUTER_IP="192.168.0.2"     # your router's LAN address, required
#   ROUTER_USER="admin"
#   ROUTER_PASS='yourpassword'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
if [ -z "$ROUTER_IP" ]; then
    echo "ROUTER_IP is not set. Add ROUTER_IP=\"<router address>\" to $CONFIG_FILE" >&2
    exit 3
fi
case "$ROUTER_IP" in
    *://*|*/*)
        echo "ROUTER_IP must be an address or hostname only, without http:// or a path." >&2
        exit 3 ;;
esac
ROUTER_USER="${ROUTER_USER:-CHANGE_ME_USERNAME}"
ROUTER_PASS="${ROUTER_PASS:-CHANGE_ME_PASSWORD}"

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
log() { logger -t router-reboot "$*"; echo "$(date '+%F %T') $*"; }

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

# Wait for it to go down, then come back (up to ~90s)
sleep 10
for i in $(seq 1 40); do
    if ping -c 1 -W 2 "$ROUTER_IP" >/dev/null 2>&1; then
        log "Router is back online."
        exit 0
    fi
    sleep 2
done
log "Router did not come back within the expected time."
exit 2
