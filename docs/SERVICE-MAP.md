# Service Architecture Map

This document outlines the service dependencies and communication patterns for the fullstack composition.

## System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host Machine                            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Docker Compose Network                     │   │
│  │          (composition_network, bridge driver)           │   │
│  │                                                         │   │
│  │  ┌──────────────────┐  ┌──────────────────────────┐   │   │
│  │  │   PostgreSQL     │  │   Backend API            │   │   │
│  │  │   (postgres:16)  │  │   (Node.js 20)           │   │   │
│  │  │                  │  │                          │   │   │
│  │  │ :5432 (internal) │◄─┤ :3000 (internal)         │   │   │
│  │  │ :5432 (exposed)  │  │ :3000 (exposed)          │   │   │
│  │  │                  │  │ Endpoints: /health       │   │   │
│  │  └──────────────────┘  │                          │   │   │
│  │         ▲               │ Routes API requests      │   │   │
│  │         │               └──────────────────────────┘   │   │
│  │         │                        ▲                     │   │
│  │    pg_isready                    │                     │   │
│  │         │                   Service: backend           │   │
│  │         │                   Build: ../backend          │   │
│  │         │                   Dockerfile: backend.Dockerfile
│  │         │                                              │   │
│  │  Volume: postgres_data                 ┌──────────────────────────┐
│  │  Maps to: /var/lib/postgresql/data     │   Web Frontend           │
│  │  (persisted between restarts)          │   (Nginx + React/Vite)   │
│  │                                        │                          │
│  │                                        │ :80 (internal)           │
│  │  Service: postgres                     │ :8080 (exposed)          │
│  │  Image: postgres:16-alpine             │ Endpoints: /             │
│  │                                        │                          │
│  │                                        │ Static assets from build │
│  │                                        │ Nginx config: nginx.conf │
│  │                                        │                          │
│  │                                        │ Build: ../web            │
│  │                                        │ Dockerfile: web.Dockerfile
│  │                                        └──────────────────────────┘
│  │                                                 ▲
│  │                                                 │
│  │                                            Service: web
│  │                                            Build arg:
│  │                                            VITE_API_BASE_URL=
│  │                                              http://backend:3000
│  │
│  └─────────────────────────────────────────────────────────────┘
│
│  ┌─────────────────────────────────────────────────────────────┐
│  │  Host Machine Ports (access from browser/client)           │
│  │                                                             │
│  │  :${BACKEND_PORT} → backend:3000 (default: 3000)           │
│  │  :${WEB_PORT}     → web:80       (default: 8080)           │
│  │  :${POSTGRES_PORT}→ postgres:5432 (default: 5432)          │
│  │                                                             │
│  └─────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘


Browser/Client Access:
  Web Frontend:  http://localhost:8080
  API Health:    http://localhost:3000/health
  PostgreSQL:    localhost:5432 (with psql, etc.)
```

## Service Startup Order

Services are orchestrated to start in dependency order:

```
1. PostgreSQL (postgres)
   └─ Starts immediately
   └─ Health check: pg_isready -U ${POSTGRES_USER}
   └─ Waits until healthy

2. Backend (backend)
   └─ Depends on: postgres (condition: service_healthy)
   └─ Builds from: ../backend/
   └─ Env: DATABASE_URL=postgresql://user:pass@postgres:5432/db
   └─ Health check: curl http://localhost:3000/health
   └─ Waits until healthy

3. Web Frontend (web)
   └─ Depends on: backend (condition: service_healthy)
   └─ Builds from: ../web/
   └─ Build arg: VITE_API_BASE_URL=http://backend:3000
   └─ Health check: curl http://localhost:80/
   └─ Ready for client connections
