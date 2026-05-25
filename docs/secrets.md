# Secrets

Do not commit real secrets.

Expected keys:

```text
APP_DATABASE_URL
POSTGRES_PASSWORD only when the local demo Postgres chart path is enabled
```

Managed environments should provide secrets through the platform, deployment pipeline,
or a dedicated secret operator.
