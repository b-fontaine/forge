# /forge:diff <name> — Semantic Spec Diff

## Purpose
Show structured differences between a change's delta specs and the accumulated spec base. Useful before `/forge:archive` to preview what will be merged.

## Process

1. Read `.forge/changes/<name>/specs.md` — the delta spec for this change
2. Read accumulated specs in `.forge/specs/` — find spec files that share FR-XXX IDs
3. Parse delta sections: ADDED, MODIFIED, REMOVED
4. For MODIFIED requirements, show side-by-side comparison
5. For ADDED requirements, show full requirement with AC links
6. For REMOVED requirements, show deprecation reason and replacement

## Output

```
SPEC DIFF: <name>
==================

--- .forge/specs/auth.md (accumulated)
+++ .forge/changes/<name>/specs.md (delta)

ADDED (3 requirements):
  + FR-015: Password reset via email
    MUST allow users to request password reset via email link
    MUST expire reset links after 24 hours
    AC-015: Given a registered user, When they request password reset, Then they receive an email within 60 seconds

  + FR-016: Authenticator app 2FA
    MUST support TOTP-based authenticator apps
    SHOULD support backup codes (10 one-time codes)

  + FR-017: Login rate limiting
    MUST lock account after 5 failed attempts in 10 minutes
    MUST notify user via email when account is locked

MODIFIED (1 requirement):
  ~ FR-003: Login timeout
    Previously: MUST timeout login session after 30 minutes of inactivity
    Now:        MUST timeout login session after 15 minutes of inactivity
    Reason:     UX research showed 83% of users complete their task within 10 minutes

REMOVED (1 requirement):
  - FR-008: SMS two-factor authentication — DEPRECATED
    Reason: SMS is vulnerable to SIM-swap attacks (NIST SP 800-63B)
    Replacement: FR-016 (authenticator app 2FA)

──────────────────────────
Summary: +3 added | ~1 modified | -1 removed | Net: +2 requirements
```

## Edge Cases
- **No accumulated spec exists**: Show all requirements as ADDED (first-time feature spec)
- **No delta sections in specs.md**: Warn — specs.md may not follow the delta format (Article IV)
- **FR-XXX ID conflicts**: Flag if a delta ADDED requirement uses an ID that already exists in accumulated specs

## When to Use
- Before `/forge:archive` — preview what will be merged
- During spec review — understand the scope of changes
- On-demand — anytime you want to see what a change modifies
