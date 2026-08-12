# Docker WordPress Stack (WordPress + MariaDB + Caddy)

A production-style local development stack for WordPress using Docker Compose, with:

- `WordPress` on Apache + PHP 8.3
- `MariaDB` 11.4
- `Caddy` as reverse proxy with automatic local TLS (`internal` CA)
- Persistent database and Caddy volumes
- WP-CLI preinstalled in the custom WordPress image

## Why it exists

It began as a local mirror of a client project's server: same PHP and
database versions, same reverse proxy in front, real HTTPS instead of plain
`localhost`. Matching the target environment is what stops the familiar
"works on my machine" class of bug — a PHP minor version or a TLS-only
cookie behaving differently in production than in development.

None of that project's code or data lives here. What remains is the shape of
the environment, generalised into the base I now start local WordPress work
from.

---

## Architecture

This repository contains two Compose stacks:

1. **Caddy global proxy** in `Caddy/docker-compose.yml`
	- Runs one shared `caddy` container
	- Publishes ports `80` and `443`
	- Watches Docker labels and routes traffic automatically

2. **WordPress app stack** in `docker-compose.yml`
	- `db`: MariaDB 11.4
	- `wordpress`: WordPress `php8.3-apache` (custom image from `Dockerfile`)
	- Connected to external network `caddy`

The WordPress service is exposed internally and routed by Caddy using these labels:

- `caddy: ${WP_HOST}`
- `caddy.reverse_proxy: "{{upstreams 80}}"`
- `caddy.tls: ${CADDY_TLS_MODE}`

---

## Requirements

- Docker Engine 24+ (or Docker Desktop)
- Docker Compose v2 (`docker compose`)
- Linux/macOS/WSL2 (Linux permissions section included below)

---

## Quick Start

### 1) Configure environment

Create your local env file from the template:

```bash
cp .env.example .env
```

Then edit `.env` and set secure values:

- `MYSQL_ROOT_PASS`
- `MYSQL_PASS`
- `WP_PASSWORD`
- `WP_HOST`
- `WORDPRESS_URL`

Every value in the template is a placeholder. The host defaults to
`yourhost.local`; whatever you choose must match the `/etc/hosts` entry in
the next step.

### 2) Add local DNS entry

Map your local domain to localhost in `/etc/hosts`:

```bash
127.0.0.1 yourhost.local
```

### 3) Start Caddy (global proxy)

```bash
cd Caddy
docker compose up -d
```

### 4) Start WordPress stack

From project root:

```bash
docker compose up -d --build
```

### 5) Open the site

Go to:

```text
https://yourhost.local
```

If your browser warns about the certificate, trust Caddy's local CA for your OS/browser (expected in local `internal` mode).

### 6) Install WordPress (optional)

Finish the install in the browser, or do it in one command with the values
already in your `.env`:

```bash
set -a && . ./.env && set +a
docker compose exec -T wordpress wp core install \
  --url="$WORDPRESS_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_USER" \
  --admin_password="$WP_PASSWORD" \
  --admin_email="$WP_EMAIL" \
  --skip-email --allow-root
```

---

## Services and Versions

- **WordPress**: `wordpress:php8.3-apache`, extended by `Dockerfile` and tagged
  `skt/wordpress:php8.3-apache` so the upstream tag is never overwritten
- **PHP**: 8.3 (stable)
- **MariaDB**: `mariadb:11.4`
- **Reverse Proxy**: `lucaslorentz/caddy-docker-proxy:latest`

---

## Project Structure

```text
.
├── docker-compose.yml        # WordPress + MariaDB stack
├── Dockerfile                # Custom WordPress image with WP-CLI
├── .env.example              # Environment template (copy to .env)
├── web/                      # WordPress document root (runtime, untracked)
└── Caddy/
	 ├── docker-compose.yml    # Shared Caddy reverse proxy
	 └── web/                  # Optional static web root (kept empty)
```

---

## Useful Commands

Start/rebuild app stack:

```bash
docker compose up -d --build
```

Stop app stack:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f
```

Open shell in WordPress container:

```bash
docker compose exec wordpress bash
```

Run WP-CLI:

```bash
docker compose exec wordpress wp --info --allow-root
```

Stop Caddy stack:

```bash
cd Caddy
docker compose down
```

---

## Linux Permissions (bind mount)

Apache inside the container writes as `www-data` (uid 33), so files created
by WordPress — uploads, plugin installs, generated files — end up owned by
that uid on the host. If your editor cannot write to them:

```bash
sudo chown -R $USER:$USER ./web
```

Overriding the container's `user:` is deliberately not done here: the
official image starts as root to bind port 80 and drops privileges itself,
so forcing a uid breaks Apache's own startup.

---

## Notes for Production

- `CADDY_TLS_MODE=internal` is ideal for local development only.
- For a real public domain, use DNS + public certificates and adjust Caddy strategy accordingly.
- Rotate all secrets in `.env` before any public deployment.

---

## Troubleshooting

- **Domain does not resolve**: check `/etc/hosts` entry.
- **TLS warning**: expected with local internal CA until trusted.
- **502 / upstream errors**: verify both stacks are running and on the `caddy` network.
- **DB connection errors**: confirm `.env` credentials and container health.

---

## License

MIT — see [LICENSE](./LICENSE). Use and adapt it for your own projects.
