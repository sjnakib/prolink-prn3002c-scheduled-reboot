# cron

Goal: run `reboot_router.sh` on a schedule with cron on Linux or macOS.

Status: Not tested.

## Before you start

- A Linux or macOS machine that stays on and is on the router's LAN.
- `cron` is installed and running. Most Linux distributions include it. macOS
  includes it.
- You can edit your crontab with `crontab -e`.

## Steps

1. Create a folder and install the script and credentials:

   ```bash
   mkdir -p ~/router-reboot
   cd ~/router-reboot
   curl -L -o reboot_router.sh https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/reboot_router.sh
   curl -L -o router-reboot.env.example https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/router-reboot.env.example
   chmod 750 reboot_router.sh
   cp router-reboot.env.example router-reboot.env
   chmod 600 router-reboot.env
   nano router-reboot.env
   ```

   Set `ROUTER_IP`, `ROUTER_USER`, and `ROUTER_PASS` in the file.

2. Run the script once by hand and confirm it works:

   ```bash
   ~/router-reboot/reboot_router.sh
   ```

   Expect "Logging in...", "Sending reboot request...", and "Router is back
   online."

3. Open your crontab:

   ```bash
   crontab -e
   ```

4. Add one line. Replace `/full/path/to/reboot_router.sh` with the real path
   to the script:

   ```
   0 4 * * * /full/path/to/reboot_router.sh >> "$HOME/router-reboot.log" 2>&1
   ```

   This runs the script every day at 04:00 and appends the output to
   `~/router-reboot.log`.

5. Save and close the editor. Cron installs the new crontab immediately.

## The five time fields

| Field | Value in the example | Meaning |
| --- | --- | --- |
| Minute | `0` | At minute 0. |
| Hour | `4` | At 04:00. |
| Day of month | `*` | Every day of the month. |
| Month | `*` | Every month. |
| Day of week | `*` | Every day of the week. |

For a weekly reboot on Sundays at 04:00, use `0 4 * * 0`. Day of week 0 is
Sunday.

## Notes

- Cron runs with a minimal environment. Use full paths for the script and for
  commands inside wrappers.
- Cron runs the job as the user who owns the crontab. That user must be able
  to read `router-reboot.env` and execute the script.
- The script reads `router-reboot.env` from its own folder, so the path in the
  crontab can point at the script directly.
- If the machine is off or asleep at the scheduled time, the job does not run.

## Check the log

```bash
tail -n 20 "$HOME/router-reboot.log"
```

## Optional: systemd timer

On Linux, a systemd timer is an alternative to cron. Place the script and
`router-reboot.env` in `/srv/router-reboot/`, or change `ExecStart` to the
real path. Make sure `<user>` can read both files. Create
`/etc/systemd/system/router-reboot.service`:

```ini
[Unit]
Description=Reboot the Prolink router

[Service]
Type=oneshot
User=<user>
ExecStart=/srv/router-reboot/reboot_router.sh
```

Create `/etc/systemd/system/router-reboot.timer`:

```ini
[Unit]
Description=Weekly router reboot

[Timer]
OnCalendar=Sun 04:20
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now router-reboot.timer
```

Check the next run time with:

```bash
systemctl list-timers router-reboot.timer
```

If the job does not run, see [troubleshooting.md](troubleshooting.md).
