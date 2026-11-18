# Troubleshooting

Goal: find the cause when the script or the schedule does not work.

## Before you start

Run the script by hand and note the exit code:

```bash
./reboot_router.sh
echo "exit code: $?"
```

The exit code narrows down the problem. The sections below are grouped by
symptom and exit code.

## bad interpreter or ^M errors

**Cause:** The script has Windows line endings (CRLF). Bash tries to run `\r`
as part of the interpreter path.

**Fix:** Remove the carriage returns:

```bash
sed -i 's/\r$//' reboot_router.sh
```

On Home Assistant OS, use the full path:

```bash
sed -i 's/\r$//' /config/scripts/reboot_router.sh
```

The repository's `.gitattributes` marks shell scripts as LF, so a normal
`git clone` avoids this. Downloading or copying the file through some Windows
tools can still add CRLF.

## Exit code 3: missing configuration

**Cause:** The credentials file is missing, unreadable, or one of the three
variables is empty. The script prints a message such as:

```text
Missing required configuration: ROUTER_PASS
```

**Fix:** Check the file the script reports, then check the values:

```bash
ls -l <config>/scripts/router-reboot.env
```

The file must be readable by the user who runs the script. `ROUTER_IP`,
`ROUTER_USER`, and `ROUTER_PASS` must all be set.

The script checks these locations in order:

1. `$ENV_FILE`, if set.
2. `router-reboot.env` next to the script.
3. `/etc/router-reboot.env`.

If `ENV_FILE` points at a missing file, the script exits 3. Unset it or fix
the path.

## Exit code 3: ROUTER_IP has a URL or path

**Cause:** `ROUTER_IP` contains `http://`, `https://`, or `/`.

**Fix:** Use only the address or hostname:

```bash
ROUTER_IP="192.168.0.2"
```

`192.168.0.2` is an example. Use your router's address.

## Exit code 1: router unreachable

**Cause:** The script cannot ping the router before it tries to reboot it.

**Fix:** Check the address and the network:

```bash
ping -c 2 <router-ip>
```

- Confirm `ROUTER_IP` matches the router's LAN address.
- Confirm the machine is on the router's LAN, not on a guest network or a
  different subnet.
- Confirm the router answers ping. Some routers block ping, and this script
  would report exit code 1 even when the web interface works.

## Exit code 2: router did not come back

**Cause:** The router took longer than the wait window, or its address
changed after the reboot.

**Fix:** Open the router's admin page by hand and check that it is running.
If the router uses DHCP and gets a new address, update `ROUTER_IP`. If the
router is slow, use `--no-wait` and check the router separately.

## Script says success but the router did not reboot

**Possible causes:**

- The password is wrong. The script does not verify the login response, so a
  failed login can still lead to a reboot request that the router ignores.
- Another admin session is open, or the router is logged in elsewhere.
- The firmware on your router differs from the tested firmware.

**Fix:** Log out of the router web interface in every browser tab, check the
password in `router-reboot.env`, then run the script again. Confirm the reboot
by checking the router's uptime on its status page.

## Timed out running command in the Home Assistant log

**Cause:** Home Assistant stops a `shell_command` after 60 seconds. The reboot
request is sent early in the run, so the router usually still reboots.

**Fix:** Check whether the router rebooted. To avoid the timeout message, use
`--no-wait` in the shell command:

```yaml
shell_command:
  reboot_router: "/config/scripts/reboot_router.sh --no-wait"
```

See the timeout note in
[home-assistant-docker.md](home-assistant-docker.md#timeout-note).

## Script is missing from the Scheduler card picker

**Cause:** The card's `include:` or `exclude:` filter does not include
scripts.

**Fix:** Edit the card in YAML and add `script` to `include:`:

```yaml
type: custom:scheduler-card
include:
  - script
  - switch
```

See [home-assistant-scheduling.md](home-assistant-scheduling.md).

## command not found: shellcheck

**Cause:** shellcheck is not installed. It is only needed for development.

**Fix:** Install it:

```bash
sudo apt install shellcheck
```

On macOS with Homebrew:

```bash
brew install shellcheck
```

Other platforms: <https://www.shellcheck.net/>.

## Logged out of the router web page after a reboot

**Cause:** The router restarted and cleared its sessions.

**Fix:** None. Log in again. This is expected.

## Still stuck

Open a
[bug report](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/issues/new?template=bug_report.md)
with the command you ran, the output, the exit code, your operating system,
and how you scheduled the script. Remove passwords, cookies, and personal
paths first.
