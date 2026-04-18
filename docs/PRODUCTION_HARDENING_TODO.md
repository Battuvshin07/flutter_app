# Production Hardening TODO

Date: 2026-04-07
Status: Master execution backlog for full remediation

## How to Use

- Mark checkboxes as work completes.
- Do not start Medium tasks before all Critical tasks are done.
- Every completed task must include evidence (PR, test run, deploy log, or screenshot).

## Phase 1: Critical Blockers (Must finish first)

### Security

- [x] Replace root wildcard Firestore rule with least-privilege rules.
- [x] Add Firestore rules emulator tests (positive and negative cases).
- [x] Block rule deployment when tests fail in CI.

### Auth and Access

- [x] Remove role field from public register validation.
- [x] Force role=user server-side in register controller.
- [x] Add admin promotion endpoint protected by admin role and audit logging.

### Backend Runtime Integrity

- [x] Decide Content module strategy: restore or remove.
- [x] Fix backend imports for content route/model references.
- [x] Add startup module-load smoke test in CI.

### Mobile Build Integrity

- [x] Resolve AuthProvider ambiguous import in OTP screen.
- [x] Run flutter analyze until zero blocking errors.
- [x] Run flutter test and ensure compile passes.

### OTP Verification Reliability

- [x] Implement sendVerificationCode callable function.
- [x] Implement verifyCode callable function.
- [x] Add rate limiting and expiration validation for OTP.
- [x] Add OTP integration tests (emulator).

### Release Quality Gates

- [x] Add backend lint script.
- [x] Add backend test script.
- [x] Add functions test script.
- [x] Add required CI workflows for backend/functions/flutter.
- [x] Enforce required checks with branch protection.

Exit criteria for Phase 1:

- [x] Zero Critical findings remain open.
- [x] All required CI checks are enforced on protected branch (backend-ci, flutter-ci, functions-ci).

## Phase 2: High-Risk Hardening

### Security Hardening

- [ ] Remove JWT secret fallback default.
- [ ] Add startup config validator for required env vars.
- [ ] Rotate JWT and Firebase service account keys.
- [ ] Move Firebase Admin credentials to Secret Manager or workload identity.

### CORS and Session Policy

- [ ] Replace wildcard origin with strict allowlist by environment.
- [ ] Block invalid wildcard+credentials configurations at startup.

### Data Integrity

- [ ] Change quiz submission contract to send answers, not score.
- [ ] Grade quiz on server and compute score internally.
- [ ] Ensure XP awarding is idempotent and race-safe.

### API Response Safety

- [ ] Create public-safe quiz/story serializers without answer keys.
- [ ] Enforce isPublished visibility for public consumers.

### Product Safety

- [ ] Remove sample data seeding button from production UI.
- [ ] Restrict seed operations to debug/admin tooling only.

### Operational Baseline

- [ ] Add structured logging for backend and functions.
- [ ] Define alerts for error rate, latency, and function failures.
- [ ] Define runbook for auth outage and OTP failure scenarios.

Exit criteria for Phase 2:

- [ ] Zero High findings remain open.
- [ ] Security and QA sign-off completed in staging.

## Phase 3: Reliability and Scale

### Query and Performance

- [ ] Replace admin progress N+1 reads with scalable query model.
- [ ] Add pagination for admin data views.
- [ ] Replace skip-based API pagination with cursor/keyset strategy where needed.
- [ ] Restrict searchable/sortable fields with allowlists.

### Firebase Environment Discipline

- [ ] Define dev/stage/prod aliases in Firebase config.
- [ ] Add promotion workflow from staging to production.
- [ ] Ensure index/rules deployment is environment-specific and audited.

### App Stability

- [ ] Add startup failure screen when Firebase init fails.
- [ ] Fix password-change UX/service mismatch.
- [ ] Improve offline/error states to avoid false-empty UI.

### Readiness Endpoints

- [ ] Add readiness endpoint checking DB and critical dependencies.
- [ ] Keep liveness endpoint minimal and separate.

Exit criteria for Phase 3:

- [ ] Core user journeys pass smoke and regression suites.
- [ ] Performance and reliability SLO baseline established.

## QA and Test Strategy TODO

### Backend

- [ ] Unit tests: auth, role logic, progress scoring, admin guards.
- [ ] Integration tests: register/login/protected routes.
- [ ] Concurrency tests: XP award race conditions.

### Functions

- [ ] Unit tests for OTP generation/validation logic.
- [ ] Integration tests with emulator for callable functions.

### Flutter

- [ ] Widget tests for auth gate and OTP flow.
- [ ] Integration tests for login, verification, journey, and profile update.
- [x] Analyzer warning cleanup plan (target: zero errors, minimal warnings) (warnings: 0 on 2026-04-18).

### Release gates

- [ ] Coverage reports in CI for backend and flutter.
- [ ] Minimum coverage thresholds defined and enforced.

## Ownership Matrix

- Backend Owner: API contracts, auth, scoring, startup integrity.
- Mobile Owner: compile stability, OTP UX, app state/error handling.
- Security Owner: rules, secrets, JWT/CORS policy, threat review.
- DevOps Owner: CI/CD enforcement, environment separation, deploy safety.
- QA Owner: test matrix, regression automation, release confidence.

## Go/No-Go Checklist

- [ ] Critical findings = 0
- [ ] High findings = 0
- [ ] Required CI checks = green
- [ ] Staging sign-off = complete
- [ ] Rollback rehearsal = complete
- [ ] Incident runbook and alerting = validated

## Tracking Fields (fill during execution)

- Start date:
- Target launch date:
- Release manager:
- Last updated: 2026-04-18
- Current phase: Phase 2 (ready to start)
- Blocking issue IDs:
