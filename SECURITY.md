# Security Policy

Forge takes security seriously. This document explains what we support, how
to report a vulnerability privately, and what to expect after you report one.

## Supported Versions

Security fixes are backported according to the [versioning policy](docs/VERSIONING.md).

| Version line   | Status        | Security fixes       |
|----------------|---------------|----------------------|
| `0.y.z` (pre-GA) | **Current**   | Latest `0.y.z` only  |
| `< 0.1.0`      | Unsupported   | Please upgrade       |

Once Forge reaches `1.0.0`, this table will list the two most recent `MAJOR`
lines as supported for security fixes.

## Scope

In scope:

- The Forge CLI (`@forge/cli`) and installer shell script
  (`bin/forge-install.sh`)
- The deterministic scripts in `.forge/scripts/` (`verify.sh`,
  `constitution-linter.sh`) and the official Docker image
  (`forge/linter:*`)
- Templates, schemas, and standards shipped under `.forge/` when they
  cause a project scaffolded by Forge to be insecure by default
- Agent prompts under `.claude/agents/` when they can be coerced into
  running unsafe operations on behalf of the user

Out of scope:

- Vulnerabilities in third-party dependencies (report those upstream;
  we will track CVEs and bump dependencies on our side)
- Vulnerabilities in Claude Code itself — report to Anthropic
- User-written code in a project that happens to use Forge

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Please report privately via one of the following channels, in order of
preference:

1. **GitHub Security Advisories** — [open a private advisory](https://github.com/bfontaine/forge/security/advisories/new)
   on this repository. This is the preferred channel.
2. **Email** — send an encrypted or plaintext report to
   **benoit.fontaine@septeo.com** with the subject line
   `[Forge Security] <short description>`.

Include in your report:

- A description of the vulnerability and the component affected
- Steps to reproduce (minimal proof-of-concept preferred)
- The Forge version (`VERSION` file content) and the environment
  (OS, Node version if CLI-related, Docker version if image-related)
- Your assessment of impact (confidentiality / integrity / availability)
- Optional: a suggested fix or mitigation

## What to Expect

- **Acknowledgment**: within **3 business days** of receiving the report.
- **Initial triage**: within **7 business days** — we confirm whether
  the report is accepted, needs more info, or is out of scope.
- **Fix and disclosure timeline**: we aim for **30 days** for a fix to land
  in `main`, up to **90 days** for complex issues. If a vulnerability is
  actively exploited in the wild, we fast-track a patch release.
- **Credit**: with your consent, we will credit you in the changelog and
  the security advisory. Anonymous reports are also accepted.
- **Embargo**: please keep details private until a fix is released or we
  jointly agree the embargo can be lifted.

## Coordinated Disclosure

We follow a coordinated disclosure model. Once a fix is ready, we will:

1. Prepare a patch release (PATCH bump for non-breaking fixes,
   MINOR/MAJOR if the fix requires behavior change — see
   [docs/VERSIONING.md](docs/VERSIONING.md)).
2. Publish a GitHub Security Advisory with the affected versions,
   the patched versions, workarounds, and a CVE identifier (if assigned).
3. Update `CHANGELOG.md` under a `### Security` subsection referencing
   the advisory.
4. Notify reporters and, when relevant, downstream integrators.

## Safe Harbour

We will not pursue or support legal action against researchers who:

- Make a good-faith effort to comply with this policy.
- Avoid privacy violations, destruction of data, and interruption or
  degradation of our services or users.
- Report the issue promptly and refrain from public disclosure until we
  have had a reasonable chance to fix it.

Thank you for helping keep Forge and its users safe.
