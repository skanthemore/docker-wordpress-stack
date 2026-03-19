# Docker WordPress Stack (WordPress + MariaDB + Caddy)

A production-style local development stack for WordPress using Docker Compose, with:

- `WordPress` on Apache + PHP 8.3
- `MariaDB` 11.4
- `Caddy` as reverse proxy with automatic local TLS (`internal` CA)
- Persistent database and Caddy volumes
- WP-CLI preinstalled in the custom WordPress image

This setup is designed to look clean and professional on GitHub while staying simple to run.

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

Edit `.env` and set secure values:

- `MYSQL_ROOT_PASS`
- `MYSQL_PASS`
- `WP_PASSWORD`
- `WP_HOST`
- `WORDPRESS_URL`

Current defaults use:

- `WP_HOST=yourgost.local`
- `WORDPRESS_URL=https://yourgost.local`

### 2) Add local DNS entry

Map your local domain to localhost in `/etc/hosts`:

```bash
127.0.0.1 yourgost.local
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
https://yourgost.local
```

If your browser warns about the certificate, trust Caddy's local CA for your OS/browser (expected in local `internal` mode).

---

## Services and Versions

- **WordPress**: `wordpress:php8.3-apache`
- **PHP**: 8.3 (stable)
- **MariaDB**: `mariadb:11.4`
- **Reverse Proxy**: `lucaslorentz/caddy-docker-proxy:latest`

---

## Project Structure

```text
.
├── docker-compose.yml        # WordPress + MariaDB stack
├── Dockerfile                # Custom WordPress image with WP-CLI
├── .env                      # Runtime configuration
└── Caddy/
	 ├── docker-compose.yml    # Shared Caddy reverse proxy
	 └── web/                  # Optional static web root (if needed)
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

If you have write permission issues in the mounted WordPress files:

1. Set your `UID` in `.env` (`echo $UID`)
2. Fix ownership from project root:

```bash
sudo chown -R $USER:$USER ./web
```

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

Use and adapt this stack for your own projects.
