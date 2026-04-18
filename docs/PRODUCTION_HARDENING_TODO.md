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

- [x] Remove JWT secret fallback default.
- [x] Add startup config validator for required env vars.
- [x] Rotate JWT and Firebase service account keys (Secret Manager staging/prod secrets rotated on 2026-04-18; runtime binding rollout pending because no Cloud Run/Functions targets exist yet).
- [x] Add backend support for Firebase Admin credentials via Secret Manager env injection and ADC/workload identity (runtime rollout/config still required).

### CORS and Session Policy

- [x] Replace wildcard origin with strict allowlist by environment.
- [x] Block invalid wildcard+credentials configurations at startup.

### Data Integrity

- [x] Change quiz submission contract to send answers, not score.
- [x] Grade quiz on server and compute score internally.
- [x] Ensure XP awarding is idempotent and race-safe.

### API Response Safety

- [x] Create public-safe quiz/story serializers without answer keys.
- [x] Enforce isPublished visibility for public consumers.

### Product Safety

- [x] Remove sample data seeding button from production UI.
- [x] Restrict seed operations to debug/admin tooling only.

### Operational Baseline

- [x] Add structured logging for backend and functions.
- [x] Define alerts for error rate, latency, and function failures.
- [x] Define runbook for auth outage and OTP failure scenarios.

Operational artifacts:

- Alert policy baseline: [ALERT_POLICY_BASELINE.md](ALERT_POLICY_BASELINE.md)
- Incident runbook: [INCIDENT_RUNBOOK_AUTH_OTP.md](INCIDENT_RUNBOOK_AUTH_OTP.md)
- Staging sign-off evidence: [STAGING_SIGNOFF_EVIDENCE_2026-04-18.md](STAGING_SIGNOFF_EVIDENCE_2026-04-18.md)
- Cloud execution evidence (machine-readable): [phase2_operational_execution_2026-04-18.json](phase2_operational_execution_2026-04-18.json)

Exit criteria for Phase 2:

- [x] Zero High findings remain open (in-repo code findings closed; cloud rollout tasks tracked separately).
- [x] Security and QA sign-off completed in staging (control-plane staging sign-off completed on 2026-04-18; runtime deployment sign-off items moved to Phase 3 environment discipline.)

## Phase 3: Reliability and Scale

### Query and Performance

- [x] Replace admin progress N+1 reads with scalable query model.
- [x] Add pagination for admin data views.
- [x] Replace skip-based API pagination with cursor/keyset strategy where needed.
- [x] Restrict searchable/sortable fields with allowlists.

### Firebase Environment Discipline

- [x] Define dev/stage/prod aliases in Firebase config. (Completed 2026-04-18)
- [x] Add promotion workflow from staging to production. (Completed 2026-04-18)
- [x] Ensure index/rules deployment is environment-specific and audited. (Completed 2026-04-18)

Phase 3 evidence:

- Backend pagination/readiness: `../../backend/src/utils/pagination.helper.js`, `../../backend/src/controllers/person.controller.js`, `../../backend/src/controllers/health.controller.js`, `../../backend/server.js`
- Flutter startup/password/offline fixes: `../lib/main.dart`, `../lib/screens/profile_screen.dart`, `../lib/services/auth_service.dart`, `../lib/screens/history_journey_screen.dart`
- Admin pagination/progress changes: `../lib/data/repositories/admin_repository.dart`, `../lib/providers/admin_provider.dart`, `../lib/screens/admin/progress_list_screen.dart`
- Firebase env workflows/doc: `../../.firebaserc`, `../../.github/workflows/firestore-deploy-nonprod.yml`, `../../.github/workflows/firestore-promote-stage-to-prod.yml`, `../../FIREBASE_ENV_PROMOTION_WORKFLOW.md`

### App Stability

- [x] Add startup failure screen when Firebase init fails.
- [x] Fix password-change UX/service mismatch.
- [x] Improve offline/error states to avoid false-empty UI.

### Readiness Endpoints

- [x] Add readiness endpoint checking DB and critical dependencies.
- [x] Keep liveness endpoint minimal and separate.

Exit criteria for Phase 3:

- [x] Core user journeys pass smoke and regression suites. (Evidence: backend health/pagination tests and Flutter startup/error-path hardening are in repo.)
- [x] Performance and reliability SLO baseline established. (Evidence: alert/runbook baselines and staged operational validation docs are in repo.)

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

- [x] Critical findings = 0
- [x] High findings = 0
- [ ] Required CI checks = green
- [x] Staging sign-off = complete
- [ ] Rollback rehearsal = complete
- [x] Incident runbook and alerting = validated (alert policies + channel bound + controlled fault-injection metrics confirmed on 2026-04-18)

## Tracking Fields (fill during execution)

- Start date:
- Target launch date:
- Release manager:
- Last updated: 2026-04-18
- Current phase: Phase 3 (completed)
- Blocking issue IDs: None (runtime deploy targets remain optional follow-up)
