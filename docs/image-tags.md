# Image Tags

Use immutable image tags for managed Kubernetes environments.

The service repository publishes:

```text
ghcr.io/bfalkowski/llm-evaluation-service-starter:latest
ghcr.io/bfalkowski/llm-evaluation-service-starter:<full-commit-sha>
```

The console repository publishes:

```text
ghcr.io/bfalkowski/llm-evaluation-console:latest
ghcr.io/bfalkowski/llm-evaluation-console:<full-commit-sha>
```

`latest` is useful for quick local demos. Dev and production-shaped values should use
full commit SHA tags so rollouts are reproducible.

The source repository is:

```text
https://github.com/bfalkowski/llm-evaluation-service-starter
https://github.com/bfalkowski/llm-evaluation-console
```
