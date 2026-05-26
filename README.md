# llm-evaluation-service-deploy

Helm-based deployment configuration for the LLM evaluation service and companion console.

This repository is intended to stay separate from the service source code. The service
repository builds and publishes a container image; this repository selects an image tag
and applies environment-specific Kubernetes configuration.

Service source repository:
`https://github.com/bfalkowski/llm-evaluation-service-starter`

Console source repository:
`https://github.com/bfalkowski/llm-evaluation-console`

Published image:
`ghcr.io/bfalkowski/llm-evaluation-service-starter`

Console image:
`ghcr.io/bfalkowski/llm-evaluation-console`

## Structure

```text
charts/
  llm-evaluation-service/
    Chart.yaml
    values.yaml
    values-local.yaml
    values-dev.yaml
    values-prod-example.yaml
    templates/
docs/
```

Start with `docs/deployment-flow.md` for the full service-image-to-Helm-deploy flow.
Use `docs/local-platform.md` to run the API, demo Postgres, and console together in a
local Kubernetes cluster.
Use `docs/managed-kubernetes.md` for the managed runtime deployment path.

## Render Locally

See `charts/llm-evaluation-service/README.md` for full chart usage.

```bash
helm lint charts/llm-evaluation-service
helm template llm-evaluation-service \
  charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-local.yaml
```

CI runs the same Helm lint/render checks and validates rendered manifests with
`kubeconform`.

## Install Locally

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-local.yaml
```

See `docs/local-platform.md` for rollout checks, port-forwarding, smoke tests, and
cleanup.

## Image Tags

The service image is published by the service repository:

```text
ghcr.io/bfalkowski/llm-evaluation-service-starter:latest
ghcr.io/bfalkowski/llm-evaluation-service-starter:<full-commit-sha>
```

The console image is published by the console repository:

```text
ghcr.io/bfalkowski/llm-evaluation-console:latest
ghcr.io/bfalkowski/llm-evaluation-console:<full-commit-sha>
```

Use `latest` for quick local demos. Use immutable commit SHA tags for managed
Kubernetes environments.

## Secrets

Do not commit real secrets. Local secret files and `.env` files are ignored.

The chart can create demo secrets for local use, but managed environments should inject
secrets through the platform, deployment pipeline, or a dedicated secret operator.
