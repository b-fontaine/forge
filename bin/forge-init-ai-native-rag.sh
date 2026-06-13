#!/usr/bin/env bash
# Forge — `forge init --archetype ai-native-rag` wrapper
# <!-- Audit: B.7.2 (b7-2a-dispatch-register) — refusing stub -->
#
# REGISTERED, NOT YET SCAFFOLDABLE. The ai-native-rag archetype is declared
# (`.forge/scaffolding/dispatch-table.yml`) and its 1.0.0 schema is
# `stage: candidate` / `scaffoldable: false` (.forge/schemas/ai-native-rag/
# 1.0.0.yaml, B.7.1). The CLI versioned-schema layer (cli/src/commands/init.ts →
# resolveScaffolder) refuses `forge init --archetype ai-native-rag` with exit 3
# BEFORE this wrapper is ever invoked.
#
# This file is the wrapper-side defense-in-depth layer (mirrors
# bin/_forge-init-helpers.sh::_refuse_if_forbidden, J.8): if the CLI guard is
# bypassed and the wrapper is called directly, it refuses identically — exit 3,
# structured stderr, and ZERO filesystem writes (never a partial scaffold).
#
# B.7.2 (full scaffolder) replaces this body with the real scaffold logic
# (templates + scaffold-plan + pins from B.7.3) and promotes the schema to
# stable/scaffoldable. Until then: refuse.
#
# Stable ABI shape (B.5.1) — flags are accepted for ABI compatibility and ignored;
# no action is taken on any of them:
#   forge-init-ai-native-rag.sh --target <dir> --project-name <slug> \
#       --reverse-domain <fqdn> [--force]
#
# Refusal exit code: 3 (no scaffoldable schema version ; mirrors the B.8.3.b /
# ADR-J8-003 policy-refusal convention).

set -euo pipefail

# All ABI flags (--target / --project-name / --reverse-domain / --force) and any
# positional args are accepted-and-ignored: this wrapper reads none of them and
# performs NO work — it refuses unconditionally before touching the filesystem.
# (Deliberately no arg-parsing loop, so a value-less flag can't trip `set -e`.)

echo "[REFUSAL: ai-native-rag: not-yet-scaffoldable: the ai-native-rag schema is a candidate (scaffoldable:false) — templates ship in B.7.2 ; alternative: use --archetype full-stack-monorepo, or 'default' then add RAG components manually]" >&2
exit 3