```

## Communication Patterns

### Backend ↔ PostgreSQL

**Direction**: Backend initiates connections to PostgreSQL

**Protocol**: PostgreSQL wire protocol (port 5432)

**Connection String** (injected by docker-compose):
```
postgresql://appuser:password@postgres:5432/composition_db
```

**Within Docker Network**:
- Backend service name: `backend`
- Database service name: `postgres`
- Backend connects to: `postgres:5432`

**Example TypeScript Connection**:
```typescript
const url = process.env.DATABASE_URL;
// "postgresql://appuser:password@postgres:5432/composition_db"
```

### Web Frontend ↔ Backend

**Direction**: Frontend (browser) makes HTTP requests to backend

**Protocol**: HTTP/REST (port 3000)

**Base URL** (injected at build time):
```
VITE_API_BASE_URL=http://backend:3000
```

**Example Vite Environment Variable**:
```typescript
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;
// "http://backend:3000" (within docker network)
// or "http://localhost:3000" (from browser on host)
```

**From Browser**: http://localhost:3000/api/*  
**From Web Container**: http://backend:3000/api/*

## Data Flow Example: API Request

```
┌─────────────────────────────────────┐
│  User opens browser                 │
│  http://localhost:8080              │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Browser loads from Nginx (port 80) │
│  Gets React app index.html          │
│  Includes VITE_API_BASE_URL config  │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  React app running in browser       │
│  Makes API call to backend          │
│  fetch('http://localhost:3000/...')│
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Node.js Backend (port 3000)        │
│  Receives request                   │
│  Parses/executes business logic     │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Backend connects to PostgreSQL      │
│  Executes SQL query                 │
│  CONNECTION: postgres:5432          │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  PostgreSQL returns data            │
│  Stored in postgres_data volume     │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Backend returns response (JSON)    │
│  HTTP 200 to browser                │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  Browser renders data in UI         │
│  User sees the result               │
└─────────────────────────────────────┘
```

## Port Mapping

| Service | Internal Port | External Port (Host) | Environment Variable | Default |
|---------|---------------|----------------------|----------------------|---------|
| PostgreSQL | 5432 | 5432 | `POSTGRES_PORT` | 5432 |
| Backend | 3000 | 3000 | `BACKEND_PORT` | 3000 |
| Web (Nginx) | 80 | 8080 | `WEB_PORT` | 8080 |

**Note**: Internal ports are fixed (3000, 80, 5432). External ports are configurable via `.env`.

## Health Check Summary

| Service | Health Check | Interval | Timeout | Retries |
|---------|--------------|----------|---------|---------|
| PostgreSQL | `pg_isready -U ${POSTGRES_USER}` | 10s | 5s | 5 |
| Backend | `curl http://localhost:3000/health` | 10s | 5s | 5 |
| Web | `curl http://localhost:80/` | 10s | 5s | 5 |

If a service fails health checks for too long, docker-compose marks it as unhealthy.  
Dependent services (like web → backend) won't start until dependencies are healthy.

## Environment Variable Flow

```
.env (root source of truth)
  ↓
docker-compose.yml (reads from .env)
  ├─ postgres container → POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
  ├─ backend container → DATABASE_URL (constructed), NODE_ENV, PORT
  └─ web container (build arg) → VITE_API_BASE_URL
       ↓
       web.Dockerfile uses VITE_API_BASE_URL at build time
       ↓
       compiled into dist/ directory (embedded in JS)
```

## Volume Management

| Volume | Path | Purpose | Persistence |
|--------|------|---------|-------------|
| `postgres_data` | `/var/lib/postgresql/data` | PostgreSQL data | Yes (survives down/up) |

**Clearing data**:
```bash
docker compose down -v   # -v removes all volumes
```

## Network Details

- **Network Name**: `composition_network`
- **Driver**: bridge
- **DNS**: Docker's embedded DNS allows `postgres` and `backend` hostnames

Services resolve via service name:
- `postgres` → IP of postgres container
- `backend` → IP of backend container
- `web` → IP of web container

## Extending the Architecture

To add a new service (e.g., Redis cache):

```yaml
# In docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    networks:
      - composition_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

# Backend can now connect to redis:6379
```

Backend code:
```typescript
const redis = new Redis('redis://redis:6379');
```

---

**Last Updated**: March 2026  
**Architecture Version**: 1.0
