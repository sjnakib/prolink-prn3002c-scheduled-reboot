# Home Assistant scheduling

Goal: run `script.reboot_router` at a fixed time with the Scheduler card, an
automation, or a Schedule helper.

Status: Tested with the Scheduler card. The automation and Schedule helper
options are not tested.

## Before you start

- `script.reboot_router` exists and works when run from Developer Tools,
  Actions. See [home-assistant-docker.md](home-assistant-docker.md) or
  [home-assistant-os.md](home-assistant-os.md).
- Home Assistant has the correct time zone. Check **Settings**, then
  **System**, then **General**.

## Option A: Scheduler card

This is the option the maintainer uses. It needs [HACS](https://hacs.xyz) and
two custom components:

- [scheduler-component](https://github.com/nielsfaber/scheduler-component)
- [scheduler-card](https://github.com/nielsfaber/scheduler-card)

Install both from their documentation. The steps below assume they are
installed and Home Assistant has restarted.

1. Add the Scheduler card to a dashboard.
2. Click **Add**.
3. Choose the **Reboot Router** script as the entity, then choose the
   **Execute** action.
4. Set the time and days, for example 04:20 on Sundays.
5. Save the entry and check that its toggle is on.

If the script is missing from the picker, edit the card in YAML and check
`include:` and `exclude:`. If `include:` is used, `script` must be listed:

```yaml
type: custom:scheduler-card
include:
  - script
  - switch
```

## Option B: automation

This option needs no extra install.

```yaml
automation:
  - alias: "Reboot router weekly"
    triggers:
      - trigger: time
        at: "04:20:00"
    conditions:
      - condition: time
        weekday:
          - sun
    actions:
      - action: script.reboot_router
```

Remove the `conditions` block for a daily reboot. You can build the same
automation in the UI under **Settings**, then **Automations & Scenes**.

## Option C: Schedule helper

1. Open **Settings**, then **Devices & services**, then **Helpers**.
2. Create a **Schedule** helper and set the days and time range.
3. Create an automation with a state trigger for the helper turning on.
4. Set the action to `script.reboot_router`.

## Tips

- Pick a quiet hour when nobody needs the network.
- Confirm the first run by checking the router's uptime on its status page,
  or by opening **Settings**, then **Automations & Scenes**, selecting the
  script, and checking **Last triggered**.
- Home Assistant stops a `shell_command` after 60 seconds. A normal run takes
  about 25 to 40 seconds. See the timeout note in
  [home-assistant-docker.md](home-assistant-docker.md#timeout-note) if your
  router is slower.

If the schedule does not fire, see
[troubleshooting.md](troubleshooting.md).
