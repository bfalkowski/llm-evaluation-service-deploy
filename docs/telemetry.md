# Telemetry

The service supports console, disabled, and OTLP trace export through environment
configuration:

```text
APP_OTEL_ENABLED
APP_OTEL_EXPORTER
APP_OTEL_OTLP_ENDPOINT
```

Local values use console tracing. Dev and production-shaped values assume an OTLP
collector endpoint.

The service also exposes Prometheus-compatible metrics on `/metrics`. If the cluster
scrapes Services by annotation, enable scrape metadata on the API Service:

```yaml
service:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: /metrics
    prometheus.io/port: "80"
```

For clusters that use the Prometheus Operator, keep ServiceMonitor resources in the
environment layer that owns the monitoring stack instead of requiring that CRD in this
base chart.
