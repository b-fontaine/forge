# /forge:review <name> — Quality Gate Review

## Purpose
Run all quality gates before a change can be archived.

## Quality Guardian Agents
- Flutter changes → Invoke **Nemesis**
- Rust changes → Invoke **Tribune**
- Full-stack → Both Nemesis + Tribune
- All changes → Invoke **Aegis** (Security Auditor)
- Test quality → Invoke **Eris** (Test Architect) for anti-pattern checklist and coverage analysis
- Documentation → Invoke **Calliope** (Technical Writer) for documentation quality check

## Review Protocol

### 0. Deterministic Verification (Run First)
Execute `.forge/scripts/verify.sh` and `.forge/scripts/constitution-linter.sh`. Capture output from both.
If ANY check fails → include failures in the review report.
Deterministic failures BLOCK the gate regardless of LLM assessment.
Proceed to LLM-based checks only after deterministic checks are captured.
Consider running `/forge:verify <name>` for spec-to-code traceability check.

### 1. Spec Compliance Verification
For every FR-XXX in specs.md:
- [ ] Has at least one test covering it?
- [ ] All BDD scenarios (Given/When/Then) pass?
- [ ] Acceptance criteria verified?

### 2. Quality Guardian Checklists
Run full Nemesis (Flutter) / Tribune (Rust) checklists:
- Tests: coverage ≥80%, no skip, golden up to date
- Architecture: layers respected, DI, no logic in widgets
- Code quality: zero warnings, documented APIs, no TODO

### 3. Security Audit (Aegis)
- Auth, data protection, input validation, dependency vulnerabilities
- Flutter: cert pinning, encrypted storage
- Rust: zero unsafe, no secrets in code

### 4. Results

#### PASS Condition
ALL checks pass → 
```
✅ REVIEW PASSED for <name>
All [N] FR requirements verified
Coverage: [X]%
No security issues found
Ready to archive: /forge:archive <name>
```

#### FAIL Condition
Any check fails →
```
❌ REVIEW FAILED for <name>

Failures:
- [Specific failure 1] → Delegate to [Agent]
- [Specific failure 2] → Delegate to [Agent]

Return to /forge:implement <name> to fix, then re-run /forge:review
```
