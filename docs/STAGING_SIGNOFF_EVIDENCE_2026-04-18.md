# Staging Sign-off Evidence (2026-04-18)

## Execution Metadata

- Date (UTC): 2026-04-18
- Primary execution window (UTC): 2026-04-18T09:06:45Z to 2026-04-18T09:12:05Z
- Firebase/GCP project ID: `historyapp-d1d66`
- GCP project number: `823744797822`
- Operator account: `battuvshin.naranbaatar07@gmail.com`
- Full machine-readable execution log: [phase2_operational_execution_2026-04-18.json](phase2_operational_execution_2026-04-18.json)

## Sign-off Decision

- Decision: APPROVED for Phase 2 operational closure
- Scope: control-plane security/observability rollout and validation completed in historyapp-d1d66
- Carry-over to Phase 3: runtime deployment and runtime-level verification after service targets are provisioned
- Approved at (UTC): 2026-04-18T09:12:05Z

## Commands Executed (Real Cloud Operations)

### Auth and project verification

```powershell
Set-Location 'c:\Projects\mongol_history_app'
firebase --version
firebase login:list
firebase projects:list --json
firebase functions:list --project historyapp-d1d66 --json
firebase apphosting:backends:list --project historyapp-d1d66
```

### Live GCP mutation/validation execution (via Firebase OAuth token -> Google APIs)

```powershell
Set-Location 'c:\Projects\mongol_history_app'
@'
<Node.js script executed through node stdin to perform all actions below>
- Cloud Run/Functions runtime discovery
- Secret Manager secret create+version rotation
- IAM service account key creation for firebase-adminsdk-fbsvc@historyapp-d1d66.iam.gserviceaccount.com
- Cloud Monitoring notification channel/policy creation
- Cloud Logging log-based metrics creation
- Controlled log fault injection
- Monitoring timeSeries validation polling
'@ | node -
```

### Temporary probe secret cleanup verification

```powershell
Set-Location 'c:\Projects\mongol_history_app'
@'
<Node.js script executed through node stdin>
- GET projects/historyapp-d1d66/secrets/PHASE2_ACCESS_PROBE
- DELETE projects/historyapp-d1d66/secrets/PHASE2_ACCESS_PROBE (if present)
- Re-GET verification for NOT_FOUND
'@ | node -
```

## Runtime Discovery Results

- Cloud Run services discovered: `0`
- Cloud Functions v2 discovered: `0`
- Cloud Run API response included unreachable regions list: `europe-west15`, `me-central2`, `us-central2`, `us-east7`, `us-west8`

Operational impact:

- Startup-validator runtime env var rollout could not be applied because there were no runtime targets to patch.
- Post-rotation revision health verification was not applicable because there were no deployed revisions/services.

## Secret Rotation Executed

### JWT secret rotation (staging/prod)

- `projects/823744797822/secrets/backend_jwt_secret_staging`
  - Latest version: `projects/823744797822/secrets/backend_jwt_secret_staging/versions/1`
  - Labels: `env=staging`, `managed_by=phase2_ops`, `secret_type=jwt`
- `projects/823744797822/secrets/backend_jwt_secret_production`
  - Latest version: `projects/823744797822/secrets/backend_jwt_secret_production/versions/1`
  - Labels: `env=production`, `managed_by=phase2_ops`, `secret_type=jwt`

### Firebase credential source rotation

- Runtime service account: `firebase-adminsdk-fbsvc@historyapp-d1d66.iam.gserviceaccount.com`
- New key artifacts present after rotation:
  - `projects/historyapp-d1d66/serviceAccounts/firebase-adminsdk-fbsvc@historyapp-d1d66.iam.gserviceaccount.com/keys/879e2601c4afb7c44c4d484e1b13258612db29f0`
  - `projects/historyapp-d1d66/serviceAccounts/firebase-adminsdk-fbsvc@historyapp-d1d66.iam.gserviceaccount.com/keys/ece11533590ab6bd3bda37361c64cbb3572b9997`
- Existing pre-rotation key still present for rollback safety:
  - `projects/historyapp-d1d66/serviceAccounts/firebase-adminsdk-fbsvc@historyapp-d1d66.iam.gserviceaccount.com/keys/ac95fc2465976ae0978d64e3b05412ecd837151c`

- Secret payload rotations executed:
  - `projects/823744797822/secrets/backend_firebase_service_account_json_staging/versions/1`
  - `projects/823744797822/secrets/backend_firebase_service_account_json_production/versions/1`

Rotation policy metadata for runtime validators (target values):

- `JWT_SECRET_ROTATED_AT=2026-04-18`
- `JWT_SECRET_MAX_AGE_DAYS=90`
- `FIREBASE_CREDENTIALS_ROTATED_AT=2026-04-18`
- `FIREBASE_CREDENTIALS_MAX_AGE_DAYS=90`

## Monitoring and Alerting Implementation

### Notification channel

