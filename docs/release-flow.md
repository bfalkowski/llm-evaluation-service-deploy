# Release Flow

Move changes from source repositories to a Kubernetes deployment.

## Release Inputs

Every managed-runtime release should identify:

- Service image tag.
- Console image tag.
- Helm chart commit.
- Target values file or environment overlay.
- Migration expectation.
- Rollback tags.

Use full commit SHA image tags for managed environments.

## Service Change

1. Merge a service change to `main` in `llm-evaluation-service-starter`.
2. Wait for service CI to pass.
3. Confirm the service image exists in GHCR:

   ```text
   ghcr.io/bfalkowski/llm-evaluation-service-starter:<service-full-commit-sha>
   ```

4. Update this deploy repo or pass the tag at deploy time:

   ```bash
   --set image.tag=<service-full-commit-sha>
   ```

5. If the change includes a database migration, keep migrations enabled:

   ```yaml
   migrations:
     enabled: true
   ```

6. Deploy with Helm or let GitOps apply the updated values.

## Console Change

1. Merge a console change to `main` in `llm-evaluation-console`.
2. Wait for console CI to pass.
3. Confirm the console image exists in GHCR:

   ```text
   ghcr.io/bfalkowski/llm-evaluation-console:<console-full-commit-sha>
   ```

4. Update this deploy repo or pass the tag at deploy time:

   ```bash
   --set console.image.tag=<console-full-commit-sha>
   ```

5. Deploy with Helm or let GitOps apply the updated values.

## Chart Or Values Change

1. Change chart templates, schema, docs, or values in this repo.
2. Run local validation:

   ```bash
   helm lint charts/llm-evaluation-service
   helm template llm-evaluation-service charts/llm-evaluation-service \
     -f charts/llm-evaluation-service/values-dev.yaml
   helm template llm-evaluation-service charts/llm-evaluation-service \
     -f charts/llm-evaluation-service/values-prod-example.yaml
   ```

3. Merge after CI passes.
4. Deploy with the intended service and console image tags.

## Manual Helm Release

Dev-shaped install:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

Production-shaped install:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-prod-example.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

## GitOps Release

For GitOps, keep environment-specific values in this repo or a downstream environment
repo. A release is then a small values change:

```yaml
image:
  tag: <service-full-commit-sha>

console:
  image:
    tag: <console-full-commit-sha>
```

The GitOps controller reconciles the chart after the values commit lands.

## Verification

```bash
kubectl -n llm-evaluation get pods
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service-console
kubectl -n llm-evaluation get jobs
```

API readiness:

```bash
kubectl -n llm-evaluation run api-check \
  --rm \
  --restart=Never \
  --image=curlimages/curl:8.11.1 \
  -- http://llm-evaluation-service/health/ready
```

Console access depends on the environment:

- Local: port-forward `service/llm-evaluation-service-console`.
- Managed: use the configured console ingress host.

## Rollback

Fast rollback:

```bash
helm rollback llm-evaluation-service --namespace llm-evaluation
```

Pin previous known-good tags:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  -f charts/llm-evaluation-service/values-dev.yaml \
  --set image.tag=<previous-service-full-commit-sha> \
  --set console.image.tag=<previous-console-full-commit-sha>
```

If a migration has already run, check whether the schema change is backward compatible
before rolling application images back.

## Current Gaps

- No automated image tag update PRs yet.
- No vulnerability scan gate yet.
- No signed image or provenance check yet.
- No GitOps controller configuration yet.
