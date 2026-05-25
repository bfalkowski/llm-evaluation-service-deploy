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
