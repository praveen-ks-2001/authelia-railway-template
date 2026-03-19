# Authelia on Railway

A production-ready [Authelia](https://www.authelia.com/) deployment for [Railway](https://railway.app), configured entirely via environment variables.

Authelia is a self-hosted authentication and authorization server providing:
- Single Sign-On (SSO) via forward-auth
- Two-factor authentication (TOTP, WebAuthn)
- OpenID Connect provider (optional)
- Fine-grained access control rules

## Stack

| Service    | Purpose                                                  |
|------------|----------------------------------------------------------|
| Authelia   | Auth portal (this repo)                                  |
| PostgreSQL | Persistent storage (sessions, TOTP secrets, OIDC tokens) |
| Redis      | Session cache                                            |

## Deploy on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/authelia)

### Manual setup

1. Fork this repo
2. Create a new Railway project
3. Add a **PostgreSQL** service
4. Add a **Redis** service
5. Add a new service from your forked repo
6. Set environment variables (see `.env.example` or the tables below)
7. Deploy

## Required Environment Variables

| Variable | Description |
|---|---|
| `AUTHELIA_DOMAIN` | Your root domain (e.g. `example.com`) — no `https://` prefix |
| `AUTHELIA_AUTH_URL` | Full public HTTPS URL of Authelia (e.g. `https://auth.example.com`) |
| `AUTHELIA_SESSION_SECRET` | Random secret for session signing — use `${{secret(32)}}` |
| `AUTHELIA_STORAGE_ENCRYPTION_KEY` | Random encryption key — use `${{secret(32)}}` |
| `AUTH_JWT_SECRET` | JWT secret for password reset — use `${{secret(32)}}` |
| `PG_HOST` | Reference: `${{Postgres.PGHOST}}` |
| `PG_PORT` | Reference: `${{Postgres.PGPORT}}` |
| `PG_DATABASE` | Reference: `${{Postgres.PGDATABASE}}` |
| `PG_USERNAME` | Reference: `${{Postgres.PGUSER}}` |
| `PG_PASSWORD` | Reference: `${{Postgres.PGPASSWORD}}` |
| `AUTHELIA_SESSION_REDIS_HOST` | Reference: `${{Redis.REDISHOST}}` |
| `AUTHELIA_SESSION_REDIS_PORT` | Reference: `${{Redis.REDISPORT}}` |
| `AUTHELIA_SESSION_REDIS_PASSWORD` | Reference: `${{Redis.REDISPASSWORD}}` |
| `PORT` | Must be `9091` |
| `RAILWAY_RUN_UID` | Must be `0` |

## Initial User

Set these variables to create the first user on first boot:

| Variable | Description |
|---|---|
| `INIT_USERNAME` | Username (default: `admin`) |
| `INIT_PASSWORD` | Password — required on first boot |
| `INIT_EMAIL` | Email (optional, defaults to `username@domain`) |
| `INIT_DISPLAY_NAME` | Display name (optional, defaults to `Administrator`) |

- Users are seeded into `/config/users_database.yml` on **first boot only**. Subsequent restarts skip this step.
- Authelia watches the file live — changes take effect without a restart.
- To add more users after first boot, edit `users_database.yml` directly on the volume.
- Postgres stores TOTP secrets, WebAuthn credentials, OIDC tokens, and session data — not the user list itself.

## Access Control

By default, `ACCESS_CONTROL_DEFAULT_POLICY` is set to `two_factor`. This requires users to register a TOTP or WebAuthn device after first login.

> **Note:** Registering a 2FA device requires Authelia to send a verification email. Without SMTP configured, this email is written to `/config/notifications.txt` on the volume and cannot be delivered. Set `ACCESS_CONTROL_DEFAULT_POLICY=one_factor` to use username + password only, or configure SMTP to enable full 2FA.

| Policy | Behaviour |
|---|---|
| `one_factor` | Username + password only |
| `two_factor` | Username + password + TOTP or WebAuthn (requires SMTP for device registration) |

## Optional Variables

See `.env.example` for the full list. Key optional vars:

| Variable | Default | Description |
|---|---|---|
| `ACCESS_CONTROL_DEFAULT_POLICY` | `two_factor` | `one_factor` or `two_factor` |
| `AUTHELIA_LOG_LEVEL` | `info` | `trace`, `debug`, `info`, `warn`, `error` |
| `SMTP_HOST` | — | Enables email delivery for 2FA and password reset |
| `OIDC_CLIENT_ID` | — | Enables OpenID Connect provider |

## How it works

On every container start, `entrypoint.sh`:

1. Validates all required environment variables
2. Generates `/config/configuration.yml` from scratch
3. On **first boot** only: hashes passwords and writes `/config/users_database.yml`
4. Hands off to the Authelia binary

Changing any setting is as simple as updating an env var and redeploying — no manual file editing needed.

## SMTP (optional)

If `SMTP_HOST` is not set, Authelia uses a filesystem notifier — emails are written to `/config/notifications.txt`. This is fine for testing but means 2FA device registration and password reset won't deliver real emails.

To enable SMTP:

```
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USERNAME="you@gmail.com"
SMTP_PASSWORD="your-app-password"
SMTP_SENDER="Authelia <authelia@example.com>"
```

## OIDC (optional)

Authelia can act as an OpenID Connect provider for apps like Gitea, Grafana, Nextcloud, and Outline. Set the following to enable it:

```
OIDC_CLIENT_ID="my-app"
OIDC_CLIENT_SECRET="strong-secret"
OIDC_REDIRECT_URI="https://my-app.example.com/oauth/callback"
AUTHELIA_OIDC_HMAC_SECRET="strong-secret"
```

An RSA key pair is auto-generated on first boot.

## Connecting your reverse proxy

Authelia is a **forward-auth middleware** — it doesn't protect anything by itself. Configure your reverse proxy (Traefik, Nginx, Caddy) to forward auth requests to:

```
https://your-authelia-domain/api/authz/forward-auth
```

Authelia listens on port `9091`.
