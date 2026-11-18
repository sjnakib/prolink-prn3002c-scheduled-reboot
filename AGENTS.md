# AGENTS.md

Instructions for coding agents working in this repository.

## Project overview

This repository provides a scheduled reboot for the Prolink PRN3002-C
router. The router has no reboot scheduler in its web interface, so the
script logs in to the web interface and sends the same requests a browser
would send.

The main script is `reboot_router.sh`. Guides cover Home Assistant
(Docker and Home Assistant OS), cron, and Windows Task Scheduler. The
target reader is a home user who wants this working in about 10 minutes
and may not know bash or YAML well.

The only tested router is the Prolink PRN3002-C. Do not claim support for
other models without a compatibility report.

## Repository layout

```text
.
├── README.md
├── LICENSE
├── AGENTS.md
├── CLAUDE.md
├── SPEC.md
├── CONTRIBUTING.md
├── SECURITY.md
├── CHANGELOG.md
├── .gitignore
├── .gitattributes
├── .editorconfig
├── reboot_router.sh
├── reboot_router.ps1
├── router-reboot.env.example
├── .github/
│   ├── workflows/lint.yml
│   ├── ISSUE_TEMPLATE/bug_report.md
│   ├── ISSUE_TEMPLATE/router_compatibility.md
│   └── PULL_REQUEST_TEMPLATE.md
└── docs/
    ├── how-it-works.md
    ├── home-assistant-docker.md
    ├── home-assistant-os.md
    ├── home-assistant-scheduling.md
    ├── cron.md
    ├── windows.md
    └── troubleshooting.md
```

Keep `reboot_router.sh` at the repository root so raw download URLs stay
short.

## Commands

Run both checks before every commit that touches a script:

```bash
shellcheck reboot_router.sh
bash -n reboot_router.sh
```

Install shellcheck from your package manager, for example
`sudo apt install shellcheck`, or see <https://www.shellcheck.net/>.

There is no build step and no automated test suite. Hardware behavior is
checked with the manual test plan in `SPEC.md`.

## Script rules

- Use bash only. The script must run inside the Home Assistant container.
  The current script relies on bash builtins plus `curl`, `ping`, `sleep`,
  `seq`, `mktemp`, `dirname`, `date`, `cat`, and an optional `logger`. Do
  not add `jq`, `python`, `wget`, or similar.
- Keep `set -euo pipefail`.
- Never print the password and never use `set -x`.
- `ROUTER_IP`, `ROUTER_USER`, and `ROUTER_PASS` are required and have no
  defaults. The router address must never be hard coded.
- Look up configuration in this order: `$ENV_FILE` if set, then
  `router-reboot.env` next to the script, then `/etc/router-reboot.env`.
- If a required value is missing, name the variable and the locations
  searched, then exit with code 3.
- Reject a `ROUTER_IP` that contains `://` or `/` with exit code 3, so a
  pasted URL does not become a malformed request.
- The script must pass `shellcheck` with no warnings and `bash -n`.
- Keep the endpoints and form fields unchanged unless a compatibility
  report shows they differ. See `docs/how-it-works.md`.
- Exit codes are part of the interface: 0 success, 1 router unreachable
  before reboot, 2 router did not come back in time, 3 configuration
  error.
- Document purpose, usage, configuration, exit codes, and the tested model
  in the script header.
- `reboot_router.ps1` mirrors the bash behavior. It reads credentials
  from a DPAPI-protected file and uses the same exit codes.

## Git and commit guidelines

Follow [Conventional Commits](https://www.conventionalcommits.org/).

Format:

```text
<type>(<optional scope>): <subject>

<optional body>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `ci`, `test`.

- One logical change per commit. Do not mix a script change with a docs
  change.
- Subject: imperative mood ("add", not "added"), lowercase after the
  colon, no trailing period, 50 characters preferred, 72 maximum.
- Body: wrap at 72 characters. Explain why the change exists, not what the
  diff shows. Skip the body when the subject says it all.
- No emojis, no em dashes, and no "Generated with" or AI co-author
  trailers.
- Reference issues with `Closes #12` in the body when relevant.
- Never commit secrets. Before every commit, run `git status` and
  `git diff --staged`, and check that no credentials file, password, or
  personal path is staged.
- Never force push and never rewrite pushed history.
- Do not change global git config.

## Writing guidelines

These apply to every file: README, guides, comments, commit messages, and
issue templates.

Voice:

- Concise, complete, and easy to scan. A reader should find the needed
  step in seconds.
- Plain words. Short sentences. Active voice. Address the reader as "you".
- Say what to do, then show the command, then show expected output when it
  helps.
- One action per step. Number steps that must happen in order.
- Define a term the first time it appears, once.

Do not use:

- Em dashes or en dashes. Use a period, comma, colon, or parentheses.
  Write number ranges as "25 to 40".
- Emojis.
- Filler and marketing words such as "seamless", "robust", "powerful",
  "leverage", "elevate", "delve", "game-changer", "simply", "just",
  "easily", "effortless", "in today's world", "let's dive in", or "it's
  important to note".
- Openers that restate the question, or closers that restate the page.
- Claims that cannot be backed up. If it was not tested, say "not tested".

Format:

- Sentence case headings.
- Every command in a fenced block with a language tag. Commands must be
  copy-pasteable. Use placeholders such as `<router-ip>` and say what to
  replace.
- Tables only for comparisons or reference data. Lists only for real
  lists.
- Link to other docs with relative paths.
- Use generic paths in docs such as `~/router-reboot/` and `<config>`.
  Never use a contributor's home directory or username.
- Never include a real password, even one that looks real. Use
  `change-me`.

## Do not

- Do not commit secrets, credentials, or personal paths.
- Do not add dependencies to the scripts.
- Do not change router endpoints or form fields without a compatibility
  report.
- Do not create the `v1.0.0` tag without maintainer confirmation that the
  final script worked on real hardware.
- Do not claim hardware testing. Agents cannot test against a router and
  must say so when reporting results.
- Do not commit local bootstrap, scratch, or environment files.
