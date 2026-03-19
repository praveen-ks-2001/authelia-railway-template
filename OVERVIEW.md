![Authelia logo](placeholder-logo.png)

# Deploy and Host Authelia

Authelia is an open-source authentication and authorization server that adds single sign-on (SSO) and two-factor authentication (2FA) to your web applications via a forward-auth middleware. It's built for developers who want to protect self-hosted services without shipping auth code — supporting TOTP, WebAuthn, and an OpenID Connect provider that is OpenID Certified™.

Self-host Authelia on Railway with this one-click deploy template. It pre-wires Authelia with a PostgreSQL database for persistent schema storage and a Redis instance for session caching — all connected over Railway's private network with no manual networking or Docker configuration required.

![Authelia Railway architecture](placeholder-architecture.png)

## Getting Started with Authelia on Railway

After deploying, set `AUTHELIA_DOMAIN` to your domain and `AUTHELIA_AUTH_URL` to the full public HTTPS URL of this service. Visit the URL in your browser to reach the Authelia login portal and sign in with the credentials you set in `INIT_USERNAME` and `INIT_PASSWORD`. This template defaults to **one-factor authentication** — username and password only, no 2FA device required. Once logged in, configure your reverse proxy to forward authentication requests to `https://<your-authelia-url>/api/authz/forward-auth` to start protecting applications.

> **Want two-factor authentication (TOTP/WebAuthn)?** Set `ACCESS_CONTROL_DEFAULT_POLICY=two_factor` and configure SMTP (see SMTP variables below). Without SMTP, Authelia cannot deliver the verification email required to register a 2FA device.

![Authelia dashboard screenshot](placeholder-screenshot.png)

## About Hosting Authelia

Authelia is a lightweight IAM gateway — not a full identity provider. It sits in front of your applications and delegates auth via forward auth, so your reverse proxy checks with Authelia before serving any request.

**Key features:**
- Single Sign-On across all subdomains with one session cookie
- Two-factor authentication: TOTP, WebAuthn (YubiKey, passkeys), Duo push
- OpenID Connect provider (OpenID Certified™) — use as an IdP for Gitea, Grafana, Nextcloud
- Fine-grained access control per domain, subdomain, or path
- Brute-force protection with configurable lockouts and ban times
- File-based user database — no LDAP required

**Architecture:** Authelia stores its schema in PostgreSQL (sessions, TOTP secrets, OIDC tokens) and uses Redis as a distributed session cache. On Railway, both services connect to Authelia over `.railway.internal` private hostnames.

## Why Deploy Authelia on Railway

One-click deploy Authelia with its full stack — no Docker configs, volume management, or networking to wire up manually:

- Private networking between Authelia, Postgres, and Redis out of the box
- Fully env-var driven — change any setting, redeploy, done
- Auto-generated secrets via Railway's `${{secret(32)}}` syntax
- Managed TLS and custom domain support
- One-click redeploys from Git

## Common Use Cases

- **Protect homelab services** — add login + 2FA to Grafana, Portainer, Jellyfin, Home Assistant without modifying each app
- **SSO across subdomains** — one login session valid across all `*.yourdomain.com` services
- **OIDC provider** — use Authelia as the identity provider for OAuth2/OIDC-compatible apps
- **Lock staging environments** — gate internal dev URLs behind 2FA without shipping auth code

## Dependencies for Authelia

