# SPEC.md

Behavior and interface for the Prolink PRN3002-C reboot script.

## Purpose

The Prolink PRN3002-C has no scheduled reboot feature in its web
interface. This project logs in to the router and sends the reboot request
that the web interface sends, so the reboot can run from Home Assistant,
cron, or Windows Task Scheduler.

The target reader is a home user on the router's LAN. The project does not
change router firmware and does not require a custom firmware image.

## Requirements

- A Linux, macOS, or Windows machine on the same network as the router.
- `bash` and `curl` for `reboot_router.sh`. `ping` is used to check that
  the router is reachable.
- The router admin address, username, and password.
- HTTP access to the router's web interface. The router does not offer
  HTTPS.
- For Home Assistant: a working installation with access to its
  `configuration.yaml` and a way to run a shell command.

## Behavior

`reboot_router.sh` runs these steps in order:

1. Parse flags. `-h` or `--help` prints usage and exits 0. An unknown flag
   prints usage and exits 3. `--no-wait` disables the wait after the reboot
   request.
2. Resolve the credentials file. The first match wins:
   1. `$ENV_FILE` if the variable is set and the file is readable.
   2. `router-reboot.env` in the same directory as the script.
   3. `/etc/router-reboot.env`.
   If `$ENV_FILE` is set but unreadable, the script exits 3. Values already
   present in the environment are also accepted.
3. Read `ROUTER_IP`, `ROUTER_USER`, and `ROUTER_PASS`. If any is empty,
   print the missing variable names and the file locations searched, then
   exit 3. If `ROUTER_IP` contains `://` or `/`, print a clear error and
   exit 3.
4. Ping the router twice. If it does not answer, log that the router is not
   reachable and exit 1.
5. Send `POST /login.cgi` with the login fields and a `login.htm` referer.
6. Send `POST /form2Reboot.cgi` with the reboot fields and a `reboot.htm`
   referer. Connection errors are ignored because the router may drop the
   connection while rebooting.
7. With `--no-wait`, log that the request was sent and exit 0.
8. Otherwise wait 10 seconds, then ping the router up to 40 times with a
   2 second pause between attempts. If a ping succeeds, log "Router is
   back online." and exit 0. If the loop ends, log that the router did not
   return and exit 2.

The script logs to stdout. It also sends each message to syslog with
`logger -t router-reboot` when `logger` is available.

The script does not verify that the login succeeded. It relies on the
reboot request working, which matches the router's behavior: the login
response sets no cookie and the router tracks the logged-in client by IP
address.

## Interface

Usage:

```bash
./reboot_router.sh [--no-wait]
./reboot_router.sh --help
```

### Configuration

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ROUTER_IP` | Yes | None | Router LAN address or hostname, without `http://` and without a path. |
| `ROUTER_USER` | Yes | None | Router admin username. |
| `ROUTER_PASS` | Yes | None | Router admin password. |
| `ENV_FILE` | No | None | Path to a credentials file. Overrides the search order. |

No variable has a default value. The router address is never hard coded.
Users can find it on the router label, with `ip route | grep default` on
Linux, `route -n get default` on macOS, or `ipconfig` on Windows.

### Flags

| Flag | Description |
| --- | --- |
| `-h`, `--help` | Print usage and exit 0. |
| `--no-wait` | Send the reboot request and exit 0 without waiting for the router to return. |

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success. The reboot request was sent, and the router returned unless `--no-wait` was used. |
| 1 | The router was unreachable before the reboot request. |
| 2 | The router did not come back within the expected time. |
| 3 | Configuration error, including a missing variable, an unreadable `ENV_FILE`, a malformed `ROUTER_IP`, or an unknown flag. |

## Router protocol

These values come from the maintainer's Prolink PRN3002-C and were
verified with browser developer tools.

| Item | Value |
| --- | --- |
| Model | Prolink PRN3002-C, 300Mbps Wireless-N AP / Router |
| Web server header | `Virtual Web 0.9` |
| Admin URL | `http://<router-ip>/login.htm` |
| Login request | `POST /login.cgi` with fields `username`, `password`, and `submit.htm?login.htm=Send` |
| Login response | HTTP 200 with a small page that redirects to `index.htm`. No cookie is set. |
| Reboot page | `reboot.htm`, form posts to `form2Reboot.cgi` |
| Reboot request | `POST /form2Reboot.cgi` with fields `reboot=Reboot` and `submit.htm?reboot.htm=Send` |
| Referer | `login.htm` for login, `reboot.htm` for reboot |
| Reboot duration | A 35 second countdown was shown. The router was back online about 24 seconds after the request. |
| Transport | HTTP only. No HTTPS. |

The password is sent as plain text. The login page JavaScript only checks
that the username is not empty.

## Non-goals

- Supporting other router brands or models without a tested report.
- A web interface or a hosted service.
- HTTPS support.
- Router firmware changes.
- Verifying the login response or reading the router's reboot progress.

## Known limitations

- HTTP only, so credentials cross the LAN unencrypted. This is a router
  limitation.
- The script does not verify that the login succeeded. It relies on the
  reboot request working.
- Only one router model has been tested.
- Home Assistant stops a `shell_command` after 60 seconds. A normal run
  takes about 25 to 40 seconds, but use `--no-wait` if the run is slower.
- The wait after the reboot request uses ping. A router that blocks ping
  will appear offline.
- The router may track the logged-in client by IP. A second admin session
  or a changed address can interfere with the login and reboot.
- The PowerShell script is experimental and has not been tested on real
  hardware.

## Manual test plan

Run this after any change to the script or the router interaction.

1. Run the script by hand from a machine on the router's LAN:

   ```bash
   ./reboot_router.sh
   ```

2. Confirm the output includes "Logging in...", "Sending reboot request...",
   and "Router is back online."
3. Confirm the router actually rebooted, for example by watching its status
   lights or checking the uptime on its status page.
4. Repeat the test from Home Assistant:

   ```bash
   docker exec homeassistant /config/scripts/reboot_router.sh
   ```

5. Run `script.reboot_router` from Developer Tools, Actions.
6. Run the scheduled entry from the Scheduler card or automation and confirm
   it triggers at the configured time.
7. Record which steps passed and which setup was used. Update the
   compatibility matrix if a setup was tested for the first time.

## Compatibility matrix

| Setup | Status |
| --- | --- |
| Prolink PRN3002-C | Tested |
| Ubuntu, script run directly | Tested |
| Home Assistant in Docker | Tested |
| Home Assistant OS | Not tested |
| cron | Not tested |
| Windows with PowerShell and Task Scheduler | Experimental, not tested |
| Windows with WSL or Git Bash | Experimental, not tested |
| Other router models | Unknown |
