# Authelia on Railway

A production-ready [Authelia](https://www.authelia.com/) deployment for [Railway](https://railway.app), configured entirely via environment variables.

Authelia is a self-hosted authentication and authorization server providing:
- Single Sign-On (SSO) via forward-auth
- Two-factor authentication (TOTP, WebAuthn)
- OpenID Connect provider (optional)
- Fine-grained access control rules

## Stack

| Service    | Purpose                          |
|------------|----------------------------------|
| Authelia   | Auth portal (this repo)          |
| PostgreSQL | Persistent storage               |
| Redis      | Session cache                    |

## Deploy on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/authelia)

### Manual setup

1. Fork this repo
2. Create a new Railway project
3. Add a **PostgreSQL** service
4. Add a **Redis** service
5. Add a new service from your forked repo
6. Mount a **volume** on the Authelia service at `/config`
7. Set environment variables (see `.env.example` or the table below)
8. Deploy

## Required Environment Variables

| Variable | Description |
|---|---|
| `AUTHELIA_DOMAIN` | Your root domain (e.g. `example.com`) |
| `AUTHELIA_AUTH_URL` | Full public HTTPS URL of Authelia (e.g. `https://auth.example.com`) |
| `AUTHELIA_SESSION_SECRET` | Random secret for session signing — use `${{secret(32)}}` |
| `AUTHELIA_STORAGE_ENCRYPTION_KEY` | Random encryption key — use `${{secret(32)}}` |
| `AUTHELIA_JWT_SECRET` | JWT secret for password reset — use `${{secret(32)}}` |
| `AUTHELIA_STORAGE_POSTGRES_HOST` | Reference: `${{Postgres.PGHOST}}` |
| `AUTHELIA_STORAGE_POSTGRES_PORT` | Reference: `${{Postgres.PGPORT}}` |
| `AUTHELIA_STORAGE_POSTGRES_DATABASE` | Reference: `${{Postgres.PGDATABASE}}` |
| `AUTHELIA_STORAGE_POSTGRES_USERNAME` | Reference: `${{Postgres.PGUSER}}` |
| `AUTHELIA_STORAGE_POSTGRES_PASSWORD` | Reference: `${{Postgres.PGPASSWORD}}` |
| `AUTHELIA_SESSION_REDIS_HOST` | Reference: `${{Redis.REDISHOST}}` |
| `AUTHELIA_SESSION_REDIS_PORT` | Reference: `${{Redis.REDISPORT}}` |
| `AUTHELIA_SESSION_REDIS_PASSWORD` | Reference: `${{Redis.REDIS_PASSWORD}}` |
| `AUTHELIA_INIT_PASSWORD` | Password for the initial admin user (first boot only) |

See `.env.example` for the full list of optional variables (SMTP, OIDC, session tuning, etc.).

## How it works

On every container start, `entrypoint.sh`:

1. Reads all environment variables
2. Generates `/config/configuration.yml` from scratch
3. On **first boot** only: hashes `AUTHELIA_INIT_PASSWORD` using Argon2id and writes `/config/users_database.yml`
4. Hands off to the Authelia binary

This means you can change any setting by updating an env var and redeploying — no manual file editing needed.

## First boot notes

- `AUTHELIA_INIT_PASSWORD` is only used once to seed the first user. After the first successful deploy, you can remove it from Railway variables — `users_database.yml` is already written to the volume.
- OIDC is disabled by default. Set `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_REDIRECT_URI`, and `AUTHELIA_OIDC_HMAC_SECRET` to enable it. An RSA key pair is generated automatically on first boot.
- SMTP is optional. If `SMTP_HOST` is not set, email notifications are written to `/config/notifications.txt` — useful during initial testing.

## Connecting your reverse proxy

Authelia is a **forward-auth middleware** — it doesn't protect anything by itself. You need a reverse proxy (Traefik, Nginx, Caddy) configured to forward auth requests to:

```
https://your-authelia-domain.up.railway.app/api/authz/forward-auth
```

Authelia listens on port `9091`.
