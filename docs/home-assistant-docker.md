# Home Assistant in Docker

Goal: run `reboot_router.sh` inside the Home Assistant Docker container and
call it from a script entity.

Status: Tested by the maintainer with `ghcr.io/home-assistant/home-assistant:stable`.

## Before you start

- Home Assistant runs in Docker with its config folder mounted at `/config`.
  For example, the host folder `~/.config/homeassistant` is mounted as
  `/config`.
- You can run `docker` commands on the host.
- You know your router's LAN address, admin username, and admin password.
- You can edit files in the Home Assistant config folder.

The container cannot see host paths outside its mounts. Keep the script and
the credentials file inside the config folder. The examples below use
`<config>` for the host path to that folder. Replace it with your own path.

## Steps

1. Create the scripts folder and download the script and example file:

   ```bash
   mkdir -p <config>/scripts
   cd <config>/scripts
   curl -L -o reboot_router.sh https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/reboot_router.sh
   curl -L -o router-reboot.env.example https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/router-reboot.env.example
   chmod 750 reboot_router.sh
   ```

2. Create the credentials file and set the three values:

   ```bash
   cp router-reboot.env.example router-reboot.env
   chmod 600 router-reboot.env
   nano router-reboot.env
   ```

   Set `ROUTER_IP` to the router's LAN address, without `http://`. Set
   `ROUTER_USER` and `ROUTER_PASS` to the router admin credentials.

3. Test the script inside the container. The container name may differ; check
   it with `docker ps`.

   ```bash
   docker exec homeassistant /config/scripts/reboot_router.sh
   ```

   Expect output like this:

   ```text
   2026-11-18 14:31:19 Logging in...
   2026-11-18 14:31:19 Sending reboot request...
   2026-11-18 14:31:43 Router is back online.
   ```

   The router should reboot during the wait.

4. Add a shell command. Open `<config>/configuration.yaml` and add it under
   an existing `shell_command:` section, or create the section:

   ```bash
   nano <config>/configuration.yaml
   ```

   ```yaml
   shell_command:
     reboot_router: "/config/scripts/reboot_router.sh"
   ```

   YAML uses spaces only. Do not use tabs.

5. Add a script entity. Open `<config>/scripts.yaml`:

   ```bash
   nano <config>/scripts.yaml
   ```

   ```yaml
   reboot_router:
     alias: "Reboot Router"
     icon: mdi:router-wireless-restart
     mode: single
     sequence:
       - action: shell_command.reboot_router
   ```

   If `configuration.yaml` does not contain `script: !include scripts.yaml`,
   add that line. If `scripts.yaml` contains only `{}` or `[]`, remove that
   line first.

6. Check the configuration, then restart Home Assistant:

   ```bash
   docker exec homeassistant python3 -m homeassistant --script check_config -c /config
   docker compose restart homeassistant
   ```

   Run `docker compose` from the folder that contains your compose file. New
   shell commands need a restart, not a reload.

7. Verify. Open **Developer Tools**, then **Actions**. Run
   `script.reboot_router`. The router should reboot.

8. Schedule it. See
   [home-assistant-scheduling.md](home-assistant-scheduling.md) for the
   Scheduler card and automation examples.

## Timeout note

Home Assistant stops a `shell_command` after 60 seconds. A normal run takes
about 25 to 40 seconds. If your router is slower, add `--no-wait`:

```yaml
shell_command:
  reboot_router: "/config/scripts/reboot_router.sh --no-wait"
```

The reboot request is sent before the wait starts, so the router still
reboots when the command times out. `--no-wait` avoids the timeout message.

If something does not work, see
[troubleshooting.md](troubleshooting.md).
