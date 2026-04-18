# Alert Policy Baseline (Phase 2)

Date: 2026-04-18
Owner: DevOps/SRE
Scope: backend API and Firebase OTP callable functions

## Objective

Define actionable production alerts for error rate, latency, and function failures.

## Alert Definitions

### 1) Backend API Error Rate

Signal: HTTP 5xx responses divided by total HTTP responses.

Suggested thresholds:

- Warning: >2% for 15 minutes
- Critical: >5% for 5 minutes

Recommended filters:

- Service: mongol-history-backend
- Exclude expected client errors (4xx)

### 2) Backend API Latency (P95)

Signal: p95 request latency.

Suggested thresholds:

- Warning: P95 > 1500 ms for 10 minutes
- Critical: P95 > 3000 ms for 5 minutes

Recommended dimensions:

- endpoint group: /api/auth/*, /api/progress/*, /api/stories/*
- environment: production

### 3) OTP Callable Function Failure Rate

Signal: failed executions divided by total executions for
sendVerificationCode and verifyCode.

Suggested thresholds:

- Warning: >3% for 10 minutes
- Critical: >8% for 5 minutes

### 4) OTP Function Error Burst

Signal: absolute failure count.

Suggested thresholds:

- Warning: >=20 failures in 10 minutes
- Critical: >=50 failures in 10 minutes

Use with failure-rate alert to catch low-traffic and high-traffic incidents.

## Implementation Steps

### A. Create Log-Based Metrics (GCP)

1. Ensure structured logs are enabled in backend and functions runtime.

1. Create metrics from logs, for example:

```bash
# Backend request failures (example filter, adjust resource labels)
gcloud logging metrics create backend_request_failures \
  --description="Backend failed request count" \
  --log-filter='resource.type="cloud_run_revision" AND jsonPayload.event="http.request.failed"'

# OTP callable failures
gcloud logging metrics create otp_callable_failures \
  --description="OTP callable failure count" \
  --log-filter='resource.type="cloud_function" AND jsonPayload.message="callable.request.failure"'
```

1. Verify metrics ingestion in Cloud Monitoring Metrics Explorer.

### B. Create Alert Policies

Create policies in Cloud Monitoring UI or via JSON policy files.

```bash
# Example command pattern
gcloud alpha monitoring policies create --policy-from-file=monitoring/alerts/backend-error-rate.json
```

Recommended channels:

- Pager (critical)
- Team chat channel (warning + critical)
- Email distribution list (warning)

### C. Validate in Staging

1. Trigger controlled failures (non-customer traffic).

1. Confirm warning and critical thresholds fire correctly.

1. Confirm de-duplication and notification routing.

1. Record screenshots or policy IDs in release evidence.

## Routing and Severity

- P1 (critical): backend 5xx critical, OTP failure critical
- P2 (warning): sustained warning thresholds

## Operational Notes

- Keep thresholds reviewable each sprint until baseline stabilizes.
- Do not alert on raw error count only; pair with rate-based policies.
- Tie alerts to the runbook in INCIDENT_RUNBOOK_AUTH_OTP.md.

## Manual Prerequisites

Cloud console or gcloud IAM permissions are required for:

- creating log-based metrics
- creating alert policies
- configuring notification channels
