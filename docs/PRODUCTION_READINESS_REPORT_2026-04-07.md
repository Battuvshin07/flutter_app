<!-- # Production Readiness Assessment

Date: 2026-04-07
Project: mongol_history_app
Prepared via global multi-specialist agent team (team lead + security + backend + mobile + devops + QA + performance + product)

## Executive Summary

Release recommendation: NO-GO

Current readiness score: 2.5/10

Why this is not launch-ready yet:
1. Critical security exposure in deployed Firestore rules.
2. Privilege escalation path in public registration.
3. Backend runtime import failures that can prevent API startup.
4. Flutter compile blocker currently failing analysis/tests.
5. OTP verification flow is referenced by app but missing in cloud functions exports.
6. Quality gates are not enforced consistently across backend, functions, and mobile.

## Audit Scope

Reviewed modules:
- backend (Express + MongoDB)
- flutter_app (Flutter + Firebase client)
- functions (Firebase Cloud Functions)
- Firebase config and rules at repository root

Validation method:
- Read-only architecture and code audit.
- Direct module-load smoke checks.
- Flutter analyze and test run.
- NPM scripts and lint/test gate checks.
- Dependency vulnerability scan with npm audit.

## Critical Findings

### C1. Firestore root rules are globally open

Why this matters:
- Any client can read/write data while the time-based allow rule is active.
- High risk of data tampering, exfiltration, and abuse.

Evidence:
- firestore.rules:15

Recommended fix:
1. Replace wildcard allow rule with least-privilege collection-specific rules.
2. Add emulator-based rules tests and block deploy if tests fail.
3. Remove date-based temporary global allow from production rules permanently.

### C2. Public registration allows role self-assignment

Why this matters:
- New users can request admin role during signup.
- Direct privilege escalation to administrative endpoints.

Evidence:
- backend/src/middleware/validate.middleware.js:54
- backend/src/routes/auth.routes.js:32
- backend/src/controllers/auth.controller.js:38

Recommended fix:
1. Remove role from public registration contract.
2. Force role=user on server for public signup.
3. Move admin promotion to protected admin-only workflow with audit logs.

### C3. Backend startup has missing module imports

Why this matters:
- API process can crash/fail startup due to unresolved modules.

Evidence:
- backend/server.js:21 imports content.routes that is missing
- backend/server.js:91 mounts /api/content
- backend/src/services/admin.service.js:12 imports Content.model that is missing
- backend/src/routes folder has no content.routes.js
- backend/src/models folder has no Content.model.js

Smoke check result:
- require('./src/services/admin.service') -> FAIL (Cannot find module ../models/Content.model)
- require('./src/routes/content.routes') -> FAIL

Recommended fix:
1. Remove stale Content imports/routes if deprecated.
2. Or restore missing Content route/model/controller if still required.
3. Add startup preflight smoke test in CI to require all route/service imports.

### C4. Flutter compile blocker: ambiguous AuthProvider import

Why this matters:
- Analyzer and tests fail at compile stage.
- Mobile release build confidence is blocked.

Evidence:
- flutter_app/lib/screens/otp_verification_screen.dart:5
- flutter_app/lib/screens/otp_verification_screen.dart:7
- flutter_app/lib/screens/otp_verification_screen.dart:246

Validation result:
- flutter analyze --no-pub -> error ambiguous_import
- flutter test test/widget_test.dart --no-pub -> failed to compile

Recommended fix:
1. Alias or hide one AuthProvider import.
2. Re-run analyze and tests immediately.
3. Add this check as required CI gate.

### C5. OTP callable functions referenced by app are not exported

Why this matters:
- Email verification flow may fail at runtime.
- Core authentication funnel is unreliable.

Evidence:
- flutter_app/lib/services/otp_service.dart:17 calls sendVerificationCode
- flutter_app/lib/services/otp_service.dart:52 calls verifyCode
- functions/index.js:24 only global options set
- functions/index.js has no exported callable handlers

