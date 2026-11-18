# Windows

Goal: run the reboot on a schedule from Windows with Task Scheduler.

Status: Experimental. Not tested on real hardware by the author. Reports
welcome.

Two routes are available:

- Route A uses the PowerShell script and a DPAPI-protected credential file.
- Route B runs the bash script through WSL or Git Bash.

## Before you start

- Windows 10 or Windows 11.
- Your PC is on the same network as the router.
- You know your router's LAN address, admin username, and admin password.
- Your PC is awake at the scheduled time. A desktop that sleeps will miss the
  task.

## Route A: PowerShell and Task Scheduler

1. Create `C:\Scripts\` and put `reboot_router.ps1` there. Copy it from the
   repository.

2. Create the router address file. Copy `router-reboot.env.example` to
   `C:\Scripts\router-reboot.env` and set `ROUTER_IP`. The PowerShell script
   uses only `ROUTER_IP` from this file. `ROUTER_USER` and `ROUTER_PASS` are
   ignored because the credentials come from the credential file.

3. Save the credentials once, as the user the task will run as:

   ```powershell
   Get-Credential | Export-Clixml C:\Scripts\router-cred.xml
   ```

   Enter the router admin username and password. `Export-Clixml` encrypts the
   password for that Windows user on that machine. If you change the user or
   move the file to another PC, create it again.

4. Test the script from PowerShell:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\reboot_router.ps1
   ```

   Expect the same three lines as the bash script, and the router should
   reboot.

5. Create a daily task at 04:00:

   ```powershell
   schtasks /Create /TN "Reboot Router" /SC DAILY /ST 04:00 /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\reboot_router.ps1"
   ```

   For a weekly task on Sundays at 04:00, replace the schedule arguments:

   ```powershell
   schtasks /Create /TN "Reboot Router" /SC WEEKLY /D SUN /ST 04:00 /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\reboot_router.ps1"
   ```

   You can also use Task Scheduler and **Create Basic Task** in the Start
   menu, then set the action to start `powershell.exe` with those arguments.

6. Verify. Open Task Scheduler, find **Reboot Router**, and check **Last Run
   Result**. A result of `0x0` means success. Check the router's uptime on its
   status page to confirm the reboot.

By default, the task runs only when the user is logged on. To run it while
logged off, open the task properties and choose **Run whether user is logged
on or not**. Task Scheduler then stores the user's password.

## Route B: bash through WSL or Git Bash

1. Install WSL or Git for Windows.

2. Put `reboot_router.sh` and `router-reboot.env` in a folder such as
   `C:\Scripts\`. Set `ROUTER_IP`, `ROUTER_USER`, and `ROUTER_PASS` in the
   file.

3. Test from PowerShell with WSL:

   ```powershell
   wsl.exe -e /mnt/c/Scripts/reboot_router.sh
   ```

   Or test with Git Bash:

   ```powershell
   & "C:\Program Files\Git\bin\bash.exe" -c "/c/Scripts/reboot_router.sh"
   ```

4. Create the task with the matching command:

   ```powershell
   schtasks /Create /TN "Reboot Router" /SC DAILY /ST 04:00 /TR "wsl.exe -e /mnt/c/Scripts/reboot_router.sh"
   ```

   For Git Bash:

   ```powershell
   schtasks /Create /TN "Reboot Router" /SC DAILY /ST 04:00 /TR '"C:\Program Files\Git\bin\bash.exe" -c "/c/Scripts/reboot_router.sh"'
   ```

5. If the script reports `bad interpreter` or `^M`, remove the Windows line
   endings. In Git Bash:

   ```bash
   sed -i 's/\r$//' /c/Scripts/reboot_router.sh
   ```

   The repository marks shell scripts as LF in `.gitattributes`, so a normal
   `git clone` keeps the correct line endings.

## Notes

- A Windows PC must be awake, and the task must run as a user with access to
  the credential file. For an always-on setup, a small Linux box, a Raspberry
  Pi, or Home Assistant is more reliable.
- Home Assistant in Docker Desktop on Windows follows the
  [Docker guide](home-assistant-docker.md), using Windows paths for the bind
  mount. This setup is not tested.
- The PowerShell script is experimental. If you test it, open an issue with
  the result.

If something does not work, see [troubleshooting.md](troubleshooting.md).
