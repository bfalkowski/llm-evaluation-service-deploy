# Secrets

Do not commit real secrets.

Expected keys:

```text
APP_DATABASE_URL
APP_AUTH_DEMO_SECRET when demo JWT auth is enabled
POSTGRES_PASSWORD only when the local demo Postgres chart path is enabled
```

Managed environments should provide secrets through the platform, deployment pipeline,
or a dedicated secret operator.

`APP_AUTH_DEMO_SECRET` supports the service's local/demo HMAC JWT validator. Production
deployments should replace that demo auth path with OIDC/JWKS or platform-managed
identity integration and should not store identity-provider secrets in values files.
