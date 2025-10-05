# Revive Adserver on Easypanel

Domain: `ads.rptecnologias.com.br`

## Files
- `Dockerfile` – builds PHP 8.2 + Apache and installs Revive Adserver.
- `docker-compose.yml` – services: `revive` (app), `db` (MariaDB 10.6), `phpmyadmin`.
- `.env` – your database credentials (already filled).

## Quick Deploy (Easypanel)
1. Create a **Compose** service in your project.
2. Connect this repository via **Git** _or_ paste these three files in a repo and link it.
3. Click **Deploy**. Wait until all services are running.
4. In **Domains**, attach `ads.rptecnologias.com.br` to service **revive** on internal port **80**, enable HTTPS.
5. Open the domain in your browser and complete the Revive installer:
   - DB Host: `db`
   - DB Name: `${DB_NAME}`
   - DB User: `${DB_USER}`
   - DB Password: `${DB_PASSWORD}`
   - Table prefix: `rv_` (default)
6. After finishing, **delete the `/install` folder** via the Revive prompt.

## Optional local testing
Uncomment the `ports` mappings in `docker-compose.yml` and run:
```
docker compose up -d
```
Then access:
- App: http://localhost:8080
- phpMyAdmin: http://localhost:8081
