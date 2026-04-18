# Incident Runbook: Auth Outage and OTP Failures

Date: 2026-04-18
Owner: Backend + Functions + DevOps On-Call

## Scope

This runbook covers:

- Backend authentication outage
- OTP send/verify failures in Firebase callable functions

## Severity Guide

- SEV-1: Login or verification unavailable for most users
- SEV-2: Partial degradation with workaround
- SEV-3: Localized or intermittent failures

## Detection

Primary signals:

- Backend error-rate alert (critical/warning)
- Backend latency alert (critical/warning)
- OTP callable failure-rate alert
- OTP callable failure burst alert

Secondary signals:

- Health endpoint failures
- Spike in user support tickets for login/verification

## Initial Triage (first 15 minutes)

1. Confirm incident scope.

- Which journey is broken (login, send OTP, verify OTP)?
- Which environment is impacted (prod/stage)?

1. Check core health.

- Backend health endpoint
- Recent backend startup logs and DB connection logs
- sendVerificationCode and verifyCode logs for failure pattern

1. Identify failure domain.

- Auth token/JWT validation
- MongoDB connectivity
- Firebase callable runtime errors
- SMTP/provider failure for OTP delivery

1. Assign incident commander and communications owner.

## Scenario A: Auth Outage

### Detection Criteria (Auth Outage)

- Backend 5xx critical alert firing
- auth endpoints returning sustained 5xx/timeout

### Triage Checklist (Auth Outage)

1. Check deployment history for backend release timing.

1. Inspect structured logs.

- server.start_failed
- mongodb.connection.failed
- http.request.failed on /api/auth/*

1. Verify JWT secret rotation metadata and environment values.

### Mitigation / Rollback (Auth Outage)

1. If caused by latest release, rollback traffic to last known good revision.

```bash
# Example for Cloud Run (replace placeholders)
gcloud run services update-traffic SERVICE_NAME \
  --region REGION \
  --to-revisions REVISION_NAME=100
```

1. If credential/config issue, restore last known-good secret values.

1. If DB connectivity issue, fail over or restore DB access policy.

1. Announce user-facing status and expected recovery window.

### Recovery Validation (Auth Outage)

- /api/health stable
- login/register/authenticated request smoke checks pass
- error-rate alert cleared for at least 15 minutes

## Scenario B: OTP Send/Verify Failure

### Detection Criteria (OTP)

- otp callable failure-rate warning/critical
- otp failure burst alert
- user reports of missing code or rejected valid code

### Triage Checklist (OTP)

1. Check function logs.

- callable.request.failure
- Failed to dispatch OTP email

1. Distinguish failure type.

- sendVerificationCode failures (email dispatch/rate limit)
- verifyCode failures (expired code/attempt limit/runtime exception)

1. Validate email provider credentials and quota state.

1. Validate Firebase service account credential source health.

### Mitigation / Rollback (OTP)

1. Roll back functions to last known good deployment if regression confirmed.

```bash
# Redeploy known-good code from tagged commit or release branch
firebase deploy --only functions:sendVerificationCode,functions:verifyCode
```

1. If provider outage, switch to fallback provider config (if available).

1. Temporarily increase retry/cooldown messaging in client if needed.

1. Keep incident status updates every 15-30 minutes.

### Recovery Validation (OTP)

- OTP send success rate returns to baseline
- verify success rate returns to baseline
- no sustained callable failures for 30 minutes

## Communications Template

- Start: "We are investigating authentication/verification degradation in production."
- Update: include impacted flow, mitigation in progress, ETA window.
- Resolve: root cause summary, user impact window, follow-up actions.

## Post-Incident Checklist

1. Capture timeline (detection, mitigation, recovery).
2. Record root cause and contributing factors.
3. Add or refine alert thresholds if noisy or late.
4. Add regression tests for discovered gap.
5. Confirm rotation metadata updates if secret changes occurred.
6. Link incident report in production hardening tracker.

## Preconditions / Access

Manual cloud access required for:

- deployment rollback
- traffic switching
- secret value rollback
- alert policy/channel updates