Recommended fix:
1. Implement and export sendVerificationCode and verifyCode handlers.
2. Add abuse controls (rate limit, replay defense, expiration checks).
3. Add integration tests against Firebase emulator.

### C6. No enforced release-quality gates for all deployables

Why this matters:
- Broken or insecure changes can ship without deterministic checks.

Evidence:
- backend/package.json has no test/lint scripts
- functions/package.json has lint but no test script
- flutter_app/.github/workflows/azure-webapps-node.yml is template/misaligned and uses optional checks

Recommended fix:
1. Create mandatory CI workflows per deployable.
2. Require analyze/lint/test/build/security scans for merge.
3. Enforce branch protection with required status checks.

## High Findings

### H1. JWT secret fallback to insecure default
Evidence:
- backend/src/config/constants.js:16
- backend/.env.example:14

Fix:
- Fail startup if JWT_SECRET missing/weak/default.
- Rotate secret and invalidate old sessions.

### H2. CORS wildcard with credentials enabled
Evidence:
- backend/server.js:49
- backend/server.js:52
- backend/.env.example:18

Fix:
- Use strict origin allowlist per environment.
- Reject wildcard + credentials configuration at startup.

### H3. Quiz scoring and XP trust client-submitted score
Evidence:
- backend/src/routes/progress.routes.js:22
- backend/src/controllers/progress.controller.js:124
- backend/src/controllers/progress.controller.js:152
- backend/src/controllers/progress.controller.js:172

Fix:
- Submit answers only; score server-side.
- Use atomic idempotent XP grant protection.

### H4. Public payload leaks quiz internals via story quiz population
Evidence:
- backend/src/controllers/stories.controller.js:61 populates quiz questions
- backend/src/controllers/quiz.controller.js:43 returns full quiz objects
- backend/src/models/Quiz.model.js:28 contains correctIndex

Fix:
- Introduce public-safe serializers excluding answer keys.
- Enforce isPublished filters for non-admin users.

### H5. Production UI exposes sample data seeding action
Evidence:
- flutter_app/lib/screens/history_journey_screen.dart:199
- flutter_app/lib/providers/journey_provider.dart:231

Fix:
- Remove from production UI.
- Allow only debug/admin guarded path.

### H6. Admin progress implementation has N+1 read pattern
Evidence:
- flutter_app/lib/data/repositories/admin_repository.dart:270
- flutter_app/lib/providers/admin_provider.dart:103

Fix:
- Move to collection-group or denormalized admin_progress.
- Add true pagination and projection.

### H7. Firebase Admin key file usage is file-path based
Evidence:
- backend/src/firebase/firebaseAdmin.js:17
- backend/src/firebase/firebaseAdmin.js:23
- backend/keys/serviceAccountKey.json present in workspace

Fix:
- Rotate key immediately.
- Move to Secret Manager/Workload Identity.
- Add key-leak scanning and startup policy checks.

### H8. Dependency vulnerabilities in backend/functions
Validation:
- npm audit --omit=dev shows high vulnerabilities in transitive deps (including lodash and fast-xml-parser in backend tree).

Fix:
- Plan controlled dependency upgrade lane with compatibility tests.
- Patch high-severity issues first.

## Medium Findings

1. Health endpoint is shallow and does not check dependency readiness.
- Evidence: backend/server.js:80
- Fix: split liveness/readiness; validate DB connectivity.

2. Firebase environment separation is weak (single default alias only).
- Evidence: .firebaserc:3
- Fix: define dev/stage/prod aliases and gated promotion flow.

3. Root firestore.indexes.json is empty while app-level indexes differ.
- Evidence: firebase.json:5, firestore.indexes.json:49, flutter_app/firestore.indexes.json:2
- Fix: maintain one canonical index source and deploy via CI.

4. Flutter startup proceeds even when Firebase init fails.
- Evidence: flutter_app/lib/main.dart:36, flutter_app/lib/main.dart:43
- Fix: fatal startup screen + retry path + crash reporting.

