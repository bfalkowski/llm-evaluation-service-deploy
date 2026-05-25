# Deployment Flow

This repository is the deployment/config side of a two-repo service delivery flow.

```text
llm-evaluation-service-starter
  -> test, lint, type check
  -> build container image
  -> publish image to GHCR

llm-evaluation-service-deploy
  -> select image tag in Helm values
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

## Deployment Repository

Source:

```text
https://github.com/bfalkowski/llm-evaluation-service-deploy
```

Responsibilities:

- Helm chart.
- Environment-specific values.
- Secret expectations.
- Managed Postgres assumptions.
- Telemetry endpoint configuration.
- Offline manifest validation in CI.

## Typical Managed Kubernetes Flow

1. Merge a service change to `main`.
2. Service CI publishes a new image tag to GHCR.
3. Choose the immutable image tag for deployment.
4. Update the deploy repo values or pass the tag with `--set image.tag=<full-commit-sha>`.
5. Deploy repo CI runs Helm lint, Helm template, and kubeconform.
6. Apply the chart with Helm or let a GitOps controller apply it.

Manual Helm example:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<full-commit-sha>
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
curl -s http://localhost:8000/health/ready
```

## What Changes By Environment

Local:

- May use `latest`.
- Enables demo Postgres.
- Can create demo Secret values.
- Uses console or disabled telemetry export.

Dev:

- Uses an immutable image tag.
- Uses managed Postgres.
- Expects externally managed secrets.
- Exports telemetry through OTLP.

Production-shaped example:

- Uses an immutable image tag.
- Uses multiple replicas.
- Enables ingress placeholders.
- Expects managed secrets, managed Postgres, TLS, and platform-level controls.

## What Is Not Automated Yet

- Image tag update PRs.
- GitOps controller setup.
- Cloud provider identity integration.
- Managed Secret operator integration.
- Database migrations.
- Separate API and worker deployments.
