# Local Platform Runbook

Run the service, demo Postgres, and Streamlit console in a local Kubernetes cluster.

## Prerequisites

- Docker Desktop, kind, minikube, or another local Kubernetes runtime.
- `kubectl` pointed at the local cluster.
- Helm installed locally.
- Public access to the GHCR images:
  - `ghcr.io/bfalkowski/llm-evaluation-service-starter:latest`
  - `ghcr.io/bfalkowski/llm-evaluation-console:latest`

Check the active cluster:

```bash
kubectl config current-context
kubectl cluster-info
```

## Validate The Chart

```bash
helm lint charts/llm-evaluation-service

helm template llm-evaluation-service \
  charts/llm-evaluation-service \
  -f charts/llm-evaluation-service/values-local.yaml
```

## Install

`values-local.yaml` enables demo Postgres, creates local demo Secret values, enables
demo JWT auth, runs migrations as a Kubernetes Job, runs a separate worker Deployment,
and enables the console.

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  --create-namespace \
  -f charts/llm-evaluation-service/values-local.yaml
```

## Check Rollout

```bash
kubectl -n llm-evaluation get pods
kubectl -n llm-evaluation wait --for=condition=complete job/llm-evaluation-service-migrations --timeout=180s
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service-worker
kubectl -n llm-evaluation rollout status deployment/llm-evaluation-service-console
```

If an image pull or startup issue occurs:

```bash
kubectl -n llm-evaluation describe pod -l app.kubernetes.io/component=service
kubectl -n llm-evaluation describe pod -l app.kubernetes.io/component=worker
kubectl -n llm-evaluation describe pod -l app.kubernetes.io/component=console
kubectl -n llm-evaluation logs -l app.kubernetes.io/component=service
kubectl -n llm-evaluation logs -l app.kubernetes.io/component=worker
kubectl -n llm-evaluation logs -l app.kubernetes.io/component=console
```

## Port Forward

Open two terminal sessions.

API:

```bash
kubectl -n llm-evaluation port-forward service/llm-evaluation-service 8000:80
```

Console:

```bash
kubectl -n llm-evaluation port-forward service/llm-evaluation-service-console 8501:80
```

## Smoke Test

API health:

```bash
curl -s http://localhost:8000/health/ready
```

Create a local demo bearer token from the service repository:

```bash
cd ../llm-evaluation-service-starter
APP_AUTH_DEMO_SECRET=local-demo-secret \
python scripts/create_demo_jwt.py --tenant-id demo-tenant --subject local-user
```

Submit an evaluation:

```bash
TOKEN="<paste-token>"

curl -s -X POST http://localhost:8000/v1/evaluations \
  -H 'content-type: application/json' \
  -H "authorization: Bearer ${TOKEN}" \
  -d '{
    "project_id": "demo-project",
    "question": "What should an LLM platform monitor?",
    "answer": "It should monitor failures, latency, cost, throughput, and quality.",
    "rubric": "Score whether the answer mentions failures, latency, cost, or quality."
  }'
```

Open the console:

```text
http://localhost:8501
```

Use these default values in the console sidebar:

```text
API base URL: http://llm-evaluation-service:80
Tenant: demo-tenant
Project: demo-project
Bearer token: <paste-token>
```

For a browser running outside the cluster, the console itself calls the API from inside
the cluster, so the in-cluster API URL is expected.

## Verify Auth Secret Wiring

After install or chart changes, confirm the release secret includes demo auth keys:

```bash
./scripts/verify-local-helm-auth.sh llm-evaluation llm-evaluation-service
```

If `APP_AUTH_DEMO_SECRET` is missing, re-run `helm upgrade` with `values-local.yaml` so
Kubernetes recreates the secret from the chart template.

## Upgrade Images

For local demos:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  -f charts/llm-evaluation-service/values-local.yaml \
  --set image.tag=latest \
  --set console.image.tag=latest
```

`values-local.yaml` uses `Always` as the pull policy because `latest` can otherwise
reuse a stale image already cached by the local Kubernetes node.

For reproducible managed-runtime style testing, use immutable tags:

```bash
helm upgrade --install llm-evaluation-service \
  charts/llm-evaluation-service \
  --namespace llm-evaluation \
  -f charts/llm-evaluation-service/values-local.yaml \
  --set image.tag=<service-full-commit-sha> \
  --set console.image.tag=<console-full-commit-sha>
```

## Cleanup

```bash
helm uninstall llm-evaluation-service --namespace llm-evaluation
kubectl delete namespace llm-evaluation
```

## Notes

- The local demo Secret values, including `APP_AUTH_DEMO_SECRET`, are not suitable for shared environments.
- Demo Postgres does not use persistent storage.
- Managed environments should use managed Postgres, external secret injection, TLS, immutable image tags, and production identity-provider integration.