5. Password change UX/service mismatch creates failure path.
- Evidence: flutter_app/lib/screens/profile_screen.dart:945, flutter_app/lib/services/auth_service.dart:183
- Fix: require current password input or provider-specific flow.

## Quality Gate Baseline (Validated)

### Flutter
- Command: flutter analyze --no-pub
- Result: 59 issues, including 1 blocking compile error (ambiguous AuthProvider).

- Command: flutter test test/widget_test.dart --no-pub
- Result: failed due to same compile error.

### Backend
- Command: npm run test
- Result: missing script test.

- Command: npm run lint
- Result: missing script lint.

### Functions
- Command: npm run test
- Result: missing script test.

- Command: npm run lint
- Result: failed with 4 errors in functions/index.js.

### Test footprint (project-owned)
- backend source files: 47
- backend tests: 0
- functions source files: 2
- functions tests: 0
- flutter source files: 116
- flutter tests: 1

## Existing Strengths

1. Security middleware baseline exists in backend (helmet, rate limit).
2. Centralized configuration/constants structure is present.
3. Progress model has compound unique index for userId+storyId.
4. Flutter architecture is modular with provider layering.
5. app-level Firestore rules in flutter_app/firestore.rules are stricter than root wildcard rules.

## 30-60-90 Day Execution Plan

### Day 0-30 (Launch blockers)
1. Fix all Critical findings C1-C6.
2. Make CI required checks hard-fail for all apps.
3. Reach clean compile/test baseline on mobile and backend startup.

Exit criteria:
- Zero open Critical findings.
- All required checks green on protected branch.

### Day 31-60 (Hardening)
1. Close all High findings H1-H8.
2. Complete secret management hardening and env separation.
3. Implement server-authoritative scoring and public-safe serializers.

Exit criteria:
- Zero open High findings.
- Security and QA sign-off in staging.

### Day 61-90 (Production excellence)
1. Resolve major Medium findings affecting reliability/perf.
2. Add load test, resilience drills, and rollback rehearsal.
3. Operate canary rollout with alerting and incident runbooks.

Exit criteria:
- Launch Go decision approved by backend/mobile/security/devops/QA owners.

## Top-10 Prioritized Backlog

1. Lock down root Firestore rules (Owner: Security).
2. Remove self-admin registration vector (Owner: Backend).
3. Restore/remove missing Content modules to pass startup (Owner: Backend).
4. Fix Flutter AuthProvider ambiguous import (Owner: Mobile).
5. Implement/export OTP callable functions (Owner: Backend/Functions).
6. Enforce mandatory CI gates and branch protection (Owner: DevOps).
7. Remove JWT fallback and enforce secret policy (Owner: Security/Backend).
8. Correct CORS policy (Owner: Security/Backend).
9. Move quiz scoring to server-authoritative logic (Owner: Backend).
10. Replace admin progress N+1 pattern with scalable query model (Owner: Mobile/Backend).

## Production Launch Definition of Done

Security and access:
- No wildcard open Firestore rules.
- No role assignment in public registration.
- No default JWT secret fallback.
- No plaintext key-file dependency in production path.

Build and quality:
- backend: lint+test+startup smoke required.
- functions: lint+test required.
- flutter: analyze+test required.
- required checks enforced in branch protection.

Reliability and operations:
- readiness checks validate critical dependencies.
- logs/metrics/alerts active for API/functions/mobile crash paths.
- rollback runbook tested.
- environment isolation (dev/stage/prod) active.

Data and correctness:
- server-authoritative scoring and XP accounting.
- public-safe API payloads (no answer keys).
- index definitions canonicalized and deployed.

## Risks If Timeline Slips

1. Security incident probability remains high.
2. Runtime/build blockers can cause launch failure.
3. Authentication funnel instability can reduce retention.
4. Regression rate will remain high without enforced gates.
5. Incident response time will be high without observability hardening.

---

Prepared for implementation planning and execution tracking. -->
