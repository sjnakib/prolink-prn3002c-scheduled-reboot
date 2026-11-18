# Home Assistant OS

Goal: run `reboot_router.sh` on Home Assistant OS and call it from a script
entity.

Status: Not tested. The Docker guide was tested with the same Home Assistant
Core container image, so the script is expected to work. The difference is
getting the files into `/config`.

## Before you start

- Home Assistant OS is installed and reachable.
- You can install an add-on to move files into `/config`, or you already have
  a file editor.
- You know your router's LAN address, admin username, and admin password.

Home Assistant OS runs Home Assistant Core in a container, and `/config` is
the config folder you see in the UI and in the add-ons. The script must be
inside that folder.

## Steps

1. Put `reboot_router.sh` and `router-reboot.env.example` in
   `/config/scripts/`. Pick one method:

   **Samba share add-on**

   Install the Samba share add-on, configure a share for `config`, and copy
   the two files from your computer to the `scripts` folder over the network
   share.

   **File editor or Studio Code Server add-on**

   Install the add-on, open `/config/scripts/`, and create each file in the
   browser. Paste the contents from the repository.

   **Advanced SSH & Web Terminal or Terminal & SSH add-on**

   Install the add-on, open its terminal, and download the files:

   ```bash
   mkdir -p /config/scripts
   cd /config/scripts
   curl -L -o reboot_router.sh https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/reboot_router.sh
   curl -L -o router-reboot.env.example https://raw.githubusercontent.com/sjnakib/prolink-prn3002c-scheduled-reboot/main/router-reboot.env.example
   chmod 750 reboot_router.sh
   ```

2. Create the credentials file and set the three values:

   ```bash
   cd /config/scripts
   cp router-reboot.env.example router-reboot.env
   chmod 600 router-reboot.env
   nano router-reboot.env
   ```

   Set `ROUTER_IP` to the router's LAN address, without `http://`. Set
   `ROUTER_USER` and `ROUTER_PASS` to the router admin credentials.

3. Add a shell command. Open `/config/configuration.yaml` with your editor or
   the File editor add-on. Add it under an existing `shell_command:` section,
   or create the section:

   ```yaml
   shell_command:
     reboot_router: "/config/scripts/reboot_router.sh"
   ```

   YAML uses spaces only. Do not use tabs.

4. Add a script entity. Open `/config/scripts.yaml`:

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

5. Check the configuration. Open **Developer Tools**, then **YAML**, then
   click **Check configuration**. Fix any errors before continuing.

6. Restart Home Assistant. Open **Settings**, then **System**, then
   **Restart Home Assistant**. New shell commands need a restart, not a
   reload.

7. Verify. Open **Developer Tools**, then **Actions**. Run
   `script.reboot_router`. The response panel shows stdout, stderr, and the
   return code. Expect the three lines from the
   [Docker guide](home-assistant-docker.md#steps), and the router should
   reboot.

8. Schedule it. See
   [home-assistant-scheduling.md](home-assistant-scheduling.md) for the
   Scheduler card and automation examples.

## If the script does not run

If the script is not executable, open the SSH add-on and run:

```bash
chmod 750 /config/scripts/reboot_router.sh
```

If the file was uploaded from Windows and the script reports `bad
interpreter` or `^M`, remove the Windows line endings:

```bash
sed -i 's/\r$//' /config/scripts/reboot_router.sh
```

Home Assistant stops a `shell_command` after 60 seconds. See the timeout note
in [home-assistant-docker.md](home-assistant-docker.md#timeout-note), or add
`--no-wait` to the shell command.

If something else does not work, see
[troubleshooting.md](troubleshooting.md).
