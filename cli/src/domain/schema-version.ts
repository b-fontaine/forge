// Forge — versioned archetype-schema selection (b8-14-promotion-flip, C2).
//
// `forge init` historically routed by archetype NAME only and never read a
// schema version. B.8.14 enables a Kong-less 2.0.0 front-door: when an archetype
// ships multiple versioned schemas (e.g. full-stack-monorepo/schema.yaml = 1.0.0
// stable + 2.0.0.yaml = 2.0.0 stable), init must pick the HIGHEST stage:stable +
// scaffoldable:true version and route to its versioned scaffolder wrapper.
//
// It also lands the deferred B.8.3.b guard: refuse to scaffold an archetype whose
// only schema versions are non-scaffoldable (candidate/draft, scaffoldable:false).
//
// Field semantics (validate-foundations.sh + b8-3b):
//   - stage ∈ {draft, candidate, stable}; only `stable` is selectable.
//   - candidate ⇒ scaffoldable:false (enforced by the validator).
//   - stable WITHOUT an explicit `scaffoldable` key ⇒ scaffoldable (T-010).
//
// No YAML dependency — the three fields are line-parsed by regex, mirroring
// `resolveFrameworkVersion` in cli.ts (NFR-IW-002, zero third-party deps).

export interface SchemaMeta {
  version: string;
  stage: string;
  scaffoldable: boolean;
}

/**
 * Parse the {version, stage, scaffoldable} triple out of an archetype schema
 * YAML. Returns null when there is no `version:` field (not a schema file).
 */
export function parseSchemaMeta(content: string): SchemaMeta | null {
  const v = content.match(/^version:\s*"?([^"\n]+?)"?\s*$/m);
  if (!v) return null;
  const s = content.match(/^stage:\s*"?([^"\n]+?)"?\s*$/m);
  const stage = s ? s[1].trim() : ""; // absent stage ⇒ unknown ⇒ not selectable
  const sc = content.match(/^scaffoldable:\s*(true|false)\b/m);
  // b8-3b T-010: explicit value wins; otherwise stable defaults to scaffoldable,
  // anything else defaults to NOT scaffoldable.
  const scaffoldable = sc ? sc[1] === "true" : stage === "stable";
  return { version: v[1].trim(), stage, scaffoldable };
}

const SEMVER = /^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$/;

/**
 * Compare two SemVer strings. Returns 1 if a > b, -1 if a < b, 0 if equal.
 * A release outranks a prerelease of the same x.y.z. Non-SemVer falls back to
 * lexicographic compare (deterministic, never throws).
 */
export function compareSemver(a: string, b: string): number {
  const pa = a.match(SEMVER);
  const pb = b.match(SEMVER);
  if (!pa || !pb) return a < b ? -1 : a > b ? 1 : 0;
  for (let i = 1; i <= 3; i++) {
    const d = Number(pa[i]) - Number(pb[i]);
    if (d !== 0) return d > 0 ? 1 : -1;
  }
  const preA = pa[4] !== undefined;
  const preB = pb[4] !== undefined;
  if (preA !== preB) return preA ? -1 : 1; // release > prerelease
  if (preA && preB) return pa[4] < pb[4] ? -1 : pa[4] > pb[4] ? 1 : 0;
  return 0;
}

/**
 * Pick the highest stage:stable + scaffoldable:true schema. Returns null when no
 * version qualifies (the B.8.3.b refusal condition).
 */
export function selectScaffoldableVersion(
  metas: readonly SchemaMeta[],
): SchemaMeta | null {
  const ok = metas.filter((m) => m.stage === "stable" && m.scaffoldable);
  if (ok.length === 0) return null;
  return ok.reduce((best, m) =>
    compareSemver(m.version, best.version) > 0 ? m : best,
  );
}
