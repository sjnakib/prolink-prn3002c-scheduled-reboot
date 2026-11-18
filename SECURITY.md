# Security policy

## Reporting a vulnerability

Use GitHub's private vulnerability reporting:

<https://github.com/sjnakib/prolink-prn3002c-scheduled-reboot/security/advisories/new>

If private reporting is not available, open a regular issue and ask for a
private channel. Do not include exploit details, passwords, or router access
information in a public issue.

Include:

- What the issue affects.
- Steps to reproduce it.
- The version or commit you tested.
- Any suggested fix.

You will get an acknowledgement as soon as possible. This is a small
volunteer project, so there is no guaranteed response time.

## Scope

In scope:

- The script handling credentials, arguments, or temporary files unsafely.
- A way to make the script log or expose a password.
- Command injection or path traversal in the scripts.
- Documentation that could lead a reader to expose the router admin page or
  credentials.

Out of scope:

- The router's HTTP-only web interface. The router does not offer HTTPS, so
  credentials cross the LAN unencrypted. This is a router limitation.
- Weak or default router admin passwords.
- Router firmware vulnerabilities.
- Attacks that require physical access to the router or the host.
- The risk of exposing the router admin page to the internet. Do not do that.

## Supported versions

The latest release and the current `main` branch receive fixes. Older
releases are not maintained.
