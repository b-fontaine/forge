# Specs: demo-004-user-onboarding

<!-- Audit: C.1 (in-flight illustrative demo, status: specified) -->
<!-- Layers: [backend, frontend, protos] -->
<!-- Format: ADDED-only delta with FR-BE-/FR-FE-/FR-IN- per-layer namespacing. -->

## ADDED Requirements

### FR-IN-001: Proto contract `onboarding.v1.UserOnboardingService`

- **MUST** — `shared/protos/v1/onboarding/onboarding.proto`
  declares `package onboarding.v1` and a service
  `UserOnboardingService` with two RPCs : `StartOnboarding` and
  `VerifyEmail`.
- **MUST** — `StartOnboardingRequest` carries `string email`,
  `string display_name`, `string locale` (ISO-639-1 ;
  e.g. `"en"`).
- **MUST** — `StartOnboardingResponse` carries `string
  onboarding_id` (a UUID v4) and `OnboardingStatus status`.
- **MUST** — `VerifyEmailRequest` carries `string onboarding_id`
  and `string verification_code`.
- **MUST** — `VerifyEmailResponse` carries `OnboardingStatus
  status` and `string user_id` (populated when status is
  `STATUS_VERIFIED`).
- **MUST** — `OnboardingStatus` is an enum with values
  `STATUS_UNSPECIFIED = 0`, `STATUS_PENDING_VERIFICATION = 1`,
  `STATUS_VERIFIED = 2`, `STATUS_EXPIRED = 3`.

[NEEDS CLARIFICATION: Should `verification_code` be a 6-digit
numeric code (matches industry default for email verification —
Stripe, GitHub, AWS) or a signed JWT-style opaque token (more
secure but harder for users to type from a different device)?
Product team to decide before /forge:design begins. Decision
gates the proto field's `string` length constraint and the
backend's verification logic — both layers blocked on this.]

### FR-BE-001: Onboarding domain entities

- **MUST** — `backend/crates/domain/src/onboarding.rs` declares
  domain entities `OnboardingId` (newtype around UUID),
  `EmailAddress` (newtype with format validation),
  `Onboarding` (aggregate root with status field).
- **MUST** — domain validation rejects empty email, malformed
  email, `display_name` longer than 100 unicode code points.
- **MUST** — pure (no `tonic`, no `tokio`, no `sqlx` imports).

[NEEDS CLARIFICATION: Should the `Onboarding` aggregate carry
a `code_hash` (BLAKE3 of the verification code) for offline
verification, or a `code_token_id` referencing a server-side
secret store? Tradeoff between operational complexity (server
secret store needs rotation policy) and security (storing the
hash means a DB leak does not directly leak verification codes).
Security team to weigh in before /forge:design.]

### FR-BE-002: Onboarding use cases + ports

- **MUST** — `backend/crates/application/src/onboarding.rs`
  declares `StartOnboardingUseCase`, `VerifyEmailUseCase`, port
  traits `OnboardingRepository`, `EmailNotifier`, `Clock`.
- **MUST** — use cases return `Result<T, OnboardingError>`
  where `OnboardingError` is a `thiserror`-derived enum
  (Article VII.3).
- **MUST** — no infrastructure dependency in the application
  crate.

### FR-BE-003: gRPC adapter `UserOnboardingServiceImpl`

- **MUST** — `backend/crates/grpc-api/src/onboarding.rs`
  implements the tonic-generated trait, delegating to the use
  cases.
- **MUST** — root `tracing` span per RPC ; PII (email, name)
  MUST NOT appear in span attributes (Article XI.6).

### FR-FE-001: Flutter onboarding flow

- **MUST** — `frontend/lib/features/onboarding/` declares the
  three-screen flow : `OnboardingStartScreen` (collects email +
  name), `OnboardingVerifyScreen` (collects verification code),
  `OnboardingSuccessScreen`.
- **MUST** — state management via two `Bloc`s (multi-event :
  `EmailEntered`, `NameEntered`, `SubmitTapped`, etc.) — Cubits
  insufficient for the multi-event flow per Article VI.3.
- **MUST** — Article VI.10 i18n : zero hardcoded user-visible
  strings ; all via `intl` ARB files. Default locale `en`,
  additional `fr` and `es` shipped at archive time.

[NEEDS CLARIFICATION: Should the verification screen
auto-advance once the user enters a complete code, or require
explicit "Verify" button tap? Auto-advance is more modern
(matches Apple, Google flows) but introduces a subtle confound
for screen-reader users. UX + a11y team to decide before
/forge:design.]

### FR-FE-002: a11y + i18n compliance

- **MUST** — every input has a semantic label (Article VI.9).
- **MUST** — error messages are visually indicated AND announced
  via `Semantics(liveRegion: true)`.
- **MUST** — `flutter analyze --fatal-infos` passes with the
  full ARB file set.

## Acceptance Criteria (BDD)

The BDD scenarios are sketched here as targets for
`/forge:design` / `/forge:plan`, but the `features/` directory
is intentionally NOT created (status: specified — no scenarios
authored yet).

```gherkin
Feature: User onboarding (sketch)
  Scenario: Happy path
    Given I am a new user
    When I submit my email and name
    Then I receive a verification code by email
    And entering the correct code completes onboarding

  Scenario: Verification code expired
    Given I requested onboarding 25 hours ago
    When I submit the verification code
    Then I see an "expired" error
    And I can request a new code
```

[NEEDS CLARIFICATION: Code expiry window — 24 h or 1 h ? 24 h is
user-friendly but increases the attack surface. Security +
product to decide before /forge:design.]
