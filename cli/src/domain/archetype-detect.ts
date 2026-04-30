// Forge — archetype auto-detection heuristic (FR-IW-005 of
// b5-1-init-wizard). Pure function over a signal record.
//
// Caller (init-archetype.ts) probes the file system to build the
// `signalsByPath: Record<string, boolean>` input, then invokes
// this function. Splitting pure logic from I/O makes the
// heuristic exhaustively unit-testable without tmpdir setup.

export interface ArchetypeRegistration {
  name: string;
  /** Files that, when ALL present in the target dir, suggest this archetype. */
  signals: string[];
}

export type DetectionResult =
  | { kind: "match"; archetype: string }
  | { kind: "ambiguous"; candidates: string[]; detected: string[] }
  | { kind: "none"; detected: string[] };

export function detectArchetype(
  registrations: ReadonlyArray<ArchetypeRegistration>,
  signalsByPath: Readonly<Record<string, boolean>>,
): DetectionResult {
  const detected = Object.keys(signalsByPath).filter((p) => signalsByPath[p]);
  // An archetype "matches" iff every one of its signals is present.
  const matched = registrations.filter(
    (r) =>
      r.signals.length > 0 &&
      r.signals.every((s) => signalsByPath[s] === true),
  );
  if (matched.length === 1) {
    return { kind: "match", archetype: matched[0].name };
  }
  if (matched.length > 1) {
    return {
      kind: "ambiguous",
      candidates: matched.map((m) => m.name),
      detected,
    };
  }
  // Zero archetype matched fully. If the user provided signals
  // that don't fully satisfy any archetype's list, surface that
  // as ambiguity (caller decides to abort with [NEEDS DECISION:]).
  if (detected.length > 0) {
    // Find archetypes whose signal set INTERSECTS the detected
    // signals — these are the closest candidates.
    const partial = registrations.filter(
      (r) =>
        r.signals.length > 0 &&
        r.signals.some((s) => signalsByPath[s] === true),
    );
    return {
      kind: "ambiguous",
      candidates: partial.map((p) => p.name),
      detected,
    };
  }
  return { kind: "none", detected: [] };
}
