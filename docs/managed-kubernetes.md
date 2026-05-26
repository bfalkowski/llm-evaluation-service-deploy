# Managed Kubernetes Runbook

Deploy the API service, background worker, and Streamlit console to a managed Kubernetes
environment.

This flow assumes:

- Container images are published to GHCR.
- PostgreSQL is provided by a managed database service.
- Secrets are injected by the platform, pipeline, or a secret operator.
- Ingress, TLS, and DNS are managed by the cluster platform.
- Traces are exported through an OpenTelemetry Collector.

## Image Tags

Use immutable tags for managed environments.

```text
ghcr.io/bfalkowski/llm-evaluation-service-starter:<service-full-commit-sha>
ghcr.io/bfalkowski/llm-evaluation-console:<console-full-commit-sha>
```

Avoid `latest` outside local demos.

## Database

Disable demo Postgres and use an externally managed connection string.

```yaml
postgresDemo:
  enabled: false

config:
  storageBackend: postgres
  autoCreateSchema: false
```

Create or sync a Kubernetes Secret with:

```text
APP_DATABASE_URL
```

The connection URL should use the async SQLAlchemy driver expected by the service:

```text
postgresql+asyncpg://<user>:<password>@<host>:5432/<database>
```

## Secrets

Managed values should not contain secret material.

```yaml
secrets:
  create: false
  existingSecretName: llm-evaluation-service-secrets
```

The chart expects the existing Secret to contain:

```text
APP_DATABASE_URL
```

`POSTGRES_PASSWORD` is only used by the local demo Postgres path.

## Migrations

Managed values should run migrations explicitly before application pods roll forward.

```yaml
migrations:
  enabled: true
  useHelmHooks: true
```

The migration Job runs:

```text
alembic upgrade head
```

## API And Worker Split

Managed values should run the API and background worker as separate Deployments.

```yaml
worker:
  enabled: true
```

With the worker enabled, API pods run in API-only mode and worker pods claim queued jobs
from Postgres. This keeps request handling independent from evaluation processing and
allows the two workloads to scale separately.

Worker pods also recover stale `running` jobs after `config.workerStaleJobSeconds`. Jobs
with attempts remaining return to `queued`; jobs that exhausted their attempt budget are
marked `failed`.

## Telemetry

Use OTLP export and point the service at the cluster collector.

```yaml
config:
  otelExporter: otlp
  otelOtlpEndpoint: http://otel-collector:4317
```

The chart does not install the collector. The cluster should provide one separately.

## Ingress And TLS

The API and console can be exposed independently.

```yaml
ingress:
  enabled: true
  className: nginx
  host: llm-evaluation.example.com
  tls:
    enabled: true
    secretName: llm-evaluation-service-tls

console:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    host: llm-evaluation-console.example.com
    tls:
      enabled: true
      secretName: llm-evaluation-console-tls
```

The console calls the API through the in-cluster service by default:

```text
http://llm-evaluation-service:80
```

Override `console.config.apiBaseUrl` only when the console needs to call a different API
endpoint.

## Example Install

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

Production-shaped example:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-prod-example.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

## Post-Deploy Checks

```bash
kubectl -n llm-evaluation get pods
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service-worker
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service-console
kubectl -n llm-evaluation get jobs
kubectl -n llm-evaluation get ingress
```

Check API readiness from inside the cluster:

```bash
kubectl -n llm-evaluation run api-check \
  --rm \
  --restart=Never \
  --image=curlimages/curl:8.11.1 \
  -- http://llm-evaluation-service/health/ready
```

## Rollback

Roll back to the previous Helm release:

```bash
helm rollback llm-evaluation-service --namespace llm-evaluation
```

Or pin known-good image tags:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<previous-service-full-commit-sha> \
  --set console.image.tag=<previous-console-full-commit-sha>
```

## Notes

- Use environment-specific values files or GitOps overlays for real environments.
- Keep secrets outside source control.
- Keep migrations explicit and observable.
- Treat the console as an operator surface and protect it with ingress auth, network policy, or platform access controls.