- **Authelia** — `authelia/authelia:4.38` ([GitHub](https://github.com/praveen-ks-2001/authelia-railway-template), [Docker Hub](https://hub.docker.com/r/authelia/authelia))
- **PostgreSQL** — Railway-managed Postgres (persistent schema and OIDC token storage)
- **Redis** — Railway-managed Redis (distributed session cache)

### Environment Variables Reference

| Variable | Description | Required |
|---|---|---|
| `AUTHELIA_DOMAIN` | Root domain cookies are scoped to (e.g. `example.com`) | Yes |
| `AUTHELIA_AUTH_URL` | Full public HTTPS URL of this Authelia instance | Yes |
| `AUTHELIA_SESSION_SECRET` | Secret for signing session cookies (min 64 chars) | Yes |
| `AUTHELIA_STORAGE_ENCRYPTION_KEY` | Key for encrypting storage data (min 20 chars) | Yes |
| `AUTH_JWT_SECRET` | JWT secret for password reset tokens | Yes |
| `INIT_USERNAME` | First admin username (default: `admin`) | First boot |
| `INIT_PASSWORD` | First admin password — can remove after first deploy | First boot |
| `ACCESS_CONTROL_DEFAULT_POLICY` | `one_factor` (default) or `two_factor` (requires SMTP) | No |
| `AUTHELIA_LOG_LEVEL` | Log verbosity: `trace`, `debug`, `info`, `warn`, `error` | No |
| `SMTP_HOST` | Required for 2FA device registration and password reset emails | No |
| `SMTP_PORT` | SMTP port (default: `587`) | No |
| `SMTP_USERNAME` | SMTP login username | No |
| `SMTP_PASSWORD` | SMTP login password | No |
| `OIDC_CLIENT_ID` | Enables OpenID Connect provider when set with `OIDC_CLIENT_SECRET` | No |

### Deployment Dependencies

- **Runtime:** Alpine Linux, Bash (via `authelia/authelia:4.38`)
- **Authelia upstream:** https://github.com/authelia/authelia
- **Template repo:** https://github.com/praveen-ks-2001/authelia-railway-template

## Minimum Hardware Requirements for Authelia

Authelia is one of the most resource-efficient auth solutions available — it runs on a Raspberry Pi.

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 0.1 vCPU | 0.25 vCPU |
| RAM | 64 MB | 256 MB |
| Storage | 100 MB | 500 MB (for Postgres data) |

Unlike Authentik (2 cores + 2 GB RAM minimum) or Keycloak (512 MB+ RAM), Authelia typically uses 20–25 MB of memory at runtime.

## Self-Hosting Authelia

To run Authelia on your own VPS using Docker Compose:

```yaml
# docker-compose.yml
services:
  authelia:
    image: authelia/authelia:4.38
    volumes:
      - ./config:/config
    ports:
      - "9091:9091"
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: authelia
      POSTGRES_USER: authelia
      POSTGRES_PASSWORD: changeme

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass changeme
```

Minimal `./config/configuration.yml` to get started:

```yaml
server:
  address: tcp://0.0.0.0:9091/
authentication_backend:
  file:
    path: /config/users_database.yml
session:
  secret: changeme
  cookies:
    - domain: example.com
      authelia_url: https://auth.example.com
storage:
  encryption_key: changeme
  postgres:
    address: tcp://postgres:5432
    database: authelia
    username: authelia
    password: changeme
notifier:
  filesystem:
    filename: /config/notifications.txt
```

## Authelia vs Authentik vs Keycloak

| Feature | Authelia | Authentik | Keycloak |
|---|---|---|---|
| Open source | ✅ Apache 2.0 | ✅ MIT | ✅ Apache 2.0 |
| Self-hostable | ✅ | ✅ | ✅ |
| Memory usage | ~25 MB | ~500 MB+ | ~512 MB+ |
| Full IdP (SAML, LDAP) | ❌ | ✅ | ✅ |
| Forward auth | ✅ | ✅ | ❌ native |
| Best for | Homelabs, lightweight SSO | Growing teams, full IdP | Enterprise |

Authelia wins on resource usage and simplicity. Choose Authentik or Keycloak if you need SAML, LDAP, or enterprise-scale user management.

## Adding Multiple Users

This template seeds one user on first boot. To add more users after deployment:

1. **Deploy a Filebrowser service** in the same Railway project — [![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/Nan7Bs)
2. **Mount the Authelia volume** (`/config`) on the Filebrowser service
3. Open Filebrowser, navigate to `users_database.yml`, and add new user entries in this format:

```yaml
users:
  existing_user:
    disabled: false
    displayname: "Existing User"
    password: "$argon2id$..."   # keep existing hash
    email: existing@example.com
    groups:
      - users

  new_user:
    disabled: false
    displayname: "New User"
    password: "$argon2id$..."   # generate with: authelia crypto hash generate argon2 --password "yourpassword"
    email: newuser@example.com
    groups:
      - users
```

4. **Detach the volume from Filebrowser** and reattach it to Authelia
5. Authelia watches the file live — changes take effect immediately with no restart needed

> To generate a password hash without a running Authelia instance, use the [Authelia CLI](https://www.authelia.com/reference/cli/authelia/authelia_crypto_hash_generate_argon2/) locally: `authelia crypto hash generate argon2 --password "yourpassword"`

## How Much Does Authelia Cost?

Authelia is 100% free and open-source under the Apache 2.0 license — no paid tiers, no licensing fees, no feature paywalls. On Railway, you pay only for the infrastructure (Authelia, Postgres, Redis). There is no official Authelia cloud offering; self-hosting is the only deployment model.

## FAQ

**What is Authelia?**
Authelia is an open-source forward authentication server that adds SSO and 2FA to web applications. It works as middleware alongside a reverse proxy (Traefik, NGINX, Caddy) — the proxy asks Authelia to verify identity before forwarding a request to the upstream app.

**What does this Railway template deploy?**
Three services: Authelia (the auth portal on port 9091), a PostgreSQL database (schema, TOTP secrets, OIDC tokens), and a Redis instance (session cache). All three are connected over Railway's private network using `.railway.internal` hostnames.

**Why does this template include PostgreSQL and Redis?**
Authelia requires a relational database for persistent storage and Redis for distributed session caching. Without both, Authelia will refuse to start.

**Can I use this in production?**
Yes. Authelia is used in production across IT, healthcare, and financial services. For production: use a strong `AUTHELIA_STORAGE_ENCRYPTION_KEY`, configure SMTP for real email notifications, and point a custom domain at the service.

**Does Authelia support OpenID Connect?**
Yes — Authelia is OpenID Certified™ and can act as an OIDC provider for Gitea, Grafana, Nextcloud, Outline, and Portainer. Set `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_REDIRECT_URI`, and `AUTHELIA_OIDC_HMAC_SECRET` to enable it. An RSA key pair is auto-generated on first boot.

**How do I protect an app with Authelia?**
Configure your reverse proxy to forward auth requests to `https://<authelia-url>/api/authz/forward-auth`. Authelia handles login, 2FA, and redirects — your app only receives authenticated requests.

**What 2FA methods are supported?**
TOTP (Google Authenticator, Authy, 1Password), WebAuthn (YubiKey, passkeys, hardware security keys), and Duo mobile push notifications. To enable 2FA, set `ACCESS_CONTROL_DEFAULT_POLICY=two_factor` and configure SMTP — Authelia sends a verification email before allowing a device to be registered.

---

## Template Metadata

### Titles
1. Deploy Authelia SSO and 2FA on Railway
2. Self-Host Authelia: Open Source Auth Gateway on Railway
3. Run Authelia with Postgres and Redis on Railway
4. Launch a Self-Hosted SSO Portal with Authelia on Railway
5. Authelia — Lightweight Open Source Keycloak Alternative

### Descriptions
1. Self-hosted SSO and 2FA portal with Postgres and Redis on Railway. (64 chars)
2. Deploy Authelia on Railway — forward auth, TOTP, WebAuthn, OIDC. (65 chars)
3. Open-source auth gateway. SSO, 2FA, OIDC. Postgres + Redis pre-wired. (71 chars)
4. Add login and 2FA to any app. Authelia + Postgres + Redis on Railway. (70 chars)
5. Authelia: self-hosted SSO, TOTP, WebAuthn, OpenID Connect, forward auth. (73 chars)

### Slugs
1. authelia
2. self-host-authelia
3. authelia-sso-2fa
4. authelia-postgres-redis
5. authelia-forward-auth

### Service Logo
URL: https://www.authelia.com/svgs/branding/logo.svg
Format: SVG
Source: authelia.com official branding page (https://www.authelia.com/reference/guides/branding/)
