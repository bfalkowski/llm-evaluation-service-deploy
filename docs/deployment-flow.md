# Deployment Flow

This repository is the deployment/config side of a multi-repo delivery flow.

```text
llm-evaluation-service-starter
  -> test, lint, type check
  -> build container image
  -> publish image to GHCR

llm-evaluation-console
  -> lint
  -> build console container image
  -> publish image to GHCR

llm-evaluation-service-deploy
  -> select service and console image tags in Helm values
  -> render and validate Kubernetes manifests
  -> install or upgrade into Kubernetes
```

## Service Repository

Source:

```text
https://github.com/bfalkowski/llm-evaluation-service-starter
```

Responsibilities:

- FastAPI application code.
- Tests and OpenAPI contract.
- Dockerfile.
- CI for tests, static checks, package build, and image publishing.
- Published container image.
- Basic starter Kubernetes manifests for local understanding.

Published image:

```text
ghcr.io/bfalkowski/llm-evaluation-service-starter:<tag>
```

## Console Repository

Source:

```text
https://github.com/bfalkowski/llm-evaluation-console
```

Responsibilities:

- Streamlit operator console.
- Evaluation submission and review workflow.
- Dockerfile.
- CI for linting, image build, and image publishing.

Published image:

```text
ghcr.io/bfalkowski/llm-evaluation-console:<tag>
```

## Deployment Repository

Source:

```text
https://github.com/bfalkowski/llm-evaluation-service-deploy
```

Responsibilities:

- Helm chart for the service and optional console.
- Environment-specific values.
- Secret expectations.
- Managed Postgres assumptions.
- Telemetry endpoint configuration.
- Offline manifest validation in CI.

## Typical Managed Kubernetes Flow

See `docs/managed-kubernetes.md` for the concrete managed-runtime runbook.

1. Merge a service change to `main`.
2. Service CI publishes a new image tag to GHCR.
3. Console CI publishes a new image tag to GHCR when the console changes.
4. Choose immutable image tags for deployment.
5. Update the deploy repo values or pass tags with `--set`.
6. Deploy repo CI runs Helm lint, Helm template, and kubeconform.
7. Apply the chart with Helm or let a GitOps controller apply it.
8. The migration Job runs `alembic upgrade head` before app pods roll forward.

Manual Helm example:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

## Local Demo Flow

Local demos can use `latest` and the demo Postgres values:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-local.yaml
```

Then:

```bash
kubectl -n llm-evaluation port-forward service/llm-evaluation-service 8000:80
kubectl -n llm-evaluation port-forward service/llm-evaluation-service-console 8501:80
curl -s http://localhost:8000/health/ready
```

## What Changes By Environment

Local:

- May use `latest`.
- Enables demo Postgres.
- Enables the console.
- Can create demo Secret values.
- Uses console or disabled telemetry export.

Dev:

- Uses an immutable image tag.
- Uses managed Postgres.
- Can enable the console with an internal service URL or separate ingress.
- Expects externally managed secrets.
- Exports telemetry through OTLP.

Production-shaped example:

- Uses an immutable image tag.
- Uses multiple replicas.
- Enables ingress placeholders.
- Enables separate service and console ingress placeholders.
- Expects managed secrets, managed Postgres, TLS, and platform-level controls.

## What Is Not Automated Yet

- Image tag update PRs.
- GitOps controller setup.
- Cloud provider identity integration.
- Managed Secret operator integration.
- Database migrations.
- Separate API and worker deployments.
