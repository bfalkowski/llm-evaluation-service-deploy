# Roadmap

Practical next milestones for turning the current template into a more complete
platform slice.

## 1. Auth Boundary

Add authentication and tenant authorization at the API boundary.

Expected shape:

- API derives `tenant_id` from auth claims instead of trusting request input.
- Console authenticates through the platform ingress or an app auth flow.
- Cross-tenant reads remain `404`.
- Tests cover allowed, denied, and missing-auth cases.

## 2. Durable Queue

Replace the in-process queue with a durable worker queue.

Expected shape:

- API process submits jobs.
- Worker process consumes jobs.
- Queue supports retries and dead-letter behavior.
- Helm chart deploys API and worker as separate workloads.
- Operational docs include queue depth and retry checks.

## 3. Provider Adapter

Replace the mock evaluator with a provider adapter boundary.

Expected shape:

- Provider calls are isolated behind an interface.
- Timeouts, retries, and budget controls are explicit.
- Prompt and answer content are not logged or traced by default.
- Tests cover provider success, timeout, retryable failure, and terminal failure.

## 4. Metrics

Expand metrics for operational visibility.

Expected shape:

- Request count and latency. Added in service and exposed at `/metrics`.
- Evaluation job status counts. Added in service and exposed at `/metrics`.
- Scoring latency. Added in service and exposed at `/metrics`.
- Service scrape annotations. Supported by chart values.
- Job queue depth and age.
- Provider error and timeout counts.
- Optional cost and token usage signals when a real provider is added.

## 5. Security Scanning

Add supply-chain checks to CI.

Expected shape:

- Dependency vulnerability scan.
- Container image vulnerability scan.
- Dockerfile lint or policy check.
- Optional SBOM generation.
- Release docs describe how findings are handled.

## 6. GitOps Automation

Automate image tag promotion into deployment configuration.

Expected shape:

- Service and console image publishes can open deploy-repo update PRs.
- Deploy repo CI validates Helm output before merge.
- GitOps controller reconciles environment values.
- Rollback uses previous image tags or previous GitOps commits.

## 7. Production Data Policy

Make prompt and answer retention explicit.

Expected shape:

- Retention period documented.
- Redaction/classification boundary documented.
- Audit events are durable and append-only.
- Admin/operator access to details is controlled and logged.

## 8. Environment Promotion

Separate local, dev, staging, and production-shaped values.

Expected shape:

- Local uses demo Postgres and `latest`.
- Dev uses managed Postgres and immutable tags.
- Staging mirrors production controls with lower scale.
- Production values are examples only unless paired with real secret and ingress setup.

## Current Priority

The highest-impact next implementation milestone is the API/worker split with a durable
queue. That change turns the service from a single-process starter into a more realistic
managed runtime workload while preserving the current API contract.
