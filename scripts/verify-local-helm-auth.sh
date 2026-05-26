#!/usr/bin/env bash
# Verify local Helm release has auth secret keys required by the chart.
set -euo pipefail

NAMESPACE="${1:-llm-evaluation}"
RELEASE="${2:-llm-evaluation-service}"
SECRET_NAME="${RELEASE}-secrets"

echo "Checking secret ${SECRET_NAME} in namespace ${NAMESPACE}..."
if ! kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null 2>&1; then
  echo "Secret not found. Run:" >&2
  echo "  helm upgrade --install ${RELEASE} charts/llm-evaluation-service \\" >&2
  echo "    --namespace ${NAMESPACE} --create-namespace \\" >&2
  echo "    -f charts/llm-evaluation-service/values-local.yaml" >&2
  exit 1
fi

keys="$(kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" -o jsonpath='{.data}' | python3 -c "import json,sys; print(' '.join(json.load(sys.stdin).keys()))")"
echo "Secret keys: ${keys}"

for required in APP_DATABASE_URL APP_AUTH_DEMO_SECRET; do
  if ! kubectl -n "${NAMESPACE}" get secret "${SECRET_NAME}" -o jsonpath="{.data.${required}}" | grep -q .; then
    echo "Missing required key: ${required}" >&2
    echo "Re-run helm upgrade with values-local.yaml (config.authEnabled=true, secrets.authDemoSecret set)." >&2
    exit 1
  fi
done

echo "Auth secret wiring looks correct."
