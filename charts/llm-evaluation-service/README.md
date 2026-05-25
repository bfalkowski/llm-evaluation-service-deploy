# llm-evaluation-service Helm Chart

Deploys the LLM evaluation service and optional Streamlit console to Kubernetes.

The chart is intentionally small. It covers the API Deployment, Service, ServiceAccount,
ConfigMap, optional Secret, optional demo Postgres, NetworkPolicy examples, optional
console workload, and optional Ingress. It can also run Alembic migrations as a Helm
pre-install/pre-upgrade Job.

## Values Files

```text
values.yaml                Safe defaults and shared chart settings
values-local.yaml          Local cluster demo with in-cluster Postgres
values-dev.yaml            Managed-runtime example with external secrets
values-prod-example.yaml   Production-shaped example values
```

## Validate

```bash
helm lint charts/llm-evaluation-service

helm template llm-evaluation-service \
  charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-local.yaml
```

The chart includes `values.schema.json`, so `helm lint` also validates common value
types and allowed options.

Render all provided values files:

```bash
helm template llm-evaluation-service charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-local.yaml

helm template llm-evaluation-service charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-dev.yaml

helm template llm-evaluation-service charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-prod-example.yaml
```

## Local Install

`values-local.yaml` enables demo Postgres and creates demo Secret values.
It also enables the companion Streamlit console.

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-local.yaml
```

Check rollout:

```bash
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service
kubectl -n llm-evaluation get pods
```

Port-forward:

```bash
kubectl -n llm-evaluation port-forward service/llm-evaluation-service 8000:80
kubectl -n llm-evaluation port-forward service/llm-evaluation-service-console 8501:80
```

Test:

```bash
curl -s http://localhost:8000/health/ready
```

Expected response:

```json
{"status":"ready"}
```

Open the console at:

```text
http://localhost:8501
```

For the complete local platform flow, see `docs/local-platform.md` from the repository
root.

## Managed Runtime Install

Managed environments should provide secrets externally and use a managed Postgres
connection string. Do not enable demo Postgres outside local development.

Example with a pre-created Kubernetes Secret:

```bash
export APP_DATABASE_URL='<managed-postgres-connection-url>'

kubectl -n llm-evaluation create secret generic llm-evaluation-service-secrets \
  --from-literal=APP_DATABASE_URL="$APP_DATABASE_URL"
```

Install with the dev values and an immutable image tag:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

## Database Migrations

`values-dev.yaml` and `values-prod-example.yaml` enable the migration Job:

```yaml
migrations:
  enabled: true
```

By default the Job runs as a Helm `pre-install,pre-upgrade` hook:

```text
alembic upgrade head
```

The application config sets:

```yaml
config:
  autoCreateSchema: false
```

That keeps schema changes as an explicit deployment step instead of relying on app
startup to create tables.

`values-local.yaml` keeps migrations disabled and `config.autoCreateSchema=true` because
the demo Postgres Deployment may not be ready before a Helm pre-install hook runs.

## Image Tags

The service repo publishes:

```text
ghcr.io/bfalkowski/llm-evaluation-service-starter:latest
ghcr.io/bfalkowski/llm-evaluation-service-starter:<full-commit-sha>
```

The console repo publishes:

```text
ghcr.io/bfalkowski/llm-evaluation-console:latest
ghcr.io/bfalkowski/llm-evaluation-console:<full-commit-sha>
```

Use `latest` for quick local demos. Use full commit SHA tags for managed runtime
deployments.

## Important Values

| Value | Purpose |
| --- | --- |
| `image.repository` | Container image repository |
| `image.tag` | Image tag to deploy |
| `replicaCount` | Number of API replicas |
| `config.environment` | Service environment label |
| `config.otelExporter` | `console`, `otlp`, or `none` |
| `config.otelOtlpEndpoint` | OTLP collector endpoint |
| `config.autoCreateSchema` | Whether the app creates tables on startup |
| `secrets.create` | Create a Kubernetes Secret from values |
| `secrets.existingSecretName` | Use an externally managed Secret |
| `migrations.enabled` | Render the Alembic migration Job |
| `postgresDemo.enabled` | Enable local demo Postgres |
| `networkPolicy.enabled` | Render NetworkPolicy resources |
| `ingress.enabled` | Render Ingress resource |
| `console.enabled` | Render the Streamlit console Deployment and Service |
| `console.image.tag` | Console image tag to deploy |
| `console.config.apiBaseUrl` | Optional API URL override; defaults to the in-cluster service URL |
| `console.ingress.enabled` | Render console Ingress resource |

## Cleanup

```bash
helm uninstall llm-evaluation-service --namespace llm-evaluation
kubectl delete namespace llm-evaluation
```

## Notes

- Secret values in `values-local.yaml` are only for local demos.
- Managed environments should inject secrets through the platform or deployment pipeline.
- NetworkPolicy behavior depends on the cluster CNI.
- The chart does not install an OpenTelemetry Collector; it only configures the service to export to one.
