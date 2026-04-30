import { describe, expect, it } from "vitest";
import { validateReverseDomain } from "../../src/domain/reverse-domain.js";

describe("validateReverseDomain", () => {
  describe("valid", () => {
    for (const v of ["io.acme.app", "co.uk.example", "org.example.foo"]) {
      it(`accepts ${v}`, () => {
        expect(validateReverseDomain(v).valid).toBe(true);
      });
    }
  });

  describe("invalid", () => {
    for (const v of ["", "Acme.io", "123.acme.io", "acme", ".acme.io", "-bad.com"]) {
      it(`rejects ${JSON.stringify(v)}`, () => {
        const r = validateReverseDomain(v);
        expect(r.valid).toBe(false);
        expect(r.reason).toBeDefined();
      });
    }
  });
});
