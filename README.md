# Prolink PRN3002-C scheduled reboot

Reboot a Prolink PRN3002-C router on a schedule from Home Assistant, cron,
or Windows Task Scheduler.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Lint](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/actions/workflows/lint.yml/badge.svg)](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/actions/workflows/lint.yml)

## Why

The Prolink PRN3002-C has no scheduled reboot feature. As of November 2026,
Prolink technical support reports that firmware v1.70.00 is the latest
release, that no newer firmware has been released, and that the firmware
source files are no longer available.

The hardware still works. Without firmware updates or source, the stock web
interface is the practical way to manage it. This project is a small attempt
to keep the router out of landfill by adding the scheduled reboot that the
stock firmware lacks, so it can serve as a separate Wi-Fi access point for
IoT devices.

## How it works

1. Log in with the router's normal login form.
2. Send the reboot request that the web interface sends.
3. Wait until the router answers again.

The router only offers HTTP on the local network. The script was written for
one model. See [docs/how-it-works.md](docs/how-it-works.md) for the request
details and for notes on adapting it to another router.

## Requirements

- A Linux, macOS, or Windows machine on the same network as the router.
- `bash` and `curl`.
- The router's admin address, username, and password.

## Quick start

```bash
git clone https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot.git
cd prolink-prn3002c-scheduled-reboot
cp router-reboot.env.example router-reboot.env
chmod 600 router-reboot.env
nano router-reboot.env
./reboot_router.sh
```

In `router-reboot.env`, set `ROUTER_IP` to your router's address, then set
`ROUTER_USER` and `ROUTER_PASS`. Do not include `http://` in the address.

Expected output (the times and duration will differ):

```text
2026-11-18 14:31:19 Logging in...
2026-11-18 14:31:19 Sending reboot request...
2026-11-18 14:31:43 Router is back online.
```

A normal run takes about 25 to 40 seconds. If the script exits with code 3,
the credentials file is missing or a value is empty. See
[docs/troubleshooting.md](docs/troubleshooting.md).

## Schedule it

| Where you run it | Guide |
| --- | --- |
| Home Assistant in Docker | [docs/home-assistant-docker.md](docs/home-assistant-docker.md) |
| Home Assistant OS | [docs/home-assistant-os.md](docs/home-assistant-os.md) |
| Linux or macOS with cron | [docs/cron.md](docs/cron.md) |
| Windows | [docs/windows.md](docs/windows.md) |

For the Scheduler card and Home Assistant automations, see
[docs/home-assistant-scheduling.md](docs/home-assistant-scheduling.md).

## Configuration

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `ROUTER_IP` | Yes | None | Router LAN address or hostname, without `http://` and without a path. |
| `ROUTER_USER` | Yes | None | Router admin username. |
| `ROUTER_PASS` | Yes | None | Router admin password. |
| `ENV_FILE` | No | None | Path to a credentials file. Overrides the search order. |

The script reads the first readable file: `$ENV_FILE` if set, then
`router-reboot.env` next to the script, then `/etc/router-reboot.env`.

To find the router address, check the label on the router. On Linux, run
`ip route | grep default`. On macOS, run `route -n get default`. On Windows,
run `ipconfig` and look for the default gateway.

| Flag | Description |
| --- | --- |
| `--no-wait` | Send the reboot request and exit without waiting for the router. |
| `-h`, `--help` | Show usage and exit. |

| Exit code | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | The router was unreachable before the reboot. |
| 2 | The router did not come back in time. |
| 3 | Configuration error. |

## Tested on

| Setup | Status |
| --- | --- |
| Prolink PRN3002-C | Tested |
| Ubuntu, script run directly | Tested |
| Home Assistant in Docker | Tested |
| Home Assistant OS | Not tested |
| cron | Not tested |
| Windows (PowerShell, Task Scheduler) | Experimental, not tested |
| Other router models | Unknown. See [docs/how-it-works.md](docs/how-it-works.md) |

## Security notes

- The router uses plain HTTP, so use this only on a trusted LAN.
- The firmware no longer receives security updates. Treat the router as an
  unpatched device and keep it on a trusted or isolated network.
- Keep `router-reboot.env` at `chmod 600`.
- Never commit `router-reboot.env` or `router-cred.xml`. Both are in
  `.gitignore`.
- Change the router's default admin password.
- Do not expose the router admin page to the internet.

## Other router models

The endpoints and form fields are specific to the PRN3002-C. If you have a
different model, read [docs/how-it-works.md](docs/how-it-works.md) to capture
its requests, then open a
[router compatibility issue](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/issues/new?template=router_compatibility.md)
with the result.

## Support the project

If this saved you some time, a star on GitHub helps other people find it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Compatibility reports are welcome.

## License

[MIT](LICENSE)
