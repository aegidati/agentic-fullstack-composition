# Fullstack Composition Starter Pack

This starter provides a complete **Docker Compose configuration** to run your full-stack application with a single command:

```bash
docker compose up
```

All services—PostgreSQL database, Node.js backend, and React/Vite frontend—run in Docker containers with automatic health checks and service orchestration.

## Prerequisites

- **Docker** (v20.10+) and **Docker Compose** (v2.0+)
  - [Install Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Node.js** (v20+) and **npm** (for initial setup outside Docker, if needed)

## Installation

### For a New Derived Project

If you're starting a new full-stack project, copy this composition starter along with the other starters into your project:

```bash
# Create your project structure
mkdir my-fullstack-app
cd my-fullstack-app

# Copy starters (using git subtree or manual copy)
git subtree add --prefix app/backend https://github.com/aegidati/agentic-architecture-starters.git clean-backend/app
git subtree add --prefix app/web https://github.com/aegidati/agentic-architecture-starters.git react-spa/app
git subtree add --prefix app/composition https://github.com/aegidati/agentic-architecture-starters.git fullstack-composition/app
git subtree add --prefix app/contracts https://github.com/aegidati/agentic-architecture-starters.git api-contracts-openapi/app
git subtree add --prefix app/infra https://github.com/aegidati/agentic-architecture-starters.git postgres-dev/app
```

**Or manually:**

```bash
mkdir -p app/backend app/web app/composition app/contracts app/infra
# Copy directories from each starter pack into the appropriate locations
```

### Project Layout (in Derived Project)

```
my-fullstack-app/
├── app/
│   ├── backend/              ← From clean-backend starter
│   │   ├── package.json
│   │   ├── src/
│   │   └── tsconfig.json
│   ├── web/                  ← From react-spa starter
│   │   ├── package.json
│   │   ├── vite.config.ts
│   │   └── src/
│   ├── composition/          ← From this starter
│   │   ├── docker-compose.yml
│   │   ├── docker/
│   │   ├── scripts/
│   │   └── .env.example
│   ├── contracts/            ← From api-contracts-openapi starter
│   │   └── openapi/
│   └── infra/                ← From postgres-dev starter
│       └── docker-compose.yml (optional; composition may use its own postgres service)
└── README.md
```

## Quick Start

### 1. Configure Environment

```bash
cd app/composition
cp .env.example .env
# Edit .env with your settings (optional; defaults are provided)
```

**Default `.env` values:**
- `POSTGRES_DB`: composition_db
- `POSTGRES_USER`: appuser
- `POSTGRES_PASSWORD`: changeme_db_password ⚠️ **Change in production!**
- `POSTGRES_PORT`: 5432
- `BACKEND_PORT`: 3000
- `WEB_PORT`: 8080
- `VITE_API_BASE_URL`: http://backend:3000

### 2. Start All Services

```bash
./scripts/up.sh
```

This will:
- Create `.env` from `.env.example` if it doesn't exist
- Build and start PostgreSQL, Backend, and Web containers
- Perform health checks
- Display service URLs

**Expected output:**
```
✅ Composition is starting...

Waiting for services to be healthy...
CONTAINER ID   IMAGE                       STATUS         PORTS
abc123...      composition-postgres        Up 2s          5432/tcp, 0.0.0.0:5432->5432/tcp
def456...      fullstack-composition-backend_1   Up 1s   0.0.0.0:3000->3000/tcp
ghi789...      fullstack-composition-web_1       Up 1s   0.0.0.0:8080->80/tcp

📋 Service URLs:
  Backend Health: http://localhost:3000/health
  Web Frontend: http://localhost:8080
  Database: localhost:5432
```

### 3. Verify Services

```bash
./scripts/smoke-check.sh
```

This will validate:
- ✅ PostgreSQL is accepting connections
- ✅ Backend `/health` endpoint responds with HTTP 200
- ✅ Web frontend root (`/`) responds with HTTP 200

### 4. Access Services

| Service | URL | Access |
|---------|-----|--------|
| **Web Frontend** | http://localhost:8080 | Open in browser |
| **Backend Health** | http://localhost:3000/health | Health check endpoint |
| **PostgreSQL** | localhost:5432 | Use psql or DB client |

Example with `psql`:
```bash
psql -h localhost -p 5432 -U appuser -d composition_db
```

### 5. Stop Services

```bash
./scripts/down.sh
```

To also remove volumes (delete database):
```bash
docker compose down -v
```

## Docker Compose Structure

### Services

#### **postgres** (postgres:16-alpine)
- Database service running PostgreSQL 16
- **Port**: `${POSTGRES_PORT}` (default 5432)
- **Volume**: `postgres_data` (persists between restarts)
- **Health Check**: Uses `pg_isready` command
- **Network**: Internal `composition_network`

#### **backend** (Node.js 20)
- Builds from `../backend/` using `docker/backend.Dockerfile`
- **Port**: `${BACKEND_PORT}` (default 3000)
- **Environment**: 
  - `DATABASE_URL`: Automatically set to postgres connection string
  - `NODE_ENV`: production
- **Health Check**: `GET /health` endpoint
- **Depends On**: PostgreSQL (waits for healthy status)
- **Network**: Internal `composition_network`

#### **web** (Nginx with React/Vite build)
- Builds from `../web/` using `docker/web.Dockerfile`
- Multi-stage build: compiles TypeScript + React → serves static files with Nginx
- **Port**: `${WEB_PORT}` (default 8080)
- **Environment**: `VITE_API_BASE_URL=http://backend:3000` (tells frontend where backend is)
- **Health Check**: `GET /` endpoint
- **Depends On**: Backend (waits for healthy status)
- **Network**: Internal `composition_network`

### Networking

Services communicate via **internal Docker network** (`composition_network`):
- Backend connects to database: `postgresql://appuser:password@postgres:5432/composition_db`
- Web frontend connects to backend: `http://backend:3000`

External access (from host):
- Backend: http://localhost:3000
- Web: http://localhost:8080
- PostgreSQL: localhost:5432 (if exposed)

### Health Checks

All services have health checks that docker-compose monitors:

```yaml
healthcheck:
  test: [check command]
  interval: 10s          # Check every 10 seconds
  timeout: 5s            # Timeout after 5 seconds
  retries: 5             # Consider unhealthy after 5 failed checks
```

Services respect `depends_on: condition: service_healthy` to ensure proper startup order.

## Configuration

### Environment Variables

Edit or create `.env` in `app/composition/`:

```bash
# Database
POSTGRES_DB=composition_db
POSTGRES_USER=appuser
POSTGRES_PASSWORD=changeme_db_password
POSTGRES_PORT=5432

# Backend
BACKEND_PORT=3000

# Web
WEB_PORT=8080
VITE_API_BASE_URL=http://backend:3000
```

**Note**: The `VITE_API_BASE_URL` in the `.env` is used at **build time** to embed API calls in the frontend. If you only need to change the runtime backend URL, modify the Dockerfile or add a build argument.

### Backend Configuration

The backend receives these environment variables automatically:
- `NODE_ENV=production`
- `DATABASE_URL=postgresql://[user]:[password]@postgres:5432/[db]`
- `PORT=3000`

Add additional backend env vars in `docker-compose.yml` under `backend.environment`.

### Web Configuration

The web build receives:
- `VITE_API_BASE_URL` (injected at build time)

Modify `docker/web.Dockerfile` or `docker-compose.yml` to pass runtime environment variables if needed.

## Troubleshooting

### Issue: "Port already in use"
```
docker: Error response from daemon: driver failed programming external connectivity...
Bind to 0.0.0.0:3000: Only one usage of each socket address...
```

**Solution**: Change ports in `.env`:
```bash
BACKEND_PORT=3001      # Use 3001 instead of 3000
WEB_PORT=8081          # Use 8081 instead of 8080
POSTGRES_PORT=5433     # Use 5433 instead of 5432
```

Then restart:
```bash
./scripts/down.sh
./scripts/up.sh
```

### Issue: Backend can't connect to database

Check logs:
```bash
docker compose logs backend
```

Ensure:
- `.env` file exists with `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- Backend service is waiting for postgres health check: `depends_on.postgres.condition: service_healthy`
- Backend app uses `DATABASE_URL` env variable (or uses `postgres` hostname)

### Issue: Web frontend shows blank page

Check logs:
```bash
docker compose logs web
```

Ensure:
- Web app built successfully: `npm run build` produces `dist/` directory
- `VITE_API_BASE_URL` points to correct backend (default: `http://backend:3000`)
- Nginx is serving files from `/usr/share/nginx/html`

### Issue: Health check failing

View detailed service status:
```bash
docker compose ps
docker compose logs postgres
docker compose logs backend
docker compose logs web
```

Health checks can fail if:
- Backend `/health` endpoint not implemented
- PostgreSQL password incorrect
- Port conflicts
- Services not fully started yet (health checks retry; give them time)

### Debug Mode

Get detailed output:
```bash
# View logs from all services
docker compose logs -f

# View logs from specific service
docker compose logs -f backend
docker compose logs -f postgres
docker compose logs -f web

# Inspect container
docker compose exec backend sh
docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}
```

## Common Tasks

### Rebuild containers after code changes

```bash
docker compose up --build
# or
docker compose up -d --build
```

### Reset database

```bash
docker compose down -v
docker compose up -d
```

### View database from command line

```bash
docker compose exec postgres psql -U appuser -d composition_db
```

### Restart a single service

```bash
docker compose restart backend
docker compose restart web
docker compose restart postgres
```

### Run one-off commands

```bash
# Run migrations on backend
docker compose exec backend npm run migrate

# Run tests
docker compose exec backend npm test
```

## Extending the Composition

### Add a new service

Edit `docker-compose.yml`:

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - composition_network
```

### Modify Dockerfiles

- **Backend**: Edit `docker/backend.Dockerfile` if clean-backend doesn't include a Dockerfile
- **Web**: Edit `docker/web.Dockerfile` to change build or runtime behavior
- **Nginx**: Edit `docker/nginx.conf` for routing, caching, or security headers

### Mount source code for development

For faster iteration during development, mount source instead of rebuilding:

```yaml
backend:
  volumes:
    - ../backend:/app
```

Then use `npm install && npm start` (no build step).

## Architecture Notes

This composition follows these principles:

1. **Multi-stage Builds**: Backend and web both use multi-stage builds to minimize image size
2. **Health Checks**: All services report health; startup order is orchestrated
3. **Service Names for Networking**: Backend talks to "postgres" (not IP); Web talks to "backend"
4. **Volume Persistence**: Database data is stored in a named volume (`postgres_data`)
5. **Environment Isolation**: Each service reads from `.env` or gets injected vars
6. **Nginx for Web**: Static build + Nginx = fast, cacheable frontend (not a dev server)

For development (hot reload), consider running the web dev server locally instead:
```bash
cd app/web
npm install
npm run dev
```

Then point to `http://localhost:5173` while composition backend runs in Docker.

## Decisions Made

- **Backend Build Approach**: Multi-stage build with Node 20-alpine for small image
- **Web Serving**: Static build + Nginx (not Vite dev server) for production-like behavior
- **PostgreSQL Version**: 16-alpine for stability and small size
- **Health Checks**: Service-specific (postgres via pg_isready, backend via /health, web via /status)
- **Networking**: Internal Docker network for service-to-service; exposed ports for host access
- **Restart Policy**: `unless-stopped` for all services (restarts on failure but respects manual stop)

## Next Steps

1. **Implement Backend Endpoints**: Set up TypeScript/Express endpoints with `/health` check
2. **Build Frontend**: Ensure React app has `npm run build` and connects to backend
3. **Define API Contracts**: See `app/contracts/` from api-contracts-openapi starter
4. **Add Migrations**: Database migration scripts in backend startup
5. **Create ADRs**:
   - ADR-001: Architecture decision on composition vs. separate stacks
   - ADR-002: Contract strategy (API first, mock servers, etc.)

## Support

For issues or questions:
- Check **Troubleshooting** section above
- View `docs/SERVICE-MAP.md` for architecture diagram
- Review `.env.example` for all available configuration options

---

**Last Updated**: March 2026  
**Version**: 1.0
