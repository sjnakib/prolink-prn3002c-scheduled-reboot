# Contributing

Thanks for helping. The most useful contribution is a report from a router
model or setup that has not been tested yet.

## Report a compatibility result

Open a
[router compatibility issue](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/issues/new?template=router_compatibility.md)
with:

- The router model and firmware version.
- Whether login and reboot worked.
- Any endpoints or form fields that differ from the PRN3002-C.
- The output of the script, with passwords, cookies, and personal paths
  removed.

See [docs/how-it-works.md](docs/how-it-works.md) for help capturing the
requests.

## Report a bug

Open a
[bug report](https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/issues/new?template=bug_report.md)
with the command you ran, the output, the exit code, your operating system,
and how you scheduled the script. Remove secrets before posting.

## Run the checks

`reboot_router.sh` must pass both checks:

```bash
shellcheck reboot_router.sh
bash -n reboot_router.sh
```

Install shellcheck from your package manager, for example
`sudo apt install shellcheck`, or see <https://www.shellcheck.net/>.

The CI workflow runs the same two commands on every push and pull request.

## Commit rules

Follow [Conventional Commits](https://www.conventionalcommits.org/). Keep one
logical change per commit and do not mix script changes with documentation
changes.

The full rules are in
[AGENTS.md](AGENTS.md#git-and-commit-guidelines). In short:

- Use a type such as `feat`, `fix`, `docs`, or `chore`.
- Write the subject in the imperative mood, lowercase after the colon, with
  no trailing period.
- Explain why in the body when the subject is not enough.
- Do not add emojis, em dashes, or AI co-author trailers.
- Never commit credentials or personal paths.

## Pull request checklist

- [ ] `shellcheck reboot_router.sh` passes.
- [ ] `bash -n reboot_router.sh` passes.
- [ ] The change is tested, and the test setup is described.
- [ ] Documentation is updated when behavior or setup changes.
- [ ] No credentials, passwords, cookies, or personal paths are included.
- [ ] The commit history follows the rules above.

Small, focused pull requests are easier to review. If you plan a large change,
open an issue first.