- Reused channel: `projects/historyapp-d1d66/notificationChannels/9864571603769376133`
- Type: `email`
- Address: `battuvshin.naranbaatar07@gmail.com`
- Verification status from API: `VERIFICATION_STATUS_UNSPECIFIED`

### Log-based metrics

- `logging.googleapis.com/user/phase2_backend_request_count`
- `logging.googleapis.com/user/phase2_backend_error_count`
- `logging.googleapis.com/user/phase2_backend_latency_ms` (distribution metric with explicit bucket options)
- `logging.googleapis.com/user/phase2_otp_invocation_count`
- `logging.googleapis.com/user/phase2_otp_failure_count`

### Alert policies created and bound to channel

- Backend error rate:
  - `projects/historyapp-d1d66/alertPolicies/7146089986187354919`
  - Display: `Phase2 Backend Error Rate (staging signal)`
- Backend latency P95:
  - `projects/historyapp-d1d66/alertPolicies/9269964183789527644`
  - Display: `Phase2 Backend Latency P95 (staging signal)`
- OTP failure rate/burst:
  - `projects/historyapp-d1d66/alertPolicies/15594281492292571227`
  - Display: `Phase2 OTP Failure Rate or Burst (staging signal)`

## Controlled Fault Injection and Validation

Fault-injection log stream:

- Log name: `projects/historyapp-d1d66/logs/phase2_fault_injection`
- Write status: HTTP `200`

Injected event counts:

- `backend_request`: 30
- `backend_error`: 10
- `backend_latency`: 12
- `otp_invocation`: 20
- `otp_failure`: 8

Metric ingestion evidence:

- Observation timestamp: `2026-04-18T09:11:22.696Z`
- Polling attempt: 3
- `phase2_backend_request_count`: points=3, total=40, latestEnd=`2026-04-18T09:11:19.748Z`
- `phase2_backend_error_count`: points=3, total=13, latestEnd=`2026-04-18T09:11:20.456Z`
- `phase2_backend_latency_ms`: points=2, totalCount=16, latestEnd=`2026-04-18T09:11:21.046Z`
- `phase2_otp_invocation_count`: points=3, total=27, latestEnd=`2026-04-18T09:11:21.570Z`
- `phase2_otp_failure_count`: points=3, total=11, latestEnd=`2026-04-18T09:11:22.147Z`

Interpretation:

- Alert signal pathways are live and metrics are incrementing from controlled injected events.
- Incident open/close confirmation was not captured in-session; metric-level condition evidence is recorded with timestamps.

## Cleanup and Safety

- Temporary probe secret `PHASE2_ACCESS_PROBE` removed.
- Post-clean verification:
  - Timestamp: `2026-04-18T09:12:05.498Z`
  - GET status: HTTP `404` (expected after cleanup)

## Rollback Notes

- Secrets rollback:
  - Rebind runtime secret references to prior versions for:
    - `backend_jwt_secret_staging`
    - `backend_jwt_secret_production`
    - `backend_firebase_service_account_json_staging`
    - `backend_firebase_service_account_json_production`
- Service account rollback:
  - Disable/delete newly created keys after runtime rollback confirms stable startup.
- Alerting rollback:
  - Disable/delete Phase2 alert policies and `phase2_*` log metrics if a temporary test configuration is no longer desired.

## Screenshot / Console Capture Placeholders

- [ ] Secret Manager secret versions list for all four rotated secrets.
- [ ] IAM service account keys list showing new key IDs.
- [ ] Monitoring alert policy list with three policy IDs.
- [ ] Notification channel details panel for channel `9864571603769376133`.
- [ ] Logs Explorer view for `phase2_fault_injection` entries.

## Outstanding Blockers and Next Executable Unblock Commands

Current blockers:

- No staging/prod Cloud Run service exists in project to receive env/secret bindings.
- No Cloud Functions v2 runtime exists in project for function-level env rollout.

Next commands after runtime creation (example sequence):

```powershell
# 1) Discover runtime targets once deployed
gcloud run services list --project historyapp-d1d66 --platform managed

# 2) Bind rotated secrets and startup validator env vars
gcloud run services update <SERVICE_NAME> `
  --project historyapp-d1d66 `
  --update-secrets JWT_SECRET=backend_jwt_secret_staging:latest,FIREBASE_SERVICE_ACCOUNT_JSON=backend_firebase_service_account_json_staging:latest `
  --update-env-vars JWT_SECRET_ROTATED_AT=2026-04-18,JWT_SECRET_MAX_AGE_DAYS=90,FIREBASE_CREDENTIALS_ROTATED_AT=2026-04-18,FIREBASE_CREDENTIALS_MAX_AGE_DAYS=90,CLIENT_ORIGINS=<STAGING_ORIGINS>,CORS_CREDENTIALS=true

# 3) Verify revision health
gcloud run services describe <SERVICE_NAME> --project historyapp-d1d66 --format="value(status.latestReadyRevisionName,status.conditions)"
```
