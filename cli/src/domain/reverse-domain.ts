// Forge — reverse-domain validator (FR-IW-007 of b5-1-init-wizard).
// Pure function ; no I/O ; safely shared between the wizard prompt
// and the --org flag validator.

const REVERSE_DOMAIN = /^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$/;

export interface ReverseDomainResult {
  valid: boolean;
  reason?: string;
}

export function validateReverseDomain(value: string): ReverseDomainResult {
  if (!value) {
    return { valid: false, reason: "reverse domain cannot be empty" };
  }
  if (!REVERSE_DOMAIN.test(value)) {
    return {
      valid: false,
      reason:
        "reverse domain must match ^[a-z][a-z0-9.-]+\\.[a-z][a-z0-9.-]+$ " +
        "(e.g. io.acme.myapp)",
    };
  }
  return { valid: true };
}
